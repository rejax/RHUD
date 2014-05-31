local HUD = RHUD:CreateHud()
HUD.Name = "Moose"
HUD.Gamemode = "deathrun"

HUD.UsesAvatar = true
HUD.Config.DarkBorder = { enabled = false, info = "Use a dark border instead of white" }

RHUD:CreateFont( "rhud_moose", "Coolvetica", 48 )
RHUD:CreateFont( "rhud_moose_big", "Coolvetica", 50 )

RHUD:CreateFont( "rhud_moose_name", "Coolvetica", 30 )
RHUD:CreateFont( "rhud_moose_name_big", "Coolvetica", 32 )

function HUD:Init( me, avatar )
	self.Avatar:SetPos( 27, ScrH()-93 )
	self.Avatar:SetSize( 66, 66 )
	
	self.Teams = {
		[TEAM_RUNNER] = "Runner",
		[TEAM_DEATH] = "Death",
		[TEAM_SPECTATOR] = "Spectator",
		[TEAM_CONNECTING] = "Connecting",
	}
end

local hp_w = 0
function HUD:Draw()
	local w = RHUD:GetHealthPercentage( self.Player ) * 173
	hp_w = hp_w == w and hp_w or Lerp( .1, hp_w, w )
	local col = self:GetConfigBool( "DarkBorder" )
	if col then col = color_black else col = color_white end
	
	if self.Player:Alive() then
		draw.RoundedBox( 0, 94, ScrH()-60, 175, 25, col )
		draw.RoundedBox( 0, 95, ScrH()-59, 173, 23, Color( 90, 20, 20 ) )
		draw.RoundedBox( 0, 95, ScrH()-59, hp_w, 11.5, Color( 220, 50, 50 ) )
		draw.RoundedBox( 0, 95, ScrH()-48.5, hp_w, 11.5, Color( 190, 50, 50 ) )
		
		draw.SimpleText( self.Player:Health(), "rhud_moose", 191, ScrH()-68, color_black )
		draw.SimpleText( self.Player:Health(), "rhud_moose", 189, ScrH()-70, color_white )
	end

	if LocalPlayer():Alive() then
		if LocalPlayer() ~= self.Player then self.Avatar:SetPlayer( LocalPlayer(), 64 ) end
		self.Player = LocalPlayer()
		
		draw.SimpleText( self.Teams[self.Player:Team()], "rhud_moose_name", 100, ScrH()-88, color_black )
		draw.SimpleText( self.Teams[self.Player:Team()], "rhud_moose_name", 98, ScrH()-90, color_white )
	else
		local ob = LocalPlayer():GetObserverTarget()
		if ob and IsValid( ob ) and ob:IsPlayer() then
			if self.Player ~= ob and ob:Alive() then
				self.Avatar:SetPlayer( ob, 64 )
			end
			self.Player = ob
			draw.SimpleText( self.Player:Nick(), "rhud_moose_name", 100, ScrH()-88, color_black )
			draw.SimpleText( self.Player:Nick(), "rhud_moose_name", 98, ScrH()-90, color_white )
		else
			if self.Player ~= LocalPlayer() then self.Avatar:SetPlayer( LocalPlayer(), 64 ) end
			self.Player = LocalPlayer()
			draw.SimpleText( "Spectating", "rhud_moose_name", 100, ScrH()-73, color_black )
			draw.SimpleText( "Spectating", "rhud_moose_name", 98, ScrH()-75, color_white )
		end
	end
	
	draw.RoundedBox( 0, 26, ScrH()-94, 68, 68, col )
	RHUD:PaintAvatar()
end

RHUD:RegisterHud( HUD )