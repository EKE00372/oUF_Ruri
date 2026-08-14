-- 暫時停用右上角玩家光環替代框，保留實作供後續評估。
--[=[
local _, ns = ...
local F, G, T = ns[2], ns[3], ns[4]

local ceil = math.ceil
local ipairs, next = ipairs, next
local CreateFrame = CreateFrame
local RegisterStateDriver = RegisterStateDriver
local GetTemporaryEnchantmentInfo = C_PaperDollInfo.GetTemporaryEnchantmentInfo

local BUFF_SIZE = 32
local DEBUFF_SIZE = 36
local MAX_BUFFS = 32
local MAX_DEBUFFS = 24
local BUFFS_PER_ROW = 16
local DEBUFFS_PER_ROW = 10
local AURA_SPACING = 6
local DURATION_HEIGHT = 12

local ITEM_ENCHANTMENT_SLOTS = {
	INVSLOT_MAINHAND,
	INVSLOT_OFFHAND,
	INVSLOT_RANGED,
}

local buffContainer
local buffGroupKey
local playerBuffs
local vehicleBuffs
local activeBuffUnit

--===================================================--
----------------    [[ Blizzard ]]    -----------------
--===================================================--

local HiddenFrame = CreateFrame("Frame")
HiddenFrame:Hide()

local function HideObject(frame)
	if not frame then return end

	frame:Hide()
	frame:SetParent(HiddenFrame)
	frame:UnregisterAllEvents()
end

local function HideBlizzardAuraFrames()
	if BuffFrame then
		HideObject(BuffFrame)
		BuffFrame.numHideableBuffs = 0
	end

	if DebuffFrame then
		-- 保留原生致命減益提示，只隱藏 DebuffFrame 本身的圖示。
		local frame = DebuffFrame
		frame:SetAlpha(0)
		frame:EnableMouse(false)

		if frame.AuraContainer then
			frame.AuraContainer:Hide()
		end

		for _, anchor in ipairs(frame.PrivateAuraAnchors or {}) do
			anchor:Hide()
		end

		frame:Show()
	end
end

--===================================================--
------------------    [[ Text ]]    -------------------
--===================================================--

local DURATION_FORMATTER = C_StringUtil.CreateNumericRuleFormatter()
DURATION_FORMATTER:SetBreakpoints({
	{
		threshold = 0,
		format = "%dS",
		step = 1,
		rounding = Enum.NumericRuleFormatRounding.Up,
	},
	{
		threshold = 60,
		format = "%dM",
		components = {
			{div = 60, step = 1, rounding = Enum.NumericRuleFormatRounding.Up},
		},
	},
	{
		threshold = 3600,
		format = "%dH",
		components = {
			{div = 3600, step = 1, rounding = Enum.NumericRuleFormatRounding.Up},
		},
	},
	{
		threshold = 86400,
		format = "%dD",
		components = {
			{div = 86400, step = 1, rounding = Enum.NumericRuleFormatRounding.Up},
		},
	},
})

local DURATION_BINDING = C_DurationUtil.CreateDurationTextBinding()
DURATION_BINDING:SetFormatter(DURATION_FORMATTER)
DURATION_BINDING:SetExpiredText("")
DURATION_BINDING:SetZeroDurationText("")

local function StyleAuraButton(element, button, options)
	button.Icon:SetTexCoord(.08, .92, .08, .92)

	button.bg = F.CreateBD(button, button, 1, .2, .2, .2, 1, 1)
	button.shadow = F.CreateSD(button, button.bg, 4)

	if options and options.showDebuffTypeShadow then
		button.bg:SetBackdropColor(0, 0, 0, 1)
		button.bg:SetBackdropBorderColor(0, 0, 0, 1)

		local dispelOptions = {
			showWithoutDispelType = true,
			style = Enum.CustomAuraButtonDispelTypeTextureStyle.PreserveAsset,
			customDispelColorMap = element.__owner.colors.dispel,
		}
		for _, texture in next, {button.shadow:GetRegions()} do
			button:AddDispelTypeTexture(texture, dispelOptions)
		end
	end

	if button.Count then
		button.Count:SetFont(G.NFont, G.NumberFS, G.FontFlag)
		button.Count:ClearAllPoints()
		button.Count:SetPoint("BOTTOMRIGHT", button, 1, -5)
		button.Count:SetTextColor(.9, .9, .1)
	end

	if button.Time then
		button.Time:SetFont(G.NFont, G.NumberFS, G.FontFlag)
		button.Time:ClearAllPoints()
		button.Time:SetPoint("TOP", button, "BOTTOM", 1, 2)
	end

	local highlight = button:CreateTexture(nil, "HIGHLIGHT")
	highlight:SetAllPoints(button.Icon)
	highlight:SetColorTexture(1, 1, 1, .25)
end

-- oUF 目前未封裝 AddItemEnchantment；只在這裡補齊原生 AuraButton 所需元件。
local function InitializeItemEnchantmentButton(button)
	button:SetSize(BUFF_SIZE, BUFF_SIZE)
	button:EnableMouse(true)
	button:SetTooltipAnchorPoint("ANCHOR_BOTTOMLEFT", 0, 0)
	button:SetHideTooltipInCombat(false)

	local icon = button:CreateTexture(nil, "BORDER")
	icon:SetAllPoints()
	button.Icon = icon
	button:SetIcon(icon)

	local count = button:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
	button.Count = count
	button:SetApplicationCount(count)

	local time = button:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
	button.Time = time
	button:SetDurationText(time, {binding = DURATION_BINDING})

	button:SetCancelAuraButtons("RightButtonUp")
	StyleAuraButton(nil, button)
	button.bg:SetBackdropBorderColor(.64, .21, .93)
end

--===================================================--
-----------------    [[ Layout ]]    ------------------
--===================================================--

local function GetLayoutOptions(size)
	return {
		elementSpacing = AURA_SPACING,
		lineSpacing = 0,
		groupSpacing = 0,
		groupLineSpacing = 0,
		elementWidth = size,
		elementHeight = size + DURATION_HEIGHT,
	}
end

local function CreateHolder(name, size, count, perRow)
	local holder = CreateFrame("Frame", name, UIParent)
	local holderWidth = (size + AURA_SPACING) * perRow
	local holderHeight = (size + DURATION_HEIGHT) * ceil(count / perRow)

	holder:SetClampedToScreen(true)
	holder:SetSize(holderWidth, holderHeight)
	RegisterStateDriver(holder, "visibility", "[petbattle] hide; show")
	return holder
end

local function CreateOverlayHolder(name, parent)
	local holder = CreateFrame("Frame", name, parent)
	holder:SetAllPoints(parent)
	return holder
end

local function CreateAuraContainer(owner, holder, size, perRow)
	local rowWidth = size * perRow + AURA_SPACING * (perRow - 1)
	local container = owner:CreateAuras({
		layout = AnchorUtil.FlowLayoutAxis.Horizontal,
		layoutLimit = rowWidth,
		initialAnchor = "TOPRIGHT",
		growthX = "LEFT",
		growthY = "DOWN",
	})
	container:SetParent(holder)
	container:ClearAllPoints()
	container:SetPoint("TOPRIGHT", holder, "TOPRIGHT")
	container.PostCreateButton = StyleAuraButton
	container.showDuration = true
	container.disableCooldown = true
	container.durationBinding = DURATION_BINDING
	return container
end

local function AddBuffGroup(container)
	return container:AddGroup("HELPFUL", {
		maxFrameCount = MAX_BUFFS,
		size = BUFF_SIZE,
		showCount = true,
		cancelButton = "RightButtonUp",
		sortMethod = AuraContainerSortMethod.Default,
		sortDirection = AuraContainerSortDirection.Normal,
		layout = GetLayoutOptions(BUFF_SIZE),
	})
end

--===================================================--
-----------------    [[ Update ]]    ------------------
--===================================================--

local function UpdateBuffHolderVisibility(owner)
	local unit = owner.__unit
	if unit == activeBuffUnit then return end

	activeBuffUnit = unit
	local isVehicle = unit == "vehicle"
	playerBuffs:SetShown(not isVehicle)
	vehicleBuffs:SetShown(isVehicle)
end

local function UpdateBuffAuraLimit()
	if not buffContainer then return end

	local activeCount = 0
	for _, slot in ipairs(ITEM_ENCHANTMENT_SLOTS) do
		local enchantmentInfo = GetTemporaryEnchantmentInfo(slot)
		if enchantmentInfo and enchantmentInfo.hasExpirationTime then
			activeCount = activeCount + 1
		end
	end

	buffContainer:SetAuraGroupMaxFrameCount(buffGroupKey, MAX_BUFFS - activeCount)
end

local function OnEvent(_, event)
	if event == "PLAYER_ENTERING_WORLD" then
		HideBlizzardAuraFrames()
	end

	UpdateBuffAuraLimit()
end

--===================================================--
-----------------    [[ Create ]]    ------------------
--===================================================--

T.CreatePlayerAuraFrames = function(self)
	HideBlizzardAuraFrames()

	local buffAnchor = CreateHolder(nil, BUFF_SIZE, MAX_BUFFS, BUFFS_PER_ROW)
	buffAnchor:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -10, -10)
	playerBuffs = CreateOverlayHolder("RuriPlayerBuffs", buffAnchor)
	vehicleBuffs = CreateOverlayHolder("RuriVehicleBuffs", buffAnchor)

	buffContainer = CreateAuraContainer(self, playerBuffs, BUFF_SIZE, BUFFS_PER_ROW)
	local enchantmentOptions = {
		hidePermanent = true,
		initializeFrame = InitializeItemEnchantmentButton,
	}
	buffContainer:AddItemEnchantment(AuraContainerItemEnchantmentSlot.MainHand, enchantmentOptions)
	buffContainer:AddItemEnchantment(AuraContainerItemEnchantmentSlot.OffHand, enchantmentOptions)
	buffContainer:AddItemEnchantment(AuraContainerItemEnchantmentSlot.Ranged, enchantmentOptions)
	buffContainer:SetItemEnchantmentSortMethod(AuraContainerItemEnchantmentSortMethod.Slot, AuraContainerSortDirection.Normal)

	local enchantmentLayout = GetLayoutOptions(BUFF_SIZE)
	enchantmentLayout.placement = CustomAuraContainerItemEnchantmentPlacement.BeforeAuraGroups
	buffContainer:SetItemEnchantmentLayout(enchantmentLayout)

	buffGroupKey = AddBuffGroup(buffContainer)

	-- 載具使用獨立容器，避免受限 AuraButton 需要由 addon 事後隱藏。
	local vehicleBuffContainer = CreateAuraContainer(self, vehicleBuffs, BUFF_SIZE, BUFFS_PER_ROW)
	AddBuffGroup(vehicleBuffContainer)

	local debuffs = CreateHolder("RuriPlayerDebuffs", DEBUFF_SIZE, MAX_DEBUFFS, DEBUFFS_PER_ROW)
	debuffs:SetPoint("TOPRIGHT", buffAnchor, "BOTTOMRIGHT", 0, -12)

	local debuffContainer = CreateAuraContainer(self, debuffs, DEBUFF_SIZE, DEBUFFS_PER_ROW)
	debuffContainer:AddGroup("HARMFUL", {
		maxFrameCount = MAX_DEBUFFS,
		size = DEBUFF_SIZE,
		showCount = true,
		showDebuffTypeShadow = true,
		sortMethod = AuraContainerSortMethod.Default,
		sortDirection = AuraContainerSortDirection.Normal,
		layout = GetLayoutOptions(DEBUFF_SIZE),
	})

	UpdateBuffAuraLimit()

	-- oUF 更新完所有 AuraContainer 的 unit 後，再切換可見容器，避免露出舊 unit 光環。
	local previousPostUpdate = self.PostUpdate
	self.PostUpdate = function(owner, event)
		if previousPostUpdate then
			previousPostUpdate(owner, event)
		end
		UpdateBuffHolderVisibility(owner)
	end
	UpdateBuffHolderVisibility(self)

	local controller = CreateFrame("Frame")
	controller:RegisterEvent("PLAYER_ENTERING_WORLD")
	controller:RegisterEvent("WEAPON_ENCHANT_CHANGED")
	controller:RegisterEvent("WEAPON_SLOT_CHANGED")
	controller:SetScript("OnEvent", OnEvent)
end
]=]
