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
-- 12.1.5 由 AuraContainerUtil.CanApplyIdentityCandidateFilters 判定是否允許按 spellID 篩選。
-- 不允許時，includeSpellIDs 直接拒絕該光環；excludeSpellIDs 則略過 ID 排除，繼續其他條件。
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

--=================================================--
-----------------    [[ Rules ]]    -----------------
--=================================================--

-- 下列清單按框體類型分區；陣列順序為 Group 顯示順序，maxFrameCount 是各組上限，不是容器總上限。

-- ToT/FoT：由 AuraPolarity 在同一組切換敵方增益與友方減益。
local SUB_HOSTILE = {filter = "HELPFUL", candidateFilters = {isBossOrRoleAura = true,},}
local SUB_FRIENDLY = {filter = "HARMFUL",candidateFilters = {isPriorityAura = true,},}

-- 首領增益
local BOSS_BUFF_GROUPS = {
	{ -- 首領與職責增益
		filter = "HELPFUL",
		candidateFilters = {
			isBossOrRoleAura = true,
		},
		maxFrameCount = 2,
	},
	{ -- 其餘可驅散增益
		filter = "HELPFUL|DISPELLABLE",
		candidateFilters = {
			isBossOrRoleAura = false,
		},
		maxFrameCount = 2,
	},
}

-- 首領減益
local BOSS_DEBUFF_GROUPS = {
	{ -- 玩家與寵物施放、由暴雪標記為個人名條追蹤的減益
		filter = "HARMFUL|PLAYER|INCLUDE_NAME_PLATE_ONLY",
		candidateFilters = {
			nameplateShowPersonal = true,
		},
		maxFrameCount = 4,
	},
	{ -- 由暴雪標記為所有人可見的其餘名條減益
		filter = "HARMFUL|INCLUDE_NAME_PLATE_ONLY",
		candidateFilters = {
			nameplateShowAll = true,
			nameplateShowPersonal = false,
		},
		maxFrameCount = 2,
	},
}

-- 競技場增益
local ARENA_BUFF_GROUPS = {
	{ -- 減傷
		filter = "HELPFUL|BIG_DEFENSIVE|!EXTERNAL_DEFENSIVE",
		maxFrameCount = 2,
	},
	{ -- 外部減傷
		filter = "HELPFUL|EXTERNAL_DEFENSIVE",
		maxFrameCount = 2,
	},
	{ -- 可驅散
		filter = "HELPFUL|RAID_PLAYER_DISPELLABLE|!BIG_DEFENSIVE|!EXTERNAL_DEFENSIVE",
		maxFrameCount = 2,
	},
}

-- 競技場減益
local ARENA_DEBUFF_GROUPS = {
	{ -- 玩家與寵物施放、由暴雪標記為個人名條追蹤的減益
		filter = "HARMFUL|PLAYER|INCLUDE_NAME_PLATE_ONLY|!CROWD_CONTROL",
		candidateFilters = {
			nameplateShowPersonal = true,
		},
		maxFrameCount = 4,
	},
	{ -- 由暴雪標記為所有人可見的其餘名條減益
		filter = "HARMFUL|INCLUDE_NAME_PLATE_ONLY|!CROWD_CONTROL",
		candidateFilters = {
			nameplateShowAll = true,
			nameplateShowPersonal = false,
		},
		maxFrameCount = 4,
	},
	{ -- 控場減益
		filter = "HARMFUL|CROWD_CONTROL",
		maxFrameCount = 2,
	},
}

-- 團隊小隊增益：共用法術白名單。
local RAID_BUFF_GROUP = {
	filter = "HELPFUL",
	candidateFilters = {
		includeSpellIDs = C.RaidWhiteList,
	},
	maxFrameCount = 4,
}

-- 團隊小隊減益：原生團框分類+黑名單。
local RAID_DEBUFF_GROUP = {
	filter = "HARMFUL",
	candidateFilters = {
		excludeSpellIDs = C.RaidBlackList,
	},
	maxFrameCount = 6,
}

-- 名條光環組合
local NAMEPLATE_AURA_GROUPS = {
	{ -- 重要
		filter = "HELPFUL|IMPORTANT|INCLUDE_NAME_PLATE_ONLY",
		maxFrameCount = 2,
	},
	{ -- 可驅散
		filter = "HELPFUL|DISPELLABLE|!IMPORTANT|INCLUDE_NAME_PLATE_ONLY",
		maxFrameCount = 2,
	},
	{ -- 玩家與寵物施放、由暴雪標記為個人名條追蹤的減益
		filter = "HARMFUL|PLAYER|INCLUDE_NAME_PLATE_ONLY|!CROWD_CONTROL",
		candidateFilters = {
			nameplateShowPersonal = true,
		},
		maxFrameCount = 4,
	},
	{ -- 由暴雪標記為所有人可見的其餘名條減益
		filter = "HARMFUL|INCLUDE_NAME_PLATE_ONLY|!CROWD_CONTROL",
		candidateFilters = {
			nameplateShowAll = true,
			nameplateShowPersonal = false,
		},
		maxFrameCount = 4,
	},
	{ -- 控場減益
		filter = "HARMFUL|CROWD_CONTROL",
		candidateFilters = {
			excludeSpellIDs = {
				[1280457] = true,
			},
		},
		maxFrameCount = 2,
	},
}

-- 光環時間格式
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

--===================================================--
-----------------    [[ General ]]    -----------------
--===================================================--

-- 設定光環外觀
local function PostCreateAuraButton(element, button, options)
	button.Icon:SetTexCoord(.08, .92, .08, .92)

	-- 1px 邊框
	local border = button:CreateTexture(nil, "BACKGROUND", nil, -1)
	border:SetPoint("TOPLEFT", button, -1, 1)
	border:SetPoint("BOTTOMRIGHT", button, 1, -1)
	border:SetColorTexture(1, 1, 1, 1)
	border:SetVertexColor(.1, .1, .1, 1)

	-- 陰影
	local shadow = button:CreateTexture(nil, "BACKGROUND", nil, -2)
	shadow:SetPoint("TOPLEFT", button, -4, 4)
	shadow:SetPoint("BOTTOMRIGHT", button, 4, -4)
	shadow:SetTexture(G.media.aurashadow)
	shadow:SetVertexColor(0, 0, 0, 1)

	local showBuffTypeBorder = (options.showBuffTypeBorder == true)
	local showDebuffTypeBorder = (options.showDebuffTypeBorder == true)
	if showBuffTypeBorder or showDebuffTypeBorder then
		local dispelBorder = border
		if options.preserveDefaultBorder == true then
			-- 動態敵友 Group 在顯示增益時仍需要普通灰框。
			dispelBorder = button:CreateTexture(nil, "BACKGROUND", nil, 0)
			dispelBorder:SetPoint("TOPLEFT", button, -1, 1)
			dispelBorder:SetPoint("BOTTOMRIGHT", button, 1, -1)
			dispelBorder:SetColorTexture(1, 1, 1, 1)
		else
			border:SetVertexColor(1, 1, 1, 1)
		end

		local dispelOptions = {
			showWhenHarmful = showDebuffTypeBorder,
			showWhenHelpful = showBuffTypeBorder,
			showWithoutDispelType = true,	-- 無驅散類型的光環也顯示
			style = Enum.CustomAuraButtonDispelTypeTextureStyle.PreserveAsset,	-- 保留自定義材質，不被原生邊框材質取代
			customDispelColorMap = element.dispelColors or element.__owner.colors.dispel,	-- 預熱容器尚無 owner，使用同一份公開色表
		}
		button:AddDispelTypeTexture(dispelBorder, dispelOptions)
	end

	button.Count:SetFont(G.NFont, G.NumberFS, G.FontFlag)
	button.Count:ClearAllPoints()
	button.Count:SetPoint("BOTTOMRIGHT", button, 0, -2)
	button.Count:SetTextColor(.9, .9, .1)

	button.Time:SetFont(G.NFont, G.NumberFS, G.FontFlag)
	button.Time:ClearAllPoints()
	button.Time:SetPoint("TOP", button, 0, 3)
end

--====================================================--
-----------------    [[ Polarity ]]    -----------------
--====================================================--

-- ToT/FoT 依敵我關係切換規則
local function UpdateAuraPolarity(self, _, unit)
	if unit and unit ~= self.__unit then return end

	local relation = self.AuraPolarity
	
	-- 敵友判定
	local hostile = UnitCanAttack("player", self.__unit)
	if relation.isHostile == hostile then return end

	-- 切換過濾條件
	relation.isHostile = hostile
	local rule = hostile and SUB_HOSTILE or SUB_FRIENDLY
	relation.container:SetAuraGroupFilterString(
		relation.filterGroup,
		rule.filter
	)
	relation.container:SetAuraGroupCandidateFilters(
		relation.filterGroup,
		rule.candidateFilters
	)
end

local function EnableAuraPolarity(self)
	if self.AuraPolarity then
		self:RegisterEvent("UNIT_FACTION", UpdateAuraPolarity)
		UpdateAuraPolarity(self)
		return true
	end
end

local function DisableAuraPolarity(self)
	self:UnregisterEvent("UNIT_FACTION", UpdateAuraPolarity)
	self.AuraPolarity.isHostile = nil
end

oUF:AddElement("AuraPolarity", UpdateAuraPolarity, EnableAuraPolarity, DisableAuraPolarity)

--======================================================--
-----------------    [[ Unitframes ]]    -----------------
--======================================================--

-- 玩家減益
T.CreatePlayerDebuffs = function(self)
	local Debuffs = self:CreateAuras({
		layout = self.mystyle == "VL" and VERTICAL or HORIZONTAL,
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
		showDebuffTypeBorder = true,
		layout = {
			elementSpacing = 5,
			lineSpacing = 5,
		},
	})

	self.Debuffs = Debuffs
	T.UpdatePlayerDebuffsPosition(Debuffs)

	return Debuffs
end

-- 目標與完整焦點光環
T.CreateTargetFocusAuras = function(self)
	local vertical = (self.mystyle == "VR")
	local size = C.AuraSize
	local spacing = 6
	local lineSpacing = spacing
	local layoutLimit = vertical and self:GetHeight() or self:GetWidth()
	local tooltipAnchor = vertical and "ANCHOR_BOTTOMLEFT" or "ANCHOR_TOPLEFT"

	local Auras = self:CreateAuras({
		layout = vertical and VERTICAL or HORIZONTAL,
		layoutLimit = layoutLimit,
		initialAnchor = vertical and "BOTTOMRIGHT" or "BOTTOMLEFT",
		growthX = vertical and "LEFT" or "RIGHT",
		growthY = "UP",
	})
	Auras:SetFrameLevel(self:GetFrameLevel() + 4)
	if vertical then
		Auras:SetPoint("BOTTOMRIGHT", self.Health, "BOTTOMLEFT", -C.PPOffset - 1, 1)
	else
		Auras:SetPoint("BOTTOMLEFT", self.Health, "TOPLEFT", 1, C.PPOffset * 2 + C.PPHeight)
	end
	Auras.PostCreateButton = PostCreateAuraButton
	Auras.showDuration = true
	Auras.disableCooldown = true
	Auras.durationFormatter = UF_AURA_DURATION

	Auras:AddGroup("HELPFUL", {
		maxFrameCount = C.MaxBuffs,
		size = size,
		showCount = true,
		tooltipAnchor = tooltipAnchor,
		layout = {
			elementSpacing = spacing,
			lineSpacing = lineSpacing,
			groupSpacing = size + spacing,
		},
	})

	Auras:AddGroup("HARMFUL", {
		maxFrameCount = C.MaxDebuffs,
		size = size,
		showCount = true,
		showDebuffTypeBorder = true,
		tooltipAnchor = tooltipAnchor,
		layout = {
			elementSpacing = spacing,
			lineSpacing = lineSpacing,
			groupSpacing = size + spacing,
			groupLineSpacing = lineSpacing,
		},
	})

	self.Auras = Auras
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
		showDebuffTypeBorder = true,
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
		showDebuffTypeBorder = true,
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
		showDebuffTypeBorder = true,
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

	local filterGroup = Auras:AddGroup(SUB_FRIENDLY.filter, {
		candidateFilters = SUB_FRIENDLY.candidateFilters,
		maxFrameCount = maxFrameCount,
		size = size,
		showCount = true,
		showDebuffTypeBorder = true,
		preserveDefaultBorder = true,
		tooltipAnchor = "ANCHOR_BOTTOMRIGHT",
		layout = {
			elementSpacing = spacing,
			lineSpacing = spacing,
		},
	})

	self.Auras = Auras
	self.AuraPolarity = {
		container = Auras,
		filterGroup = filterGroup,
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

	local filterGroup = Auras:AddGroup(SUB_FRIENDLY.filter, {
		candidateFilters = SUB_FRIENDLY.candidateFilters,
		maxFrameCount = maxFrameCount,
		size = size,
		showCount = true,
		showDebuffTypeBorder = true,
		preserveDefaultBorder = true,
		tooltipAnchor = "ANCHOR_TOPRIGHT",
		layout = {
			elementSpacing = spacing,
			lineSpacing = spacing,
		},
	})

	self.Auras = Auras
	self.AuraPolarity = {
		container = Auras,
		filterGroup = filterGroup,
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

	local filterGroup = Auras:AddGroup(SUB_FRIENDLY.filter, {
		candidateFilters = SUB_FRIENDLY.candidateFilters,
		maxFrameCount = maxFrameCount,
		size = size,
		showCount = true,
		showDebuffTypeBorder = true,
		preserveDefaultBorder = true,
		tooltipAnchor = "ANCHOR_BOTTOMRIGHT",
		layout = {
			elementSpacing = spacing,
			lineSpacing = spacing,
		},
	})

	self.Auras = Auras
	self.AuraPolarity = {
		container = Auras,
		filterGroup = filterGroup,
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

	local filterGroup = Auras:AddGroup(SUB_FRIENDLY.filter, {
		candidateFilters = SUB_FRIENDLY.candidateFilters,
		maxFrameCount = maxFrameCount,
		size = size,
		showCount = true,
		showDebuffTypeBorder = true,
		preserveDefaultBorder = true,
		tooltipAnchor = "ANCHOR_TOPRIGHT",
		layout = {
			elementSpacing = spacing,
			lineSpacing = spacing,
		},
	})

	self.Auras = Auras
	self.AuraPolarity = {
		container = Auras,
		filterGroup = filterGroup,
	}
	return Auras
end

-- 首領光環
T.CreateBossAuras = function(self)
	local spacing = 5

	local Debuffs = self:CreateAuras({
		layout = HORIZONTAL,
		layoutLimit = C.BWidth,
		initialAnchor = "LEFT",
		growthX = "RIGHT",
		growthY = "UP",
	})
	Debuffs:SetFrameLevel(self:GetFrameLevel() + 4)
	Debuffs:SetPoint("BOTTOMLEFT", self.Health, "TOPLEFT", 1, G.NameFS / 2 + C.PPHeight + 5)
	Debuffs.PostCreateButton = PostCreateAuraButton
	Debuffs.showDuration = true
	Debuffs.disableCooldown = true
	Debuffs.durationFormatter = UF_AURA_DURATION

	for layoutIndex, group in ipairs(BOSS_DEBUFF_GROUPS) do
		Debuffs:AddGroup(group.filter, {
			candidateFilters = group.candidateFilters,
			maxFrameCount = group.maxFrameCount,
			sortMethod = AuraContainerSortMethod.Default,
			size = C.AuraSize,
			showCount = true,
			showDebuffTypeBorder = true,
			layout = {
				elementSpacing = spacing,
				lineSpacing = spacing,
				layoutIndex = layoutIndex,
			},
		})
	end

	local Buffs = self:CreateAuras({
		layout = HORIZONTAL,
		layoutLimit = C.BWidth,
		initialAnchor = "RIGHT",
		growthX = "LEFT",
		growthY = "UP",
	})
	Buffs:SetFrameLevel(self:GetFrameLevel() + 4)
	Buffs:SetPoint("BOTTOMRIGHT", self.Health, "TOPRIGHT", -1, G.NameFS / 2 + C.PPHeight + 5)
	Buffs.PostCreateButton = PostCreateAuraButton
	Buffs.showDuration = true
	Buffs.disableCooldown = true
	Buffs.durationFormatter = UF_AURA_DURATION

	for layoutIndex, group in ipairs(BOSS_BUFF_GROUPS) do
		Buffs:AddGroup(group.filter, {
			candidateFilters = group.candidateFilters,
			maxFrameCount = group.maxFrameCount,
			sortMethod = AuraContainerSortMethod.Default,
			size = C.AuraSize,
			showCount = true,
			layout = {
				elementSpacing = spacing,
				lineSpacing = spacing,
				layoutIndex = layoutIndex,
			},
		})
	end

	self.Debuffs = Debuffs
	self.Buffs = Buffs
	return Debuffs, Buffs
end

-- 競技場光環
T.CreateArenaAuras = function(self)
	local spacing = 5

	local Debuffs = self:CreateAuras({
		layout = HORIZONTAL,
		layoutLimit = C.BWidth,
		initialAnchor = "LEFT",
		growthX = "RIGHT",
		growthY = "UP",
	})
	Debuffs:SetFrameLevel(self:GetFrameLevel() + 4)
	Debuffs:SetPoint("BOTTOMLEFT", self.Health, "TOPLEFT", 1, G.NameFS / 2 + C.PPHeight + 5)
	Debuffs.PostCreateButton = PostCreateAuraButton
	Debuffs.showDuration = true
	Debuffs.disableCooldown = true
	Debuffs.durationFormatter = UF_AURA_DURATION

	for layoutIndex, group in ipairs(ARENA_DEBUFF_GROUPS) do
		Debuffs:AddGroup(group.filter, {
			candidateFilters = group.candidateFilters,
			maxFrameCount = group.maxFrameCount,
			sortMethod = AuraContainerSortMethod.Default,
			size = C.AuraSize,
			showCount = true,
			showDebuffTypeBorder = true,
			layout = {
				elementSpacing = spacing,
				lineSpacing = spacing,
				layoutIndex = layoutIndex,
			},
		})
	end

	local Buffs = self:CreateAuras({
		layout = HORIZONTAL,
		layoutLimit = C.BWidth,
		initialAnchor = "RIGHT",
		growthX = "LEFT",
		growthY = "UP",
	})
	Buffs:SetFrameLevel(self:GetFrameLevel() + 4)
	Buffs:SetPoint("BOTTOMRIGHT", self.Health, "TOPRIGHT", -1, G.NameFS / 2 + C.PPHeight + 5)
	Buffs.PostCreateButton = PostCreateAuraButton
	Buffs.showDuration = true
	Buffs.disableCooldown = true
	Buffs.durationFormatter = UF_AURA_DURATION

	for layoutIndex, group in ipairs(ARENA_BUFF_GROUPS) do
		Buffs:AddGroup(group.filter, {
			maxFrameCount = group.maxFrameCount,
			sortMethod = AuraContainerSortMethod.Default,
			size = C.AuraSize,
			showCount = true,
			layout = {
				elementSpacing = spacing,
				lineSpacing = spacing,
				layoutIndex = layoutIndex,
			},
		})
	end

	self.Debuffs = Debuffs
	self.Buffs = Buffs
	return Debuffs, Buffs
end

--======================================================--
-----------------    [[ Raidframes ]]    -----------------
--======================================================--

-- 團隊與小隊減益
T.CreateRaidDebuffs = function(self)
	local spacing = 4
	local iconsPerLine = 3

	local Debuffs = self:CreateAuras({
		layout = HORIZONTAL,
		layoutLimit = (C.RaidAuraSize + 2) * iconsPerLine + spacing * (iconsPerLine - 1),
		initialAnchor = "BOTTOMLEFT",
		growthX = "RIGHT",
		growthY = "UP",
		policy = {ignoreBuffs = true},
	})
	Debuffs:SetFrameLevel(self.StringParent:GetFrameLevel() + 1)
	Debuffs:SetPoint("BOTTOMLEFT", self, 4, 6)
	Debuffs.PostCreateButton = PostCreateAuraButton
	Debuffs.showDuration = true
	Debuffs.disableCooldown = true
	Debuffs.durationFormatter = RAID_AURA_DURATION

	Debuffs:AddGroup(RAID_DEBUFF_GROUP.filter, {
		candidateFilters = RAID_DEBUFF_GROUP.candidateFilters,
		maxFrameCount = RAID_DEBUFF_GROUP.maxFrameCount,
		sortMethod = AuraContainerSortMethod.UnitFrameDebuff,
		size = C.RaidAuraSize,
		showCount = true,
		showDebuffTypeBorder = true,
		disableMouse = true,
		tooltipAnchor = "ANCHOR_TOPLEFT",
		layout = {
			elementSpacing = spacing,
			lineSpacing = spacing,
		},
	})

	self.Debuffs = Debuffs
	return Debuffs
end

-- 團隊與小隊增益
T.CreateRaidBuffs = function(self)
	local spacing = 4
	local iconsPerLine = 2

	local Buffs = self:CreateAuras({
		layout = HORIZONTAL,
		layoutLimit = (C.RaidAuraSize + 2) * iconsPerLine + spacing * (iconsPerLine - 1),
		initialAnchor = "BOTTOMRIGHT",
		growthX = "LEFT",
		growthY = "UP",
	})
	Buffs:SetFrameLevel(self.StringParent:GetFrameLevel() + 1)
	Buffs:SetPoint("BOTTOMRIGHT", self, -4, 6)
	Buffs.PostCreateButton = PostCreateAuraButton
	Buffs.showDuration = true
	Buffs.disableCooldown = true
	Buffs.durationFormatter = RAID_AURA_DURATION

	Buffs:AddGroup(RAID_BUFF_GROUP.filter, {
		candidateFilters = RAID_BUFF_GROUP.candidateFilters,
		maxFrameCount = RAID_BUFF_GROUP.maxFrameCount,
		sortMethod = AuraContainerSortMethod.Default,
		size = C.RaidAuraSize,
		showCount = true,
		disableMouse = true,
		layout = {
			elementSpacing = spacing,
			lineSpacing = spacing,
		},
	})

	self.Buffs = Buffs
	return Buffs
end

--======================================================--
-----------------    [[ Nameplates ]]    -----------------
--======================================================--

-- 名條光環外觀與群組在預熱／冷建立時完成一次，接管後不再操作按鈕。
local function InitializeNameplateAuras(Auras)
	local size = C.NPAuraSize
	local spacing = 5

	Auras.PostCreateButton = PostCreateAuraButton
	Auras.dispelColors = oUF.colors.dispel
	Auras.durationFormatter = RAID_AURA_DURATION

	for layoutIndex, group in ipairs(NAMEPLATE_AURA_GROUPS) do
		Auras:AddGroup(group.filter, {
			candidateFilters = group.candidateFilters,
			maxFrameCount = group.maxFrameCount,
			sortMethod = AuraContainerSortMethod.Default,
			size = size,
			showBuffTypeBorder = true,
			showDebuffTypeBorder = true,
			layout = {
				elementSpacing = spacing,
				lineSpacing = spacing,
				layoutIndex = layoutIndex,
			},
		})
	end
end

local NAMEPLATE_AURA_OPTIONS = {
	frameLevelOffset = 4,
	layout = HORIZONTAL,
	layoutLimit = C.NPAuraSize * C.NPMaxAura + 5 * (C.NPMaxAura - 1),
	initialAnchor = "BOTTOMLEFT",
	growthX = "RIGHT",
	growthY = "UP",
	initialize = InitializeNameplateAuras,
}

T.PrewarmNameplateAuras = function()
	oUF:PrewarmAuras(NAMEPLATE_AURA_OPTIONS)
end

T.CreateNameplateAuras = function(self)
	local Auras = self:CreatePrewarmAuras(NAMEPLATE_AURA_OPTIONS)
	self.Auras = Auras
	return Auras
end
