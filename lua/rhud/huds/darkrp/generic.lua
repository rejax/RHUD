local HUD = RHUD:CreateHud()
HUD.Config.DrawIcons = { value = true, info = "Draw icons beside the various stat bars" }
HUD.Config.ExpandBGToAvailableBars = { value = true, info = "Draw the background of the health area to the amount of bars available" }

HUD.Name = "Generic"
HUD.Gamemode = "darkrp"
HUD.HideElements["DarkRP_Hungermod"] = false

HUD.HPMat = Material( "icon16/heart.png" )
HUD.ArmorMat = Material( "icon16/shield.png" )
HUD.HungerMat = Material( "icon16/cup.png" )

HUD.NameIcon = Material( "icon16/user.png" )
HUD.JobIcon = Material( "icon16/vcard.png" )
HUD.MoneyIcon = Material( "icon16/money_dollar.png" )

RHUD:CreateFont( "rhud_generic", "Tahoma", 18 )

function HUD:Init()
	self.hunger = self.Player:getDarkRPVar( "Energy" )
end

function HUD:DrawGradBox( x, y, w, h, col, dir )
	surface.SetDrawColor( col.r, col.g, col.b )
	surface.SetTexture( dir )
	surface.DrawTexturedRect( x, y, w, h )
end

local bw, bh = 300, 80
local barw, barh = 120, 18
local down = surface.GetTextureID( "vgui/gradient_down" )
local up = surface.GetTextureID( "vgui/gradient_up" )
function HUD:Draw()
	local marginx = 32 
	local name = self.Player:Nick()
	local wide = bw
	surface.SetFont( "rhud_generic" )
	local namew = surface.GetTextSize( name )
	
	if 206 + namew > bw then wide = 207 + namew end
	
	draw.RoundedBox( 0, 20, ScrH() - 100, wide, bh, Color( 50, 50, 50 ) )
	
	surface.SetDrawColor( 60, 60, 60, 150 )
	
	surface.SetTexture( down )
	surface.DrawTexturedRect( 22, ScrH() - 98, wide - 4, bh - 4 )
	
	surface.SetTexture( up )
	surface.DrawTexturedRect( 22, ScrH() - 98, wide - 4, bh - 4 )
	
	local h = 74
	if self:GetConfig( "ExpandBGToAvailableBars" ) then
		h = 28
		if self.Player:Armor() > 0 then h = 50 end
		if self.hunger then h = 74 end
	end
	
	draw.RoundedBox( 0, 23, ScrH() - 97, 160, h, Color( 30, 30, 30, 100 ) )
	
	if self:GetConfig( "DrawIcons" ) then 
		if self.Player:Health() < 20 then
			local mul = 21 - self.Player:Health()
			local strdiv = math.min( 1, math.abs( math.sin( CurTime() + mul ) ) )
			surface.SetDrawColor( math.max( 100 + ( mul * 2 ), 255 * strdiv ), 0, 0 )
		else
			surface.SetDrawColor( 255, 0, 0 )
		end
		surface.SetMaterial( self.HPMat )
		surface.DrawTexturedRect( marginx, ScrH() - 90, 16, 16 )
		
	if self.Player:Armor() > 0 then
		surface.SetDrawColor( 255, 255, 255 )
		surface.SetMaterial( self.ArmorMat )
		surface.DrawTexturedRect( marginx, ScrH() - 68, 16, 16 )
	end
	
	if self.hunger then
		surface.SetDrawColor( 255, 255, 255 )
		surface.SetMaterial( self.HungerMat )
		surface.DrawTexturedRect( marginx, ScrH() - 46, 16, 16 )
	end
	
		marginx = marginx + 24
	end
	
	local healthw = barw * ( self.Player:Health() / 100 )
	
	draw.RoundedBox( 0, marginx, ScrH() - 90, barw, barh, Color( 50, 0, 0, 100 ) )
	draw.RoundedBox( 0, marginx, ScrH() - 90, healthw, barh, Color( 100, 20, 20 ) )
	self:DrawGradBox( marginx, ScrH() - 90, healthw, barh, Color( 80, 10, 10 ), down )
	
	if self.Player:Armor() > 0 then
		local armorw = barw * ( self.Player:Armor() / 100 )
		
		draw.RoundedBox( 0, marginx, ScrH() - 68, barw, barh, Color( 0, 0, 50, 100 ) )
		draw.RoundedBox( 0, marginx, ScrH() - 68, armorw, barh, Color( 20, 20, 220 ) )
		self:DrawGradBox( marginx, ScrH() - 68, armorw, barh, Color( 10, 10, 200 ), down )
	end
	
	if self.hunger then
		draw.RoundedBox( 0, marginx, ScrH() - 46, 120, barh, Color( 20, 220, 20 ) )
		local hungerw = barw * ( self.Player:getDarkRPVar( "Energy" ) / 100 )
		draw.RoundedBox( 0, marginx, ScrH() - 46, hungerw, barh, Color( 20, 220, 20 ) )
		self:DrawGradBox( marginx, ScrH() - 46, hungerw, barh, Color( 10, 200, 10 ), down )
	end
	
	draw.RoundedBox( 0, 185, ScrH() - 97, 39 + namew, 74, Color( 30, 30, 30, 100 ) )
	
	local vars = RHUD:GetDarkRPVars()
	RHUD:DrawImageLabel( 190, ScrH() - 90, self.NameIcon, "rhud_generic", self.Player:Nick(), color_white )
	RHUD:DrawImageLabel( 190, ScrH() - 68, self.MoneyIcon, "rhud_generic", vars.money .. " + ", color_white )
	RHUD:DrawImageLabel( 190, ScrH() - 48, self.JobIcon, "rhud_generic", vars.job, color_white )
	
	surface.SetFont( "rhud_generic" )
	draw.SimpleText( vars.salary, "rhud_generic", 210 + surface.GetTextSize( vars.money .. " + " ), ScrH() - 68, Color( 200, 255, 200 ) )
end

RHUD:RegisterHud( HUD )