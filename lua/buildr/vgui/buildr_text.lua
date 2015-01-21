local TEXT = {}
TEXT.SaveVariables = {
	font_tab = function( self, var )
		self.font_tab = var
		surface.CreateFont( var.name, {
				size = var.size,
				font = var.font,
				weight = var.weight,
			} )
	end,
	text = true,
}

surface.CreateFont( "buildr_default", {
	font = "Arial",
	size = 24,
	weight = 600
} )

surface.CreateFont( "buildr_textpreview", {
	font = "Comic Sans MS",
	size = 32,
	weight = 600
} )

local info = ([[
	#n becomes your nickname
	#{code} is parsed as lua
	#rp(var) - getDarkRPVar
]]):gsub( "\t", "   " )

TEXT.font_tab = { name = "buildr_default", font = "Arial", size = 24, weight = 600, text = "TEXT" }
TEXT.text = "TEXT"

function TEXT:Init()
	self:SizeToText()
end

function TEXT:GetCode()
	return { ('draw.SimpleText( "%s", "%s", $x$, $y$, $color$ )'):format( self:GetConcatText(), self.font_tab.name ) }
end

function TEXT:GetInitCode()
	return {}
end

function TEXT:GetSetupCode()
	local font = "RHUD:CreateFont( \"%s\", \"%s\", %d, { weight = %d } )"
	local ft = self.font_tab
	font = font:format( ft.name, ft.font, ft.size, ft.weight )
	return { font }
end

function TEXT:SizeToText()
	surface.SetFont( self.font_tab.name )
	local w, h = surface.GetTextSize( self:GetTextParsed() )
	self:SetSize( w, h )
end

function TEXT:AddRightClickOptions( menu )
	menu:AddOption( "Edit Text", function() self:EditText() end ):SetIcon( "icon16/pencil.png" )
	menu:AddOption( "Create Font", function() self:CreateFont() end ):SetIcon( "icon16/font.png" )
end

function TEXT:CreateFont()
	local popup = vgui.Create( "DFrame", buildr.base )
		popup:SetTitle( "Create Font" )
		popup:SetSize( 500, 250 )
		popup:Center()
		popup:MakePopup()
		self.SuppressClick = popup
		
	local prop = vgui.Create( "DProperties", popup )
		prop:SetPos( 3, 25 )
		prop:SetSize( popup:GetWide()/2 - 3, popup:GetTall() - 25 )
		
		local tcolor = buildr.white
		local text_col = prop:CreateRow( "Preview", "Text Color" )
			text_col:Setup( "VectorColor" )
			text_col:SetValue( Vector( 1, 0, 0 ) )
			text_col.DataChanged = function( _, val )
				val = (" "):Explode( val )
				tcolor = Color( val[1] * 255,  val[2] * 255, val[3] * 255 )
			end
		
		local dtext = "ass"
		local text = prop:CreateRow( "Preview", "Preview Text" )
			text:Setup( "Generic" )
			text:SetValue( "ass" )
			text.DataChanged = function( _, val ) dtext = val end
			
		local bg = prop:CreateRow( "Preview", "Background Color" )
			bg:Setup( "VectorColor" )
			bg:SetValue( Vector( 0, 0, 0 ) )
			
		local bgcol = color_black
			bg.DataChanged = function( _, val )
				val = (" "):Explode( val )
				bgcol = Color( val[1] * 255,  val[2] * 255, val[3] * 255 )
			end
	
	local font = "buildr_default"
	
	local size = prop:CreateRow( "Font", "Size" )
		size:Setup( "Int", { max = 200 } )
		size:SetValue( 24 )
		size._Value = 24
		size.DataChanged = function( s, v ) s._Value = v end
		
	local font_name = prop:CreateRow( "Font", "Font" )
		font_name:Setup( "Generic" )
		font_name:SetValue( "Arial" )
		font_name._Value = "Arial"
		font_name.DataChanged = function( s, v ) s._Value = v end
			
	local weight = prop:CreateRow( "Font", "Weight" )
		weight:Setup( "Int", { max = 800 } )
		weight:SetValue( 600 )
		weight._Value = 600
		weight.DataChanged = function( s, v ) s._Value = v end
	
	local pnl = vgui.Create( "Panel", popup )
		pnl:SetPos( popup:GetWide()/2 + 3, 25 )
		pnl:SetSize( popup:GetWide()/2 - 6, popup:GetTall() - 28 )
		pnl.Paint = function( s, w, h )
			surface.SetDrawColor( bgcol )
			surface.DrawRect( 0, 0, w, h )
			
			surface.SetFont( font )
			surface.SetTextPos( 3, h/2 )
			surface.SetTextColor( tcolor )
			surface.DrawText( dtext )
		end
	
	local fname = "buildr_generated_" .. os.time()
	local rb = vgui.Create( "DButton", popup )
		rb:SetText( "Render" )
		rb:SetPos( 13, popup:GetTall() - 50 )
		rb:SetSize( popup:GetWide()/2 - 20, 20 )
		rb.DoClick = function()
			surface.CreateFont( fname, {
				size = size._Value,
				font = font_name._Value,
				weight = weight._Value,
			} )
			font = fname
		end
		
	local finish = vgui.Create( "DButton", popup )
		finish:SetText( "Finish" )
		finish:SetPos( 13, popup:GetTall() - 25 )
		finish:SetSize( popup:GetWide()/2 - 20, 20 )
		finish.DoClick = function()
			rb:DoClick()
			self.font_tab = {
				size = size._Value,
				font = font_name._Value,
				weight = weight._Value,
				name = fname
			}
			surface.CreateFont( fname, {
				size = size._Value,
				font = font_name._Value,
				weight = weight._Value,
			} )
			self:SizeToText()
			popup:Remove()
		end
end

function TEXT:EditText()
	local popup = vgui.Create( "DFrame", buildr.base )
		popup:SetTitle( "Edit Text" )
		popup:SetSize( 200, 200 )
		popup:Center()
		popup:MakePopup()
		self.SuppressClick = popup
	
	local lab = vgui.Create( "DLabel", popup )
		lab:Dock( TOP )
		lab:SetText( info )
		lab:SetTextColor( buildr.white )
		lab:SizeToContents()
		
	local entry = vgui.Create( "DTextEntry", popup )
		entry:Dock( BOTTOM )
		entry:SelectAllOnFocus( true )
		entry:SetText( self.text )
		entry.OnChange = function( s )
			self.text = s:GetValue()
			self.font_tab.text = self.text
			self:SizeToText()
		end
end

local escapes = {
	["#n"] = { 
		function() 
			return LocalPlayer():Nick() 
		end, 
		function() 
			return "LocalPlayer():Nick()" 
		end 
	},
	["#%b{}"] = { 
		function( text )
			local code = text:sub( 3, -2 )
			local env = { __index = _G }
			local meta = setmetatable( { RETVAL = "???" }, env )
			local comp = "RETVAL=" .. code
			local func = CompileString( comp, "error", false )
			if isstring( func ) then return func end
			setfenv( func, meta )
			func()
			
			return tostring( meta.RETVAL )
		end, 
		function( text )
			return "tostring( " .. text:sub( 3, -2 ) .. " )"
		end 
	},
	["#rp%b()"] = {
		function( text )
			return LocalPlayer():getDarkRPVar( text:sub(5, -2) )
		end,
		function( text )
			return "LocalPlayer():getDarkRPVar( \"" .. text:sub(5, -2) .. "\" )"
		end,
	}
}

function TEXT:GetConcatText()
	local t = self.text
	for pat, rep in pairs( escapes ) do
		t = t:gsub( pat, function( text )
			return "|*" .. rep[2]( text ) .. "*|" 
		end )
	end
	return t
end

function TEXT:GetTextParsed()
	local text = self.text
	if not text then return "????" end
	
	for pat, rep in pairs( escapes ) do
		text = text:gsub( pat, rep[1] )
	end
	
	return text
end
function TEXT:GetText() return self.text end

function TEXT:PaintPreview( w, h, pnl )
	surface.SetDrawColor( color_black )
	surface.DrawRect( 0, 0, w, h )
	
	surface.SetFont( "buildr_textpreview" )
	surface.SetTextColor( 255, 20, 147 )
	surface.SetTextPos( 5, 5 )
	surface.DrawText( "ass" )
end

function TEXT:Paint( w, h )
	surface.SetFont( self.font_tab.name )
	surface.SetTextColor( self:GetColor() )
	surface.SetTextPos( 0, 0 )
	surface.DrawText( self:GetTextParsed() )
end

buildr.register( "Text", {
	description = "draw words on the screen",
	panel = TEXT,
} )
