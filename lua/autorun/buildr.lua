if SERVER then
	AddCSLuaFile( "buildr/core.lua" )
	AddCSLuaFile( "buildr/build.lua" )
else
	include( "buildr/core.lua" )
	include( "buildr/build.lua" )
end

local pnls = file.Find( "buildr/vgui/*.lua", "LUA" )
for _, pnl in pairs( pnls ) do
	if SERVER then
		AddCSLuaFile( "buildr/vgui/" .. pnl )
	else
		include( "buildr/vgui/" .. pnl )
	end
end