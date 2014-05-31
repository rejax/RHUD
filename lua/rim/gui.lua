RIM.Editor = { FirstOpen = true }
RIM.Editor.Styles = {
	Colors = {
		base = {
			closebutton = Color( 120, 40, 50 ),
			background_top = Color( 80, 80, 80 ),
			background_fill = Color( 70, 70, 70 ),
		},
		menubar = {
			bar = Color( 150, 150, 150 ),
			dropdown = Color( 200, 200, 200 ),
			dropdown_margin = Color( 130, 130, 130 ),
		},
		editor = {
			background = Color( 50, 50, 50 ),
			margin = Color( 60, 60, 60, 200 ),
			activelinebg = Color( 255, 255, 255, 10 ),
		},
		scrollbar = {
			background = Color( 200, 200, 200 ),
		},
		syntax = {
			information = Color( 200, 255, 200 ),
			config_setting = Color( 230, 235, 100 ),
			variable = Color( 250, 200, 200 ),
			functions = Color( 200, 200, 255 ),
			default_text = Color( 255, 255, 255 ),
		},
		tabs = {
			tab_active = Color( 130, 130, 130 ),
			tab_active_highlight = Color( 190, 170, 100 ),
			tab = Color( 120, 120, 120 ),
			background = Color( 90, 90, 90 ),
		},
		filebrowser = {
			background = Color( 120, 120, 120 ),
			web_background = Color( 90, 90, 90 ),
			closebutton = Color( 120, 40, 50 ),
		},
		style_editor = {
			background = Color( 30, 30, 30 ),
			closebutton = Color( 120, 40, 50 ),
			back = Color( 110, 110, 110 )
		},
	},
	Fonts = {
		active = "Courier",
		available = { "Courier", "Tahoma" },
		size = 14,
		size_margin = 8,
	}
}

for _, v in pairs( RIM.Editor.Styles.Fonts.available ) do
	surface.CreateFont( "rim_code_"..v, {
		font = v,
		size = RIM.Editor.Styles.Fonts.size,
		antialiasing = true
	} )

	surface.CreateFont( "rim_margin_"..v, {
		font = v,
		size = RIM.Editor.Styles.Fonts.size_margin,
		antialiasing = true
	} )
end

RIM.Editor.Settings = RIM.Editor.Settings or {
	tabs = {
		["save_onexit"] = { info = "Save open tabs on close (and reopening)", bool = true },
		["prompt_unsaved"] = { info = "Ask to close unsaved tabs", bool = true },
	},
	data = {
		["save_oncompile"] = { info = "Save changes when compiling", bool = false },
		["compile_onsave"] = { info = "Automatically compile when saved", bool = false }
	},
	general = {
		["save_confirmnoise"] = { info = "Play a sound when saved successfully", bool = true },
	}
}

function RIM.Editor:GetColor( category, name )
	return self.Styles.Colors[category][name]
end

function RIM.Editor:SetColor( category, name, color )
	self.Styles.Colors[category][name] = color
end

function RIM.Editor:GetSetting( category, name )
	return self.Settings[category][name].bool
end

function RIM.Editor:Open()
	if self.FirstOpen then
		if file.Exists( "rim/stored/styles.txt", "DATA" ) then
			local styles = file.Read( "rim/stored/styles.txt", "DATA" )
			local stylet = util.JSONToTable( styles )
			self.Styles = stylet
		end
		if file.Exists( "rim/stored/settings.txt", "DATA" ) then
			local settings = file.Read( "rim/stored/settings.txt", "DATA" )
			local sett = util.JSONToTable( settings )
			for cat, t in pairs( sett ) do
				for name, b in pairs( t ) do
					self.Settings[cat][name] = b
				end
			end
		end
		self.FirstOpen = false
	end
	
	local base = vgui.Create( "DFrame" )
		base:SetSize( 800, 600 )
		base:Center()
		base:SetTitle( "RIM Editor" )
		base:ShowCloseButton( false )
		base:MakePopup()
		base.CloseFunc = function( s )
			if not file.IsDir( "rim/stored", "DATA" ) then file.CreateDir( "rim/stored" ) end
			if self.StylesChanged then
				local json = util.TableToJSON( self.Styles )
				file.Write( "rim/stored/styles.txt", json )
			end
			if self:GetSetting( "tabs", "save_onexit" ) then
				local tabs = {}
				for _, s in pairs( self.TabSheet.Items ) do
					if not s.Name:find( "new rim" ) and self.TabSheet:GetActiveTab() == s.Tab and s.Panel.Editor.Local then
						table.insert( tabs, s.Name )
						break -- editor sort of poops itself with multiple (will fix)
					end
				end
				file.Write( "rim/stored/tabs.txt", util.TableToJSON( tabs ) )
			end
			
			local text = util.TableToJSON( self.Settings )
			file.Write( "rim/stored/settings.txt", text )
			s:Close()
		end
		
		base.CheckClose = function( s )
			local ok = true
			for _, p in pairs( self.TabSheet.Items ) do
				if not p.Panel.Editor:IsSaved() then
					Derma_Query( "Are you sure you want to close? You have one (or more) unsaved tabs opened",
						"Close",
						"Yes", function() s:CloseFunc() end,
						"No!", function() end ,
						"Save All and Close", function() self:SaveAllTabs(); s:CloseFunc() end,
						"Save Active Tab and Close", function() self:SaveActiveTab(); s:CloseFunc() end )
					ok = false
					break
				end
			end
			if ok then
				s:CloseFunc()
			end
		end
		base.Paint = function( s, w, h )
			draw.RoundedBox( 0, 0, 30, w, h-30, self:GetColor( "base", "background_fill" ) )
			draw.RoundedBox( 0, 0, 0, w, 30, self:GetColor( "base", "background_top" ) )
		end
	
	local closebutton = vgui.Create( "DButton", base )
		closebutton:SetSize( 90, 26 )
		closebutton:SetPos( base:GetWide() - 90, 0 )
		closebutton:SetText( "Close" )
		closebutton:SetTextColor( color_white )
		closebutton.DoClick = function() base:CheckClose() end
		closebutton.Paint = function( s, w, h )
			draw.RoundedBox( 0, 0, 0, w, h, self:GetColor( "base", "closebutton" ) )
		end
	
	self.Frame = base
		
	self:BuildTabs( base )
end

local mat_Active = "icon16/script_edit.png"--Material( "icon16/script_edit.png" )
local mat_Open = "icon16/script.png"--Material( "icon16/script.png" )
function RIM.Editor:BuildTabs( base )
	local tabs = vgui.Create( "DPropertySheet", base )
		tabs:Dock( FILL )
		tabs:DockMargin( 0, 3, 0, 0 )
	self.TabSheet = tabs
	
	local opentab = false
	if file.Exists( "rim/stored/tabs.txt", "DATA" ) and self:GetSetting( "tabs", "save_onexit" ) then
		local opened = util.JSONToTable( file.Read( "rim/stored/tabs.txt", "DATA" ) )
		if #opened ~= 0 then
			for k, v in pairs( opened ) do
				local content = file.Open( "rim/"..v..".txt", "r", "DATA" )
				if not content then break end
				local str = content:Read( content:Size() )
				if not str then break end
				local tab = self:BuildTab( tabs, string.Explode( "\n", str ), v )
				local new = tabs:AddSheet( v, tab, mat_Active, false, false )
				self:ModifyPropertySheet( tabs )
				opentab = true
			end
		end
	end
	
	if not opentab then
		local tab = self:BuildTab( tabs, { "" }, "new rim script" )
		local new = tabs:AddSheet( "new rim script", tab, mat_Active, false, false )
		tabs:SetActiveTab( new.Tab )
	end
	
	self:ModifyPropertySheet( tabs )
	self:AddMenuBar( base, tabs )
end

function RIM.Editor:ModifyPropertySheet( sheet )
	sheet.Paint = function( s, w, h )
		draw.RoundedBox( 0, 0, 20, w, h-3, self:GetColor( "tabs", "background" ) )
	end
	for n, item in pairs( sheet.Items ) do
		local tab, name, panel = item.Tab, item.Name, item.Panel
		tab.Think = function( s )
			s.Image:SetImage( s:IsActive() and mat_Active or mat_Open )
		end
		
		tab.Paint = function( s, w, h )
			surface.DisableClipping( true )
			if s:IsActive() then
				draw.RoundedBox( 0, 0, 0, w, h-3, self:GetColor( "tabs", "tab_active" ) )
				draw.RoundedBox( 0, 0, h-6, w, 3, self:GetColor( "tabs", "tab_active_highlight" ) )
			else
				draw.RoundedBox( 0, 0, 0, w, h + 1, self:GetColor( "tabs", "tab" ) )
			end
			surface.DisableClipping( false )
		end
	
		tab.DoRightClick = function( s )
			local menu = vgui.Create( "DMenu" )
				menu:SetDrawColumn( true )
				menu:AddOption( "Rename", function()
					Derma_StringRequest( "New Name", 
						"Input the new name for this file", panel.Editor.Name, 
						function( newname )
							panel.Editor.Name = newname
							item.Tab:SetText( newname )
							item.Tab:SizeToContentsX( 16 )
							sheet.tabScroller:InvalidateLayout( true )
							if not file.Exists( "rim/"..newname..".txt", "DATA" ) then
								file.Write( "rim/"..newname..".txt", panel.Editor:GetCode() )
								if file.Exists( "rim/"..panel.Editor.Name..".txt", "DATA" ) then
									file.Delete( "rim/"..panel.Editor.Name..".txt", "DATA" )
								end
							end
						end 
					)
				end ):SetIcon( "icon16/pencil.png" )
				
				if #sheet.Items > 1 then
					menu:AddOption( "Close", function()
						if not panel.Editor.Saved and self:GetSetting( "tabs", "prompt_unsaved" ) then
							Derma_Query( "This tab has unsaved changes! Are you sure you want to close it?",
							"Close",
							"Yes", function() 
								if tab:IsActive() then
									for _, t in pairs( sheet.Items ) do
										if t.Tab ~= tab then 
											sheet:SetActiveTab( t.Tab ) 
											break 
										end
									end
								end
								tab:SetAlpha( 0 )
								timer.Simple( 0.1, function() 
									sheet:CloseTab( tab, true )
								end )
							end,
							"No", function() end )
						else
							if tab:IsActive() then
								for _, t in pairs( sheet.Items ) do
									if t.Tab ~= tab then 
										sheet:SetActiveTab( t.Tab ) 
										break 
									end
								end
							end
							tab:SetAlpha( 0 )
							timer.Simple( 0.1, function() 
								sheet:CloseTab( tab, true )
							end )
						end
					end ):SetIcon( "icon16/script_delete.png" )
				end
				menu:AddSpacer()
			
			menu:Open()
		end
	end
	self.TabSheet = sheet
end

function RIM.Editor:SaveActiveTab( frombuild )
	local tab = self.TabSheet:GetActiveTab():GetPanel().Editor
	tab:SaveCode()
	local code = tab:GetCode()
	local name = tab.Name
	if name == "new rim hud" then name = "unnamed" end
	
	file.Write( "rim/"..name..".txt", code )
	
	if self:GetSetting( "data", "compile_onsave" ) and not frombuild then
		self:BuildCurrentTab( true )
	end
	
	if self:GetSetting( "general", "save_confirmnoise" ) then
		surface.PlaySound( "doors/handle_pushbar_locked1.wav" )
	end
end

function RIM.Editor:SaveAllTabs()
	for _, t in pairs( self.TabSheet.Items ) do
		local tab = t.Tab:GetPanel().Editor
		tab:SaveCode()
		local code = tab:GetCode()
		local name = tab.Name
		
		file.Write( "rim/"..name..".txt", code )
		
		if self:GetSetting( "general", "save_confirmnoise" ) then
			surface.PlaySound( "doors/handle_pushbar_locked1.wav" )
		end
	end
end

function RIM.Editor:BuildCurrentTab( fromsave )
	if self:GetSetting( "data", "save_oncompile" ) and not fromsave then
		self:SaveActiveTab( true )
	end
	
	local edit = self.TabSheet:GetActiveTab():GetPanel().Editor
	RIM:Build( edit.Name )
end

function RIM.Editor:AddMenuBar( base, tabs )
	local menu_bar = vgui.Create( "DMenuBar", base )
		menu_bar:DockMargin( -5, -3, -5, 0 )
	
	menu_bar.File = menu_bar:AddMenu( "File" )
		
		menu_bar.File:AddOption( "New", function()
			local new_amt = 1
			for n, t in pairs( tabs.Items ) do
				if t.Name:find( "new rim script" ) then new_amt = new_amt + 1 end
			end
			if new_amt == 1 then new_amt = "" else new_amt = " " .. new_amt end
			local tab = self:BuildTab( tabs, { "" }, "new rim script" .. new_amt )
			local new = tabs:AddSheet( "new rim script" .. new_amt, tab, mat_Active, false, false )
			tabs:SetActiveTab( new.Tab )
			self:ModifyPropertySheet( tabs )
		end ):SetIcon( "icon16/script_add.png" )
		
		menu_bar.File:AddSpacer()
		
		menu_bar.File:AddOption( "Save", function()
			self:SaveActiveTab()
		end ):SetIcon( "icon16/disk.png" )
		
		menu_bar.File:AddOption( "Save As", function()
			Derma_StringRequest( "Save As", 
				"Input the filename", "", 
				function( name )
					local edit = tabs:GetActiveTab():GetPanel()
					edit.Editor:SaveCode()
					local code = edit.Editor:GetCode()
					file.Write( "rim/"..name..".txt", code )
					
					tabs:GetActiveTab():SetText( name )
					tabs:GetActiveTab():SizeToContentsX( 16 )
					tabs.tabScroller:InvalidateLayout( true )
				end )
		end ):SetIcon( "icon16/page_save.png" )
		
		menu_bar.File:AddSpacer()
		
		menu_bar.File:AddOption( "Open", function()
			local open = vgui.Create( "DFrame", tabs:GetParent() )
				open:SetSize( 150, 300 )
				local posx, posy = tabs:GetParent():GetPos()
				open:SetPos( gui.MousePos() )
				open:ShowCloseButton( false )
				open:SetTitle( "RIM" )
				open:MakePopup()
				open.Paint = function( s, w, h )
					draw.RoundedBox( 0, 0, 0, w, h, self:GetColor( "filebrowser", "background" ) )
				end
			
			local closebutton = vgui.Create( "DButton", open )
				closebutton:SetSize( 60, 26 )
				closebutton:SetPos( open:GetWide() - 60, 0 )
				closebutton:SetText( "Close" )
				closebutton:SetTextColor( color_white )
				closebutton.DoClick = function() open:Close() end
				closebutton.Paint = function( s, w, h )
					draw.RoundedBox( 0, 0, 0, w, h, self:GetColor( "filebrowser", "closebutton" ) )
				end
			
			local files = vgui.Create( "DListView", open )
				files:Dock( FILL )
				files:AddColumn( "File" )
				files:SetCursor( "hand" )
				files.OnClickLine = function( s, line, row )
					if input.IsMouseDown( MOUSE_RIGHT ) then return end
					local content = file.Open( "rim/"..line.File, "r", "DATA" )
					local str = content:Read( content:Size() )
				--	content:Close()
					if not str then Derma_Message( "Invalid File?", "Ok" ) return end
					
					local tab = self:BuildTab( tabs, string.Explode( "\n", str ), line.File:sub( 1, -5 ) )
					local new = tabs:AddSheet( line.File:sub( 1, -5 ), tab, mat_Active, false, false )
					tabs:SetActiveTab( new.Tab )
					self:ModifyPropertySheet( tabs )
					open:Close()
				end
				
				files.OnRowRightClick = function( s, row ) 
					local m = DermaMenu()
					local fname = s:GetLine( row ):GetColumnText( 1 )
					m:AddOption( "Delete " .. fname .. "?", function()
						Derma_Query( "Are you sure you want to delete " .. fname .. "?", "Delete", "Yes", function()
							local f = "rim/" .. fname .. ".txt"
							MsgC( Color( 255, 0, 0 ), "[RIM] Deleting '" .. f .. "'\n" )
							file.Delete( f )
							timer.Simple( 0.1, function() 
								if file.Exists( f, "DATA" ) then file.Delete( f ) end -- garry y
							end )
							files:RemoveLine( row )
						end, "No", function() end )
					end ):SetIcon( "icon16/cancel.png" )
					m:Open()
				end
				
			for _, f in pairs( file.Find( "rim/*.txt", "DATA" ) ) do
				local found = false
				for _, p in pairs( tabs.Items ) do
					if p.Name == f:sub( 1, -5 ) then found = true end
				end
				if found then continue end
				local l = files:AddLine( f:sub( 1, -5 ) )
				l:SetCursor( "hand" )
				l.File = f
			end
		end ):SetIcon( "icon16/folder_go.png" )
		
		menu_bar.File:AddSpacer()
		
		menu_bar.File:AddOption( "Load from web", function()
			self:OpenWebLoader()
		end ):SetIcon( "icon16/world_edit.png" )
		
		menu_bar.Compile = menu_bar:AddMenu( "Compile" )
		menu_bar.Compile:AddOption( "Build Current", function()
			self:BuildCurrentTab()
		end ):SetIcon( "icon16/wrench.png" )
		
		menu_bar.Compile:AddOption( "Build All", function()
			for _, p in pairs( tabs.Items ) do
				if not p.Panel.Editor.Name:find( "new rim" ) then
					RIM:Build( p.Panel.Editor.Name )
				end
			end
		end ):SetIcon( "icon16/wrench_orange.png" )
		
		menu_bar.Compile:AddSpacer()
		
		menu_bar.Compile:AddOption( "Output Lua to console", function()
			local hud = tabs:GetActiveTab():GetPanel().Editor:GetCode()
			local faketab = { Variables = {}, Config = {}, Functions = {} }
			local code = RIM:Parse( hud, faketab )
			
			MsgC( color_white, code .. "\n" )
		end ):SetIcon( "icon16/application_xp_terminal.png" )
		
	menu_bar.Paint = function( s, w, h )
		draw.RoundedBox( 0, 0, 0, w, h, self:GetColor( "menubar", "bar" ) )
	end
	
	menu_bar.Settings = menu_bar:AddMenu( "Settings" )
		menu_bar.Settings:AddOption( "Configure Styles", function()
			self:ConfigureStyles()
		end ):SetIcon( "icon16/palette.png" )
		
		menu_bar.Settings:AddSpacer()
		
		menu_bar.Settings:AddOption( "Configure Settings", function()
			self:ConfigureSettings()
		end ):SetIcon( "icon16/cog.png" )
		
	for _, p in pairs( menu_bar.Menus ) do
		p.Paint = function( s, w, h )
			draw.RoundedBox( 0, 0, 0, w, h, self:GetColor( "menubar", "dropdown" ) )
			draw.RoundedBox( 0, 0, 0, 25, h, self:GetColor( "menubar", "dropdown_margin" ) )
		end
	end
end

function RIM.Editor:BuildTab( parent, code_tab, name, web )
	local edit = {}
	edit.Saved = true
	edit.Name = name
	edit.Code = table.Copy( code_tab )
	edit.Lines = {}
	edit.Local = ( web ~= true )
	
	local bg = vgui.Create( "DPanel", parent )
		bg.Paint = function( s, w, h )
			draw.RoundedBox( 0, 0, 0, w, h, self:GetColor( "editor", "background" ) )
			draw.RoundedBox( 0, 0, 0, 22, h, self:GetColor( "editor", "margin" ) )
			
			local posx, posy = s:GetPos()
			render.SetScissorRect( posx, posy, posx + w, posy + h, true )
		end
		bg.Editor = edit
		bg:Dock( FILL )
		
	local scroll = vgui.Create( "DScrollPanel", bg )
		scroll:Dock( FILL )
		scroll:DockMargin( 25, 0, 0, 0 )
		scroll.OnMousePressed = function() edit:LoseFocus() end
		scroll.OnScrollbarAppear = function( s )
			local bar = s:GetVBar()
			bar.Paint = function( p, w, h )
				draw.RoundedBox( 0, 0, 0, w, h, self:GetColor( "scrollbar", "background" ) )
			end
		end
	
	edit.GetCode = function( s )
		if s.Edit:IsVisible() then s:LoseFocus() end
		local t = {}
		for _, pnl in pairs( s.Lines ) do
			table.insert( t, pnl:GetText() )
		end
		return table.concat( t, "\n" )
	end
	
	edit.IsSaved = function( s ) 
		if s.Edit:IsVisible() then s:LoseFocus( true ) end
		for l, pnl in pairs( s.Lines ) do
			if s.Code[l] ~= pnl:GetText() then return false end
		end
		return s.Saved
	end
	
	edit.LayoutCode = function( s )
		local pos = 2
		for line, code in pairs( edit.Code ) do
			local l = vgui.Create( "DLabel", scroll )
				local formcode = self:FormatCode( code )
				l.IsEmpty = not formcode:find( "%a" )
				if l.IsEmpty then formcode = " " end
				l:SetPos( 5, pos )
				l:SetText( formcode )
				l:SetTextColor( self:ColorLine( code ) )
				l:SetFont( "rim_code_" .. self.Styles.Fonts.active )
				l:SizeToContents()
				l.Line = line
				
				l.PaintOver = function( s, w, h )
					surface.DisableClipping( true )
						draw.SimpleText( line, "rim_margin_" .. self.Styles.Fonts.active, -27, 0, color_white )
					surface.DisableClipping( false )
				end
			
			local posx, posy = l:GetPos()
			local b = vgui.Create( "DButton", scroll )
				b:SetPos( posx - 5, posy )
				b:SetSize( 800, 16 )
				b:SetAlpha( 0 )
				b:SetCursor( "beam" )
				b.DoClick = function(s)
					local x = s:LocalCursorPos()
					edit:LineClicked( l, x )
				end
			
			l.Button = b
			
			table.insert( edit.Lines, l )
			pos = pos + 15
		end
	end
	
	edit.SaveCode = function( s )
		s.Code = {}
		for l, pnl in pairs( s.Lines ) do
			if l ~= s.ActiveLine then
				s.Code[l] = pnl:GetText()
			else
				s.Code[l] = s.Edit:GetText()
			end
			pnl:SetText( s.Code[l] )
			pnl:SizeToContents()
		end
		edit.Saved = true
	end
	
	edit.RemoveCode = function( s )
		for l, p in pairs( s.Lines ) do
			p.Button:Remove()
			p:Remove()
		end
		s.Lines = {}
		s.ActiveLinePanel = nil
		s.ActiveLine = nil
	end
	edit:LayoutCode()
	
	edit.LineClicked = function( s, line, x, enter, manual_caret )
		if s.ActiveLinePanel == line then return end
		
		if s.ActiveLinePanel and s.ActiveLinePanel ~= line then 
			local newtext = s.Edit:GetText()
			if newtext == "" then newtext = " " end
			s.ActiveLinePanel.IsEmpty = newtext == " "
			
			s.ActiveLinePanel:SetVisible( true ) 
			s.ActiveLinePanel:SetText( newtext )
			s.ActiveLinePanel:SetTextColor( s.Edit:GetTextColor() )
			s.ActiveLinePanel:SizeToContents()
		end
	--	s:SaveCode()
		
		s.ActiveLinePanel = line
		s.ActiveLine = line.Line
		
		line:SetVisible( false )
		
		local text
		if line.IsEmpty then text = "" else text = line:GetText() end
		
		local indent = self:GetCursorIndent( line, x )
		local posx, posy = line:GetPos()
		local caret = s.Edit:GetCaretPos()
		
		s.Edit:SetVisible( true )
		s.Edit:SetPos( posx - 3, posy - 4 )
		s.Edit:SetTextColor( line:GetTextColor() )
		
		s.Edit:SetText( text )
		s.Edit:OnValueChange( text )
		-- after about 20 minutes of tears, i found out it doesnt change if there's keyboard focus ;_;
		if enter then
			s.Edit:SetCaretPos( caret )
		elseif not enter and not manual_caret then
			s.Edit:SetCaretPos( indent )
		end
		
		s.Edit.Hidden = false
		s.Edit.Line = line.Line
		s.Edit:RequestFocus()
	end
	
	edit.LoseFocus = function( s, check )
		if not check then s:SaveCode() end
		if s.ActiveLinePanel then
			local newtext = s.Edit:GetText()
			if newtext == "" then newtext = " " end
			s.ActiveLinePanel.IsEmpty = newtext == " "
			
			s.ActiveLinePanel:SetVisible( true )
			s.ActiveLinePanel:SetText( newtext )
			s.ActiveLinePanel:SizeToContents()
			s.Edit:SetVisible( false )
			s.Edit.Hidden = true
			s.Edit.Line = nil
			s.ActiveLine = nil
			s.ActiveLinePanel = nil
		end
	end
	
	edit.Enter = function( s )
		local line = s.ActiveLine
		local linetext = s.Edit:GetText()
		local caretpos = s.Edit:GetCaretPos()
		s:RemoveCode()
		
		local text_new = ""
		local text_old = linetext
		local ltext = string.Explode( "", linetext )
		for p, l in pairs( ltext ) do
			if p == caretpos then
				text_new = table.concat( ltext, "", p+1 )
				text_old = table.concat( ltext, "", 1, p )
				break
			end
		end
		
		table.insert( s.Code, line+1, text_new )
		s.Code[line] = text_old
		s:LayoutCode()
		s.Edit:SetText( text_new )
		s.Edit.Line = line
		
		s:LineClicked( s.Lines[line+1], 0, true )
		
		timer.Simple( 0, function() 
			scroll.VBar:SetScroll( scroll.VBar.CanvasSize )
		end )
	end
	
	edit.BackLine = function( s )
		local line = s.ActiveLine
		local linetext = s.ActiveLinePanel:GetText()
		if not edit.Lines[line-1] then return end
		local oldl = edit.Lines[line-1]:GetText()
		
		s:SaveCode()
		s:RemoveCode()
		
		table.remove( s.Code, line )
		
		s:LayoutCode()
		s:LineClicked( s.Lines[line-1], 0, false, true )
		
		s.Edit.Line = s.Edit.Line - 1
		s.Edit:SetText( s.Edit:GetText() .. linetext:sub( -2 ) )
		s.Edit:SetCaretPos( s.Edit:GetText():len() + 1 )
	end
	
	edit.KeyUp = function( s, caret )
		if not s.Lines[s.ActiveLine-1] then return end
		s:LineClicked( s.Lines[s.ActiveLine-1], caret )
	end
	
	edit.KeyDown = function( s, caret )
		if not s.Lines[s.ActiveLine+1] then return end
		local line = s.ActiveLine
		s:LineClicked( s.Lines[line+1], caret )
	end
	
	timer.Simple( .05, function()
		edit.Edit = self:MakeTextEditor( scroll, bg:GetWide(), edit )
		if new then edit:LineClicked( edit.Lines[#edit.Lines], 0 ) end
	end )
	
	return bg
end

function RIM.Editor:MakeTextEditor( parent, wide, edit_t )
	local edit = vgui.Create( "DTextEntry", parent )
		edit:SetSize( wide - 22, 20 )
		edit:SetVisible( false )
		edit:SetFont( "rim_code_" .. self.Styles.Fonts.active )
		edit:SetDrawBackground( false )
		edit:SetDrawBorder( false )
		edit:SetCursorColor( color_white )
		edit.OnEnter = function(s)
			edit_t:Enter()
		end
		edit.Hidden = false
		edit.OnKeyCode = function( s, key )
			if key == KEY_TAB then
				local cpos = s:GetCaretPos()
				local line = edit_t.ActiveLinePanel
				
				if s:GetText():find( "%a" ) then
					if cpos ~= s:GetText():len() then
						local p, text = s:GetCaretIndent()
						if text then
							local startline = table.concat( text, "", 1, p-1 )
							local endline = table.concat( text, "", p )
							s:SetText( startline .. string.rep( " ", 6 ) .. endline )
						end
					else
						s:SetText( s:GetText() .. ( " " ):rep( 6 ) )
					end
				else
					local _, amt = s:GetText():gsub( "%s", "_" )
					s:SetText( string.rep( " ", amt + 6 ) )
					s:SetCaretPos( amt + 6 )
				end
				edit_t:LoseFocus()
				timer.Simple( 0, function()
					edit_t:LineClicked( line, 0, false, true ) 
					s:SetCaretPos( cpos + 6 ) 
				end )
			elseif key == KEY_BACKSPACE then
				if s:GetCaretPos() == 0 and not s:GetText():find( "%a" ) then
					edit_t:BackLine()
				end
			elseif key == KEY_UP then
				edit_t:KeyUp( s:GetCaretIndent() )
			elseif key == KEY_DOWN then
				edit_t:KeyDown( s:GetCaretPos() )
			end
		end
		edit.GetCaretIndent = function( s )
			local cpos = s:GetCaretPos() + 1
			local text = string.Explode( "", s:GetText() )
			local pos = 0
			for p, l in pairs( text ) do
				if p == cpos then
					pos = p
					break
				end
			end
			return pos, text
		end
		edit.OnChange = function() edit_t.Saved = false end
		edit.PaintOver = function( s, w, h )
			if s.Hidden then return end
			surface.DisableClipping( true )
				draw.RoundedBox( 0, -5, 4, w, h - 7, self:GetColor( "editor", "activelinebg" ) )
				
				if s.Line then
					draw.SimpleText( s.Line, "rim_margin_" .. self.Styles.Fonts.active, -24, 4, color_white )
				end
			surface.DisableClipping( false )
		end
		
		edit.LastSave = CurTime()
		edit.Think = function( s )
			if s.Line then
				if s.Line ~= edit_t.ActiveLine then
					s:SetText( edit_t.ActiveLinePanel:GetText() )
					s.Line = edit_t.ActiveLine
					s:SetCaretPos( s:GetText():len() )
					edit_t.Saved = false
				end
				edit_t.Lines[s.Line]:SetTextColor( s:GetTextColor() )
			end
			s:SetTextColor( self:ColorLine( s:GetText() ) )
			if input.IsKeyDown( KEY_S ) and input.IsControlDown() then
				if s.LastSave + 1 < CurTime() then
					self:SaveActiveTab()
					s.LastSave = CurTime()
				end
			end
		end
		
	return edit
end

function RIM.Editor:ColorLine( line )
	if line:sub( 1, 1 ) == "$" then return self:GetColor( "syntax", "config_setting" ) end
	if line:sub( 1, 2 ) == ">>" then return self:GetColor( "syntax", "information" ) end
	if line:sub( 1, 3 ) == "var" then return self:GetColor( "syntax", "variable" ) end
		
	if line:find( "[=-]>" ) or line:sub( 1, 2 ) == "<>" then return self:GetColor( "syntax", "functions" ) end

	return self:GetColor( "syntax", "default_text" )
end

function RIM.Editor:FormatCode( code )
	local indent = 6
	code = code:gsub( "\t", string.rep( " ", indent ) )
	
	return code
end

function RIM.Editor:GetCursorIndent( line, x )
	local chars = string.Explode( "", line:GetText() )
	surface.SetFont( line:GetFont() )
	local char_w = surface.GetTextSize( "W" )
	
	local ind = false
	local xw = 0
	for p in pairs( chars ) do
		local a = char_w * p
		if not ind or math.abs( x - a ) < ind then
			xw = p
			ind = math.abs( x - a )
		end
	end
	
	return xw
end

function RIM.Editor:ConfigureStyles()
	local base = vgui.Create( "DFrame", self.Frame )
		base:SetSize( 500, 500 )
		base:Center()
		base:SetTitle( "RIM Style Editor" )
		base:ShowCloseButton( false )
		base:MakePopup()
		base.Paint = function( s, w, h )
			draw.RoundedBox( 0, 0, 0, w, h, self:GetColor( "style_editor", "background" ) )
		end
	
	local closebutton = vgui.Create( "DButton", base )
		closebutton:SetSize( 90, 26 )
		closebutton:SetPos( base:GetWide() - 90, 0 )
		closebutton:SetText( "Close" )
		closebutton:SetTextColor( color_white )
		closebutton.DoClick = function() base:Close() end
		closebutton.Paint = function( s, w, h )
			draw.RoundedBox( 0, 0, 0, w, h, self:GetColor( "style_editor", "closebutton" ) )
		end
		
	local category = vgui.Create( "DListView", base )
		category:Dock( FILL )
		category:AddColumn( "Element" )
		category:SetCursor( "hand" )
		category.Panels = {}
	
	local back = vgui.Create( "DButton", base )
		back:Dock( BOTTOM )
		back:SetText( "<-- Go Back" )
		back:SetTextColor( color_white )
		back.DoClick = function() category:GoBack() end
		back.Paint = function( s, w, h )
			draw.RoundedBox( 0, 0, 0, w, h, self:GetColor( "style_editor", "back" ) )
		end
		
		category.ShowBaseCategories = function( s )
			s.Panels = {}
			s:Clear()
			for k, v in pairs( self.Styles ) do
				local line = s:AddLine( k )
				line:SetCursor( "hand" )
				s.Panels[line] = k
			end
		end
		
		category.ShowCategoryElements = function( s )
			s.Panels = {}
			s:Clear()
			for k, v in pairs( self.Styles[s.Category] ) do
				local line = s:AddLine( k )
				line:SetCursor( "hand" )
				s.Panels[line] = k
			end
		end
		
		category.ShowCategoryElementSpecifics = function( s )
			s.Panels = {}
			s:AddColumn( "Color" )
			s:InvalidateLayout()
			s:Clear()
			for k, v in pairs( self.Styles[s.Category][s.CategoryElement] ) do
				local line = s:AddLine( k, "Currently this color!" )
				line:SetCursor( "hand" )
				line.Columns[2]:SetColor( v )
				s.Panels[line] = k
			end
		end
		
		category.LastClick = CurTime()
		category.OnClickLine = function( s, line )
			if s.LastClick + .5 > CurTime() then return end
			s.LastClick = CurTime()
			
			if not s.Category then
				if s.Panels[line] == "Colors" then
				s.Category = s.Panels[line]
				s:ShowCategoryElements()
				else Derma_Message( "These are disabled for now", "rip in piece fonts", "ok :(" ) end
			else
				if not s.CategoryElement then
					s.CategoryElement = s.Panels[line]
					s:ShowCategoryElementSpecifics()
				else
					s:QueryElement( line:GetColumnText( 1 ) )
				end
			end
		end
		
		category.GoBack = function( s )
			if not s.Category then return end
			if s.Category and not s.CategoryElement then
				s.Category = nil
				s:ShowBaseCategories()
			else
				s.Columns[2] = nil
				s:InvalidateLayout()
				s.CategoryElement = nil
				s:ShowCategoryElements()
			end
		end
		
		category.QueryElement = function( s, element )
			local bcol = self.Styles[s.Category][s.CategoryElement][element]
			
			local base = vgui.Create( "DFrame", category )
				base:SetSize( 300, 300 )
				base:Center()
				base:SetTitle( "Color Picker" )
				base:ShowCloseButton( false )
				base:MakePopup()
				base.Paint = function( s, w, h )
					draw.RoundedBox( 0, 0, 0, w, h, self:GetColor( "style_editor", "background" ) )
				end
			
			local closebutton = vgui.Create( "DButton", base )
				closebutton:SetSize( 90, 26 )
				closebutton:SetPos( base:GetWide() - 90, 0 )
				closebutton:SetText( "Close" )
				closebutton:SetTextColor( color_white )
				closebutton.DoClick = function() base:Close() end
				closebutton.Paint = function( s, w, h )
					draw.RoundedBox( 0, 0, 0, w, h, self:GetColor( "style_editor", "closebutton" ) )
				end
			
			local color = vgui.Create( "DColorMixer", base )
				color:Dock( FILL )
				color:SetPalette( true )
				color:SetAlphaBar( false )
				color:SetWangs( true )
				color:SetColor( bcol )
				color.ValueChanged = function( c, col )
					self:SetColor( s.CategoryElement, element, col )
					self.StylesChanged = true
				end
		end
		
	category:ShowBaseCategories()
end

function RIM.Editor:ConfigureSettings()
	local base = vgui.Create( "DFrame", self.Frame )
		base:SetSize( 500, 500 )
		base:Center()
		base:SetTitle( "RIM Settings" )
		base:ShowCloseButton( false )
		base:MakePopup()
		base.Paint = function( s, w, h )
			draw.RoundedBox( 0, 0, 0, w, h, self:GetColor( "style_editor", "background" ) )
		end
	
	local closebutton = vgui.Create( "DButton", base )
		closebutton:SetSize( 90, 26 )
		closebutton:SetPos( base:GetWide() - 90, 0 )
		closebutton:SetText( "Close" )
		closebutton:SetTextColor( color_white )
		closebutton.DoClick = function() base:Close() end
		closebutton.Paint = function( s, w, h )
			draw.RoundedBox( 0, 0, 0, w, h, self:GetColor( "style_editor", "closebutton" ) )
		end
		
	local property = vgui.Create( "DProperties", base )
		for cat, elem in pairs( self.Settings ) do
			for set, t in pairs( elem ) do
			local setting = property:CreateRow( cat, t.info )
				setting:Setup( "Boolean" )
				setting:SetValue( t.bool )
				setting.DataChanged = function( _, val ) 
					self.Settings[cat][set].bool = val
				end
			end
		end
		
		property:Dock( FILL )
end

local host = "http://www.uppercutservers.com/rejax/"
function RIM.Editor:OpenWebLoader()
	local base = vgui.Create( "DFrame", self.TabSheet:GetParent() )
		base:SetSize( 400, 500 )
		local posx, posy = self.TabSheet:GetParent():GetPos()
		base:SetPos( gui.MousePos() )
		base:ShowCloseButton( false )
		base:SetTitle( "RIM - Web Load" )
		base:MakePopup()
		base.Paint = function( s, w, h )
			draw.RoundedBox( 0, 0, 0, w, h, self:GetColor( "filebrowser", "web_background" ) )
		end
		
		base.HUDReady = function( s, hud )
			s.MountButton.HUD = hud
			s.MountButton:SetText( "Retrieve and Mount in editor" )
			s.MountButton:SetDisabled( false )
		end
	
	local button = vgui.Create( "DButton", base )
		button:Dock( BOTTOM )
		button:SetTall( 100 )
		button:SetText( "Right click on a file" )
		button:SetTextColor( color_black )
		button.DoClick = function( s )
			local hud = s.HUD
			http.Fetch( host .. "rim/upload/huds/" .. hud.file, function( body )
			local code = string.Explode( "\n", body )
			if code then
				local tab = self:BuildTab( self.TabSheet, code, hud.name, true )
				local new = self.TabSheet:AddSheet( hud.name, tab, mat_Active, false, false )
				self.TabSheet:SetActiveTab( new.Tab )
				self:ModifyPropertySheet( self.TabSheet )
				base:Close()
			end
			end,
			function()
				Derma_Message("Something went wrong when retrieving file " .. hud.name .. "!", "Ok" )
				base:Close()
			end )
		end
		button:SetDisabled( true )
	base.MountButton = button
			
	local closebutton = vgui.Create( "DButton", base )
		closebutton:SetSize( 60, 26 )
		closebutton:SetPos( base:GetWide() - 60, 0 )
		closebutton:SetText( "Close" )
		closebutton:SetTextColor( color_white )
		closebutton.DoClick = function() base:Close() end
		closebutton.Paint = function( s, w, h )
			draw.RoundedBox( 0, 0, 0, w, h, self:GetColor( "filebrowser", "closebutton" ) )
		end
	
	local huds = vgui.Create( "DListView", base )
		huds:Dock( FILL )
		huds:AddColumn( "Public RIM Scripts" )
		huds:AddLine( "fetching..." )
		huds.CanClick = false
	
		huds.OnRowRightClick = function( s, row )
			if not s.CanClick then return end
			
			local n = s:GetLine( row ):GetColumnText( 1 )
			local menu = DermaMenu()
			menu:AddOption( "Request " .. n .. "?", function()
				s:RequestFile( n )
			end ):SetIcon( "icon16/transmit_go.png" )
			menu:Open()
		end
		
		huds.RequestFile = function( s, name ) 
			http.Fetch( host .. "rim/upload/hud_info/" .. name, function( body )
				if not ValidPanel( s ) then return end
				if not body:find( "</html>$" ) then
					local t = util.JSONToTable( body )
					s:Clear()
					s.Columns[1] = nil
					s:InvalidateLayout()
					
					s:AddColumn( "info" )
					s:AddColumn( "data" )
					for inf, d in pairs( t ) do
						if inf ~= "file" then
							s:AddLine( inf .. " = ", d )
						end
					end
					s:InvalidateLayout()
					base:HUDReady( t )
				else
					s:Clear()
					s:AddLine( "Failed to retrieve hud " .. name )
					timer.Simple( 1, function() s:Fetch() end )
				end
			end,
			function()
				hud:Clear()
				hud:AddLine( "Failed to retrieve hud " .. name )
				timer.Simple( 1, function() s:Fetch() end )
			end )
		end
		
		huds.Fetch = function( s )
			http.Fetch( host .. "rim/list.php", function( body, len, headers, code )
				if not ValidPanel( s ) then return end
				s:RemoveLine( 1 ) 
				if body == "no huds" then s:AddLine( "failed, no huds" ) return end
				local json = util.JSONToTable( body )
				for _, v in pairs( json ) do
					s:AddLine( v )
				end
				s.CanClick = true
			end,
			function()
				s:RemoveLine( 1 ) 
				s:AddLine( "failed" )
			end )
		end
		huds:Fetch()
end
