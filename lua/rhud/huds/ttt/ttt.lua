local HUD = RHUD:CreateHud()
HUD.Name = "TTT"
HUD.Author = "rejax"
HUD.Gamemode = "terrortown"

HUD.Config.EnableAnimations = { value = true, info = "Enable/Disable animations" }
HUD.Config.EnableTrailingBars = { value = true, info = "Toggle the bars that follow the animated hp/ammo bars" }

RHUD:CreateFont( "rhud_ttt_time", "Roboto", 40 )
RHUD:CreateFont( "rhud_ttt_spec", "Roboto", 38 )
RHUD:CreateFont( "rhud_ttt_role", "Roboto", 28 )
RHUD:CreateFont( "rhud_ttt_spec_sml", "Roboto", 24 )
RHUD:CreateFont( "rhud_ttt_round", "Roboto", 22 )
RHUD:CreateFont( "rhud_ttt_health", "Roboto", 18 )
RHUD:CreateFont( "rhud_ttt_ammo", "Roboto", 16 )
RHUD:CreateFont( "rhud_ttt_ammo2", "Roboto", 12 )

HUD.Colors = {
   default = Color(100,100,100,200),
   traitor = Color(150, 25, 25, 200),
   innocent = Color(25, 150, 25, 200),
   detective = Color(25, 25, 200, 200)
}

function HUD:Init()
	self.RoundStrings = { -- these wont exist at runtime
		[ROUND_WAIT]   = "Waiting",
		[ROUND_PREP]   = "Preparing",
		[ROUND_ACTIVE] = "Active",
		[ROUND_POST]   = "Post"
	}
	
	self.health_w = 0
	self.health_trail = 0
	
	self.ammo_w = 0
	self.ammo_trail = 0

	self.col_active = {
	   tip = {
	      [ROLE_INNOCENT]  = HUD.Colors.innocent,
	      [ROLE_TRAITOR]   = HUD.Colors.traitor,
	      [ROLE_DETECTIVE] = HUD.Colors.detective
	   },
	
	   bg = Color( 40, 40, 40, 250 ),
	
	   text_empty = Color(200, 20, 20, 255),
	   text = Color(255, 255, 255, 255),
	
	   shadow = 255
	}
	self.col_dark = {
	   tip = {
	      [ROLE_INNOCENT]  = Color(60, 160, 50, 155),
	      [ROLE_TRAITOR]   = Color(160, 50, 60, 155),
	      [ROLE_DETECTIVE] = Color(50, 60, 160, 155),
	   },
	
	   bg = Color(40, 40, 40, 200),
	
	   text_empty = Color(200, 20, 20, 100),
	   text = Color(255, 255, 255, 100),
	
	   shadow = 100
	}
	GAMEMODE.HUDDrawPickupHistory = nil
end

function HUD:DrawTime( w, endtime, round )
	local haste_t, haste_c, haste_f = "", color_white, "rhud_ttt_time"
	
	if haste then
		local hastetime = GetGlobalFloat("ttt_haste_end", 0) - CurTime()
		if hastetime > 0 then
			if not self.Player:IsActiveTraitor() or math.ceil( CurTime() ) % 7 <= 2 then
				haste_t = "Haste"
			else
				haste_t = util.SimpleTime( math.max( 0, endtime ), "%02i:%02i" )
			end
			haste_c = Color( 150, 50, 60 )
		else
			local t = hastetime
			if is_traitor and math.ceil(CurTime()) % 6 < 2 then
				t = endtime
				haste_c = Color( 150, 50, 60 )
			end
			haste_t = util.SimpleTime(math.max(0, t), "%02i:%02i")
		end
	else
		haste_t = util.SimpleTime(math.max(0, endtime), "%02i:%02i")
	end
	
	draw.SimpleText( haste_t, haste_f, 25 + w, ScrH() - 115, haste_c )
	
	surface.SetFont( haste_f )
	draw.SimpleText( round, "rhud_ttt_round", 30 + surface.GetTextSize( haste_t ) + w, ScrH() - 100, color_white )
end
local margin = 10
local width = 300
local height = 20
function HUD:DrawBarBg(x, y, w, h, col)
	local rx = math.Round(x - 4)
	local ry = math.Round(y - (h / 2)-4)
	local rw = math.Round(w + 9)
	local rh = math.Round(h + 8)

	local b = 8 --bordersize
	local bh = b / 2

	local role = LocalPlayer():GetRole() or ROLE_INNOCENT

	local c = col.bg
	surface.SetDrawColor(c.r, c.g, c.b, c.a)
	surface.DrawRect( rx, ry,  rw,  rh )
	
	c = col.tip[role]
	surface.SetDrawColor(c.r, c.g, c.b, c.a)
	surface.DrawRect( rx, ry, b/2, rh )
	
	surface.SetDrawColor(c.r, c.g, c.b, c.a - 80)
	surface.DrawRect( rx, ry, b*3, rh )
end

-- Alig96
function HUD:DrawWepSwitch( w )
	if not w.Show then return end

	local weps = w.WeaponCache

	local x = ScrW() - width - margin*2
	local y = ScrH() - (#weps * (height + margin))

	local col = self.col_dark

	for k, wep in pairs(weps) do
		if w.Selected == k then
			col = self.col_active
		else
			col = self.col_dark
		end

      		self:DrawBarBg(x, y, width, height, col)
		if not w:DrawWeapon(x, y, col, wep) then
         
			w:UpdateWeaponCache()
			return
		end

      		y = y + height + margin
   	end
end

local health_desired = 240
function HUD:DrawHealth()
	local dec = RHUD:GetHealthPercentage( self.Player )
	local w = health_desired * dec
	
	if self:GetConfig( "EnableAnimations" ) then
		if self.health_w ~= w then self.health_w = Lerp( .05, self.health_w, w ) end
		if self:GetConfig( "EnableTrailingBars" ) then
			if self.health_trail ~= w then self.health_trail = Lerp( .03, self.health_trail, w ) end
		else
			self.health_trail = 0
		end
	else
		self.health_w = w
		self.health_trail = w
	end
	
	local health_t = math.Clamp( self.health_trail, 0, health_desired )
	local health_w = math.Clamp( self.health_w, 0, health_desired )
	draw.RoundedBox( 0, 21, ScrH() - 75, health_desired, 20, Color( 100, 50, 60 ) )
	draw.RoundedBox( 0, 21, ScrH() - 75, health_t, 20, Color( 140, 40, 50 ) )
	draw.RoundedBox( 0, 21, ScrH() - 75, health_w, 20, Color( 150, 50, 60 ) )
	draw.SimpleText( self.Player:Health(), "rhud_ttt_health", 265, ScrH() - 70, color_white )
end

local ammo_w, ammo_trail = 0, 0
function HUD:DrawAmmo()
	local wep = self.Player:GetActiveWeapon()
	if not wep or not IsValid( wep ) or not wep.Clip1 then return end
	
	local clip = wep:Clip1() or 0
	if clip < 0 then return end
	
	local max = wep.Primary.ClipSize or 0
	max = math.max( clip, max )
	local held = wep:Ammo1()
	
	local div = clip / max
	local w = health_desired * div
	
	if self:GetConfig( "EnableAnimations" ) then
		if self.ammo_w ~= w then self.ammo_w = Lerp( .04, self.ammo_w, w ) end
		if self:GetConfig( "EnableTrailingBars" ) then
			if self.ammo_trail ~= w then self.ammo_trail = Lerp( .02, self.ammo_trail, w ) end
		else
			self.ammo_trail = w
		end
	else
		self.ammo_w = w
		self.ammo_trail = w
	end	
	
	local ammo_t = math.Clamp( self.ammo_trail, 0, health_desired )
	local ammo_w = math.Clamp( self.ammo_w, 0, health_desired )
	draw.RoundedBox( 0, 21, ScrH() - 50, health_desired, 20, Color( 150, 140, 30 ) )
	draw.RoundedBox( 0, 21, ScrH() - 50, ammo_t, 20, Color( 180, 170, 60 ) )
	draw.RoundedBox( 0, 21, ScrH() - 50, ammo_w, 20, Color( 200, 190, 80 ) )
	draw.SimpleText( clip .. " + " .. held, "rhud_ttt_ammo", 265, ScrH() - 45, color_white )
	--draw.SimpleText( "lnv - " .. held, "rhud_ttt_ammo2", 265, ScrH() - 40, color_white )
end

local roleb_w = 120
function HUD:Draw()
	if not self.Player:Alive() or self.Player:IsSpec() then self:DrawSpectator() roleb_w = 0 return end
	
	local role = self.Player:GetRole()
	local rolestring = self.Player:GetRoleString()
	local rolec = self.Colors[self.Player:GetRoleStringRaw()]
	local round = self.RoundStrings[GAMEMODE.round_state]
	local endtime = GetGlobalFloat( "ttt_round_end", 0 ) - CurTime()
	local w
	
	if not rolec then rolec = self.Colors.default end
	
	draw.RoundedBox( 0, 20, ScrH() - 115, 300, 86, Color( 40, 40, 40 ) )
	
	if GAMEMODE.round_state == ROUND_ACTIVE then
		w = 120
	else
		w = 0
		rolestring = ""
	end
	if self:GetConfig( "EnableAnimations" ) then
		if roleb_w ~= w then roleb_w = Lerp( .2, roleb_w, w ) end
	else
		roleb_w = w
	end
	draw.RoundedBox( 0, 21, ScrH() - 114, roleb_w, 32, rolec )
	draw.SimpleText( rolestring, "rhud_ttt_role", 26, ScrH() - 107, color_white )
	
	self:DrawTime( roleb_w, endtime, round )
	self:DrawHealth()
	self:DrawAmmo()
	self:HUDDrawPickupHistory()
end

local p_hp, t_h = 0, 80
function HUD:DrawSpectator()
	local p = self.Player:GetObserverTarget()
	local time = util.SimpleTime( math.max( 0, GetGlobalFloat( "ttt_round_end", 0 ) - CurTime() ), "%02i:%02i" )
	local round = "Post"--self.RoundStrings[GAMEMODE.round_state]
	surface.SetFont( "rhud_ttt_spec" )
	local time_w = surface.GetTextSize( time )
	surface.SetFont( "rhud_ttt_spec_sml" )
	local round_w = surface.GetTextSize( round )
	local h = 80
	
	if IsPlayer( p ) then
		h = 130
		surface.SetFont( "rhud_ttt_spec" )
		local name = p:Nick()
		local name_w = surface.GetTextSize( name )
		local box_w = 50 + name_w
		local hp = p:Health()
		local spec_hp = math.min( hp/100, 1 )
		local str, col = util.HealthToString( hp )
		
		if self:GetConfig( "EnableAnimations" ) then
			if p_hp ~= spec_hp then p_hp = Lerp( .1, p_hp, spec_hp ) end
		else
			p_hp = spec_hp
		end
		
		local box_x = 30
		
		draw.RoundedBox( 0, box_x, ScrH() - 80, box_w, 40, Color( 30, 30, 30, 150 ) )
		draw.SimpleText( name, "rhud_ttt_spec", box_x + 25, ScrH() - 80, color_white )
		
		draw.RoundedBox( 0, box_x, ScrH() - 40, box_w*p_hp, 2, col )
		draw.RoundedBox( 0, box_x, ScrH() - 40, box_w, 2, Color( 10, 10, 10, 150 ) )
	end
	
	if self:GetConfig( "EnableAnimations" ) then
		if t_h ~= h then t_h = Lerp( .1, t_h, h ) end
	else
		t_h = h
	end
	
	local posx_time = 35
	local posx_timeb = 30
	local posx_round = 35
	local posx_roundb = 30
	local timew = time_w + 15
	local roundw = round_w + 15
	
	draw.RoundedBox( 0, posx_timeb, ScrH() - t_h, timew, 40, Color( 30, 30, 30, 150 ) )
	draw.SimpleText( time, "rhud_ttt_spec", posx_time, ScrH() - t_h, color_white )
	
	draw.RoundedBox( 0, posx_roundb, ScrH() - t_h - 20, roundw, 20, Color( 30, 30, 30, 150 ) )
	draw.SimpleText( round, "rhud_ttt_spec_sml", posx_round, ScrH() - t_h - 20, color_white )
end

local pickupclr = {
	//Innocent
	["5517050"]  = Color(25, 150, 25, 200),
	//Traitor
	["1805040"]   = Color(150, 25, 25, 200),
	//Detective
	["5060180"] = Color(25, 25, 200, 200),
	//Ammo
	["2051550"] = Color(230, 125, 35, 255),
}

function HUD:HUDDrawPickupHistory()
	if GAMEMODE == nil then return end
	if (GAMEMODE.PickupHistory == nil) then return end
	
	local x, y = ScrW() - GAMEMODE.PickupHistoryWide - 20, GAMEMODE.PickupHistoryTop
	local tall = 0
	local wide = 0

	for k, v in pairs( GAMEMODE.PickupHistory ) do

		if v.time < CurTime() then	

			if (v.y == nil) then v.y = y end

			v.y = (v.y*5 + y) / 6

			local delta = (v.time + v.holdtime) - CurTime()
			delta = delta / v.holdtime

			local alpha = 255
			local colordelta = math.Clamp( delta, 0.6, 0.7 )

			if delta > (1 - v.fadein) then
				alpha = math.Clamp( (1.0 - delta) * (255/v.fadein), 0, 255 )
			elseif delta < v.fadeout then
				alpha = math.Clamp( delta * (255/v.fadeout), 0, 255 )
			end

			v.x = x + GAMEMODE.PickupHistoryWide - (GAMEMODE.PickupHistoryWide * (alpha/255))


			local rx, ry, rw, rh = math.Round(v.x-4), math.Round(v.y-(v.height/2)-4), math.Round(GAMEMODE.PickupHistoryWide+9), math.Round(v.height+8)
			local bordersize = 8

			//surface.SetTexture( GAMEMODE.PickupHistoryCorner )
			//Tip
			local col = pickupclr[v.color.r .. v.color.g .. v.color.b]
			col.a = alpha
			surface.SetDrawColor( col )
			//surface.DrawTexturedRectRotated( rx + bordersize/2 , ry + bordersize/2, bordersize, bordersize, 0 )
			//surface.DrawTexturedRectRotated( rx + bordersize/2 , ry + rh -bordersize/2, bordersize, bordersize, 90 )
			//surface.DrawRect( rx, ry+bordersize,  bordersize, rh-bordersize*2 )
			surface.DrawRect( rx+bordersize, ry, (v.height - 4)/2, rh )
			col.a = math.Clamp( col.a - 100, 0, 255 )
			surface.SetDrawColor( col )
			surface.DrawRect( rx+bordersize, ry, (v.height - 4), rh )
			//BG
			surface.SetDrawColor( 40*colordelta, 40*colordelta, 40*colordelta, math.Clamp(alpha, 0, 200) )

			surface.DrawRect( rx+bordersize+v.height-4, ry, rw - (v.height - 4), rh )
			//surface.DrawTexturedRectRotated( rx + rw - bordersize/2 , ry + rh - bordersize/2, bordersize, bordersize, 180 )
			//surface.DrawTexturedRectRotated( rx + rw - bordersize/2 , ry + bordersize/2, bordersize, bordersize, 270 )
			//surface.DrawRect( rx+rw-bordersize, ry+bordersize, bordersize, rh-bordersize*2 )

			draw.SimpleText( v.name, v.font, v.x+2+v.height+8, v.y - (v.height/2)+2, Color( 0, 0, 0, alpha*0.75 ) )

			draw.SimpleText( v.name, v.font, v.x+v.height+8, v.y - (v.height/2), Color( 255, 255, 255, alpha ) )

			if v.amount then
				draw.SimpleText( v.amount, v.font, v.x+GAMEMODE.PickupHistoryWide+2, v.y - (v.height/2)+2, Color( 0, 0, 0, alpha*0.75 ), TEXT_ALIGN_RIGHT )
				draw.SimpleText( v.amount, v.font, v.x+GAMEMODE.PickupHistoryWide, v.y - (v.height/2), Color( 255, 255, 255, alpha ), TEXT_ALIGN_RIGHT )
			end

			y = y + (v.height + 16)
			tall = tall + v.height + 18
			wide = math.Max( wide, v.width + v.height + 24 )

			if alpha == 0 then GAMEMODE.PickupHistory[k] = nil end
		end
	end

	GAMEMODE.PickupHistoryTop = (GAMEMODE.PickupHistoryTop * 5 + ( ScrH() * 0.75 - tall ) / 2 ) / 6
	GAMEMODE.PickupHistoryWide = (GAMEMODE.PickupHistoryWide * 5 + wide) / 6
end

RHUD:RegisterHud( HUD )
