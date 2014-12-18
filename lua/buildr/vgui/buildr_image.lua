local IMAGE = {}
IMAGE.SaveVariables = { 
	ImagePath = function( self, img )
		self:SetImage( img )
	end
}

function IMAGE:Init()
	self:SetImage( "icon16/help.png" )
end

function IMAGE:GetCode()
	return {
		("surface.SetMaterial( self.material_%s )"):format( self.ImageName ),
		"surface.SetDrawColor( $color$ )",
		("surface.DrawTexturedRect( $x$, $y$, %s, %s )"):format( self:GetSize() )
	}
end

function IMAGE:GetInitCode()
	return { ("self.material_%s = Material( \"%s\" )"):format( self.ImageName, self.ImagePath ) }
end

local mat = Material( "icon16/image.png" )
function IMAGE:PaintPreview( w, h, pnl )
	surface.SetMaterial( mat )
	surface.SetDrawColor( buildr.white )
	surface.DrawTexturedRect( 0, 0, w, h )
end

function IMAGE:SetImage( img )
	self.Image = Material( img )
	self.ImagePath = img
	self.ImageName = (img:match( "/.-%..+$" ) or "_IMG____"):sub( 2, -5 )
	self.DrawFunction = (img:sub( -3 ) == "png") and surface.SetMaterial or surface.SetTexture
	self:SetSize( self.Image:Width(), self.Image:Height() )
end

function IMAGE:AddRightClickOptions( menu )
	menu:AddOption( "Choose Image", function() self:ChooseImage() end ):SetIcon( "icon16/image.png" )
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
			self:SetImage( s:GetValue() )
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
	panel = IMAGE,
} )