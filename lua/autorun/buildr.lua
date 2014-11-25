if SERVER then
	AddCSLuaFile( "buildr/core.lua" )
else
	include( "buildr/core.lua" )
end

local pnls = file.Find( "buildr/vgui/*.lua", "LUA" )
for _, pnl in pairs( pnls ) do
	if SERVER then
		AddCSLuaFile( "buildr/vgui/" .. pnl )
	else
		include( "buildr/vgui/" .. pnl )
	end
end