local HUD = RHUD:CreateHud()
HUD.Name = "fuck knows"
HUD.UsesAvatar = true
HUD.Gamemode = "darkrp"
HUD.DrawWhileDead = false

HUD.AvatarBorderColor = Color( 100, 100, 0 )
HUD.NameColor = Color( 255, 255, 255 )
HUD.WalletColor = Color( 255, 255, 255 )
HUD.JobColor = Color( 255, 255, 255 )

HUD.TopBarColor = Color( 100, 50, 50 )
HUD.LowerBarColor = Color( 80, 30, 30 )
HUD.BottomBarColor = Color( 10, 50, 20 )

HUD.HealthBarColor = Color( 150, 30, 20 )
HUD.HealthBarTrailColor = Color( 130, 10, 0 )
HUD.HealthTextBGColor = Color( 50, 50, 50 )
HUD.HealthColor = Color( 255, 255, 255 )

HUD.DrawBackground = true

local we = { weight = 400 }
RHUD:CreateFont( "rhud_flat", "Roboto Lt", 32, we )
RHUD:CreateFont( "rhud_flat_sml", "Roboto Lt", 24, we )
RHUD:CreateFont( "rhud_flat_hp", "Tahoma", 16, we )

local draw = draw
local surface = surface
local ScrH = ScrH

function HUD:Init()
	self:AdjustAvatar()
	
	self.NameBarLength = 100
	self.NameBarLengthMax = 160
end

function HUD:OnDeath()
	self.NameBarLength = 100
end

function HUD:AdjustAvatar()
	self.Avatar:SetPos( 40, ScrH()-124 )
end

local health_opt = 114
local health_bar = 0
local health_trail = 0
function HUD:Draw()
	local me = self.Player
	local name = me:Nick()
	local job = me:getDarkRPVar( "job" )
	local salary = me:getDarkRPVar( "salary" )
	local job_with_salary = job .. " ($" .. salary .. ")"
	local wallet = me:getDarkRPVar( "money" )
	local bar_len = self.NameBarLength
	local scrh = ScrH()
	
	surface.SetFont( "rhud_flat" )
	local name_w, name_h = surface.GetTextSize( name )
	local job_w, job_h = surface.GetTextSize( job_with_salary )
	local dolla_w = surface.GetTextSize( wallet )
	
	if bar_len ~= ( 100 + name_w ) then
		bar_len = Lerp( .1, bar_len, 100 + name_w )
		self.NameBarLength = bar_len
	end
	
	local div = RHUD:GetHealthPercentage( self.Player )
	local h_len = health_opt * div
	health_bar = health_bar == h_len or Lerp( .1, health_bar, h_len )
	health_trail = health_trail == h_len or Lerp( .03, health_trail, h_len )
	
	if self.DrawBackground then
		draw.RoundedBox( 0, 28, scrh - 120, 104 + (name_w), 34, Color( 10, 10, 10, 200 ) )
		local t, h = 90, 70
		if name_w > 117 then t=t-4; h=h-4 end
		
		draw.RoundedBox( 0, 28, scrh - t, 162 + dolla_w, h, Color( 10, 10, 10, 200 ) )
	end
	
	draw.RoundedBox( 0, 30, scrh - 118, bar_len, 30, self.TopBarColor )
	draw.SimpleText( name, "rhud_flat", 117, scrh - 120, self.NameColor )
	
	draw.RoundedBox( 0, 50, scrh - 88, 50 + job_w, 30, self.LowerBarColor )
	draw.SimpleText( job_with_salary, "rhud_flat_sml", 117, scrh - 84, self.JobColor )
	
	draw.RoundedBox( 0, 32, scrh-58, 40 + dolla_w, 35, self.BottomBarColor )
	draw.SimpleText( "$" .. wallet, "rhud_flat", 42, scrh - 56, self.WalletColor )
	
	draw.RoundedBox( 0, 72 + dolla_w, scrh-58, 70, 25, self.HealthTextBGColor )
	draw.SimpleText( "Health", "rhud_flat_sml", 76 + dolla_w, scrh-54, self.HealthColor )
	draw.SimpleText( self.Player:Health(), "rhud_flat_hp", 145 + dolla_w, scrh-46, self.HealthColor )
	
	draw.RoundedBox( 0, 72 + dolla_w, scrh-33, health_trail, 10, self.HealthBarTrailColor )
	draw.RoundedBox( 0, 72 + dolla_w, scrh-33, health_bar, 10, self.HealthBarColor )
	
	draw.RoundedBox( 0, 38, scrh-126, 68, 68, self.AvatarBorderColor )
	RHUD:PaintAvatar()
end

RHUD:RegisterHud( HUD )