include( "fn_op.lua" )

function RIM:Parse( rim, t )
	local lines = string.Explode( "\n", rim )
	local compiled = {}
	local usesav = false
	local usespm = false
	local whitespace = 0
	local funcd = false
	local last_text_line = 0
	
	for line, code in pairs( lines ) do
		if code:lower():find( "avatar" ) then usesav = true end
		if code:lower():find( "model" ) then usespm = true end
		local s = code
		
		if code:find( "->" ) then 
			funcd = true 
			whitespace = 0
			local args_s = code:find( "[%[%]]" )
			if args_s then
				local func = code:sub( 1, args_s-2 ):gsub( "[ ]?->", "" )
				t.Functions[func] = true
			else
				t.Functions[code:gsub( "[ ]?->", "" )] = true
			end
		end
		
		if not s:find( "%a" ) then whitespace = whitespace + 1 else last_text_line = line end
		if code:find( "<>" ) then funcd = false whitespace = 0 end
		if whitespace > 0 and funcd and ( lines[line+1] and ( lines[line+1] == "" or lines[line+1]:find( "->" ) ) ) then 
			s = "end"
			last_text_line = line
			s = s.."\n"
			whitespace = 0 
			funcd = false 
		end
		
		local words = string.Explode( " ", s )
		s = s:gsub( "[%s]?=[%s]?", "=" )
		
		if s:find( "^>>" ) then
			local op = ""
			for id, word in pairs( string.Explode( "=", s ) ) do
				if id == 1 then
					word = string.format( "RIMHUD[ [[%s]] ]=", word:sub( 3 ) )
				elseif id == 2 then
					word = string.format( "[[%s]]", word:gsub( "[\"\']", "" ) )
				end
				
				op = op .. word
			end
			s = op
		end
		
		compiled[line] = s
	end
	if funcd then table.insert( compiled, "end" ) end
	
	for line, s in pairs( compiled ) do
		local words = string.Explode( " ", s:gsub( " ", "" ) )
		for word, func in pairs( self.Parser.Functions ) do
			if s:find( word ) then s = func( s, words, table.KeyFromValue( words, word ), t, lines[line] ) end
		end
		
		local find = words[1]:find( "%)" )
		local checkfunc = words[1]:sub( 1, find ):gsub( "%(%)", "" )
		
		local arg = checkfunc:find( "%(" )
		if arg and not checkfunc:find( "RIMHUD" ) then
			checkfunc = checkfunc:sub( 1, arg-1 )
		end
		if t.Functions[checkfunc] then
			s = Format( "RIMHUD:%s", words[1] )
		end
		
		compiled[line] = s
	end
	
	for line, s in pairs( compiled ) do
		local words = string.Explode( " ", s )
		for word, func in pairs( self.Parser.Operators ) do
			if s:find( word ) then s = func( s, words, table.KeyFromValue( words, word ), t ) end
		end
		compiled[line] = s
	end
	
	compiled = self:TidyUpLines( compiled )
	return string.Implode( "\n", compiled ), usesav, usespm
end

function RIM:TidyUpLines( t )
	local last_t = 0
	for line, content in ipairs( t ) do
		if content:find( "%a" ) then last_t = line end
		if line - last_t > 1 then
			table.remove( t, line )
		end
		content = content:gsub( string.rep( " ", 4 ), "\t" )
	end
	return t
end

local function roundtime() return ( GetGlobalFloat( "ttt_round_end", 0 ) - CurTime() ), ( GetGlobalFloat( "ttt_haste_end", 0 ) - CurTime() ) end
local colors = {
	white = Color( 255, 255, 255 ),
	black = Color( 0, 0, 0 ),
	red = Color( 255, 0, 0 ),
	blue = Color( 0, 0, 255 ),
	green = Color( 0, 255, 0 ),
}
function RIM:Compile( hud, success, fail )
	local str = CompileString( hud.Code, Format( "RIM COMPILE ERROR: File:'%s', line", hud.FileName ) )
	if not str then fail() return end
	
	local fenv = { __index = function( t, k )
		if hud.Functions[k] then hud[k]() return end
		if hud.Variables[k] then return hud.Variables[k] end
		error( Format( "RIM: Error in syntax in file '%s'! Undefined \"" .. k .. "\" from pointer: %s", hud.FileName, tostring( t ) ) )
	end }
	
	local env = { 
		["RIMHUD"] = hud, RHUD = RHUD,
		Player = LocalPlayer(), ply = LocalPlayer(), 
		ScrH = ScrH(), ScrW = ScrW(),
		Color = Color, Material = Material,
		Lerp = Lerp, GetRoundTime = roundtime, CurTime = CurTime,
		draw = draw, surface = surface, render = render, math = math, string = string,
		print = print,
	}
	table.foreach( colors, function( k, col ) env[k] = col end )
	
	setmetatable( env, fenv )

	hud.Compiled = setfenv( str, env )
	hud.Compiled()
	
	if not hud.Name then
		fail()
		error( Format( "RIM COMPILE ERROR: File:'%s' is missing Name variable!", hud.FileName ) )
	elseif not hud.Draw then
		fail()
		error( Format( "RIM COMPILE ERROR: File:'%s' is missing Draw function!", hud.FileName ) )
	else
		success()
	end
end
