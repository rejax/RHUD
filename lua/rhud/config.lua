function RHUD:LoadConfigs()
	if not sql.TableExists( "rhud_config" ) then
		local setup_table = [[
			CREATE TABLE rhud_config (
				HUD varchar( 30 ) PRIMARY KEY,
				Config TEXT
			);
		]] -- i know varchar primary keys are bad, but it's much simpler
		local q = sql.Query( setup_table )
		
		for name, hud in pairs( self:GetFullHuds() ) do
			if hud.None then continue end
			local hud_row = Format( [[INSERT INTO rhud_config ( HUD ) VALUES ( %s );]], SQLStr( name ) )
			local q2 = sql.Query( hud_row )
			
			local configs = util.TableToJSON( hud:GetConfigValues() )
			local q3 = sql.Query( Format( [[UPDATE rhud_config SET Config=%s WHERE HUD=%s]], SQLStr( configs ), SQLStr( name ) ) )
		end
	else
		local configs = sql.Query( "SELECT * FROM rhud_config" )
		if configs then
			for name, config in pairs( configs ) do
				local save = util.JSONToTable( config.Config )
				local hud = self:GetFullHudNamed( config.HUD )
				if hud and config.Config ~= "[]" then
					for id, val in pairs( save ) do
						if hud.Config[id] then
							hud.Config[id].value = val
						else
							save[id] = nil
						end
					end
					local json = util.TableToJSON( save )
					sql.Query( Format( [[UPDATE rhud_config SET Config=%s WHERE HUD=%s]], SQLStr( save ), name ) )
				end
			end
			self:UpdateConfigs()
		end
	end
end

function RHUD:UpdateConfigs()
	for name, hud in pairs( self:GetFullHuds() ) do
		if hud.None then continue end
		local nHud = self:GetHudNamed( name )
		if nHud then
			for c_n, c_val in pairs( hud.Config ) do
				if nHud.Config[c_n] then
					nHud.Config[c_n].value = c_val.value
				end
			end
		end
	end
end

function RHUD:ReloadConfigs( hud )
	self:GetHudNamed( hud ).Config = table.Copy( self:GetFullHudNamed( hud ).Config )
end

function RHUD:ChangeConfigValue( hud, key, val, dont_save )
	local hud_config = self:GetHudNamed( hud ).Config
	hud_config[key].value = val
	
	if dont_save then return end
	
	self:SaveConfigs( hud )
end

function RHUD:SaveConfigs( hud )
	local vals = self:GetHudNamed( hud ):GetConfigValues()
	local json = util.TableToJSON( vals )
	local q = Format( [[UPDATE rhud_config SET Config=%s WHERE HUD=%s]], SQLStr( json ), SQLStr( hud ) )
	sql.Query( q )
end