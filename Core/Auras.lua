local _, ns = ...
local oUF = ns.oUF
local C, F, G, T = unpack(ns)

local HORIZONTAL = AnchorUtil.FlowLayoutAxis.Horizontal
local VERTICAL = AnchorUtil.FlowLayoutAxis.Vertical
local ROUND_DOWN = Enum.NumericRuleFormatRounding.Down

--===================================================================--
-------------    [[ Blizzard AuraContainer Filters ]]    -------------
--===================================================================--

-- 來源：
-- Blizzard_FrameXMLUtil/AuraUtil.lua 的 AuraUtil.AuraFilters
-- Blizzard_AuraContainer/Blizzard_CustomAuraContainer.lua
--
-- filter string 規則：
-- 1. 以「|」串接的條件全部都要成立（AND），不提供 OR。
-- 2. 條件前加「!」表示反向，例如 HARMFUL|!PLAYER。但 INCLUDE_NAME_PLATE_ONLY 與 MAW 不可反向。
-- 3. INCLUDE_NAME_PLATE_ONLY 是「也納入只供名條顯示的光環」，不是「只顯示名條光環」。
--
-- 基礎條件：
-- HELPFUL                 只納入增益。
-- HARMFUL                 只納入減益。
-- PLAYER                  只納入玩家、玩家寵物或載具施放的光環。
-- RAID                    只納入玩家可施放的增益和玩家可驅散的減益。
-- CANCELABLE              只納入玩家可主動取消的光環；反向請使用 !CANCELABLE。
-- INCLUDE_NAME_PLATE_ONLY 額外納入標記為 nameplate-only 的光環；未指定時這類光環會被排除。
-- MAW                     只納入 Torghast 光環；未指定時 Torghast 光環會被排除。
--
-- 暴雪維護的分類白名單：
-- EXTERNAL_DEFENSIVE      只納入外部減傷。
-- CROWD_CONTROL           只納入控場效果，例如暈眩、恐懼等。
-- RAID_IN_COMBAT          只納入標記為戰鬥中應顯示於團框的光環。
-- RAID_PLAYER_DISPELLABLE 只納入目前團隊中有人能驅散的光環。
-- BIG_DEFENSIVE           只納入大型防禦技能。
-- IMPORTANT               只納入重要光環；主要是即使不可偷取也應顯示於敵方名條的增益。
-- DISPELLABLE             只納入可驅散光環，不考慮玩家團隊目前是否真的具備對應驅散能力。
--
-- 常用組合：
-- HELPFUL|IMPORTANT|INCLUDE_NAME_PLATE_ONLY      敵方重要增益。
-- HARMFUL|CROWD_CONTROL|INCLUDE_NAME_PLATE_ONLY  控場減益。
-- HELPFUL|BIG_DEFENSIVE                          大型防禦技能。
-- HELPFUL|EXTERNAL_DEFENSIVE                     外部減傷。
-- HELPFUL|PLAYER|RAID_IN_COMBAT                  自己施放且應在團框顯示的 HoT／增益。
--
-- candidateFilters 是 filter string 之後的第二層 AND 篩選：
-- includeSpellIDs/excludeSpellIDs       精確納入/排除 spellID。
-- includeDispelTypes/excludeDispelTypes 精確納入/排除驅散類型。
-- maxDuration                           依完整持續時間設定上限；非 nil 時永久光環也會被排除。
-- processedAuraType                     依 ProcessAura 結果篩選，必須先使用 ProcessAura policy。
-- isFromPlayerOrPlayerPet、isRoleAura、isPriorityAura、isStealable、canApplyAura、
-- nameplateShowAll、nameplateShowPersonal、isBossAura、isBossOrRoleAura 皆可作為布林條件。
-- 所有非 nil candidateFilters 同樣是 AND，不會自動形成 OR。
--
-- includeSpellIDs/excludeSpellIDs 只會套用於可協助單位的增益、不可協助單位的減益，以及 NeverSecret 光環；
-- 其他光環會略過這兩個條件，因此不能依賴它們製作完整白名單，應優先使用上述原生分類。
--
-- AddSlot sortMethod 決定多個候選中由哪一個取得唯一 slot；AddGroup 使用相同選項排列全部候選：
-- Default            玩家本人施放優先，再依 isPriorityAura、canApplyAura、auraInstanceID 排序。
-- BigDefensive       非玩家本人施放優先，再依較晚的 expirationTime、auraInstanceID 排序。
-- UnitFrameDebuff    依 ProcessAura 產生的 debuffType 排序，再套用 Default；應搭配 ProcessAura policy。
-- ImportantOnly      C_Spell.IsSpellImportant() 為 true 者優先，再依 auraInstanceID；只排序，不負責過濾。
-- Expiration         玩家本人施放、isPriorityAura、canApplyAura 優先，再依較早到期、auraInstanceID 排序。
-- ExpirationOnly     只依較早到期、auraInstanceID 排序；永久光環排在有時限光環之後。
-- Name               玩家本人施放、isPriorityAura、canApplyAura 優先，再依名稱、auraInstanceID 排序。
-- NameOnly           只依名稱、auraInstanceID 排序。
-- AuraInstanceIDOnly 只依 auraInstanceID 排序。
-- sortDirection 可選 Normal 或 Reverse；Reverse 會反轉整套排序。
-- oUF AddSlot 預設為 Default；AddGroup 預設為 ExpirationOnly。

--===================================================--
-----------------    [[ General ]]    -----------------
--===================================================--

local UF_AURA_DURATION = C_StringUtil.CreateNumericRuleFormatter()
UF_AURA_DURATION:SetBreakpoints({
	{-- 秒
		threshold = 0,
		step = 1,
		rounding = ROUND_DOWN,
		format = "%d",
	},
	{-- 五分鐘以下
		threshold = SECONDS_PER_MIN,
		format = "%d:%02d",
		components = {
			{div = SECONDS_PER_MIN, step = 1, rounding = ROUND_DOWN},
			{mod = SECONDS_PER_MIN, step = 1, rounding = ROUND_DOWN},
		},
	},
	{-- 分
		threshold = 5 * SECONDS_PER_MIN,
		format = "%dm",
		components = {
			{div = SECONDS_PER_MIN, step = 1, rounding = ROUND_DOWN},
		},
	},
	{-- 時
		threshold = SECONDS_PER_HOUR,
		format = "%dh",
		components = {
			{div = SECONDS_PER_HOUR, step = 1, rounding = ROUND_DOWN},
		},
	},
	{-- 天
		threshold = SECONDS_PER_DAY,
		format = "%dd",
		components = {
			{div = SECONDS_PER_DAY, step = 1, rounding = ROUND_DOWN},
		},
	},
})

local RAID_AURA_DURATION = C_StringUtil.CreateNumericRuleFormatter()
RAID_AURA_DURATION:SetBreakpoints({
	{-- 秒
		threshold = 0,
		step = 1,
		rounding = ROUND_DOWN,
		format = "%d",
	},
	{-- 秒以上隱藏
		threshold = SECONDS_PER_MIN,
		format = "",
	},
})

-- 設定光環外觀
local function PostCreateAuraButton(element, button, options)
	button.Icon:SetTexCoord(.08, .92, .08, .92)

	-- 背景向按鈕外擴 1px；外置容器的錨點需補回這 1px，才能與狀態條維持相同可視間距。
	button.bg = F.CreateBD(button, button, 1, .2, .2, .2, 1, 1)
	button.shadow = F.CreateSD(button, button.bg, 3)

	if options.showDebuffTypeShadow then
		button.bg:SetBackdropColor(0, 0, 0, 1)
		button.bg:SetBackdropBorderColor(0, 0, 0, 1)

		local dispelOptions = {
			showWithoutDispelType = true,	-- 無類型減益也顯示
			style = Enum.CustomAuraButtonDispelTypeTextureStyle.PreserveAsset,	-- 保留自定義材質，不被原生邊框材質取代
			customDispelColorMap = element.__owner.colors.dispel,	-- 使用 ouf 的減益類型顏色表
		}
		for _, texture in next, {button.shadow:GetRegions()} do
			button:AddDispelTypeTexture(texture, dispelOptions)
		end
	end

	if button.Count then
		button.Count:SetFont(G.NFont, G.NumberFS, G.FontFlag)
		button.Count:ClearAllPoints()
		button.Count:SetPoint("BOTTOMRIGHT", button, 0, -2)
		button.Count:SetTextColor(.9, .9, .1)
	end

	if button.Time then
		button.Time:SetFont(G.NFont, G.NumberFS, G.FontFlag)
		button.Time:ClearAllPoints()
		button.Time:SetPoint("TOP", button, 0, 3)
	end
end

--====================================================--
-----------------    [[ Polarity ]]    -----------------
--====================================================--

-- 依敵我關係切換兩組光環的顯示上限
local function UpdateAuraPolarity(self, _, unit)
	if unit and unit ~= self.__unit then return end

	local relation = self.AuraPolarity
	if not relation then return end
	
	-- 敵友判定
	local hostile = (UnitCanAttack("player", self.__unit) and true) or false
	if relation.isHostile == hostile then return end

	relation.isHostile = hostile
	relation.container:SetAuraGroupMaxFrameCount(	-- 增益光環
		relation.helpfulGroup,
		hostile and relation.hostileHelpfulMax or relation.friendlyHelpfulMax
	)
	relation.container:SetAuraGroupMaxFrameCount(	-- 減益光環
		relation.harmfulGroup,
		hostile and relation.hostileHarmfulMax or relation.friendlyHarmfulMax
	)
	relation.container:ForceUpdate()
end

local function EnableAuraPolarity(self)
	if self.AuraPolarity then
		self:RegisterEvent("UNIT_FACTION", UpdateAuraPolarity)
		UpdateAuraPolarity(self)
		return true
	end
end

local function DisableAuraPolarity(self)
	if self.AuraPolarity then
		self:UnregisterEvent("UNIT_FACTION", UpdateAuraPolarity)
		self.AuraPolarity.isHostile = nil
	end
end

oUF:AddElement("AuraPolarity", UpdateAuraPolarity, EnableAuraPolarity, DisableAuraPolarity)

--==================================================--
-----------------    [[ Create ]]    -----------------
--==================================================--

-- 玩家橫式減益
T.CreatePlayerDebuffs = function(self)
	local Debuffs = self:CreateAuras({
		layout = HORIZONTAL,
		layoutLimit = C.PWidth,
		initialAnchor = "BOTTOMLEFT",
		growthX = "RIGHT",
		growthY = "UP",
	})
	Debuffs:SetFrameLevel(self:GetFrameLevel() + 4)
	Debuffs.PostCreateButton = PostCreateAuraButton
	Debuffs.showDuration = true
	Debuffs.disableCooldown = true
	Debuffs.durationFormatter = UF_AURA_DURATION

	Debuffs:AddGroup("HARMFUL", {
		maxFrameCount = 6,
		size = C.AuraSize + 4,
		showCount = true,
		showDebuffTypeShadow = true,
		layout = {
			elementSpacing = 5,
			lineSpacing = 5,
		},
	})

	self.Debuffs = Debuffs
	T.UpdatePlayerDebuffsPosition(Debuffs)

	return Debuffs
end

-- 玩家直式減益
T.CreateVPlayerDebuffs = function(self)
	local Debuffs = self:CreateAuras({
		layout = VERTICAL,
		layoutLimit = C.PWidth,
		initialAnchor = "BOTTOMLEFT",
		growthX = "RIGHT",
		growthY = "UP",
	})
	Debuffs:SetFrameLevel(self:GetFrameLevel() + 4)
	Debuffs.PostCreateButton = PostCreateAuraButton
	Debuffs.showDuration = true
	Debuffs.disableCooldown = true
	Debuffs.durationFormatter = UF_AURA_DURATION

	Debuffs:AddGroup("HARMFUL", {
		maxFrameCount = 6,
		size = C.AuraSize + 4,
		showCount = true,
		showDebuffTypeShadow = true,
		layout = {
			elementSpacing = 5,
			lineSpacing = 5,
		},
	})

	self.Debuffs = Debuffs
	T.UpdatePlayerDebuffsPosition(Debuffs)
	return Debuffs
end

-- 目標橫式光環
T.CreateTargetAuras = function(self)
	local size = C.AuraSize
	local spacing = 6
	local lineSpacing = spacing
	local layoutLimit = self:GetWidth()
	local iconsPerLine = math.max(1, math.floor(layoutLimit / (size + spacing) + .5))
	local helpfulMax = iconsPerLine
	local harmfulMax = math.max(C.MaxAura - helpfulMax, 0)

	local Auras = self:CreateAuras({
		layout = HORIZONTAL,
		layoutLimit = layoutLimit,
		initialAnchor = "BOTTOMLEFT",
		growthX = "RIGHT",
		growthY = "UP",
	})
	Auras:SetFrameLevel(self:GetFrameLevel() + 4)
	Auras:SetPoint("BOTTOMLEFT", self.Health, "TOPLEFT", 1, C.PPOffset * 2 + C.PPHeight)
	Auras.PostCreateButton = PostCreateAuraButton
	Auras.showDuration = true
	Auras.disableCooldown = true
	Auras.durationFormatter = UF_AURA_DURATION

	local helpfulGroup = Auras:AddGroup("HELPFUL", {
		maxFrameCount = helpfulMax,
		size = size,
		showCount = true,
		tooltipAnchor = "ANCHOR_TOPLEFT",
		layout = {
			elementSpacing = spacing,
			lineSpacing = lineSpacing,
			groupSpacing = size + spacing,
		},
	})

	local harmfulGroup = Auras:AddGroup("HARMFUL", {
		maxFrameCount = harmfulMax,
		size = size,
		showCount = true,
		showDebuffTypeShadow = true,
		tooltipAnchor = "ANCHOR_TOPLEFT",
		layout = {
			elementSpacing = spacing,
			lineSpacing = lineSpacing,
			groupSpacing = size + spacing,
			groupLineSpacing = lineSpacing,
		},
	})

	self.Auras = Auras
	self.AuraPolarity = {
		container = Auras,
		helpfulGroup = helpfulGroup,
		harmfulGroup = harmfulGroup,
		friendlyHelpfulMax = helpfulMax, 
		friendlyHarmfulMax = harmfulMax,
		hostileHelpfulMax = 4,
		hostileHarmfulMax = C.MaxAura,
	}
	return Auras
end

-- 目標直式光環
T.CreateVTargetAuras = function(self)
	local size = C.AuraSize
	local spacing = 6
	local lineSpacing = spacing
	local layoutLimit = self:GetHeight()
	local iconsPerLine = math.max(1, math.floor(layoutLimit / (size + spacing) + .5))
	local helpfulMax = iconsPerLine
	local harmfulMax = math.max(C.MaxAura - helpfulMax, 0)

	local Auras = self:CreateAuras({
		layout = VERTICAL,
		layoutLimit = layoutLimit,
		initialAnchor = "BOTTOMRIGHT",
		growthX = "LEFT",
		growthY = "UP",
	})
	Auras:SetFrameLevel(self:GetFrameLevel() + 4)
	Auras:SetPoint("BOTTOMRIGHT", self.Health, "BOTTOMLEFT", -C.PPOffset - 1, 1)
	Auras.PostCreateButton = PostCreateAuraButton
	Auras.showDuration = true
	Auras.disableCooldown = true
	Auras.durationFormatter = UF_AURA_DURATION

	local helpfulGroup = Auras:AddGroup("HELPFUL", {
		maxFrameCount = helpfulMax,
		size = size,
		showCount = true,
		tooltipAnchor = "ANCHOR_BOTTOMLEFT",
		layout = {
			elementSpacing = spacing,
			lineSpacing = lineSpacing,
			groupSpacing = size + spacing,
		},
	})

	local harmfulGroup = Auras:AddGroup("HARMFUL", {
		maxFrameCount = harmfulMax,
		size = size,
		showCount = true,
		showDebuffTypeShadow = true,
		tooltipAnchor = "ANCHOR_BOTTOMLEFT",
		layout = {
			elementSpacing = spacing,
			lineSpacing = lineSpacing,
			groupSpacing = size + spacing,
			groupLineSpacing = lineSpacing,
		},
	})

	self.Auras = Auras
	self.AuraPolarity = {
		container = Auras,
		helpfulGroup = helpfulGroup,
		harmfulGroup = harmfulGroup,
		friendlyHelpfulMax = helpfulMax,
		friendlyHarmfulMax = harmfulMax,
		hostileHelpfulMax = 4,
		hostileHarmfulMax = C.MaxAura,
	}
	return Auras
end

-- 焦點光環
T.CreateFocusAuras = function(self)
	local size = C.AuraSize
	local spacing = 6
	local layoutLimit = self:GetWidth()
	local iconsPerLine = math.max(1, math.floor(layoutLimit / (size + spacing) + .5))
	local helpfulMax = iconsPerLine
	local harmfulMax = math.max(C.MaxAura - helpfulMax, 0)

	local Auras = self:CreateAuras({
		layout = HORIZONTAL,
		layoutLimit = layoutLimit,
		initialAnchor = "BOTTOMLEFT",
		growthX = "RIGHT",
		growthY = "UP",
	})
	Auras:SetFrameLevel(self:GetFrameLevel() + 4)
	Auras:SetPoint("BOTTOMLEFT", self.Health, "TOPLEFT", 1, C.PPOffset * 2 + C.PPHeight)
	Auras.PostCreateButton = PostCreateAuraButton
	Auras.showDuration = true
	Auras.disableCooldown = true
	Auras.durationFormatter = UF_AURA_DURATION

	local helpfulGroup = Auras:AddGroup("HELPFUL", {
		maxFrameCount = helpfulMax,
		size = size,
		showCount = true,
		tooltipAnchor = "ANCHOR_TOPLEFT",
		layout = {
			elementSpacing = spacing,
			lineSpacing = spacing,
			groupSpacing = size + spacing,
		},
	})

	local harmfulGroup = Auras:AddGroup("HARMFUL", {
		maxFrameCount = harmfulMax,
		size = size,
		showCount = true,
		showDebuffTypeShadow = true,
		tooltipAnchor = "ANCHOR_TOPLEFT",
		layout = {
			elementSpacing = spacing,
			lineSpacing = spacing,
			groupSpacing = size + spacing,
		},
	})

	self.Auras = Auras
	self.AuraPolarity = {
		container = Auras,
		helpfulGroup = helpfulGroup,
		harmfulGroup = harmfulGroup,
		friendlyHelpfulMax = helpfulMax,
		friendlyHarmfulMax = harmfulMax,
		hostileHelpfulMax = 4,
		hostileHarmfulMax = C.MaxAura,
	}
	return Auras
end

-- 簡易焦點光環
T.CreateSimpleFocusAuras = function(self)
	local size = C.AuraSize - 4
	local spacing = 5
	local groupSpacing = spacing
	local maxFrameCount = 2
	local totalFrameCount = maxFrameCount * 2
	local layoutLimit = size * totalFrameCount + spacing * (totalFrameCount - 1) + groupSpacing

	local Auras = self:CreateAuras({
		layout = HORIZONTAL,
		layoutLimit = layoutLimit,
		initialAnchor = "BOTTOMLEFT",
		growthX = "RIGHT",
		growthY = "UP",
	})
	Auras:SetFrameLevel(self:GetFrameLevel() + 4)
	Auras:SetPoint("BOTTOM", self, "TOP", 4, 4)
	Auras.PostCreateButton = PostCreateAuraButton
	Auras.showDuration = true
	Auras.disableCooldown = true
	Auras.durationFormatter = UF_AURA_DURATION

	Auras:AddGroup("HELPFUL|IMPORTANT|INCLUDE_NAME_PLATE_ONLY", {
		maxFrameCount = maxFrameCount,
		size = size,
		showCount = true,
		tooltipAnchor = "ANCHOR_TOPRIGHT",
		layout = {
			elementSpacing = spacing,
			lineSpacing = spacing,
			groupSpacing = groupSpacing,
		},
	})

	Auras:AddGroup("HARMFUL|CROWD_CONTROL|INCLUDE_NAME_PLATE_ONLY", {
		maxFrameCount = maxFrameCount,
		size = size,
		showCount = true,
		showDebuffTypeShadow = true,
		tooltipAnchor = "ANCHOR_TOPRIGHT",
		layout = {
			elementSpacing = spacing,
			lineSpacing = spacing,
			groupSpacing = groupSpacing,
		},
	})

	self.Auras = Auras
	return Auras
end

-- 寵物橫式減益
T.CreatePetDebuffs = function(self)
	local Debuffs = self:CreateAuras({
		layout = HORIZONTAL,
		layoutLimit = C.TOTWidth,
		initialAnchor = "LEFT",
		growthX = "RIGHT",
		growthY = "UP",
	})
	Debuffs:SetFrameLevel(self:GetFrameLevel() + 4)
	Debuffs:SetPoint("LEFT", self.Health, "RIGHT", C.PPOffset + 1, -2)
	Debuffs.PostCreateButton = PostCreateAuraButton
	Debuffs.showDuration = true
	Debuffs.disableCooldown = true
	Debuffs.durationFormatter = UF_AURA_DURATION

	Debuffs:AddGroup("HARMFUL", {
		maxFrameCount = 2,
		size = C.AuraSize,
		showCount = true,
		showDebuffTypeShadow = true,
		layout = {
			elementSpacing = 5,
			lineSpacing = 5,
		},
	})

	self.Debuffs = Debuffs
	return Debuffs
end

-- 寵物直式減益
T.CreateVPetDebuffs = function(self)
	local Debuffs = self:CreateAuras({
		layout = VERTICAL,
		layoutLimit = C.TOTWidth,
		initialAnchor = "TOP",
		growthX = "RIGHT",
		growthY = "DOWN",
	})
	Debuffs:SetFrameLevel(self:GetFrameLevel() + 4)
	Debuffs:SetPoint("TOPRIGHT", self.Power, "TOPLEFT", -C.PPOffset - 1, -2)
	Debuffs.PostCreateButton = PostCreateAuraButton
	Debuffs.showDuration = true
	Debuffs.disableCooldown = true
	Debuffs.durationFormatter = UF_AURA_DURATION

	Debuffs:AddGroup("HARMFUL", {
		maxFrameCount = 2,
		size = C.AuraSize,
		showCount = true,
		showDebuffTypeShadow = true,
		tooltipAnchor = "ANCHOR_TOPLEFT",
		layout = {
			elementSpacing = 5,
			lineSpacing = 5,
		},
	})

	self.Debuffs = Debuffs
	return Debuffs
end

-- 目標的目標橫式光環
T.CreateToTAuras = function(self)
	local size = C.AuraSize
	local spacing = 5
	local maxFrameCount = 2

	local Auras = self:CreateAuras({
		layout = HORIZONTAL,
		layoutLimit = size * maxFrameCount + spacing * (maxFrameCount - 1),
		initialAnchor = "RIGHT",
		growthX = "LEFT",
		growthY = "UP",
	})
	Auras:SetFrameLevel(self:GetFrameLevel() + 4)
	Auras:SetPoint("RIGHT", self.Health, "LEFT", -C.PPOffset - 1, -2)
	Auras.PostCreateButton = PostCreateAuraButton
	Auras.showDuration = true
	Auras.disableCooldown = true
	Auras.durationFormatter = UF_AURA_DURATION

	local helpfulGroup = Auras:AddGroup("HELPFUL", {
		maxFrameCount = 0,
		size = size,
		showCount = true,
		layout = {
			elementSpacing = spacing,
			lineSpacing = spacing,
		},
	})

	local harmfulGroup = Auras:AddGroup("HARMFUL", {
		maxFrameCount = 0,
		size = size,
		showCount = true,
		showDebuffTypeShadow = true,
		tooltipAnchor = "ANCHOR_BOTTOMRIGHT",
		layout = {
			elementSpacing = spacing,
			lineSpacing = spacing,
		},
	})

	self.Auras = Auras
	self.AuraPolarity = {
		container = Auras,
		helpfulGroup = helpfulGroup,
		harmfulGroup = harmfulGroup,
		friendlyHelpfulMax = 0,
		friendlyHarmfulMax = maxFrameCount,
		hostileHelpfulMax = maxFrameCount,
		hostileHarmfulMax = 0,
	}
	return Auras
end

-- 目標的目標直式光環
T.CreateVToTAuras = function(self)
	local size = C.AuraSize
	local spacing = 5
	local maxFrameCount = 2

	local Auras = self:CreateAuras({
		layout = VERTICAL,
		layoutLimit = C.TOTWidth,
		initialAnchor = "TOP",
		growthX = "RIGHT",
		growthY = "DOWN",
	})
	Auras:SetFrameLevel(self:GetFrameLevel() + 4)
	Auras:SetPoint("TOPLEFT", self.Power, "TOPRIGHT", C.PPOffset + 1, -2)
	Auras.PostCreateButton = PostCreateAuraButton
	Auras.showDuration = true
	Auras.disableCooldown = true
	Auras.durationFormatter = UF_AURA_DURATION

	local helpfulGroup = Auras:AddGroup("HELPFUL", {
		maxFrameCount = 0,
		size = size,
		showCount = true,
		layout = {
			elementSpacing = spacing,
			lineSpacing = spacing,
		},
	})

	local harmfulGroup = Auras:AddGroup("HARMFUL", {
		maxFrameCount = 0,
		size = size,
		showCount = true,
		showDebuffTypeShadow = true,
		tooltipAnchor = "ANCHOR_TOPRIGHT",
		layout = {
			elementSpacing = spacing,
			lineSpacing = spacing,
		},
	})

	self.Auras = Auras
	self.AuraPolarity = {
		container = Auras,
		helpfulGroup = helpfulGroup,
		harmfulGroup = harmfulGroup,
		friendlyHelpfulMax = 0,
		friendlyHarmfulMax = maxFrameCount,
		hostileHelpfulMax = maxFrameCount,
		hostileHarmfulMax = 0,
	}
	return Auras
end

-- 焦點目標光環
T.CreateFoTAuras = function(self)
	local size = C.AuraSize
	local spacing = 5
	local maxFrameCount = 2
	local showAboveTarget = F.GetRuriOption("vertTarget")
	local initialAnchor = showAboveTarget and "BOTTOMLEFT" or "BOTTOMRIGHT"
	local growthX = showAboveTarget and "RIGHT" or "LEFT"

	local Auras = self:CreateAuras({
		layout = HORIZONTAL,
		layoutLimit = size * maxFrameCount + spacing * (maxFrameCount - 1),
		initialAnchor = initialAnchor,
		growthX = growthX,
		growthY = "UP",
	})
	Auras:SetFrameLevel(self:GetFrameLevel() + 4)
	if showAboveTarget then
		Auras:SetPoint("BOTTOMLEFT", self.Health, "TOPLEFT", 1, C.PPOffset * 2 + C.PPHeight)
	else
		Auras:SetPoint("RIGHT", self.Health, "LEFT", -C.PPOffset - 1, 0)
	end
	Auras.PostCreateButton = PostCreateAuraButton
	Auras.showDuration = true
	Auras.disableCooldown = true
	Auras.durationFormatter = UF_AURA_DURATION

	local helpfulGroup = Auras:AddGroup("HELPFUL", {
		maxFrameCount = 0,
		size = size,
		showCount = true,
		layout = {
			elementSpacing = spacing,
			lineSpacing = spacing,
		},
	})

	local harmfulGroup = Auras:AddGroup("HARMFUL", {
		maxFrameCount = 0,
		size = size,
		showCount = true,
		showDebuffTypeShadow = true,
		tooltipAnchor = "ANCHOR_BOTTOMRIGHT",
		layout = {
			elementSpacing = spacing,
			lineSpacing = spacing,
		},
	})

	self.Auras = Auras
	self.AuraPolarity = {
		container = Auras,
		helpfulGroup = helpfulGroup,
		harmfulGroup = harmfulGroup,
		friendlyHelpfulMax = 0,
		friendlyHarmfulMax = maxFrameCount,
		hostileHelpfulMax = maxFrameCount,
		hostileHarmfulMax = 0,
	}
	return Auras
end

-- 簡易焦點目標光環
T.CreateSimpleFoTAuras = function(self)
	local size = C.AuraSize - 6
	local spacing = 5
	local maxFrameCount = 2
	local layoutLimit = size * maxFrameCount + spacing * (maxFrameCount - 1)

	local Auras = self:CreateAuras({
		layout = HORIZONTAL,
		layoutLimit = layoutLimit,
		initialAnchor = "RIGHT",
		growthX = "LEFT",
		growthY = "UP",
	})
	Auras:SetFrameLevel(self:GetFrameLevel() + 4)
	Auras:SetPoint("RIGHT", self, "LEFT", -C.PPOffset, -3)
	Auras.PostCreateButton = PostCreateAuraButton
	Auras.showDuration = true
	Auras.disableCooldown = true
	Auras.durationFormatter = UF_AURA_DURATION

	local helpfulGroup = Auras:AddGroup("HELPFUL", {
		maxFrameCount = 0,
		size = size,
		showCount = true,
		layout = {
			elementSpacing = spacing,
			lineSpacing = spacing,
		},
	})

	local harmfulGroup = Auras:AddGroup("HARMFUL", {
		maxFrameCount = 0,
		size = size,
		showCount = true,
		showDebuffTypeShadow = true,
		tooltipAnchor = "ANCHOR_TOPRIGHT",
		layout = {
			elementSpacing = spacing,
			lineSpacing = spacing,
		},
	})

	self.Auras = Auras
	self.AuraPolarity = {
		container = Auras,
		helpfulGroup = helpfulGroup,
		harmfulGroup = harmfulGroup,
		friendlyHelpfulMax = 0,
		friendlyHarmfulMax = maxFrameCount,
		hostileHelpfulMax = maxFrameCount,
		hostileHarmfulMax = 0,
	}
	return Auras
end

-- 首領光環
T.CreateBossAuras = function(self)
	local Debuffs = self:CreateAuras({
		layout = HORIZONTAL,
		layoutLimit = C.BWidth,
		initialAnchor = "LEFT",
		growthX = "RIGHT",
		growthY = "UP",
	})
	Debuffs:SetFrameLevel(self:GetFrameLevel() + 4)
	Debuffs:SetPoint("BOTTOMLEFT", self.Health, "TOPLEFT", 1, C.PPOffset * 2 + C.PPHeight)
	Debuffs.PostCreateButton = PostCreateAuraButton
	Debuffs.showDuration = true
	Debuffs.disableCooldown = true
	Debuffs.durationFormatter = UF_AURA_DURATION

	Debuffs:AddGroup("HARMFUL|PLAYER", {
		maxFrameCount = 3,
		size = C.AuraSize,
		showCount = true,
		showDebuffTypeShadow = true,
		layout = {
			elementSpacing = 5,
			lineSpacing = 5,
		},
	})

	local Buffs = self:CreateAuras({
		layout = HORIZONTAL,
		layoutLimit = C.PWidth,
		initialAnchor = "RIGHT",
		growthX = "LEFT",
		growthY = "UP",
	})
	Buffs:SetFrameLevel(self:GetFrameLevel() + 4)
	Buffs:SetPoint("BOTTOMRIGHT", self.Health, "TOPRIGHT", -1, C.PPOffset * 2 + C.PPHeight)
	Buffs.PostCreateButton = PostCreateAuraButton
	Buffs.showDuration = true
	Buffs.disableCooldown = true
	Buffs.durationFormatter = UF_AURA_DURATION

	Buffs:AddGroup("HELPFUL", {
		maxFrameCount = 2,
		size = C.AuraSize,
		showCount = true,
		layout = {
			elementSpacing = 5,
			lineSpacing = 5,
		},
	})

	self.Debuffs = Debuffs
	self.Buffs = Buffs
	return Debuffs, Buffs
end

-- 競技場光環
T.CreateArenaAuras = function(self)
	local Debuffs = self:CreateAuras({
		layout = HORIZONTAL,
		layoutLimit = C.BWidth,
		initialAnchor = "LEFT",
		growthX = "RIGHT",
		growthY = "UP",
	})
	Debuffs:SetFrameLevel(self:GetFrameLevel() + 4)
	Debuffs:SetPoint("BOTTOMLEFT", self.Health, "TOPLEFT", 1, C.PHeight / 2 + C.PPOffset)
	Debuffs.PostCreateButton = PostCreateAuraButton
	Debuffs.showDuration = true
	Debuffs.disableCooldown = true
	Debuffs.durationFormatter = UF_AURA_DURATION

	Debuffs:AddGroup("HARMFUL", {
		maxFrameCount = 4,
		size = C.AuraSize,
		showCount = true,
		showDebuffTypeShadow = true,
		layout = {
			elementSpacing = 5,
			lineSpacing = 5,
		},
	})

	local Buffs = self:CreateAuras({
		layout = HORIZONTAL,
		layoutLimit = C.PWidth,
		initialAnchor = "RIGHT",
		growthX = "LEFT",
		growthY = "UP",
	})
	Buffs:SetFrameLevel(self:GetFrameLevel() + 4)
	Buffs:SetPoint("BOTTOMRIGHT", self.Health, "TOPRIGHT", -1, C.PHeight / 2 + C.PPOffset)
	Buffs.PostCreateButton = PostCreateAuraButton
	Buffs.showDuration = true
	Buffs.disableCooldown = true
	Buffs.durationFormatter = UF_AURA_DURATION

	Buffs:AddGroup("HELPFUL", {
		maxFrameCount = 1,
		size = C.AuraSize,
		showCount = true,
		layout = {
			elementSpacing = 5,
			lineSpacing = 5,
		},
	})

	self.Debuffs = Debuffs
	self.Buffs = Buffs
	return Debuffs, Buffs
end

-- 團隊與小隊減益
T.CreateRaidDebuffs = function(self)
	local spacing = 4

	local Debuffs = self:CreateAuras({
		layout = HORIZONTAL,
		layoutLimit = C.RaidAuraSize * 4 + spacing * 6,
		initialAnchor = "BOTTOMLEFT",
		growthX = "RIGHT",
		growthY = "UP",
	})
	Debuffs:SetAuraProcessingPolicy(CustomAuraContainerAuraProcessingPolicy.ProcessAura, {
		ignoreBuffs = true,
	})
	Debuffs:SetFrameLevel(self:GetFrameLevel() + 4)
	Debuffs:SetPoint("BOTTOMLEFT", self, 4, 6)
	Debuffs.PostCreateButton = PostCreateAuraButton
	Debuffs.showDuration = true
	Debuffs.disableCooldown = true
	Debuffs.durationFormatter = RAID_AURA_DURATION

	Debuffs:AddGroup("HARMFUL", {
		maxFrameCount = 4,
		sortMethod = AuraContainerSortMethod.UnitFrameDebuff,
		size = C.RaidAuraSize,
		showCount = true,
		showDebuffTypeShadow = true,
		disableMouse = true,
		tooltipAnchor = "ANCHOR_TOPLEFT",
		candidateFilters = {
			processedAuraType = AuraUtil.AuraUpdateChangedType.Debuff,
		},
		layout = {
			elementSpacing = spacing,
			lineSpacing = spacing,
		},
	})

	self.Debuffs = Debuffs
	return Debuffs
end

-- 名條光環
T.CreateNameplateAuras = function(self)
	local size = C.NPAuraSize
	local spacing = 5
	local layoutLimit = size * C.NPMaxAura + spacing * (C.NPMaxAura - 1)
	local helpfulMax = math.min(2, C.NPMaxAura)
	local harmfulMax = math.max(C.NPMaxAura - helpfulMax, 0)

	local Auras = self:CreateAuras({
		layout = HORIZONTAL,
		layoutLimit = layoutLimit,
		initialAnchor = "BOTTOMLEFT",
		growthX = "RIGHT",
		growthY = "UP",
	})
	Auras:SetFrameLevel(self:GetFrameLevel() + 4)
	Auras.PostCreateButton = PostCreateAuraButton
	Auras.showDuration = true
	Auras.disableCooldown = true
	Auras.durationFormatter = RAID_AURA_DURATION

	Auras:AddGroup("HELPFUL|DISPELLABLE|INCLUDE_NAME_PLATE_ONLY", {
		maxFrameCount = helpfulMax,
		size = size,
		showCount = true,
		disableMouse = true,
		tooltipAnchor = "ANCHOR_TOPLEFT",
		layout = {
			elementSpacing = spacing,
			lineSpacing = spacing,
			groupSpacing = spacing,
		},
	})

	Auras:AddGroup("HARMFUL|PLAYER|INCLUDE_NAME_PLATE_ONLY", {
		maxFrameCount = harmfulMax,
		size = size,
		showCount = true,
		showDebuffTypeShadow = true,
		disableMouse = true,
		tooltipAnchor = "ANCHOR_TOPLEFT",
		layout = {
			elementSpacing = spacing,
			lineSpacing = spacing,
			groupSpacing = spacing,
		},
	})

	self.Auras = Auras
	return Auras
end
