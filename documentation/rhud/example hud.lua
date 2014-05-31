local hud = RHUD:CreateHud() -- this is necessary for now, as i plan to do more stuff with this later.
hud.Name = "example hud" -- this needs to be filled in
hud.Author = "rejax" -- this is optional
hud.Config.Option = { enabled = false, info = "example config option" }
--	everything in the hud's Config table will be saved and synced
--		first option is auto enabled (this will be toggled by the user)
--		second option is the information to be displayed

hud.UsesAvatar = true

function hud:Init()
	print( "the user swapped to this hud" )
end

function hud:OnDeath()
	print( "the player died" )
end

function hud:OnChanged()
	print( "the hud was changed from this one" )
end

function hud:Think()
	print( "thinking like a normal hook" )
end

function hud:Draw()
	-- This is what is called to draw the hud, you need this
	
	RHUD:DrawAvatar() -- render the avatar to the screen
	--RHUD:DrawPlayerModel()
end

RHUD:RegisterHud( hud ) -- you need to call this, and supply the hud table. otherwise it wont be registered