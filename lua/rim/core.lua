RIM = RIM or { Huds = {}, Parser = {} }

function RIM:Init()
	local huds = file.Find( "data/rim/*.txt", "GAME" )
	
	for _, name in pairs( huds ) do
		name = name:sub( 1, name:len() - 4 )
		self:Build( name )
	end
end
hook.Add( "InitPostEntity", "RIM_Init", function() RIM:Init() end )

function RIM:Build( name )
	self.Huds[name] = { Variables = {}, Config = {}, Functions = {} }
		
	local hud = self.Huds[name]
	
	local f = file.Open( "rim/"..name..".txt", "r", "DATA" )
	if not f then print( "not valid" ) return end
	
	local rimcode = f:Read( f:Size() )
	f:Close()
	
	local code, usesAvatar, usesPlayerModel = self:Parse( rimcode, hud )
		hud.FileName = name
		hud.Code = code
		hud.IsRIM = true
		hud.UsesAvatar = usesAvatar
		hud.UsesPlayerModel = usesPlayerModel
		
	self:Compile( hud, 
		function() RHUD:RegisterHud( hud ) end,
		function() self.Huds[name] = nil 
	end )
end