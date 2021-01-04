local PANEL = {
	EffectivityColor = Color(0, 0, 255),
	HookDescription = "No description set."
}

AccessorFunc(PANEL, "EffectivityColor", "EffectivityColor")
AccessorFunc(PANEL, "HookEvent", "HookEvent", FORCE_STRING)
AccessorFunc(PANEL, "HookID", "HookID")
AccessorFunc(PANEL, "HookDescription", "HookDescription", FORCE_STRING)

--do not generate an example
function PANEL:GenerateExample(class, sheet, width, height) return end

function PANEL:Init()
	--uses the parent's init function too.
	--this fixes the exapnsion animation not happening the first time we expand the panel
	self:SetExpanded(false)
	self.m_bSizeExpanded = false
	
	--duration is funky, but 1 seems to work fine
	self.animSlide:Start(1, {From = self.Header:GetTall()})
	
	do --togglability check box
		local check_box = vgui.Create("DCheckBox", self.Header)
		local header = self.Header
		local width, height = header:GetSize()
		local size = 15
		
		check_box:Dock(FILL)
		check_box:DockMargin(width - size, 4, 0, height - size - 4)
		check_box:SetChecked(true)
		
		function self:OnChange(value)
			--still have not started the hook controller function... well we won't do it here anyways; we will do the functionality in main.lua
			print("We tried to change the hook!", self.HookEvent, self.HookID, "changes to", value)
		end
		
		self.CheckBox = check_box
	end
	
	do --description label
		local label_description = vgui.Create("DLabel", self)
		
		self:SetContents(label_description)
		
		label_description:Dock(TOP)
		label_description:SetAutoStretchVertical(true)
		label_description:SetText(self.HookDescription)
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
	local check_box = self.CheckBox
	local header = self.Header
	local header_width, header_height = header:GetSize()
	local size = 15
	
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
	
	check_box:Dock(FILL)
	check_box:DockMargin(header_width - size, 4, 0, header_height - size - 4)
	
	self.animSlide:Run()
	self:UpdateAltLines()
end

function PANEL:SetHook(event, id)
	self:SetHookEvent(tostring(event) or "broketh")
	self:SetHookID(id)
	
	self:SetLabel(event .. "::" .. (tostring(id) or "???"))
end

function PANEL:SetHookDescription(description)
	--update the description
	self.LabelDescription:SetText(description)
	
	--then do what the accessor func intended
	self.HookDescription = description
end

function PANEL:SetEffectivityColor(color)
	self.EffectivityColor = color
	
	self.Header:SetColor(color)
end

derma.DefineControl("OptimodHookController", "Hook entry in the Optimod GUI's Hook tab", PANEL, "DCollapsibleCategory")