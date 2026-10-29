local _, ns = ...
local oUF = ns.oUF

-- 名條專用。官方 Auras 的私有 STATE 不接受既有容器，因此另註冊 meta element。
-- 沿用 oUF elements/auras.lua 的 native binding 與生命週期；不掃描或處理 aura payload。
-- 同一份 options 定義一個預熱池，initialize 只在建立容器時設定群組與外觀。
local pools = {}
local elements = {}

local function CreateButton(element, options, button)
	button:SetSize(options.size, options.size)
	button:EnableMouse(false)

	local icon = button:CreateTexture(nil, "BORDER")
	icon:SetAllPoints()
	button.Icon = icon
	button:SetIcon(icon)

	local count = button:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
	button.Count = count
	button:SetApplicationCount(count, {})

	local time = button:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
	button.Time = time
	button:SetDurationText(time, {textFormatter = element.durationFormatter})

	-- Native 在 initializeFrame 結束後限制 AuraButton 存取，外觀只能在此階段設定。
	element:PostCreateButton(button, options)
end

local elementMixin = {}

function elementMixin:AddGroup(filter, options)
	options.sortMethod = options.sortMethod or AuraContainerSortMethod.ExpirationOnly
	options.sortDirection = options.sortDirection or AuraContainerSortDirection.Normal
	options.initializeFrame = GenerateClosure(CreateButton, self, options)
	self.groupIndex = self.groupIndex + 1
	local key = "Group" .. self.groupIndex
	self:AddAuraGroup(key, filter, options)
	return key
end

function elementMixin:ForceUpdate()
	self:UpdateAllAuras()
end

local function Build(options)
	local element = CreateFrame("AuraContainer", nil, UIParent, "CustomAuraContainerTemplate")
	element:SetEnabled(false)
	element:Hide()
	element.groupIndex = 0
	Mixin(element, elementMixin)

	element:SetFlowLayoutAxis(options.layout)
	element:SetFlowLayoutMaximumLineSize(options.layoutLimit)
	element:SetFlowLayoutAnchorPoint(options.initialAnchor)
	element:SetFlowLayoutGrowthDirection(options.growthX == "LEFT" and -1 or 1, options.growthY == "DOWN" and -1 or 1)
	element:SetFlowLayoutPadding(0, 0, 0, 0)
	options.initialize(element)
	return element
end

-- 排程由 layout 負責，僅在戰鬥外呼叫；不綁 unit、不建立 oUF owner 或註冊 unit event。
function oUF:PrewarmAuras(options)
	local pool = pools[options]
	if not pool then
		pool = {}
		pools[options] = pool
	end
	local element = Build(options)
	pool[#pool + 1] = element
	return element
end

local function Create(self, options)
	local pool = pools[options]
	local element = (pool and table.remove(pool)) or Build(options)
	element.__owner = self
	elements[self] = element
	element:SetParent(self)
	element:Show()
	-- 接管後永久留在這個 owner；原生名條復用只換 unit，不回池、不重建群組。
	return element
end

local function Update(self, event)
	local element = elements[self]
	if element:GetUnit() ~= self.__unit then
		element:SetUnit(self.__unit)
	else
		element:ForceUpdate()
	end
	if element.PostUpdate then
		element:PostUpdate(event)
	end
end

local function Enable(self)
	local element = elements[self]
	if element then
		element:SetEnabled(true)
		return true
	end
end

local function Disable(self)
	elements[self]:SetEnabled(false)
end

oUF:AddMetaElement("PrewarmAuras", Create, Update, Enable, Disable)
