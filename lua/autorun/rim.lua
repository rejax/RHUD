if SERVER then
	AddCSLuaFile( "rim/core.lua" )
	AddCSLuaFile( "rim/parser.lua" )
	AddCSLuaFile( "rim/gui.lua" )
	AddCSLuaFile( "rim/fn_op.lua" )
else
	if not file.IsDir( "rim", "DATA" ) then
		file.CreateDir( "rim" )
	end
	include( "rim/core.lua" )
	include( "rim/parser.lua" )
	include( "rim/gui.lua" )
end