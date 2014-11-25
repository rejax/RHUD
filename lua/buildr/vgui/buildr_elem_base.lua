local BASE = {}

function BASE:Init()
	self:SetSize( 100, 100 )
	self.Round = 0
	self.edits = buildr.get( self.class ).edits
	
	self.Bound = {}
end

function BASE:UpdateSaveVariables()
	self.posx, self.posy = self:GetPos()
	self.width, self.height = self:GetSize()
end

BASE.SaveVariables = {
	posx = function( self, var )
		local _, y = self:GetPos()
		self:SetPos( var, y )
	end,
	posy = function( self, var )
		local x = self:GetPos()
		self:SetPos( x, var )
	end,
	width = function( self, var )
		self:SetWide( var )
	end,
	height = function( self, var )
		self:SetTall( var )
	end,
	Bound = function( self, var )
		for id, pos in pairs( var ) do
			self.Bound[buildr.base.Elements[id]] = pos
		end
	end,
	BoundTo = function( self, var )
		local panel = buildr.base.Elements[var]
		self.BoundTo = panel
	end,
	Color = function( self, var )
		self:SetColor( Color( var.r, var.g, var.b, var.a ) )
	end,
	name = true,
}
function BASE:LoadSavedVar( name, val )
	if type( self.SaveVariables[name] ) == "function" then
		self.SaveVariables[name]( self, val )
	else
		self[name] = val
	end
end

function BASE:PaintPreview( w, h )
	draw.RoundedBox( 4, 0, 0, w, h, HSVToColor( CurTime() % 360, .5, .5 ) --[[Color( 100, 0, 0 )]] )
end

BASE.Code = {
	"draw.RoundedBox( %d, $x$, $y$, %d, %d, $color$ )"
}
function BASE:GetCode()
	local code = table.Copy( self.Code )
	code[1] = code[1]:format( self.Round, self:GetWide(), self:GetTall() )
	return code
end

function BASE:GetCodeVar( name )
	return ""
end

function BASE:GetInitCode()
	return {}
end

function BASE:GetSetupCode()
	return {}
end

function BASE:OnMousePressed( m )
	if buildr.binding and m == MOUSE_LEFT then
		if buildr.binding ~= self then
			buildr.binding:BindTo( self )
		end
		buildr.binding = nil
		return
	end
	
	if m == MOUSE_LEFT then
		local _x, _y = self:CursorPos()
		self.Dragging = { x = _x, y = _y }
	elseif m == MOUSE_RIGHT then
		self:RightClick()
		self:OnMouseReleased( MOUSE_LEFT )
	end
end

function BASE:OnMouseReleased( m )
	if m == MOUSE_LEFT then
		self.Dragging = nil
	end
end

function BASE:RightClick()
	local menu = DermaMenu()
	
	menu:AddOption( ("panel [%d] [%s]"):format( self.id, self.name or self.class ) ):SetIcon( "icon16/information.png" )
	menu:AddSpacer()
	
	if not self.BoundTo then
		menu:AddOption( "Bind To", function() buildr.binding = self end ):SetIcon( "icon16/connect.png" )
	else
		menu:AddOption( ("Unbind from [%d] [%s]"):format( self.BoundTo.id, self.BoundTo.name or self.BoundTo.class ), function()
			self.BoundTo.Bound[self] = nil
			self.BoundTo = nil
		end ):SetIcon( "icon16/disconnect.png" )
	end
	
	menu:AddOption( "Set Name", function()
		Derma_StringRequest( "Set Name", "Enter new name", self.name or "", function( name )
			self.name = name
		end )
	end ):SetIcon( "icon16/pencil.png" )
	
	local dock = menu:AddSubMenu( "Dock" )
	
	local both = dock:AddSubMenu( "Both" )
	
	both:AddOption( "Absolute", function()
		Derma_StringRequest( "Dock Margin", "Enter the pixels to dock by", "", function( str )
			local num = tonumber( str )
			assert( num, "invalid input" )
			
			self:SetPos( num, num )
			self.BoundDirty = true
		end )
	end ):SetIcon( "icon16/anchor.png" )
	
	both:AddOption( "Subtractive", function()
		Derma_StringRequest( "Dock Margin", "Enter the pixels to subtract by", "", function( str )
			local num = tonumber( str )
			assert( num, "invalid input" )
			
			self:SetPos( num, ScrH() - self:GetTall() - num )
			self.BoundDirty = true
		end )
	end ):SetIcon( "icon16/anchor.png" )
	
	local horizontal = dock:AddSubMenu( "Horizontal" )
	horizontal:AddOption( "From Left", function()
		Derma_StringRequest( "Dock Horizontal", "Enter the pixels to dock by", "", function( str )
			local num = tonumber( str )
			assert( num, "invalid input" )
			
			local _, posy = self:GetPos()
			self:SetPos( num, posy )
			self.BoundDirty = true
		end )
	end )
	
	horizontal:AddOption( "From Right", function()
		Derma_StringRequest( "Dock Horizontal", "Enter the pixels to dock by", "", function( str )
			local num = tonumber( str )
			assert( num, "invalid input" )
			
			local _, posy = self:GetPos()
			self:SetPos( ScrW() - ( num + self:GetWide() ), posy )
			self.BoundDirty = true
		end )
	end )
	
	local vertical = dock:AddSubMenu( "Vertical" )
	vertical:AddOption( "From Top", function()
		Derma_StringRequest( "Dock Vertical", "Enter the pixels to dock by", "", function( str )
			local num = tonumber( str )
			assert( num, "invalid input" )
			
			local posx = self:GetPos()
			self:SetPos( posx, num )
			self.BoundDirty = true
		end )
	end )
	
	vertical:AddOption( "From Bottom", function()
		Derma_StringRequest( "Dock Vertical", "Enter the pixels to dock by", "", function( str )
			local num = tonumber( str )
			assert( num, "invalid input" )
			
			local posx = self:GetPos()
			self:SetPos( posx, ScrH() - ( num + self:GetTall() ) )
			self.BoundDirty = true
		end )
	end )
	
	local copytxt = "Copy [%s] [%s]"
	local copy = dock:AddSubMenu( "Copy Position" )
		for id, pnl in pairs( buildr.base.Elements ) do
			if pnl == self then continue end
			copy:AddOption( copytxt:format( pnl.id, pnl.name or pnl.class ), function()
				self:CopyPos( pnl )
				self.BoundDirty = true
			end )
		end
	
	menu:AddOption( "Edit Color", function()
		self:EditColor()
	end ):SetIcon( "icon16/palette.png" )
	
	menu:AddOption( "Edit Size", function()
		Derma_StringRequest( "Edit Size", "Enter width and height, seperated by a comma", self:GetWide() .. "," .. self:GetTall(), function( str )
			local t = (","):Explode( str )
			assert( t[1] and t[2], "invalid size" )
			self:SetSize( tonumber( t[1] ), tonumber( t[2] ) )
		end )
	end ):SetIcon( "icon16/shape_handles.png" )

	menu:AddOption( "Edit Position", function()
		local posx, posy = self:GetPos()
		Derma_StringRequest( "Edit Position", "Enter x and y, seperated by a comma", posx .. "," .. posy, function( str )
			local t = (","):Explode( str )
			assert( t[1] and t[2], "invalid position" )
			
			self:SetPos( tonumber( t[1] ), tonumber( t[2] ) )
			self.BoundDirty = true
		end )
	end ):SetIcon( "icon16/shape_square_go.png" )
	
	menu:AddSpacer()
	
	self:AddRightClickOptions( menu )
	
	menu:AddOption( "Remove", function()
		self:GetParent():RemoveElement( self )
	end ):SetIcon( "icon16/cancel.png" )
	
	menu:Open()
end

function BASE:AddRightClickOptions()

end

function BASE:EditColor()
	local popup = vgui.Create( "DFrame", self )
		popup:SetTitle( "Edit Color" )
		popup:SetSize( 400, 400 )
		popup:Center()
		popup:MakePopup()
		popup.OnRemove = function() self.SuppressClick = nil end
		self.SuppressClick = popup
	
	local old = self:GetColor()
	local mix = vgui.Create( "DColorMixer", popup )
		mix:Dock( FILL )
		mix:SetColor( self:GetColor() )
		mix:SetAlphaBar( false )
		mix.ValueChanged = function( _, col )
			self:SetColor( col )
		end
		
	local confirm = vgui.Create( "DButton", popup )
		confirm:SetText( "Cancel" )
		confirm:Dock( BOTTOM )
		confirm.DoClick = function()
			self:SetColor( old )
			popup:Remove()
		end
end

local TWEEN_TOP = 1
local TWEEN_BOTTOM = 2
local TWEEN_LEFT = 3
local TWEEN_RIGHT = 4

local tw_in, tw_col = Color( 200, 200, 50 ), Color( 230, 230, 90 )
function BASE:CreateSizeTweens()
	if self.HideTweens then return end
	local tweens = {}
	for i = 1, 4 do
		if i == TWEEN_TOP or i == TWEEN_LEFT then continue end
		
		local tw = vgui.Create( "DButton", self )
			tw.Paint = function( s, w, h )
				surface.SetDrawColor( self.EditingSize == s.id and tw_in or tw_col )
				surface.DrawRect( 0, 0, w, h )
			end
			tw.id = i
			tw.OnCursorEntered = function(s) s.In = true end
			tw.OnCursorExited = function(s) s.In = false end
			tw.OnMousePressed = function(s, m) 
				if m == MOUSE_LEFT then 
					self.EditingSize = i 
					local posx, posy = self:GetPos()
					self.EditingSizeInit = { x = gui.MouseX(), y = gui.MouseY(), w = self:GetWide(), h = self:GetTall(), posx = posx, posy = posy } 
				end 
			end
			tw.Think = function( s ) 
				if self.EditingSize == i then 
					if not input.IsMouseDown( MOUSE_LEFT ) then
						self.EditingSize = nil 
					end
				end 
				if s.id == TWEEN_TOP then
					s:SetPos( self:GetWide()/2-8, 0 )
				elseif s.id == TWEEN_BOTTOM then
					s:SetPos( self:GetWide()/2-8, self:GetTall()-16 )
				elseif s.id == TWEEN_LEFT then
					s:SetPos( 0, self:GetTall()/2-8 )
				elseif s.id == TWEEN_RIGHT then
					s:SetPos( self:GetWide()-16, self:GetTall()/2-8 )
				end
			end
			tw:SetSize( 16, 16 )
			tw:SetText( "" )
	end
	self.Tweens = tweens
end

function BASE:SetColor( col )
	self.Color = col
end
function BASE:GetColor() return self.Color or buildr.white end

function BASE:UpdateBound( force )
	for panel in pairs( self.Bound ) do if not IsValid( panel ) then self.Bound[panel] = nil end end
	
	if self.BoundDirty or force then
		local offx, offy = self:GetPos()
		for panel, pos in pairs( self.Bound ) do
			if IsValid( panel ) then
				panel:SetPos( offx - pos[1], offy - pos[2] )
				panel:BindTo( self )
				local obound = table.Count( panel.Bound )
				if obound > 0 then panel:UpdateBound( true ) end
			else
				self.Bound[panel] = nil
			end
		end
		if self.BoundTo then self:BindTo( self.BoundTo ) end
		self.BoundDirty = false
	end
	
	if self.BoundTo and not IsValid( self.BoundTo ) then self.BoundTo = nil end
end

function BASE:Think()
	self:UpdateSaveVariables()
	self:UpdateBound()
	if self.EditingSize then
		local e, p = self.EditingSize, self.EditingSizeInit
		local mx, my = gui.MouseX(), gui.MouseY()
		
		if e == TWEEN_TOP then
		elseif e == TWEEN_BOTTOM then
			local dist = p.h + ( my - p.y )
			self:SetTall( dist )
		elseif e == TWEEN_LEFT then
		
		elseif e == TWEEN_RIGHT then
			local dist = p.w + ( mx - p.x )
			self:SetWide( dist )
		end
	end
	if not self.Dragging then return end
	if not input.IsMouseDown( MOUSE_LEFT ) then self.Dragging = false return end
	
	local offx, offy = gui.MouseX() - self.Dragging.x, gui.MouseY() - self.Dragging.y
	self:SetPos( offx, offy )
	
	self.BoundDirty = true
end

function BASE:BindTo( other )
	self.BoundTo = other
	local x, y
	local xo, yo
	if IsValid( other ) then
		x, y = self:GetPos()
		xo, yo = other:GetPos()
		other.Bound[self] = { xo - x, yo - y }
	end
end

function BASE:Paint( w, h )
	draw.RoundedBox( self.Round, 0, 0, w, h, self:GetColor() )
end

buildr.register( "Base", {
	description = "Base panel. Everything derives from this",
	panel = BASE,
	show_tweens = true,
} )