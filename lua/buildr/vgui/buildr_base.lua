local PANEL = {}

for i = 16, 28, 12 do
	surface.CreateFont( "buildr_desc_" .. i, {
		font = "Arial",
		size = i,
		weight = 600,
	} )
end
function PANEL:Init()
	self:SetPos( 0, 0 )
	self:SetSize( ScrW(), ScrH() )
	self:SetZPos( 1 )
	self.Elements = {}
	self:MakeMenuBar()
	
	buildr.in_editor = true
	buildr.base = self
	self.name = "undefined"
	self.canvas_clickbacks = {}
	self.canvas_drawfuncs = {}
	
	self:OpenModeRequest()
end

function PANEL:OnRemove()
	buildr.in_editor = false
	buildr.base = nil
end

function PANEL:MakeMenuBar()
	self.MenuBar = vgui.Create( "buildr_menubar", self )
		self.MenuBar:SetSize( ScrW(), 30 )
		self.MenuBar:AddOptions()
		self.MenuBar.IsBase = self
end

function PANEL:OnMousePressed( m )
	for _, pnl in pairs( self.Elements ) do
		if IsValid( pnl.SuppressClick ) then 
			pnl.SuppressClick:MakePopup()
			return 
		else 
			pnl.SuppressClick = nil
		end
	end
	if IsValid( self.SuppressClick ) then self.SuppressClick:MakePopup() return else self.SuppressClick = nil end
	
	if m == MOUSE_RIGHT then
		self:RightClick()
	elseif m == MOUSE_LEFT then
		buildr.binding = nil
	end
	
	for _, func in ipairs( self.canvas_clickbacks ) do func( m, gui.MousePos() ) end
end

function PANEL:RegisterCanvasClickCallback( func )
	table.insert( self.canvas_clickbacks, func )
	return #self.canvas_clickbacks
end

function PANEL:RegisterCanvasDrawFunc( func )
	table.insert( self.canvas_drawfuncs, func )
	return #self.canvas_drawfuncs
end

local disabled = Color( 110, 100, 100 )
local hover = Color( 140, 140, 140 )
local unhover = Color( 160, 160, 160 )
function PANEL:OpenModeRequest()
	local popup = vgui.Create( "DFrame", self )
		popup:SetSize( 200, 200 )
		popup:Center()
		self.SuppressClick = popup
	
	local function go_back()
		self:OpenModeRequest()
		popup:Remove()
	end
	
	for i = 0, 1 do
		local new = tobool( i )
		
		local button = vgui.Create( "DButton", popup )
			button:Dock( TOP )
			button:SetSize( 200, 83 )
			button:SetText( new and "New" or "Load" )
			button:SetTextColor( Color( 30, 30, 30 ) )
			button.DoClick = function( s )
				popup.MenuBar:SetText( s:GetText() )
				popup.button0:Remove()
				popup.button1:Remove()
				
				local back = vgui.Create( "DImageButton", popup.MenuBar )
					back:SetImage( "icon16/arrow_left.png" )
					back:SetPos( popup.MenuBar:GetWide() - 24, popup.MenuBar:GetTall() / 2 - 8 )
					back:SetSize( 16, 16 )
					back.DoClick = go_back
				
				if new then
					local desc = vgui.Create( "DLabel", popup )
						desc:SetText( "Enter project name" )
						desc:SetTextColor( buildr.white )
						desc:Dock( TOP )
						
					local entry = vgui.Create( "DTextEntry", popup )
						entry:Dock( TOP )
						entry.OnChange = function( s )
							local new = s:GetValue()
							self.MenuBar:SetText( new )
							self.name = new
							s.button:SetDisabled( new:find( "." ) == nil )
						end
					
					local button = vgui.Create( "DButton", popup )
						button:Dock( BOTTOM )
						button:SetText( "Ok" )
						button:SetDisabled( true )
						button:SetTextColor( Color( 30, 30, 30 ) )
						button.Paint = function( s, w, h )
							draw.RoundedBox( 0, 2, 2, w - 4, h - 4, s:GetDisabled() and disabled or ( s.Hovered and hover or unhover ) )
						end
						button.DoClick = function()
							self.Working = true
							popup:Remove()
						end
						entry.button = button
					return
				end
				
				local list = vgui.Create( "DListView", popup )
					list:Dock( FILL )
					list:AddColumn( "Saved" )
					list.OnRowSelected = function( _, _, line )
						if input.IsMouseDown( MOUSE_RIGHT ) then return end -- dirty hack
						buildr.load( line.name )
						self.Working = true
						popup:Remove()
					end
					list.OnRowRightClick = function( s, i, line )
						local menu = DermaMenu()
						menu:AddOption( "Delete '" .. line.name .. "'?", function()
							Derma_Query( "Delete " .. line.name .. "?", "", "OK", function()
								buildr.delete( line.name, true )
								s:RemoveLine( i )
								if #s:GetLines() < 1 then
									go_back()
								end
							end, "Cancel" )
						end ):SetIcon( "icon16/cancel.png" )
						menu:Open()
					end
				
				for _, f in pairs( file.Find( "buildr/saves/*.dat", "DATA" ) ) do
					local line = list:AddLine( f )
					line:SetCursor( "hand" )
					line.name = f
				end
			end
			
			button:SetDisabled( not new and #file.Find( "buildr/saves/*.dat", "DATA" ) < 1 )
			button.Paint = function( s, w, h )
					draw.RoundedBox( 0, 2, 2, w - 4, h - 4, s:GetDisabled() and disabled or ( s.Hovered and hover or unhover ) )
			end
			
		popup["button" .. i] = button
	end
		
	buildr.attach_panel_extras( popup, true, "Choose Project" )
end

function PANEL:RightClick()
	if not self.Working then return end
	
	local menu = DermaMenu()
	
	menu:AddOption( "New Element", function()
		self:CreateElementSelect()
	end ):SetIcon( "icon16/shape_square_add.png" )
		
	menu:AddOption( "Manage Order", function()
		self:ManageOrder()
	end ):SetIcon( "icon16/shape_move_back.png" )
	
	menu:AddOption( "Manage Grid", function()
		self:ManageGrid()
	end ):SetIcon( "icon16/layout.png" )
	
	local build = menu:AddSubMenu( "Build" )
	
	build:AddOption( "Build to RHUD", function()
		buildr.build( "rhud", self.Elements )
	end ):SetIcon( "icon16/wrench_orange.png" )
	
	if RIM then
		build:AddOption( "Build to RIM", function()
			buildr.build( "rim", self.Elements )
		end ):SetIcon( "icon16/wrench.png" )
	end
	
	build:AddOption( "Build to Lua", function()
		buildr.build( "lua", self.Elements )
	end ):SetIcon( "icon16/script_code.png" )
		
	menu:AddOption( "Save", function()
		buildr.save( self.Elements, self.name, "saved" )
	end ):SetIcon( "icon16/disk.png" )
	
	menu:Open()
end

function PANEL:ManageOrder()
	local popup = vgui.Create( "DFrame", self )
		popup:SetSize( 400, 50 )
		popup:SetPos( buildr.gui_mousechop( popup:GetSize() ) )
		popup:MakePopup()
		self.SuppressClick = popup
		buildr.attach_panel_extras( popup, false, "Manage Order" )
	
	local text = vgui.Create( "DLabel", popup )
		text:Dock( TOP )
		text:SetText( "Drag and drop to manage draw order. (higher numbers are drawn in front)" )
		text:SetTextColor( buildr.white )
		
	local scroll = vgui.Create( "DScrollPanel", popup )
		scroll:Dock( FILL )
		scroll:DockMargin( 0, 10, 0, 0 )
		
	local items = vgui.Create( "DIconLayout", scroll )
		items:Dock( FILL )
		items:SetSpaceX( 500 )
		items:SetSpaceY( 5 )
		items.Paint = function( s, w, h )
			
		end
	
	items.LayoutItems = function( i )
		items:Clear()
		for id, pnl in ipairs( self.Elements ) do
			local p = items:Add( "DDragBase" )
			p:SetSize( 400, 64 )
			p:SetCursor( "sizeall" )
			p.id = pnl.id
			p.pnl = pnl
			
			if not popup.Sized then
				popup:SetTall( math.min( popup:GetTall() + (p:GetTall() + 10), 600 ) )
				popup:SetPos( buildr.gui_mousechop( popup:GetSize() ) )
			end
			
			p.OnCursorEntered = function( s ) s.In = true end
			p.OnCursorExited = function( s ) s.In = false end
			p.Paint = function( s, w, h )
				surface.SetDrawColor( 0, 0, 0, s.In and 180 or 100 )
				surface.DrawRect( 0, 0, w, h )
				s.pnl:PaintPreview( 64, 64, s )
				
				surface.SetTextColor( buildr.white )
				
				surface.SetFont( "buildr_desc_28" )
				surface.SetTextPos( 69, 0 )
				surface.DrawText( "[" .. s.pnl.id .. "]" )
				
				surface.SetFont( "buildr_desc_16" )
				surface.SetTextPos( 69, 34 )
				surface.DrawText( s.pnl.name or s.pnl.class )
			end
			
			p:Droppable( "buildr_elem" )
			p:Receiver( "buildr_elem", function( s, pnls, dropped )
				local pnl = pnls[1]
				pnl.In = dropped
				s.In = dropped
				if not dropped then return end
				
				self:SwapElementOrder( pnl.id, s.id )
				i:LayoutItems()
			end )
		end
	end
	items:LayoutItems()
	popup:SetTall( popup:GetTall() + 10 )
	popup.Sized = true
end

local random_number = 1457 -- no conflict
function PANEL:SwapElementOrder( id1, id2 )
	local pnl1, pnl2 = self.Elements[id1], self.Elements[id2]
	
	self.Elements[id1] = pnl2
	self.Elements[id2] = pnl1
	pnl1.id = id2
	pnl2.id = id1
	pnl1:SetZPos( random_number + pnl1.id )
	pnl2:SetZPos( random_number + pnl2.id )
end

function PANEL:CreateElementSelect()
	local popup = vgui.Create( "DFrame", self )
		popup:SetSize( 400, 400 )
		popup:SetPos( buildr.gui_mousechop( popup:GetSize() ) )
		popup:MakePopup()
		self.SuppressClick = popup
		buildr.attach_panel_extras( popup, false, "Create Element"  )
	
	local text = vgui.Create( "DLabel", popup )
		text:Dock( TOP )
		text:SetText( "Select an element" )
		text:SetTextColor( buildr.white )
		
	local scroll = vgui.Create( "DScrollPanel", popup )
		scroll:Dock( FILL )
		scroll:DockMargin( 0, 10, 0, 0 )
		
	local items = vgui.Create( "DIconLayout", scroll )
		items:Dock( FILL )
		items:SetSpaceX( 500 )
		items:SetSpaceY( 5 )
	
	for id, info in pairs( buildr.elements ) do
		local name = info.name
		local p = items:Add( "Panel" )
		p:SetSize( 390, 64 )
		p:SetCursor( "hand" )
		
		p.OnCursorEntered = function( s ) s.In = true end
		p.OnCursorExited = function( s ) s.In = false end
		p.Paint = function( s, w, h )
			surface.SetDrawColor( 0, 0, 0, s.In and 180 or 100 )
			surface.DrawRect( 0, 0, w, h )
			info.panel.PaintPreview( info.panel, 64, 64, p )
			
			surface.SetFont( "buildr_desc_28" )
			surface.SetTextPos( 69, 0 )
			surface.SetTextColor( buildr.white )
			surface.DrawText( info.name )
			
			surface.SetFont( "buildr_desc_16" )
			surface.SetTextPos( 69, 34 )
			surface.SetTextColor( buildr.white )
			surface.DrawText( info.description )
		end
		
		p.OnMousePressed = function( _, m )
			if m == MOUSE_LEFT then
				self:CreateElement( info.class, info )
				popup:Remove()
			end
		end
	end
end

function PANEL:ManageGrid()
	local popup = vgui.Create( "DFrame", self )
		popup:SetSize( 400, 55 )
		popup:SetPos( buildr.gui_mousechop( popup:GetSize() ) )
		popup:MakePopup()
		self.SuppressClick = popup
		buildr.attach_panel_extras( popup, false, "Manage Grid" )
	
	local choice = vgui.Create( "DComboBox", popup )
		choice:Dock( TOP )
		choice:SetValue( self.Grid or "Disabled" )
		for _, val in ipairs( { "Disabled", 8, 16, 32, 64 } ) do choice:AddChoice( val ) end
		choice.OnSelect = function( _, _, value )
			self.Grid = isnumber( value ) and value or nil
		end
end

function PANEL:SnapToGrid( x, y )
	if ( not self.Grid or isstring( self.Grid ) ) then
		return x, y
		else return math.Round( x / self.Grid ) * self.Grid, math.Round( y / self.Grid ) * self.Grid
	end
end

function PANEL:CreateElement( class, info )
	local pnl = vgui.Create( class, self )
		pnl:SetPos( self:SnapToGrid( gui.MousePos() ) )
		if info.show_tweens then pnl:CreateSizeTweens() end
		table.insert( self.Elements, pnl )
		pnl.id = #self.Elements
		pnl:SetZPos( 1457 + pnl.id )
		pnl:SetPaintedManually( false )
	return pnl
end

function PANEL:RemoveElement( pnl )
	if pnl.BoundTo then pnl.BoundTo.Bound[self] = nil end
	table.remove( self.Elements, pnl.id )
	pnl:Remove()
end

surface.CreateFont( "buildr_save", {
	font = "Roboto",
	size = 16,
	weight = 600
} )

function PANEL:AddCursorMessage( material, message, time, color )
	self.CursorEffect = { start = CurTime(), icon = material, text = message, duration = time or 3, color = color or color_white, alpha = 255, alpha2 = 255 }
end

local tick = Material( "icon16/accept.png" )
local cross = Material( "icon16/cancel.png" )
function PANEL:DoSaveEffect( success, message )
	self:AddCursorMessage( success and tick or cross, message, 3 )
end

function PANEL:Paint( w, h )
	surface.SetDrawColor( 0, 0, 0, 120 )
	surface.DrawRect( 0, 0, w, h )
	
	if self.Grid then
		if isstring( self.Grid ) then self.Grid = nil end
		local w, h = ScrW(), ScrH()
		surface.SetDrawColor( 255, 255, 255, 50 )
		for step = self.Grid, ScrW(), self.Grid do
			surface.DrawLine( 0, step, w, step )
			surface.DrawLine( step, 0, step, h )
		end
	end
	
	surface.SetDrawColor( buildr.white )
	
	for k, pnl in ipairs( self.Elements ) do
		if IsValid( pnl ) then
			pnl:SetPaintedManually( false )
			pnl:PaintManual()
			pnl:SetPaintedManually( true )
			
			if buildr.debug then
				local x, y = pnl:GetPos()
				local w, h = pnl:GetSize()
				draw.RoundedBox( 0, x, y, w, h, Color( 200, 200, 200, 100 ) )
			end
		else
			table.remove( self.Elements, k )
		end
	end
	
	if buildr.binding then
		surface.SetDrawColor( 150, 255, 255 )
		local px, py = buildr.binding:GetPos()
		local sw, sh = buildr.binding:GetSize()
		surface.DrawLine( px + ( sw / 2 ), py + ( sh / 2 ), gui.MouseX(), gui.MouseY() )
	end
	
	local effect = self.CursorEffect
	if effect then
		local passed = CurTime() - effect.start
		if passed < effect.duration then
			--effect.alpha = 255 - 255 * ( 1 * ( passed / effect.duration ) )
			effect.alpha = 255 - buildr.circular_ease_in_out( passed, 1, 255, effect.duration )
			
			surface.SetMaterial( effect.icon )
			surface.SetDrawColor( 255, 255, 255, effect.alpha )
			surface.DrawTexturedRect( gui.MouseX() + 24, gui.MouseY(), effect.icon:Width(), effect.icon:Height() )
			
			surface.SetFont( "buildr_save" )
			surface.SetTextColor( ColorAlpha( effect.color, effect.alpha ) )
			surface.SetTextPos( gui.MouseX() + 24, gui.MouseY() + effect.icon:Height() + 2 )
			surface.DrawText( effect.text )
		else
			self.SaveEffect = nil
		end
	end
	
	for _, func in ipairs( self.canvas_drawfuncs ) do func( w, h ) end
end

vgui.Register( "buildr_base", PANEL, "EditablePanel" )

do
	local MBAR = {}

	function MBAR:Init()
		self.Button = vgui.Create( "buildr_closebutton", self )
		self.Button:Setup( self:GetParent(), 100, 30 )
	end
	
	function MBAR:AddOptions()
		self.Options = vgui.Create( "DImageButton", self )
		self.Options:SetImage( "icon16/wrench.png" )
		self.Options:SetSize( 16, 16 )
		self.Options:SetPos( ScrW() - 123, 7 )
		
		self.Options.DoClick = function( s )
			if not buildr.base.Working then return end
			
			local menu = DermaMenu()
			
			menu:AddOption( "Exit To Menu", function()
				timer.Simple( 0, buildr.open )
				buildr.base:Remove()
			end ):SetIcon( "icon16/arrow_left.png" )
			
			menu:Open()
		end
	end
	
	function MBAR:SetText( text )
		self.name = text
	end

	local bg_color = Color( 50, 50, 50 )
	function MBAR:Paint( w, h )
		surface.SetDrawColor( bg_color )
		surface.DrawRect( 0, 0, w, h )
		
		surface.SetTextColor( buildr.white )
		surface.SetFont( "buildr_desc_16" )
		surface.SetTextPos( 5, 5 )
		surface.DrawText( self.name or "/" )
	end

	vgui.Register( "buildr_menubar", MBAR, "EditablePanel" )
end

do
	local CLOSE = {}

	local in_color = Color( 150, 50, 50 )
	local out_color = Color( 120, 50, 50 )
	function CLOSE:Setup( parent, w, h )
		self:SetSize( w, h )
		self:SetFont( "marlett" )
		self:SetText( "r" )
		self:SetTextColor( buildr.white )
		self:Dock( RIGHT )
		self:SetCursor( "arrow" )
		self.DoClick = function() parent:Remove() end
		self.OnCursorEntered = function( s ) s.In = true end
		self.OnCursorExited = function( s ) s.In = false end
		self.Paint = function( s, w, h )
			surface.SetDrawColor( s.In and in_color or out_color )
			surface.DrawRect( 0, 0, w, h )
		end
	end

	vgui.Register( "buildr_closebutton", CLOSE, "DButton" )
end