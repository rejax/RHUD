--
--	CreateFont 
--	Creates fonts, duh.
--
function RHUD:CreateFont( name, _font, _size, extra )
	local font_tab = {
		font = _font,
		size = _size
	}
	if extra then for k, v in pairs( extra ) do font_tab[k] = v end end
	
	surface.CreateFont( name, font_tab )
end

--
--	DrawImageLabel
--	Draws an image with a label. img HAS to be an IMaterial
--
function RHUD:DrawImageLabel( x, y, img, font, text, color, imgcol )
	surface.SetMaterial( img )
	if imgcol then
		surface.SetDrawColor( imgcol.r, imgcol.g, imgcol.b )
	else
		surface.SetDrawColor( 255, 255, 255 )
	end
	surface.DrawTexturedRect( x, y, 16, 16 )
	
	surface.SetFont( font )
	surface.SetTextPos( x + 20, y )
	surface.SetTextColor( color.r, color.g, color.b )
	surface.DrawText( text )
end

--
--	returns a health percentage (decimal 0-1)
--
function RHUD:GetHealthPercentage( ply, max )
	max = max or 100
	local hp = ply:Health()
	local div = math.min( hp/max, 1 )
	return div
end

--
--	returns a horse
--
function RHUD:GetArmorPercentage( ply, max )
	max = max or 100
	local armor = ply:Armor()
	local div = math.min( armor/max, 1 )
	return div
end

--
--	paints the avatar
--
function RHUD:PaintAvatar()
	self.Avatar:SetPaintedManually( false )
	self.Avatar:PaintManual()
	self.Avatar:SetPaintedManually( true )
end

--
--	paints the playermodel
--
function RHUD:PaintModel()
	self.PlayerModel:SetPaintedManually( false )
	self.PlayerModel:PaintManual()
	self.PlayerModel:SetPaintedManually( true )
end

--
--	Get/Set DarkRPVars
--	I wonder what they're used for
--
AccessorFunc( RHUD, "DarkRPVars", "DarkRPVars" )
hook.Add( "DarkRPVarChanged", "RHUD_DarkRPVars", function( _, var, _, val ) RHUD.DarkRPVars[var] = val end )

--
--	Allows huds to include files in the same director, to make
--	file structure neater.
--	good for scoreboards or something
--	it is called with HUD:Include, so the only args you need to supply are
--	name, the name that the included file will use as a reference to the hud
--	_file, to files name, with .lua
--
function RHUD:Include( hud, name, _file )
	if not hud or not hud.Gamemode then return end
	local path = "rhud/huds/" .. hud.Gamemode:lower() .. "/" .. hud.Name:lower() .. "/" .. _file
	if not file.Exists( path, "LUA" ) then 
		MsgC( Color( 255, 0, 0 ), "RHUD.IncludeExternal - No such file '" .. _file .. "' for hud '" .. hud.Name .. "' - check your paths!\n" )
	return end
	
	local env = { [name] = hud }
	local fenv = getfenv( 0 )
	
	setmetatable( env, { __index = _G } )
	setfenv( 0, env )
		include( path )
	setfenv( 0, fenv )
end