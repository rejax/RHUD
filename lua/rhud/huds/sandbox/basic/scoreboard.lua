--[[ This is all code from sandbox, it's just an example of how it's done. ]]--
if not HUD then error( "You need to refresh the core.lua file to include this!" ) return end

function HUD:ShowScoreboard()
	if not IsValid( scoreboard ) then
		scoreboard = vgui.Create( "rhud_sbox_scoreboard" )
	end

	if IsValid( scoreboard ) then
		scoreboard:Show()
		scoreboard:MakePopup()
		scoreboard:SetKeyboardInputEnabled( false )
	end
end

function HUD:HideScoreboard()
	if IsValid( scoreboard ) then
		scoreboard:Hide()
	end
end

concommand.Add( "c", function() 
	scoreboard:Remove() 
	scoreboard = nil 
	table.foreach( player.GetAll(), function( _, p ) p.SBEntry:Remove() p.SBEntry = nil end )
end )

surface.CreateFont( "RHUD_ScoreboardDefault", {
	font	= "Helvetica",
	size	= 22,
	weight	= 800
} )

surface.CreateFont( "RHUD_ScoreboardDefaultTitle", {
	font	= "Helvetica",
	size	= 32,
	weight	= 800
} )

local PLAYER = {}
function PLAYER:Init()
	self.AvatarButton = self:Add( "DButton" )
	self.AvatarButton:Dock( LEFT )
	self.AvatarButton:SetSize( 32, 32 )
	self.AvatarButton.DoClick = function() self.Player:ShowProfile() end

	self.Avatar	= vgui.Create( "AvatarImage", self.AvatarButton )
	self.Avatar:SetSize( 32, 32 )
	self.Avatar:SetMouseInputEnabled( false )	

	self.Name	= self:Add( "DLabel" )
	self.Name:Dock( FILL )
	self.Name:SetFont( "RHUD_ScoreboardDefault" )
	self.Name:DockMargin( 8, 0, 0, 0 )

	self.Mute	= self:Add( "DImageButton" )
	self.Mute:SetSize( 32, 32 )
	self.Mute:Dock( RIGHT )

	self.Ping	= self:Add( "DLabel" )
	self.Ping:Dock( RIGHT )
	self.Ping:SetWidth( 50 )
	self.Ping:SetFont( "RHUD_ScoreboardDefault" )
	self.Ping:SetContentAlignment( 5 )

	self.Deaths	= self:Add( "DLabel" )
	self.Deaths:Dock( RIGHT )
	self.Deaths:SetWidth( 50 )
	self.Deaths:SetFont( "RHUD_ScoreboardDefault" )
	self.Deaths:SetContentAlignment( 5 )

	self.Kills	= self:Add( "DLabel" )
	self.Kills:Dock( RIGHT )
	self.Kills:SetWidth( 50 )
	self.Kills:SetFont( "RHUD_ScoreboardDefault" )
	self.Kills:SetContentAlignment( 5 )

	self:Dock( TOP )
	self:DockPadding( 3, 3, 3, 3 )
	self:SetHeight( 32 + 3*2 )
	self:DockMargin( 2, 0, 2, 2 )
end

function PLAYER:Setup( pl )
	self.Player = pl

	self.Avatar:SetPlayer( pl )
	self.Name:SetText( pl:Nick() )

	self:Think( self )
end

function PLAYER:Think()
	if ( !IsValid( self.Player ) ) then
		self:Remove()
		return
	end

	if ( self.NumKills == nil || self.NumKills != self.Player:Frags() ) then
		self.NumKills	=	self.Player:Frags()
		self.Kills:SetText( self.NumKills )
	end

	if ( self.NumDeaths == nil || self.NumDeaths != self.Player:Deaths() ) then
		self.NumDeaths	=	self.Player:Deaths()
		self.Deaths:SetText( self.NumDeaths )
	end

	if ( self.NumPing == nil || self.NumPing != self.Player:Ping() ) then
		self.NumPing	=	self.Player:Ping()
		self.Ping:SetText( self.NumPing )
	end

	if ( self.Muted == nil || self.Muted != self.Player:IsMuted() ) then

		self.Muted = self.Player:IsMuted()
		if ( self.Muted ) then
			self.Mute:SetImage( "icon32/muted.png" )
		else
			self.Mute:SetImage( "icon32/unmuted.png" )
		end

		self.Mute.DoClick = function() self.Player:SetMuted( !self.Muted ) end

	end
	if ( self.Player:Team() == TEAM_CONNECTING ) then
		self:SetZPos( 2000 )
	end

	self:SetZPos( (self.NumKills * -50) + self.NumDeaths )
end

function PLAYER:Paint( w, h )
	if ( !IsValid( self.Player ) ) then
		return
	end

	if ( self.Player:Team() == TEAM_CONNECTING ) then
		draw.RoundedBox( 0, 0, 0, w, h, Color( 80, 80, 80, 200 ) )
		return
	end

	if  ( !self.Player:Alive() ) then
		draw.RoundedBox( 0, 0, 0, w, h, Color( 130, 60, 60, 255 ) )
		return
	end

	if ( self.Player:IsAdmin() ) then
		draw.RoundedBox( 0, 0, 0, w, h, Color( 80, 115, 80, 255 ) )
		return
	end

	draw.RoundedBox( 0, 0, 0, w, h, Color( 130, 130, 130, 255 ) )
end
vgui.Register( "rhud_sbox_scoreboard_player", PLAYER, "DPanel" )

local SB = {}
function SB:Init()
	self.Header = self:Add( "Panel" )
	self.Header:Dock( TOP )
	self.Header:SetHeight( 100 )

	self.Name = self.Header:Add( "DLabel" )
	self.Name:SetFont( "RHUD_ScoreboardDefaultTitle" )
	self.Name:SetTextColor( Color( 255, 255, 255, 255 ) )
	self.Name:Dock( TOP )
	self.Name:SetHeight( 40 )
	self.Name:SetContentAlignment( 5 )
	self.Name:SetExpensiveShadow( 2, Color( 0, 0, 0, 200 ) )

	self.Scores = self:Add( "DScrollPanel" )
	self.Scores:Dock( FILL )
end

function SB:PerformLayout()
	self:SetSize( 700, ScrH() - 200 )
	self:SetPos( ScrW() / 2 - 350, 100 )
end

function SB:Paint( w, h )
	draw.RoundedBox( 4, 0, 0, w, h, Color( 0, 0, 0, 80 ) )
end

function SB:Think()
	self.Name:SetText( GetHostName() )

	local plyrs = player.GetAll()
	for id, pl in pairs( plyrs ) do
		if ( IsValid( pl.SBEntry ) ) then continue end
		pl.SBEntry = vgui.Create( "rhud_sbox_scoreboard_player", pl.SBEntry )
		pl.SBEntry:Setup( pl )

		self.Scores:AddItem( pl.SBEntry )
	end	

end
vgui.Register( "rhud_sbox_scoreboard", SB, "EditablePanel" )
