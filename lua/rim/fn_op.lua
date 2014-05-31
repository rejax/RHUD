RIM.Parser.Functions = {}
RIM.Parser.Operators = {}

RIM.Parser.Operators["^var"] = function( line, words, _, t )
	local l = string.Explode( "=", line:gsub( "var ", "" ) )
	local fline = "RIMHUD.Variables[ [["..l[1].."]] ]="
	return fline .. table.concat( l, "", 2 )
end

RIM.Parser.Operators["%$"] = function( line, words, _, t )
	if line:find( "DrawText" ) or line:find( "draw.SimpleText" ) then return line end
	local t = string.Explode( "=", line, 1 )
	local config_name = t[1]:sub( 2 )
	local t2 = string.Explode( ",", t[2] )
	local on, info = t2[1], t2[2]:sub( 2 )
	
	return Format( "RIMHUD.Config[ [[%s]] ]={value=%s,info=[[%s]]}", config_name, on, info )
end

RIM.Parser.Operators["->"] = function( line )
	local func = ("function RIMHUD:%s()"):format( line:sub( 1, line:len() - 3 ) )
	if line:find( "%[" ) then
		local ft = string.Explode( " ", line )
		local args = {}
		local a_start, a_end = 0, 0
		
		ft[1] = nil
		ft[#ft] = nil
		for l, part in pairs( ft ) do
			if part:find( "%[" ) then a_start = l end
			if part:find( "%]" ) then a_end = l end
		end
		
		if a_start ~= 0 then
			if a_start == a_end then
				local arg = ft[a_start]:gsub( "[%[%] ]", "" )
				local as = string.Explode( ",", arg )
				for p in pairs( as ) do 
					if math.fmod( p, 2 ) == 0 then 
						table.insert( as, p, "," )
					end
				end
				ft = as
			else
				for i = a_start+1, a_end-1 do
					table.insert( args, ft[i] )
				end
				ft[a_start] = ft[a_start]:gsub( "%[", "" )
				ft[a_end] = ft[a_end]:gsub( "%]", "" )
			end
		end
		
		local brac = ""
		for _, arg in pairs( ft ) do
			brac = brac .. arg
		end
		
		local brackets = "(" .. brac .. ")"
		local find = func:find( "%[" )
		local new = func:gsub("[%[%]]", "" ):sub( 1, find-2 ) .. brackets
		func = new
	end
	return func
end
--RIM.Parser.Operators["=>"] = RIM.Parser.Operators["->"]

RIM.Parser.Operators["<>"] = function( line )
	return line:gsub( "<>", "end" )
end

RIM.Parser.Functions["DrawBox"] = function( line )
	line = line:gsub( "DrawBox%(", "draw.RoundedBox( 0," )
	return line
end

RIM.Parser.Functions["SetAvatarPos"] = function( line )
	return line:gsub( "SetAvatarPos", "RHUD.Avatar:SetPos" )
end

RIM.Parser.Functions["SetAvatarSize"] = function( line )
	return line:gsub( "SetAvatarSize", "RHUD.Avatar:SetSize" )
end

RIM.Parser.Functions["DrawAvatar"] = function( line )
	local g = line:gsub( "DrawAvatar", [[RHUD.Avatar:SetPaintedManually( false )
	RHUD.Avatar:PaintManual()
	RHUD.Avatar:SetPaintedManually( true )]] )
	return g:sub( 1, -3 )
end

RIM.Parser.Functions["CreateFont"] = function( line )
	return "RHUD:"..line
end

RIM.Parser.Functions["GetConfig"] = function( line )
	return line:gsub( "GetConfig", "RIMHUD:GetConfig" )
end

RIM.Parser.TextParse = {
	["rp_money"] = function() return "Player:getDarkRPVar( \"money\" )" end,
	["rp_job"] = function() return "Player:getDarkRPVar( \"job\" )" end,
	["rp_salary"] = function() return "Player:getDarkRPVar( \"salary\" )" end,
	["rp_name"] = function() return "Player:getDarkRPVar( \"rpname\" )" end,
	["rp_hunger"] = function() return "Player:getDarkRPVar( \"energy\" )" end,
	["name"] = function() return "Player:Nick()" end,
	["health"] = function() return "Player:Health()" end,
	["ttt_role"] = function() return "Player:GetRoleString()" end,
	["ttt_rawrole"] = function() return "Player:GetRoleStringRaw()" end,
	
}
function RIM.Parser:ReplaceKeywords( text, str )
	local words = string.Explode( "*", text )
	
	for i, txt in pairs( words ) do
		txt = txt:gsub( str, "" )
		if math.fmod( i, 2 ) <= 0 then
			for word, func in pairs( RIM.Parser.TextParse ) do
				if word == txt then
					words[i] = str .. ".." .. txt:gsub( word, func )
					if i < #words then words[i] = words[i] .. ".." .. str end
				end
			end
		end
	end
	local m = table.concat( words )
	m = m:gsub( str .. str .. "..", "" )
	
	return m
end

RIM.Parser.Functions["DrawText"] = function( a, line, _, _, realline )
	line = string.Implode( " ", line )
	local args = string.Explode( ",", realline )
	
	local old_t = args[1]:gsub( "DrawText%(", "" )
	local text = old_t
	local indent = false
	if old_t:find( "\t" ) then
		text = old_t:gsub( "\t", "" )
		indent = true
	end
	local space = 0
	
	local str_type = nil
	local i = 1
	for i = 1, 10 do
		str_type = text:sub( i, i )
		if str_type:find( "[\"']" ) then break end
	end
	
	if text:find( "*" ) then
		text = RIM.Parser:ReplaceKeywords( text, str_type )
	end

	text = text:gsub( ".."..str_type..str_type, "" )
	args[1] = "draw.SimpleText(" .. text
	if indent then args[1] = "\t"..args[1] end
	
	return string.Implode( ",", args )
end

RIM.Parser.Functions["echo"] = function( line ) -- ze first function
	return line:gsub( "echo(", "print(" ) .. ")"
end
