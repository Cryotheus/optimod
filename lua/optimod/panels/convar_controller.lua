local PANEL = {
	ConVarDescription = "No description set.",
	EffectivityColor = Color(0, 0, 255)
}

local convar_entry_types = {
	choices = {
		init = function(controller, header, convar, values)
			local choices = {}
			local combo_box = vgui.Create("DComboBox", header) 
			local convar_value = GetConVar(convar):GetString()
			
			for index, value in pairs(values) do
				local string_value = tostring(value)
				
				choices[combo_box:AddChoice("#optimod.convars." .. convar .. "." .. value, value, string_value == convar_value)] = string_value
			end
			
			combo_box:SetConVar(convar)
			--combo_box:ChooseOption("#optimod.convars." .. convar .. "." .. convar_value, choices[convar_value] or 0)
			
			function combo_box:OnSelect(index, text, data) controller:ChangedOptimal(data == controller.OptimalValue) end
			
			return combo_box
		end,
		
		layout = function(self, header)
			local width, height = header:GetSize()
			local text_width, text_height = header:GetTextSize()
			
			self:Dock(FILL)
			self:DockMargin(math.max(text_width + 8, width * 0.5), 4, 0, height - 16 - 4)
		end
	},
	
	range = {
		init = function(controller, header, convar, values)
			local number_wang = vgui.Create("DNumberWang", header) 
			
			number_wang:SetConVar(convar)
			number_wang:SetDecimals(0)
			number_wang:SetValue(GetConVar(convar):GetInt())
			number_wang:SetMinMax(unpack(values))
			
			function number_wang:OnChange() controller:ChangedOptimal(self:GetValue() == controller.OptimalValue) end
			
			return number_wang
		end,
		
		layout = function(self, header)
			local width, height = header:GetSize()
			
			self:Dock(FILL)
			self:DockMargin(width - 128, 4, 0, height - 16 - 4)
		end
	},
	
	toggle = {
		init = function(controller, header, convar)
			local check_box = vgui.Create("DCheckBox", header) 
			
			check_box:SetConVar(convar)
			
			function check_box:OnChange(value) controller:ChangedOptimal((value and 1 or 0) == controller.OptimalValue) end
			
			return check_box
		end,
		
		layout = function(self, header)
			local width, height = header:GetSize()
			local size = 15
			
			self:Dock(FILL)
			self:DockMargin(width - size, 4, 0, height - size - 4)
		end
	}
}

AccessorFunc(PANEL, "EffectivityColor", "EffectivityColor")
AccessorFunc(PANEL, "ConVar", "ConVar", FORCE_STRING) --force probably doesn't matter because we are overriding the function anyways
AccessorFunc(PANEL, "ConVarDescription", "ConVarDescription", FORCE_STRING)
AccessorFunc(PANEL, "OptimalValue", "OptimalValue")

--creates the panel to change the convar
function PANEL:ChangedOptimal(is_optimal) end

function PANEL:CreateConVarController(controller_type, values)
	if convar_entry_types[controller_type] then
		local convar_controller = convar_entry_types[controller_type].init(self, self.Header, self.ConVar, values)
		
		self.ConVarController = convar_controller
		self.ConVarControllerType = controller_type
		self.Header.ConVarController = convar_controller
		
		return convar_controller
	end
end

--do not generate an example
function PANEL:GenerateExample(class, sheet, width, height) return end

function PANEL:Init()
	--uses the parent's init function too.
	--this fixes the exapnsion animation not happening the first time we expand the panel
	self:SetExpanded(false)
	self.m_bSizeExpanded = false
	
	--duration is funky, but 1 seems to work fine
	self.animSlide:Start(1, {From = self.Header:GetTall()})
	
	do
		local label_description = vgui.Create("DLabel", self)
		
		self:SetContents(label_description)
		
		label_description:Dock(TOP)
		label_description:SetAutoStretchVertical(true)
		label_description:SetText(self.ConVarDescription)
		label_description:SetWrap(true)
		
		--self:InvalidateLayout(true)
		self:SizeToChildren(false, true)
		
		self.LabelDescription = label_description
	end
end

function PANEL:Paint(width, height)
	surface.SetDrawColor(40, 40, 40)
	surface.DrawRect(0, 0, width, height)
	
	surface.SetDrawColor(self.EffectivityColor)
	surface.DrawRect(0, 0, width, 2)
end

function PANEL:PerformLayout(width, height)
	local convar_controller = self.ConVarController
	
	if IsValid(self.Contents) then
		if self:GetExpanded() then
			self.Contents:InvalidateLayout(true)
			self.Contents:SetVisible(true)
		else self.Contents:SetVisible(false) end
	end
	
	if self:GetExpanded() then
		if IsValid(self.Contents) and #self.Contents:GetChildren() > 0 then self.Contents:SizeToChildren(false, true) end
		
		self:SizeToChildren(false, true)
	else
		if IsValid(self.Contents) and not self.OldHeight then self.OldHeight = self.Contents:GetTall() end
		
		self:SetTall(self:GetHeaderHeight())
	end
	
	self.animSlide:Run()
	self:UpdateAltLines()
	
	if IsValid(convar_controller) then convar_entry_types[self.ConVarControllerType].layout(convar_controller, self.Header) end
end

function PANEL:SetConVar(convar)
	convar = tostring(convar) or "broketh"
	
	self.ConVar = convar
	
	if IsValid(self.ConVarController) then self.ConVarController:SetConVar(convar) end
	
	self:SetLabel(convar)
end

function PANEL:SetConVarDescription(description)
	--update the description
	self.LabelDescription:SetText(description)
	
	--then do what the accessor func intended
	self.ConVarDescription = description
end

function PANEL:SetEffectivityColor(color)
	self.EffectivityColor = color
	
	self.Header:SetColor(color)
end

derma.DefineControl("OptimodConVarController", "ConVar entry in the Optimod GUI's ConVar tab", PANEL, "DCollapsibleCategory")