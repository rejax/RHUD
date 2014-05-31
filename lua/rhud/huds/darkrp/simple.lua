local HUD = RHUD:CreateHud()
HUD.Name = "Simple"
HUD.UsesPlayerModel = true
HUD.Gamemode = "darkrp"

HUD.Config.AutoSize = { enabled = false, info = "Stretch to fit largest element" }

HUD.CircleMat = Material( "sgm/playercircle", "noclamp" )
HUD.HPMat = Material( "sgm/playercircle", "noclamp" )

HUD.NameIcon = Material( "icon16/user.png" )
HUD.JobIcon = Material( "icon16/briefcase.png" )
HUD.MoneyIcon = Material( "icon16/money_dollar.png" )
HUD.HPIcon = Material( "icon16/heart.png" )
HUD.ArmorIcon = Material( "icon16/shield.png" )
HUD.WantedIcon = Material( "icon16/user_red.png" )

HUD.BGCurve = 0 -- 16
HUD.BGColor = Color( 50, 50, 50 )

RHUD:CreateFont( "rhud_simple_desc", "Roboto", 18, { antialiasing = true } )
RHUD:CreateFont( "rhud_simple_hp", "Roboto", 16, { antialiasing = true } )
RHUD:CreateFont( "rhud_simple_hp_amt", "Roboto", 10, { antialiasing = true } )

local draw, surface, render = draw, surface, render
local sin, cos, rad, abs, max  = math.sin, math.cos, math.rad, math.abs, math.max

function HUD:Init()
	self:SetupPlayerModel()
	self.HPFrac = 1
	self.ArmorFrac = 1
	self.Vars = RHUD:GetDarkRPVars()
	
	self.Circle = self:MakeCircle( 115, ScrH()-91, 39 )
    self.HPCircle = self:MakeCircle( 115, ScrH()-91, 100 )
end

function HUD:MakeCircle( x, y, radius )
	local circle = {}
	local reps = 30
	local t = 0
		for i = 1, reps do
			t = ( rad( i * 360 ) / reps )
			circle[i] = { x = x + cos( t ) * radius, y = y + sin( t ) * radius }
		end
	return circle
end

function HUD:SetupPlayerModel()
	self.PlayerModel:SetPos( 40, ScrH() - 150 )
	self.PlayerModel:SetSize( 150, 150 )
	self.PlayerModel:SetCamPos( Vector( 30, 0, 60 ) )
	self.PlayerModel:SetLookAt( Vector( 0, 0, 60 ) )
	
	self.PlayerModel.Entity.GetPlayerColor = function() return self.Player:GetPlayerColor() end
	self.PlayerModel.Entity:SetEyeTarget( self.PlayerModel.vCamPos + Vector( 0, 15, 10 ) )
	
	self.PlayerModel:SetPaintedManually( true )
end

function HUD:DrawInfo( r, g, b )
	surface.SetMaterial( self.CircleMat )
	surface.SetDrawColor( r, g, b )
	surface.DrawTexturedRect( 65, ScrH() - 140, 100, 100 )
	
	render.ClearStencil()
	render.SetStencilEnable( true )

	render.SetStencilWriteMask( 1 )
	render.SetStencilTestMask( 1 )

	render.SetStencilFailOperation( STENCILOPERATION_REPLACE )
	render.SetStencilPassOperation( STENCILOPERATION_ZERO )
	render.SetStencilZFailOperation( STENCILOPERATION_ZERO )
	render.SetStencilCompareFunction( STENCILCOMPARISONFUNCTION_NEVER )
	render.SetStencilReferenceValue( 1 )
	
	surface.SetDrawColor( 0, 0, 0, 255 )
	surface.DrawPoly( self.Circle )

	render.SetStencilFailOperation( STENCILOPERATION_ZERO )
	render.SetStencilPassOperation( STENCILOPERATION_REPLACE )
	render.SetStencilZFailOperation( STENCILOPERATION_ZERO )
	render.SetStencilCompareFunction( STENCILCOMPARISONFUNCTION_EQUAL )
	render.SetStencilReferenceValue( 1 )
	
	RHUD:PaintModel()
	
	if self.IsArrested then
		for i = 1, 4 do
			surface.DisableClipping( true )
			surface.SetDrawColor( 0, 0, 0 )
			surface.DrawRect( 65 + ( 19 * i ), ScrH() - 130, 5, 100 )
			surface.DisableClipping( false )
		end
	end

    render.SetStencilEnable( false )
    render.ClearStencil()
end

function HUD:Think()
	self.Vars = RHUD:GetDarkRPVars()
	
	self.IsArrested = ( self.Vars.Arrested == true )
	self.IsWanted = ( self.Vars.wanted == true )
	
	self.HPFrac = ( ( self.Player:Health() ) / 100 )
	self.ArmorFrac = ( ( self.Player:Armor() ) / 100 )
end

local hp_add_max = 100
local hp_max_warn = 75
local hp_col = 100
function HUD:InfoPaint()
	if self.Player:Health() < 20 then
		local wave = max( abs( sin( CurTime() ) * 150 ), 100 )
		hp_col = hp_max_warn + wave
	else
		local hp = 100 + ( hp_add_max - ( self.HPFrac * hp_add_max ) )
		hp_col = hp_col == hp and hp_col or Lerp( .1, hp_col, hp )
	end
	self:DrawInfo( hp_col, 50, 50 )
end

local hp_w, arm_w, hp_dest = 0, 0, 90
function HUD:DrawStats()
	draw.RoundedBox( self.BGCurve, 140, ScrH() - 166, 100, 30, Color( 0, 0, 0 ) )
	draw.RoundedBox( self.BGCurve, 142, ScrH() - 164, 96, 26, self.BGColor )
	
	hp_w = hp_w == hp_dest and hp_w or Lerp( .1, hp_w, hp_dest * RHUD:GetHealthPercentage( self.Player, 100 ) )
	
	draw.RoundedBox( 0, 144, ScrH() - 161, hp_dest + 2, 20, Color( 60, 0, 0 ) )
	draw.RoundedBox( 0, 145, ScrH() - 160, hp_dest, 18, Color( 100, 30, 30, 200 ) )
	draw.RoundedBox( 0, 145, ScrH() - 160, hp_w, 18, Color( 100, 50, 50 ) )
	RHUD:DrawImageLabel( 148, ScrH() - 159, self.HPIcon, "rhud_simple_hp", self.Player:Health(), color_white, Color( 200, 0, 0 ) )
	
	if self.Player:Armor() > 0 then
		draw.RoundedBox( self.BGCurve, 245, ScrH() - 166, 100, 30, Color( 0, 0, 0 ) )
		draw.RoundedBox( self.BGCurve, 247, ScrH() - 164, 96, 26, self.BGColor )
		
		arm_w = arm_w == hp_dest and arm_w or Lerp( .1, arm_w, hp_dest * RHUD:GetArmorPercentage( self.Player, 100 ) )
		
		draw.RoundedBox( 0, 249, ScrH() - 161, hp_dest + 2, 20, Color( 20, 20, 80 ) )
		draw.RoundedBox( 0, 250, ScrH() - 160, hp_dest, 18, Color( 30, 30, 140, 200 ) )
		draw.RoundedBox( 0, 250, ScrH() - 160, arm_w, 18, Color( 100, 100, 240 ) )
		RHUD:DrawImageLabel( 250, ScrH() - 159, self.ArmorIcon, "rhud_simple_hp", self.Player:Armor(), color_white, Color( 0, 0, 200 ) )
	end
	
	if self.IsWanted then
		draw.RoundedBox( self.BGCurve, 50, ScrH() - 164, 74, 26, Color( 0, 0, 0 ) )
		draw.RoundedBox( self.BGCurve, 52, ScrH() - 162, 70, 22, self.BGColor )
		RHUD:DrawImageLabel( 54, ScrH() - 159, self.WantedIcon, "rhud_simple_hp", "Wanted", Color( 255, 100, 100 ) )
	end
end

local bg_minw = 80
local money_amt = ""
function HUD:Draw()
	local wide = 0
	
	if self.Config.AutoSize.enabled then
		for _, v in pairs( self.Vars ) do
			if not isstring( v ) then continue end
			
			surface.SetFont( "rhud_simple_desc" )
			local w = surface.GetTextSize( v )
			if bg_minw + w > wide then wide = bg_minw + w end
		end
	else
		wide = 237
	end
	
	draw.RoundedBox( self.BGCurve, 133, ScrH() - 130, wide, 80, Color( 0, 0, 0 ) )
	draw.RoundedBox( self.BGCurve, 135, ScrH() - 126, wide - 6, 72, self.BGColor )
	
	if self.Vars.money ~= money_amt then
		money_amt = string.Comma( self.Vars.money )
	end
	
	RHUD:DrawImageLabel( 160, ScrH() - 122, self.NameIcon, "rhud_simple_desc", self.Vars.rpname, color_white )
	RHUD:DrawImageLabel( 170, ScrH() - 99, self.JobIcon, "rhud_simple_desc", self.Vars.job, color_white )
	RHUD:DrawImageLabel( 160, ScrH() - 76, self.MoneyIcon, "rhud_simple_desc", money_amt .. " + ", color_white )
	draw.SimpleText( self.Vars.salary, "rhud_simple_desc", 180 + surface.GetTextSize( money_amt .. " + " ), ScrH() - 76, Color( 100, 200, 100 ) )
	
	self:DrawStats()
	self:InfoPaint()
end
RHUD:RegisterHud( HUD )