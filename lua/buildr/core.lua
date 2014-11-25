buildr = buildr or { elements = {}, white = Color( 254, 254, 254 ) }

function buildr.open()
	local pnl = vgui.Create( "buildr_base" )
		pnl:MakePopup()
end
concommand.Add( "rhud_builder", buildr.open )

function buildr.register( name, info )
	local class = "buildr_element_" .. name:lower()
	buildr.elements[class] = {
		name = name,
		class = class,
		panel = info.panel,
		description = info.description,
		show_tweens = info.show_tweens
	}
	info.panel.class = class
	vgui.Register( class, info.panel, name == "Base" and "EditablePanel" or "buildr_element_base" )
end

function buildr.get( class )
	return buildr.elements[class:lower()]
end

local bg_color = Color( 80, 80, 80 )
function buildr.attach_panel_extras( pnl, nobutton, title )
	pnl.MenuBar = vgui.Create( "buildr_menubar", pnl )
	pnl.MenuBar:SetSize( pnl:GetWide(), 25 )
	pnl:ShowCloseButton( false )
	pnl:SetDraggable( false )
	if nobutton then
		pnl.MenuBar.Button:Remove()
	end
	pnl.MenuBar:SetText( title or "" )
	
	pnl.Paint = function( s, w, h )
		surface.SetDrawColor( bg_color )
		surface.DrawRect( 0, 0, w, h )
	end
end

function buildr.gui_mousechop( w, h )
	local x, y = gui.MousePos()
	if gui.MouseX() + w > ScrW() then x = ScrW() - w end
	if gui.MouseY() + h > ScrH() then y = ScrH() - h end
	return x, y
end

hook.Add( "HUDShouldDraw", "buildr_suppress", function()
	if buildr.in_editor then return false end
end )

file.CreateDir( "buildr" )
for _, d in pairs( { "builds", "builds/rhud", "builds/rim", "saves" } ) do
	file.CreateDir( "buildr/" .. d )
end

local formats = {
	rhud = {
		base = {
			"local HUD = RHUD:CreateHud()",
			"HUD.Name = \"%s\"",
			"HUD.Author = \"%s\"",
			"HUD.UsesAvatar = %s",
		},
		function_name = "function HUD:%s()",
		terminator = "end",
		scr = "()",
		start = 2,
	},
	rim = {
		base = {
			">>Name = %s",
			">>Author = %s",
		},
		function_name = "%s ->",
		terminator = "",
		scr = "",
		start = 1,
	}
}
local insert = table.insert
function buildr.build( format, elements )
	local hud = formats[format]
	local code = table.Copy( hud.base )
	
	local start = hud.start
	local bname = buildr.base.name or "buildr"
	code[start] = code[start]:format( bname )
	code[start + 1] = code[start + 1]:format( LocalPlayer():Nick() )
	
	local setup = {}
	local init = {}
	local drawables = {}
	local uses_avatar = false
	for z, elem in pairs( elements ) do
		if elem.avatar and not uses_avatar then uses_avatar = true end
		local posx, posy = elem:GetPos()
		local c = elem:GetColor()
		local vars = {
			x = "ScrW" .. hud.scr .. " * " .. posx/ScrW(),
			y =  "ScrH" .. hud.scr .. " * " .. posy/ScrH(),
			color = ("Color( %d, %d, %d, %d )"):format( c.r, c.g, c.b, c.a ),
		}
		
		local elem_code = elem:GetCode()
		for k, line in pairs( elem_code ) do
			elem_code[k] = line:gsub( "%$.-%$", function( match )
				local sub = match:sub( 2, -2 )
				return vars[sub] or elem:GetCodeVar( sub )
			end )
		end
		drawables[z] = table.Copy( elem_code )
		
		local head = elem:GetInitCode()
		for _, line in pairs( head ) do
			line = line:gsub( "%$.-%$", function( match )
				local sub = match:sub( 2, -2 )
				return vars[sub] or elem:GetCodeVar( sub )
			end )
			insert( init, line )
		end
		
		for _, l in pairs( elem:GetSetupCode() ) do insert( setup, l ) end
	end
	
	if format == "rhud" then
		code[start + 2] = code[start + 2]:format( tostring( uses_avatar ) )
	end
	
	for _, l in pairs( setup ) do insert( code, l ) end
	insert( code, "\n" )
	insert( code, hud.function_name:format( "Init" ) )
	for _, l in pairs( init ) do insert( code, "\t" .. l ) end
	insert( code, hud.terminator )
	insert( code, "" )
	
	insert( code, hud.function_name:format( "Draw" ) )
	for k, draws in ipairs( drawables ) do
		for _, l in pairs( draws ) do
			insert( code, "\t" .. l ) 
		end
	end
	insert( code, hud.terminator )
	
	code = table.concat( code, "\n" )
	
	code = code:gsub( "|%*", function( match )
		return "\" .. " .. match:sub( 5, -3 )
	end )
	
	code = code:gsub( "%*|", function( match )
		return " .. \""
	end )
	
	if format == "rhud" then
		local files = file.Find( "buildr/builds/rhud/*.txt", "DATA" )
		file.Write( "buildr/builds/rhud/" .. bname .. ".txt", code )
	else
		local files = file.Find( "buildr/builds/rim/*.txt", "DATA" )
		code = code:gsub( "RHUD:", "" )
		code = code:gsub( "PaintAvatar", "DrawAvatar" )
		code = code:gsub( "LocalPlayer%(%)", "Player" )
		
		local n = #files
		file.Write( "buildr/builds/rim/" .. bname .. ".txt", code )
		file.Write( "rim/" .. bname .. ".txt", code )
		RIM:Build( bname )
		RHUD:SelectHud( buildr.base.name or "buildr" )
	end
	
	buildr.save( elements, buildr.base.name )
end

function buildr.delete( name )
	file.Delete( "buildr/saves/" .. name )
	name = name:gsub( "%.dat$", "" )
	file.Delete( "buildr/builds/rim/" .. name .. ".txt" )
	file.Delete( "rim/" .. name .. ".txt" )
	if RIM then RIM.Huds[name] = nil end
	if RHUD then 
		RHUD:SelectHud( "none" )
		RHUD.Huds[name] = nil 
	end
end

function buildr.serialize( tab )
	local new = {}
	for k, v in pairs( tab ) do
		if type( k ) == "Panel" then k = k.id end
		if type( v ) == "Panel" then v = v.id end
		if type( k ) == "table" then k = buildr.serialize( k ) end
		if type( v ) == "table" then v = buildr.serialize( v ) end
		if not k then continue end
		new[k] = v
	end
	return new
end

function buildr.save( elements, name )
	local save = {}
	for id, panel in pairs( elements ) do
		save[id] = { __class = panel.class }
		for var in pairs( panel.SaveVariables ) do
			local set = panel[var]
			if not set then continue end
			if type( set ) == "Panel" then set = set.id end
			if type( set ) == "table" then
				set = buildr.serialize( set )
			end
			save[id][var] = set
		end
		save[id] = util.TableToJSON( save[id] )
	end
	
	save = util.TableToJSON( save )
	file.Write( "buildr/saves/" .. name .. ".dat", save )
	buildr.base:DoSaveEffect( true )
end

function buildr.load( name )
	buildr.base.Working = true
	buildr.base.MenuBar:SetText( name:sub( 1, -5 ) )
	
	local data = file.Read( "buildr/saves/" .. name, "DATA" )

	if not data or not data:find( "." ) then 
		buildr.base:DoSaveEffect( false )
	return end
	
	local tab = util.JSONToTable( data )
	if not tab then buildr.base:DoSaveEffect( false ) return end
	
	local tovars = {}
	for id, json in ipairs( tab ) do
		local vars = util.JSONToTable( json )
		
		local info = buildr.elements[vars.__class]
		if not info then continue end
		
		local pnl = buildr.base:CreateElement( vars.__class, info )
		tovars[pnl] = vars
	end
	
	for pnl, vars in pairs( tovars ) do
		for var, val in pairs( vars ) do
			if var:find( "^__" ) then continue end
			pnl:LoadSavedVar( var, val )
		end
	end
	
	buildr.base.name = name:gsub( "%.dat$", "" )
end