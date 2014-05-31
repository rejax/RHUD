local HUD = RHUD:CreateHud()
HUD.Name = "Basic"
HUD.Gamemode = "sandbox"

HUD.UsesAvatar = true

local we = { weight = 600 }
RHUD:CreateFont( "rhud_default", "Roboto", 28, we )
RHUD:CreateFont( "rhud_default_med", "Roboto", 24, we )
RHUD:CreateFont( "rhud_default_sml", "Roboto", 20, we )

function HUD:Init()
	self.Avatar:SetPos( 28, ScrH()-92 )
end

function HUD:Draw()
	local rotate = HSVToColor( CurTime() % 360, .5, .5 )
	local av_border = HSVToColor( CurTime() % 360, 1, 1 )
	surface.SetFont( "rhud_default" )
	local w = math.max( 130, surface.GetTextSize( self.Player:Nick() ) )
	
	draw.RoundedBox( 0, 20, ScrH() - 100, 90 + w, 80, rotate )
	draw.RoundedBox( 0, 22, ScrH() - 98, 86 + w, 76, Color( 20, 20, 20 ) )
	
	draw.RoundedBox( 0, 26, ScrH()-94, 68, 68, av_border )
	RHUD:PaintAvatar()
	
	draw.SimpleText( self.Player:Nick(), "rhud_default", 98, ScrH() - 96, color_white )
	draw.SimpleText( self.Player:GetUserGroup(), "rhud_default_med", 98, ScrH() - 70, color_white )
	
	draw.SimpleText( "Health: " .. self.Player:Health(), "rhud_default_sml", 98, ScrH() - 45, color_white )
	
	if self.Player:Armor() > 0 then
		draw.SimpleText( "Health: " .. self.Player:Health(), "rhud_default_sml", 98, ScrH() - 45, color_white )
	end
end

HUD.Scoreboard = {}
HUD:Include( "HUD", "scoreboard.lua" )

RHUD:RegisterHud( HUD )