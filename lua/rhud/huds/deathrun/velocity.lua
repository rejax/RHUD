local HUD = RHUD:CreateHud()
HUD.Name = "Velocity"
HUD.Gamemode = "deathrun"
HUD.UsesAvatar = true
HUD.Config.DrawArrow = { enabled = false, info = "Draw an arrow on the velocity bar that rotates based on speed" }

RHUD:CreateFont( "rhud_velocity", "Tahoma", 18 )
RHUD:CreateFont( "rhud_velocity_team", "Tahoma", 18, { weight = 800 } )

local math = math
local floor = math.floor
local min = math.min
local max = math.max

--[[LEETNOOB]]--
local reg = debug.getregistry()
HUD.GetVelocity = reg.Entity.GetVelocity
HUD.Length = reg.Vector.Length
--[[]]--

function HUD:Init()
	self.Avatar:SetPos( 40, ScrH() - 94 )
	self.Avatar:SetSize( 64, 64 )
	
	self.Teams = {
		[TEAM_RUNNER] = { name = "Runner", col = Color( 80, 80, 190 ) },
		[TEAM_DEATH] = { name = "Death", col = Color( 130, 60, 60 ) },
		[TEAM_SPECTATOR] = { name = "Spectator", col = color_white },
		[TEAM_CONNECTING] = { name = "Connecting", col = color_white }
	}
	self.Velocity = 0
end

local max_velocity = 300
local arrow = surface.GetTextureID( "vgui/cursors/up.vtf" )
local avatar_set = false

local info_pos = { [true] = ScrH() - 90, [false] = ScrH() - 48 }
local info_y = ScrH() - 90
local healthbar_w = 0
function HUD:Draw()
	local observer = LocalPlayer():GetObserverTarget()
	observer = IsValid( observer ) and observer or LocalPlayer()
	if self.Player ~= observer then
		self.Player = observer
		avatar_set = false
	end
	if not avatar_set then self.Avatar:SetPlayer( self.Player, 64 ) end
	
	local vel = self.GetVelocity( self.Player )
	local len = self.Length( vel )
	local len_dec = min( ( len / max_velocity ), 1 )
	local name = self.Player:Nick()
	local p_team = self.Teams[self.Player:Team()]
	local team_name, team_col = p_team.name, p_team.col
	local team_text = self.Player:Alive() and team_name or "Dead"
	
	if self.Player:Alive() then
		draw.RoundedBox( 0, 40, ScrH() - 70, 300, 40, Color( 70, 70, 70 ) )
		draw.RoundedBox( 0, 42, ScrH() - 68, 296, 36, Color( 90, 90, 90 ) )
		
		local velocitybar_w = len_dec * 296
		draw.RoundedBox( 0, 42, ScrH() - 68, 296, 18, Color( 60, 120, 60 ) )
		draw.RoundedBox( 0, 42, ScrH() - 68, velocitybar_w, 18, Color( 60, min( 255, 80 + ( 80 * len_dec ) ), 60 ) )
		draw.SimpleText( floor( len ), "rhud_velocity", 110, ScrH() - 68, color_white )
		
		local dest = ( self.Player:Health() / 100 ) * 232
		healthbar_w = healthbar_w == dest and dest or Lerp( .1, healthbar_w, dest )
		draw.RoundedBox( 0, 106, ScrH() - 50, 232, 18, Color( 80, 60, 60 ) )
		draw.RoundedBox( 0, 106, ScrH() - 50, healthbar_w, 18, Color( 150, 60, 60 ) )
		draw.SimpleText( self.Player:Health(), "rhud_velocity", 108, ScrH() - 50, color_white )
		
		if self:GetConfigBool( "DrawArrow" ) then
			local rot = ( -90 * ( len_dec ) )
			surface.SetDrawColor( 255, 255, 255, 255 * len_dec )
			surface.SetTexture( arrow )
			surface.DrawTexturedRectRotated( 120 + ( len_dec * 196 ), ScrH() - 50, 30, 30, rot )
		end
	end
	
	surface.SetFont( "rhud_velocity" )
	local name_w = surface.GetTextSize( name .. " - " )
	local team_w = surface.GetTextSize( team_text )
	
	local desired = info_pos[self.Player:Alive()]
	info_y = info_y == info_pos[desired] and info_y or Lerp( .1, info_y, desired )
	draw.RoundedBox( 0, 104, info_y, 20 + name_w + team_w, 20, Color( 50, 50, 50, 255 ) )
	draw.SimpleText( name .. " - ", "rhud_velocity", 110, info_y, color_white )
	
	draw.SimpleText( team_text, "rhud_velocity_team", 110 + name_w, info_y, team_col )
	
	draw.RoundedBox( 0, 38, ScrH() - 96, 68, 68, Color( 50, 50, 50 ) )
	RHUD:PaintAvatar()
end

RHUD:RegisterHud( HUD )