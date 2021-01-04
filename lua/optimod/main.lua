local current_config = {}
local first_time = false
local frame_gui = vgui.GetWorldPanel():Find("OptimodGUI")

--constants
local effectivity_colors = {
	Color(240, 255, 0),
	Color(255, 255, 0),
	Color(255, 190, 0),
	Color(255, 48, 0),
	Color(255, 0, 0),
	optimal = Color(172, 128, 255)--Color(64, 64, 255)
}

local expensive_hooks = {
	NeedsDepthPass = {NeedsDepthPass_Bokeh = {effectivity = 3}},
	
	PostDrawEffects = {
		RenderHalos =	{effectivity = 5},
		RenderWidgets =	{effectivity = 3}
	},
	
	PostRender = {RenderFrameBlend = {effectivity = 4}},
	
	RenderScene = {
		RenderStereoscopy =	{effectivity = 3},
		RenderSuperDoF =	{effectivity = 3}
	},
	
	RenderScreenspaceEffects = {
		RenderBloom =			{effectivity = 2},
		RenderBokeh =			{effectivity = 2},
		RenderColorModify =		{effectivity = 2},
		RenderMaterialOverlay =	{effectivity = 2},
		RenderMotionBlur =		{effectivity = 2},
		RenderSharpen =			{effectivity = 3},
		RenderSobel =			{effectivity = 2},
		RenderSunbeams =		{effectivity = 2},
		RenderTexturize =		{effectivity = 2},
		RenderToyTown =			{effectivity = 3}
	},
	
	Think = {DOFThink = {effectivity = 2}}
}

--format for the optimal_convars table
--[[ 
	"con_var" = {
		--OPTIONAL
		--controller type for convar, defaults to "toggle"
		controller_type = "choices",
		
		--the effectivity
			--1 minimal performance increase whith optimal setting, or does not increase performance on its own
			--2 minimal performance increase whith optimal setting
			--3 measureable performance increase with optimal setting
			--4 noticeable performace increase with optimal setting
			--5 very noticeable performance increase with optimal setting	
		effectivity = 2,
		
		--the optimal value for the convar
		optimal_value = 1,
		
		--OPTIONAL
		--the available values, true means any value from 0 to 2^31 - 1
		values = {[0] = "Disabled", [1] = "Enabled", [2] = "Half way up"},
	}
]]

--refer to multiline comment above
local optimal_convars = { 
	cl_threaded_bone_setup = {
		effectivity = 3,
		optimal_value = 1
	},
	
	cl_threaded_client_leaf_system = {
		effectivity = 3,
		optimal_value = 1
	},
	
	gmod_mcore_test = {
		effectivity = 5,
		optimal_value = 1
	},
	
	mat_queue_mode = {
		controller_type = "choices",
		effectivity = 3,
		optimal_value = -1,
		values = {--needs rework, value descriptions are now handled in localization files
			[-1] = "Default",
			[0] = "Single thread (effectively disables)",
			[2] = "Multithreaded"
		}
	},
	
	mat_shadowstate = {
		effectivity = 2,
		optimal_value = 0
	},
	
	nb_shadow_dist = {
		effectivity = 2,
		optimal_value = 0
	},
	
	r_queued_ropes = {
		effectivity = 2,
		optimal_value = 1
	},
	
	r_shadowfromworldlights = {
		effectivity = 3,
		optimal_value = 0
	},
	
	r_shadowmaxrendered = {
		effectivity = 2,
		optimal_value = 0,
		values = true
	},
	
	r_shadowrendertotexture = {
		effectivity = 3,
		optimal_value = 0
	},
	
	r_threaded_client_shadow_manager = {
		effectivity = 3,
		optimal_value = 1
	},
	
	r_threaded_particles = {
		effectivity = 3,
		optimal_value = 1
	},
	
	r_threaded_renderables = {
		effectivity = 3,
		optimal_value = 1
	},
	
	studio_queue_mode = {
		effectivity = 3,
		optimal_value = 1
	}
}

local panel_paint_funcitons = {
	black = function(self, width, height)
		surface.SetDrawColor(0, 0, 0)
		surface.DrawRect(0, 0, width, height)
	end,
	super = function(self, width, height)
		surface.SetDrawColor(32, 32, 32)
		surface.DrawRect(0, 0, width, height)
	end
}

--calc_vars
local advert_h = 16
local frame_header = 24
local frame_size = 640
local sheet_header = 20

local frame_gui_h
local frame_gui_w
local sheet_h

--local functions
local function calc_vars(scr_w, scr_h)
	--we want to make sure it fits their screen, even if things might get a little funky town
	--we reverse the tranlations that we will be doing to make sure there is room for those translations
	--this should be 640 on higher resolutions, sorry 4k users, but gmod is probably already giving you a hard time lol
	local scaled_size = math.min(frame_size, scr_w, scr_h / 0.8 - advert_h)
	
	frame_gui_h = scaled_size * 0.8 + advert_h
	frame_gui_w = scaled_size
	sheet_h = frame_gui_h - advert_h - frame_header - sheet_header
end

local function config_load()
	local file_read = file.Read("optimod/config.json", "DATA")
	
	if file_read then
		local json = util.JSONToTable(file_read)
		
		if json then
			current_config = json
			
			return true
		end
	else first_time = true end
	
	return true
end

local function config_save() file.Write("optimod/config.json", util.TableToJSON(current_config, true)) end

local function open_gui()
	--close the existing gui
	if IsValid(frame_gui) then frame_gui:Remove() end
	
	frame_gui = vgui.Create("DFrame", vgui.GetWorldPanel(), "OptimodGUI")
	
	frame_gui:SetSize(frame_gui_w, frame_gui_h)
	frame_gui:SetTitle("#optimod.gui.title")
	
	do --the sheet with the settings
		local sheet = vgui.Create("DPropertySheet", frame_gui)
		
		do --info panel
			local panel_info = vgui.Create("DPanel", sheet)
			panel_info.Paint = panel_paint_funcitons.black
			
			--label with description of optimod
			local label_info = vgui.Create("DLabel", panel_info)
			
			label_info:Dock(FILL)
			label_info:DockMargin(4, 4, 4, 4)
			label_info:SetContentAlignment(7)
			label_info:SetWrap(true)
			
			label_info:SetText("#optimod.descriptions.info")
			sheet:AddSheet("#optimod.tabs.info", panel_info, "icon16/information.png")
		end
		
		do --convars
			
			local list_convars = vgui.Create("DCategoryList", sheet)
			
			do
				local label_info = vgui.Create("DLabel", sheet)
				
				label_info:SetAutoStretchVertical(true)
				label_info:SetText("#optimod.descriptions.convar")
				label_info:SetWrap(true)
				list_convars:AddItem(label_info)
			end
			
			do --I don't feel like doing it the right way >:D
				--this creates a gap between the description label and the rest of the contents, yes this is a bit hackish but what ever
				local panel_spacer = vgui.Create("DPanel", list_convars)
				panel_spacer.Paint = function() end
				
				panel_spacer:SetSize(0, 4)
				
				list_convars:AddItem(panel_spacer)
			end
			
			for console_variable, constructor_data in pairs(optimal_convars) do
				local convar = GetConVar(console_variable)
				local convar_controller = vgui.Create("OptimodConVarController", list_convars)
				
				--setting convar
				convar_controller:SetConVar(console_variable)
				
				--effectivity colors
				if convar and convar:GetString() == tostring(constructor_data.optimal_value) then convar_controller:SetEffectivityColor(effectivity_colors.optimal)
				else convar_controller:SetEffectivityColor(effectivity_colors[constructor_data.effectivity] or Color(0, 0, 255)) end
				
				--convar controller
				convar_controller:CreateConVarController(constructor_data.controller_type or "toggle", constructor_data.values)
				convar_controller:SetConVarDescription("#optimod.convars." .. console_variable)
				
				--put it in the collapsible category list
				list_convars:AddItem(convar_controller)
			end
			
			list_convars.Paint = panel_paint_funcitons.black
			
			--add the sheet, and force the active sheet to this one
			sheet:SetActiveTab(sheet:AddSheet("#optimod.tabs.convar", list_convars, "icon16/wrench.png").Tab)
		end
		
		do --hooks
			local list_hooks = vgui.Create("DCategoryList", sheet)
			
			do
				local label_info = vgui.Create("DLabel", sheet)
				
				label_info:SetAutoStretchVertical(true)
				label_info:SetText("#optimod.descriptions.hook")
				label_info:SetWrap(true)
				list_hooks:AddItem(label_info)
			end
			
			do --I don't feel like doing it the right way >:D
				--this creates a gap between the description label and the rest of the contents, yes this is a bit hackish but what ever
				local panel_spacer = vgui.Create("DPanel", list_hooks)
				panel_spacer.Paint = function() end
				
				panel_spacer:SetSize(0, 4)
				
				list_hooks:AddItem(panel_spacer)
			end
			
			--add catagories with catagory lists
			for event, hook_data in pairs(expensive_hooks) do
				local category_event = list_hooks:Add(event)
				local list_event = vgui.Create("DCategoryList", category_event)
				
				category_event:SetContents(list_event)
				
				list_event.Paint = panel_paint_funcitons.super
				list_event.VBar.Enabled = false
				
				list_event.VBar:SetEnabled(false)
				
				--add all the controllers
				for id, hook_datum in pairs(hook_data) do
					local hook_controller = vgui.Create("OptimodHookController", list_event)
					
					hook_controller:SetEffectivityColor(effectivity_colors[hook_datum.effectivity])
					hook_controller:SetHook(event, id)
					hook_controller:SetHookDescription("#optimod.hooks." .. event .. "." .. tostring(id))
					
					list_event:AddItem(hook_controller)
				end
			end
			
			list_hooks.Paint = panel_paint_funcitons.black
			
			sheet:AddSheet("#optimod.tabs.hook", list_hooks, "icon16/anchor.png")
		end
		
		--TOP docking takes priority over FILL docking, so we don't have to worry about the sheet getting covered by the credation
		sheet:Dock(TOP)
		sheet:SetHeight(sheet_h) --make room for my advert please
	end
	
	do --credation panel... please don't remove me ;-;
		local panel = vgui.Create("DPanel", frame_gui)
		
		do
			local label_credation = vgui.Create("DLabel", panel)
			
			label_credation:Dock(FILL)
			label_credation:SetColor(Color(64, 64, 64))
			label_credation:SetMouseInputEnabled(true)
			label_credation:SetText("#optimod.signature")
			label_credation:SetWrap(true)
			
			function label_credation:DoClick() gui.OpenURL("https://gflclan.com/profile/46384-cryotheum/")end
		end
		
		--make it transparent
		function panel:Paint(w, h) end
		
		--fill the remaing space
		panel:Dock(FILL)
	end
	
	frame_gui:Center()
	frame_gui:MakePopup()
end

--concommands the callback for `concommand.Add` is `function(ply, command, arguments, arguments_string)`
concommand.Add("optimod_gui", open_gui, nil, "Open the GUI for Optimod")
concommand.Add("optimod_load", config_load, nil, "Load the saved configuration for Optimod.")
concommand.Add("optimod_save", config_save, nil, "Save the current configuration for Optimod.")

--post
calc_vars(ScrW(), ScrH())

--reload
if frame_gui then open_gui() end