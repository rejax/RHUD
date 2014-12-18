buildr = buildr or { elements = {}, white = Color( 254, 254, 254 ) }

function buildr.open()
	local pnl = vgui.Create( "buildr_base" )
		pnl:MakePopup()
end
concommand.Add( "rhud_builder", buildr.open )

function buildr.register( name, info )
	local class = "buildr_element_" .. name:lower()
	buildr.elements[class] = {
		name = name,
		class = class,
		panel = info.panel,
		description = info.description,
		show_tweens = info.show_tweens
	}
	info.panel.class = class
	vgui.Register( class, info.panel, name == "Base" and "EditablePanel" or "buildr_element_base" )
end

function buildr.get( class )
	return buildr.elements[class:lower()]
end

local bg_color = Color( 80, 80, 80 )
function buildr.attach_panel_extras( pnl, nobutton, title )
	pnl.MenuBar = vgui.Create( "buildr_menubar", pnl )
	pnl.MenuBar:SetSize( pnl:GetWide(), 25 )
	pnl:ShowCloseButton( false )
	pnl:SetDraggable( false )
	if nobutton then
		pnl.MenuBar.Button:Remove()
	end
	pnl.MenuBar:SetText( title or "" )
	
	pnl.Paint = function( s, w, h )
		surface.SetDrawColor( bg_color )
		surface.DrawRect( 0, 0, w, h )
	end
end

function buildr.gui_mousechop( w, h )
	local x, y = gui.MousePos()
	if gui.MouseX() + w > ScrW() then x = ScrW() - w end
	if gui.MouseY() + h > ScrH() then y = ScrH() - h end
	return x, y
end

hook.Add( "HUDShouldDraw", "buildr_suppress", function()
	if buildr.in_editor then return false end
end )

function buildr.circular_ease_in_out(t, b, c, d)
	t = t / (d/2)
	if (t < 1) then return -c/2 * (math.sqrt(1 - t*t) - 1) + b end
	t = t - 2
	return c/2 * (math.sqrt(1 - t*t) + 1) + b
end