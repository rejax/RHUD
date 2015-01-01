local LUA = {}

function LUA:Init()
	self:SetSize( 64, 64 )
end

function LUA:GetCode()

end

function LUA:GetInitCode()

end

function LUA:AddRightClickOptions( menu )

end

function LUA:PaintPreview( w, h, pnl )

end

function LUA:Paint( w, h )
	
end

--[[
buildr.register( "Lua Control", {
	description = "Insert custom code block",
	panel = LUA,
} )
]]