local IMAGE = {}

function IMAGE:Init()
	self:ChooseImage()
	self.Image = Material( "icon16/help.png" )
	self.DrawFunction = surface.SetMaterial
end

local mat = Material( "icon16/image.png" )
function IMAGE:PaintPreview( w, h, pnl )
	surface.SetMaterial( mat )
	surface.SetDrawColor( buildr.white )
	surface.DrawTexturedRect( 0, 0, w, h )
end

function IMAGE:ChooseImage()
	local popup = vgui.Create( "DFrame", self )
		popup:SetTitle( "Choose Image" )
		popup:SetSize( 200, 100 )
		local x, y = buildr.gui_mousechop( popup:GetSize() )
		popup:SetPos( x + 50, y )
		popup:MakePopup()
		self.SuppressClick = popup
		buildr.attach_panel_extras( popup )
	
	local entry = vgui.Create( "DTextEntry", popup )
		entry:Dock( BOTTOM )
		entry.OnEnter = function( s )
			self.Image = Material( s:GetValue() )
		end
		
	local help = vgui.Create( "DLabel", popup )
		help:Dock( FILL )
		help:SetText( "Only accepts png for now.\nRelative to materials/\nPress enter to confirm" )
		help:SizeToContents()
end

function IMAGE:Paint( w, h )
	self.DrawFunction( self.Image )
	surface.SetDrawColor( self:GetColor() )
	surface.DrawTexturedRect( 0, 0, self.Image:Width(), self.Image:Height() )
end

buildr.register( "Image", {
	description = "Image. Draws a simple material",
	edits = {

	},
	panel = IMAGE,
} )