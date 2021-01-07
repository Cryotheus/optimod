--locals
local first_time = false
local frame_gui = vgui.GetWorldPanel():Find("OptimodGUI") --for reload
local hook_controllers = {}

--local functions
local fl_hook_Add = OptimodHookAdd or hook.Add
local fl_hook_Remove = OptimodHookRemove or hook.Remove

--tables!
local current_config = {}

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
	
	Think = {DOFThink = {effectivity = 2}},
	
	HUDPaint = {optimod_test = {effectivity = 5}}
}

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

----calc_vars
	local advert_h = 16
	local frame_header = 24
	local frame_size = 640
	local sheet_header = 20

	local frame_gui_h
	local frame_gui_w
	local sheet_h

--globals
OptimodHookAdd = OptimodHookAdd or fl_hook_Add
OptimodHookRemove = OptimodHookRemove or fl_hook_Remove
OptimodHooks = OptimodHooks or {}

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

local function disable_hook(event, id, func)
	print("disable!", event, id, func)
	
	local event_hook = func or hook.GetTable()[event][id]
	
	--store the function in case we want to restore it later
	if OptimodHooks[event] then OptimodHooks[event][id] = event_hook
	else OptimodHooks[event] = {[id] = event_hook} end
	
	--remove it from the hook table
	fl_hook_Remove(event, id)
end

local function enable_hook(event, id, func)
	print("enable!", event, id, func)
	
	local event_hook = func or OptimodHooks[event][id]
	
	OptimodHooks[event][id] = nil
	
	--we don't need to store a bunch of empty tables
	if table.IsEmpty(OptimodHooks[event]) then OptimodHooks[event] = nil end
	
	fl_hook_Add(event, id, event_hook)
end

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
				
				hook_controllers[event] = {}
				
				--add all the controllers
				for id, hook_datum in pairs(hook_data) do
					local hook_controller = vgui.Create("OptimodHookController", list_event)
					local check_box = hook_controller.CheckBox
					hook_controllers[event][id] = hook_controller --store for later so we can edit them easily
					
					hook_controller:SetEffectivityColor(effectivity_colors[hook_datum.effectivity])
					hook_controller:SetHook(event, id)
					hook_controller:SetHookDescription("#optimod.hooks." .. event .. "." .. tostring(id))
					
					
					function check_box:OnChange(value)
						local controller = self.HookController
						
						local hooks = value and OptimodHooks or hook.GetTable()
						local event = controller.HookEvent
						local id = controller.HookID
						
						if hooks[event] then
							local event_hook = hooks[event][id]
							
							if event_hook then
								if value then enable_hook(event, id, event_hook)
								else disable_hook(event, id, event_hook) end
							end
						end
					end
					
					list_event:AddItem(hook_controller)
				end
			end
			
			list_hooks.Paint = panel_paint_funcitons.black
			
			sheet:AddSheet("#optimod.tabs.hook", list_hooks, "icon16/anchor.png")
		end
		
		--TOP docking takes priority over FILL docking, so we don't have to worry about the sheet getting covered by the credation
		sheet:Dock(TOP)
		sheet:SetHeight(sheet_h) --make room for our credation
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
	
	--so we don't try to edit a check box that was removed
	function frame_gui:OnRemove()
		frame_gui = nil
		hook_controllers = {}
	end
	
	frame_gui:Center()
	frame_gui:MakePopup()
end

local function update_hook_controller(event, id)
	print("attempt to update hook controllers")
	print("and text here")
	print("hook_controllers", hook_controllers)
	
	if hook_controllers then
		local hook_controller = hook_controllers[event] and hook_controllers[event][id] or false
		
		if IsValid(hook_controller) then print(event, id, hook_controller) hook_controller:UpdateCheckBox() print("succ")
		else print("almost made it") end
		
		return hook_controller
	else print("failed!") end
end

--concommands
--the callback for `concommand.Add` is `function(ply, command, arguments, arguments_string)`
concommand.Add("optimod_gui", open_gui, nil, "Open the GUI for Optimod")
concommand.Add("optimod_load", config_load, nil, "Load the saved configuration for Optimod.")
concommand.Add("optimod_save", config_save, nil, "Save the current configuration for Optimod.")

--hooks
hook.Add("Initialize", "optimod", function()
	local fl_hook_Add = OptimodHookAdd or hook.Add
	local fl_hook_Remove = OptimodHookRemove or hook.Remove
	OptimodHookAdd = fl_hook_Add
	OptimodHookRemove = fl_hook_Remove
	
	function hook.Add(event, id, func, ...)
		--update the function if the hook is re-added when it is disabled
		if OptimodHooks[event] and OptimodHooks[event][id] then
			print("hook.Add with stored hook")
			
			OptimodHooks[event][id] = func
		else
			print("hook.Add with other hook")
			
			fl_hook_Add(event, id, func, ...)
			
			if expensive_hooks[event] and expensive_hooks[event][id] then
				print("hook.Add with tracked hook")
				
				--if the hook was a hook we tracked, update the GUI
				--we also need to set its checked state to what we had in our configuration
				local hook_controller = update_hook_controller(event, id)
				
				--hook_controller.CheckBox:SetChecked(blah)
			end
		end
	end

	function hook.Remove(event, id, ...)
		if OptimodHooks[event] and OptimodHooks[event][id] then
			print("hook.Remove with stored hook")
			
			OptimodHooks[event][id] = nil
			
			if table.IsEmpty(OptimodHooks[event]) then OptimodHooks[event] = nil end
			
			update_hook_controller(event, id)
		else
			print("hook.Remove with other hook")
			
			fl_hook_Remove(event, id, ...)
			
			if expensive_hooks[event] and expensive_hooks[event][id] then
				print("hook.Remove with tracked hook")
				
				update_hook_controller(event, id)
			end
		end
	end
end)

--post
calc_vars(ScrW(), ScrH())

do ---[[ reload
	if frame_gui then
		hook.GetTable().Initialize.optimod()
		open_gui()
	end
	
	hook.Add("HUDPaint", "optimod_test", function() surface.SetDrawColor(color_white) surface.DrawRect(100, 100, 20, 20) end)
	--]]
end