local function LoadHuds( dir, in_folder )
	local huds, folders = file.Find( "rhud/huds/" .. dir, "LUA" )
	for f, hud in pairs( huds ) do
		local location = "rhud/huds/" .. dir:gsub("*","") .. hud
		if SERVER then
			AddCSLuaFile( location )
		else
			if not in_folder then
				include( location )
			else
				if hud == "core.lua" then
					include( location )
				end
			end
		end
	end
	if #folders > 0 then
		for _, folder in pairs( folders ) do
			local path = dir == "*" and "" or dir:gsub( "*" , "" )
			LoadHuds( path .. folder .. "/*", path:find( "[/]+" ) )
		end
	end
end

if SERVER then
	AddCSLuaFile( "rhud/core.lua" )
	AddCSLuaFile( "rhud/config.lua" )
	AddCSLuaFile( "rhud/helper.lua" )
	AddCSLuaFile( "rhud/menu.lua" )
	LoadHuds( "*" )
else
	include( "rhud/core.lua" )
	include( "rhud/config.lua" )
	include( "rhud/helper.lua" )
	include( "rhud/menu.lua" )
	LoadHuds( "*" )
end