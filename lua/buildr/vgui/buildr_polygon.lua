local POLY = {}
POLY.SaveVariables = {
	poly = true,
}

local inf = Material( "icon16/flag_yellow.png" )
function POLY:Init()
	self:SetSize( 124, 124 )
	self.init_edit = true
	
	self.poly = { { x = 0, y = 0 } }
	timer.Simple( .1, function()
		if #self.poly == 1 then 
			buildr.base:AddCursorMessage( inf, "Click anywhere to add a vertex (You need  at least 3)" )
		end
	end )
	
	buildr.base:RegisterCanvasDrawFunc( function()
		if not self.adding_point then return end
		self:PaintLine() 
	end )
	
	buildr.base:RegisterCanvasClickCallback( function()
		if not self.adding_point then return end
		self:AddPoint()
	end )
end

function POLY:GeneratePolyTable()
	local t = {}
	for i = 1, #self.poly do
		local p = self.poly[i]
		t[i] = ("\t\t[%d] = { x = %d, y = %d },"):format( i, self:LocalToScreen( p.x, p.y ) )
	end
	t = (table.concat( t, "\n" )):sub( 1, -2 )
	return "{\n" .. t .. "\n\t}"
end

function POLY:GetInitCode()
	return { ("self.poly%s = %s"):format( self.id, self:GeneratePolyTable() ) }
end

function POLY:GetCode()
	return { "draw.NoTexture()", "surface.SetDrawColor( $color$ )", ("surface.DrawPoly( self.poly%s )"):format( self.id ) }
end

local sample_vertices = {
	{ x = 32, y = 4 },
	{ x = 60, y = 24 },
	{ x = 4, y = 40 },
}
function POLY:PaintPreview( w, h, pnl )
	draw.NoTexture()
	surface.SetDrawColor( 150, 100, 100 )
	surface.DrawPoly( sample_vertices )
end

function POLY:AddRightClickOptions( menu )
	menu:AddOption( "Add Point", function() 
		self.adding_point = #self.poly
		self.startx, self.starty = self:GetPos()
		self.startw, self.starth = self:GetSize()
		self.startpoly = table.Copy( self.poly )
	end )
	menu:AddOption( "Print Poly", function()
		print( self:GeneratePolyTable() )
	end )
end

function POLY:ClosestVertex( x, y )
	local closest_dist, nearest = ScrW() + 1
	for i = 1, #self.poly do
		local dist = math.Distance( x, y, self.poly[i].x, self.poly[i].y )
		if dist < closest_dist then
			nearest = i
			closest_dist = dist
		end
	end
	
	if closest_dist > 10 then return false end
	return nearest
end

function POLY:LeftClick( x, y )
	if self.adding_point then self:AddPoint() return end
	local vert = self:ClosestVertex( x, y )
	if not vert then return end
	
	self.DragVert = { x = x, y = y, i = vert }
	return true
end

local warn = Material( "icon16/flag_red.png" )
function POLY:RightClick( x, y )
	if self.adding_point then return true end
	
	local nearest = self:ClosestVertex( x, y )
	if not nearest then return end
	
	local menu = DermaMenu()
	menu:AddOption( "Vertex [" .. nearest .. "]" ):SetIcon( "icon16/information.png" )
	menu:AddSpacer()
	menu:AddOption( "Delete", function() 
		if #self.poly > 3 then
			table.remove( self.poly, nearest )
			self:BBFromPoly()
		else
			buildr.base:AddCursorMessage( warn, "Polygon must have at least 3 vertices!", 5, Color( 255, 140, 140 ) )
		end
	end ):SetIcon( "icon16/cancel.png" )
	menu:Open()
	
	return true
end

function POLY:DisableClipping( clause, disable )
	if clause then surface.DisableClipping( disable ) end
end

local circle = surface.GetTextureID( "sgm/playercircle" )
local dragp_col = Color( 255, 100, 0 )
function POLY:Paint( w, h )
	self:DisableClipping( self.adding_point, true )
	
	if #self.poly >= 3 then
		draw.NoTexture()
		surface.SetDrawColor( self.ghost_poly and ColorAlpha( self:GetColor(), 100 ) or self:GetColor() )
		surface.DrawPoly( self.ghost_poly or self.poly )
	end
	
	self:DisableClipping( not self.adding_point, true )
		local edit_col = Color( math.Clamp( 200 * math.sin( ( RealTime() * 3 ) % 360 ), 200, 255 ), 0, 0 )
		for k, point in ipairs( self.poly ) do
			surface.SetTexture( circle )
			surface.SetDrawColor( (self.DragVert and self.DragVert.i) == k and dragp_col or edit_col )
			surface.DrawTexturedRect( point.x - 4, point.y - 4, 8, 8 )
		end
	self:DisableClipping( not self.adding_point, false )
	
	self:DisableClipping( self.adding_point, false )
end

function POLY:BBFromPoly()
	local bb = { min_x = ScrW(), min_y = ScrH(), max_x = 0, max_y = 0 }
	for _, p in ipairs( self.poly ) do
		local x, y = self:LocalToScreen( p.x, p.y )
		if x < bb.min_x then bb.min_x = x end; if y < bb.min_y then bb.min_y = y end
		if x > bb.max_x then bb.max_x = x end; if y > bb.max_y then bb.max_y = y end
	end
	
	local ox, oy = self:GetPos()
	self:SetSize( bb.max_x - bb.min_x + 5, bb.max_y - bb.min_y + 5 )
	self:SetPos( bb.min_x, bb.min_y )
	
	for _, p in ipairs( self.poly ) do
		p.x = p.x + ( ox - bb.min_x )
		p.y = p.y + ( oy - bb.min_y )
	end
end

function POLY:AddPoint()
	self.poly = table.Copy( self.ghost_poly )
	self:BBFromPoly()
	
	--[[
	if #self.poly > 2 then
		local x1 = self.poly[1].x
		local comp = false
		for i = 2, #self.poly do
			local x = self.poly[i].x
			print( i, x > x1 )
		end
	end
	]]
	
	self.adding_point = nil
	self.ghost_poly = nil
end

function POLY:Update()
	if self.init_edit then
		if #self.poly < 3 then 
			self.adding_point = #self.poly
		else
			self.init_edit = false
		end
	end
	
	if not self.DragVert then return end
	if not input.IsMouseDown( MOUSE_LEFT ) then self.DragVert = nil return end
	
	local offx, offy = buildr.base:SnapToGrid( gui.MousePos() )
	local cx, cy = self:ScreenToLocal( offx, offy )
	self.poly[self.DragVert.i] = { x = cx, y = cy }
	self:BBFromPoly()
end

function POLY:PaintLine()
	local point = self.poly[self.adding_point]
	local x, y = self:LocalToScreen( point.x, point.y )
	local g_x, g_y = buildr.base:SnapToGrid( gui.MousePos() )
	surface.SetDrawColor( Color( 255, 0, 0 ) )
	surface.DrawLine( x, y, g_x, g_y )
	
	g_x, g_y = self:ScreenToLocal( g_x, g_y )
	
	local poly = table.Copy( self.poly )
	poly[#poly + 1] = { x = g_x, y = g_y }
	self.ghost_poly = poly
end

buildr.register( "Polygon", {
	description = "Draw a polygon",
	panel = POLY,
} )