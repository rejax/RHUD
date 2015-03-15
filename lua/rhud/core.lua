RHUD = RHUD or {
	Defaults = {
		["sandbox"] = "none",
		["darkrp"] = "none",
		["terrortown"] = "none",
	}, 
	Drawing = false,
	Huds = {},
	ToRegister = {},
}

RHUD.Fallback = {
	Init = function() end,
	Name = "No Name",
	UsesAvatar = false,
	UsesPlayerModel = false,
	GetConfig = function( hud, name ) return hud.Config[name].value end,
	GetConfigValues = function( hud )
		local t = table.Copy( hud.Config )
		for name, val in pairs( t ) do
			t[name] = val.value
		end
		return t
	end,
	DrawWhileDead = false,
	OnDeath = function() end,
	OnChanged = function() end,
	Think = function() end,
	HideElements = { ["CHudHealth"] = false },
	Include = function( hud, name, f ) RHUD:Include( hud, name, f ) end,
}
RHUD.Fallback.__index = RHUD.Fallback

function RHUD:CreateHud()
	local t = setmetatable( {}, self.Fallback )
	t.Config = {}
	-- adding more to this later probably
	
	return t
end

function RHUD:GetHud( asTable )
	if self.ActiveHud then
		return ( asTable and self.Huds[self.ActiveHud] or self.ActiveHud )
	end
	return ( asTable and self.Huds[self.DefaultHud] or self.DefaultHud )
end
function RHUD:GetHuds() return self.Huds end
function RHUD:GetFullHuds() return self.FullHuds end
function RHUD:GetHudNamed( n ) return self.Huds[n] end
function RHUD:GetFullHudNamed( n ) return self.FullHuds[n] end

function RHUD:RegisterHud( hud, name )
	name = name or hud.Name:lower()
	
	if not RHUD.GamemodeLoaded then
		self.ToRegister[name] = hud
		return
	end
	
	self.Huds[name] = nil
	if hud.Gamemode then 
		if GAMEMODE_NAME:lower() ~= hud.Gamemode:lower() then return end 
	end
	
	self.Huds[name] = setmetatable( hud, self.Fallback ) 
	-- i know it's called twice, but otherwise rim/external huds wouldnt workd!!

	if self:GetHud() == name and self.Initialized then
		self:SelectHud( name )
	end
end
RHUD:RegisterHud( { Name = "No Custom Hud", None = true }, "none" )

local function register()
	RHUD.GamemodeLoaded = true
	for name, hud in pairs( RHUD.ToRegister ) do
		RHUD:RegisterHud( hud, name )
	end
end
hook.Add( "OnGamemodeLoaded", "RHUD_RegisterHuds", register )

function RHUD:SelectHud( name )
	if not self.Initialized or not self.Huds[name] then return end
	
	local old = self:GetHud( true )
	old:OnChanged()
	
	self.ActiveHud = name
	file.Write( self.FilePath, name )
	
	local hud = self:GetHudNamed( name )
	if hud.None then 
		if self.Gamemode == "darkrp" then
			self.ShowDarkRP = true
		end
		return 
	else 
		self.ShowDarkRP = false 
	end
	
	self.Avatar:SetVisible( hud.UsesAvatar )
	self.Avatar:SetPlayer( LocalPlayer(), 64 )
	self.Avatar:SetSize( 64, 64 )
	self.PlayerModel:SetVisible( hud.UsesPlayerModel )
	hud.Player = LocalPlayer()
	hud.Avatar = self.Avatar
	hud.PlayerModel = self.PlayerModel
	
	hud:Init()
end

local function RunBaseHooks()
	hook.Run( "HUDDrawTargetID" )
	hook.Run( "HUDDrawPickupHistory" )
	hook.Run( "DrawDeathNotice", 0.85, 0.04 )
end

function RHUD:Draw()
	if not self.Initialized then return false end
	
	local hud = self:GetHud( true )
	if not hud or hud.None then
		self.GMHUDDraw()
		return false
	else
		hud:Draw()
		RunBaseHooks()
		return true
	end
end
hook.Add( "HUDPaint", "RHUD_Draw", function() RHUD.Drawing = RHUD:Draw() end )

function RHUD:Think()
	if not self.Initialized then return end
	
	local hud = self:GetHud( true )
	if not hud or hud.None then return end
	
	if not IsValid( LocalPlayer() ) or not LocalPlayer():Alive() then
		if not hud.DrawWhileDead then 
			if not self.DeathFuncCalled then hud:OnDeath(); self.DeathFuncCalled = true end
		return true end
	else
		self.DeathFuncCalled = false
	end
	
	hud:Think()
end
hook.Add( "Think", "RHUD_Think", function() RHUD:Think() end )

function RHUD:Init()
	self.FullHuds = table.Copy( self.Huds )
	
	self.Avatar = vgui.Create( "AvatarImage" )
		self.Avatar:SetPlayer( LocalPlayer(), 64 )
		self.Avatar:SetName( "RHUD_Avatar" )
		self.Avatar:ParentToHUD()
		self.Avatar:SetVisible( false )
	
	self.PlayerModel = vgui.Create( "DModelPanel" )
		self.PlayerModel:SetModel( LocalPlayer():GetModel() )
		self.PlayerModel:SetName( "RHUD_PlayerModel" )
		self.PlayerModel:ParentToHUD()
		self.PlayerModel.LayoutEntity = function(s) end
		self.PlayerModel:SetVisible( false )
		
		self.PlayerModel.Model = LocalPlayer():GetModel()
		self.PlayerModel.Think = function( s )
			if s.Model ~= LocalPlayer():GetModel() then
				s.Model = LocalPlayer():GetModel()
				s:SetModel( s.Model )
			end
		end
	
	self.Gamemode = GAMEMODE_NAME:lower()
	print( "RHUD Init - ", self.Gamemode )
	for name, hud in pairs( self.Huds ) do
		if hud.Gamemode then
			if hud.Gamemode ~= self.Gamemode then
				self.Huds[name] = nil
			end
		end
	end
	
	if self.Gamemode == "terrortown" then
		self:InitTTT()
	elseif self.Gamemode == "darkrp" then
		self.ShowDarkRP = false
		
		self.DarkRPVars = {
			rpname = "???",
			money = 0,
			salary = 0,
			job = "Citizen"
		}
	end
	
	if not self.GMHUDDraw then
		local oldHud = GAMEMODE.HUDPaint
		self.GMHUDDraw = function() oldHud( GAMEMODE ) end
		GAMEMODE.HUDPaint = function() end
	end
	
	self.FilePath = ("rhud/%s.txt"):format( self.Gamemode )
	if file.Exists( self.FilePath, "DATA" ) then
		local hud = file.Read( self.FilePath, "DATA" )
		if self.Huds[hud] then self.DefaultHud = hud end
	end
	
	if not self.DefaultHud then
		if self.Defaults[self.Gamemode] then
			self.DefaultHud = self.Defaults[self.Gamemode]
			if not self.Huds[self.DefaultHud] then self.DefaultHud = "none" end
		else
			self.DefaultHud = "none"
		end
		if not file.IsDir( "rhud", "DATA" ) then file.CreateDir( "rhud" ) end
		file.Write( self.FilePath, self.DefaultHud )
	end
	
	self:LoadConfigs()
	
	self.Initialized = true
	self:SelectHud( self:GetHud() )
end
hook.Add( "InitPostEntity", "RHUD_Init", function() RHUD:Init() end )

function RHUD:InitTTT() -- holy fuck why (this was more of an experiment but fuck it, it works \(:])/
	if self.TTTInitialized then return end
	self.TTTInitialized = true
	
	local r = file.Open( "gamemodes/terrortown/gamemode/cl_hud.lua", "r", "MOD" )
	local str = r:Read( r:Size() )
	local parts = string.Explode( '\n', str )
	
	local line_start, line_end = 0, 0
	local pad = 0
	
	for l, code in pairs( parts ) do
		if pad > 12 then break end
		if code:find( "GM:HUDPaint" ) then
			line_start = l
			pad = 1
		end
		if code:find( "end" ) and pad >= 1 then
			line_end = l
			pad = pad + 1
		end
	end
	
	for k, line in pairs( parts ) do
		if k >= line_end then parts[k] = nil end
		if k <= line_start then parts[k] = nil end
		if line:find( "-- Draw" ) then parts[k] = nil end
	end
	
	local hud_code = ""
	for n, line in pairs( parts ) do
		hud_code = hud_code .. " " .. line
	end
	
	local oldTTT = GAMEMODE.HUDPaint
	self.GMHUDDraw = function() oldTTT( GAMEMODE ) end
	
	local paint = function() self:Draw() end
	local env_meta = { __index = _G }
	local env = { ["SpecHUDPaint"] = paint, ["InfoPaint"] = paint } -- because the ttt hud uses local functions to draw the actual hud
	setmetatable( env, env_meta )
	
	local new_func = CompileString( hud_code, "RHUD_TTT" )
	
	GAMEMODE.HUDPaint = setfenv( new_func, env )
	
	local oldWepSwitch = WSWITCH.Draw
	WSWITCH.Draw = function()
		local hud = self:GetHud( true )
		if hud and hud.DrawWepSwitch then
			hud:DrawWepSwitch( WSWITCH )
		else
			oldWepSwitch( WSWITCH, LocalPlayer() )
		end
	end
end

hook.Add( "HUDShouldDraw", "RHUD_HideDarkRPHUD", function( name )
	if RHUD.Initialized then
		if name == "DarkRP_LocalPlayerHUD" then return RHUD.ShowDarkRP end
		local hud = RHUD:GetHud( true )
		if not hud or hud.None then return end
		if hud.HideElements[name] ~= nil then
			return hud.HideElements[name]
		end
	end
end )

hook.Add( "HUDDrawPickupHistory", "RHUD_PickupHistory", function()
	local hud = RHUD:GetHud( true )
	if not hud or hud.None then return end
	if hud.DrawPickupHistory then
		hud:DrawPickupHistory()
		return true
	end
end )

hook.Add( "HUDAmmoPickedUp", "RHUD_PickupAmmo", function( item, amount )
	local hud = RHUD:GetHud( true )
	if not hud or hud.None then return end
	if hud.DrawAmmoPickup then
		hud:DrawAmmoPickup( item, amount )
		return true
	end
end )

hook.Add( "HUDWeaponPickedUp", "RHUD_PickupWeapon", function( weapon )
	local hud = RHUD:GetHud( true )
	if not hud or hud.None then return end
	if hud.DrawWeaponPickup then
		hud:DrawWeaponPickup( weapon )
		return true
	end
end )

hook.Add( "HUDDrawTargetID", "RHUD_TargetID", function()
	local hud = RHUD:GetHud( true )
	if not hud or hud.None then return end
	if hud.DrawTargetID then
		hud:DrawTargetID( LocalPlayer():GetEyeTrace() )
		return true
	end
end )

hook.Add( "ScoreboardShow", "RHUD_Scoreboard", function()
	local hud = RHUD:GetHud( true )
	if hud.None or not hud.ShowScoreboard then return end
	hud:ShowScoreboard()
	return true
end )

hook.Add( "ScoreboardHide", "RHUD_ScoreboardHide", function()
	local hud = RHUD:GetHud( true )
	if hud.None or not hud.HideScoreboard then return end
	hud:HideScoreboard()
	return true
end )

concommand.Add( "rhud_credits", function() 
	PrintTable( { ["Everything"] = "rejax", ["Steam"] = "steamcommunity.com/id/rejax_" } )
end )
