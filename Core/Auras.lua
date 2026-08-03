local _, ns = ...
local C, F, G, T = unpack(ns)

local HORIZONTAL = AnchorUtil.FlowLayoutAxis.Horizontal
local VERTICAL = AnchorUtil.FlowLayoutAxis.Vertical
local ROUND_DOWN = Enum.NumericRuleFormatRounding.Down

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
	Auras:SetPoint("BOTTOMLEFT", self.Health, "TOPLEFT", 0, C.PPOffset * 2 + C.PPHeight)
	Auras.PostCreateButton = PostCreateAuraButton
	Auras.showDuration = true
	Auras.disableCooldown = true
	Auras.durationFormatter = UF_AURA_DURATION

	Auras:AddGroup("HELPFUL", {
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

	Auras:AddGroup("HARMFUL", {
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
	Auras:SetPoint("BOTTOMRIGHT", self.Health, "BOTTOMLEFT", -C.PPOffset, 0)
	Auras.PostCreateButton = PostCreateAuraButton
	Auras.showDuration = true
	Auras.disableCooldown = true
	Auras.durationFormatter = UF_AURA_DURATION

	Auras:AddGroup("HELPFUL", {
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

	Auras:AddGroup("HARMFUL", {
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
	Auras:SetPoint("BOTTOMLEFT", self.Health, "TOPLEFT", 0, C.PPOffset * 2 + C.PPHeight)
	Auras.PostCreateButton = PostCreateAuraButton
	Auras.showDuration = true
	Auras.disableCooldown = true
	Auras.durationFormatter = UF_AURA_DURATION

	Auras:AddGroup("HELPFUL", {
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

	Auras:AddGroup("HARMFUL", {
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
	return Auras
end

-- 簡易焦點減益
T.CreateSimpleFocusDebuffs = function(self)
	local size = C.AuraSize
	local spacing = 5
	local maxFrameCount = 4

	local Debuffs = self:CreateAuras({
		layout = HORIZONTAL,
		layoutLimit = size * maxFrameCount + spacing * (maxFrameCount - 1),
		initialAnchor = "BOTTOMLEFT",
		growthX = "RIGHT",
		growthY = "UP",
	})
	Debuffs:SetFrameLevel(self:GetFrameLevel() + 4)
	Debuffs:SetPoint("BOTTOM", self, "TOP", 3, 3)
	Debuffs.PostCreateButton = PostCreateAuraButton
	Debuffs.showDuration = true
	Debuffs.disableCooldown = true
	Debuffs.durationFormatter = UF_AURA_DURATION

	Debuffs:AddGroup("HARMFUL", {
		maxFrameCount = maxFrameCount,
		size = size,
		showCount = true,
		showDebuffTypeShadow = true,
		tooltipAnchor = "ANCHOR_TOPRIGHT",
		layout = {
			elementSpacing = spacing,
			lineSpacing = spacing,
		},
	})

	self.Debuffs = Debuffs
	return Debuffs
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
	Debuffs:SetPoint("LEFT", self.Health, "RIGHT", 6, -2)
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
	Debuffs:SetPoint("TOPRIGHT", self.Power, "TOPLEFT", -C.PPOffset, -2)
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

	if UnitCanAttack("player", self.unit) then
		local Buffs = self:CreateAuras({
			layout = HORIZONTAL,
			layoutLimit = size * maxFrameCount + spacing * (maxFrameCount - 1),
			initialAnchor = "RIGHT",
			growthX = "LEFT",
			growthY = "UP",
		})
		Buffs:SetFrameLevel(self:GetFrameLevel() + 4)
		Buffs:SetPoint("RIGHT", self.Health, "LEFT", -6, -2)
		Buffs.PostCreateButton = PostCreateAuraButton
		Buffs.showDuration = true
		Buffs.disableCooldown = true
		Buffs.durationFormatter = UF_AURA_DURATION

		Buffs:AddGroup("HELPFUL", {
			maxFrameCount = maxFrameCount,
			size = size,
			showCount = true,
			layout = {
				elementSpacing = spacing,
				lineSpacing = spacing,
			},
		})

		self.Buffs = Buffs
		return Buffs
	else
		local Debuffs = self:CreateAuras({
			layout = HORIZONTAL,
			layoutLimit = C.TOTWidth,
			initialAnchor = "RIGHT",
			growthX = "LEFT",
			growthY = "UP",
		})
		Debuffs:SetFrameLevel(self:GetFrameLevel() + 4)
		Debuffs:SetPoint("RIGHT", self.Health, "LEFT", -6, -2)
		Debuffs.PostCreateButton = PostCreateAuraButton
		Debuffs.showDuration = true
		Debuffs.disableCooldown = true
		Debuffs.durationFormatter = UF_AURA_DURATION

		Debuffs:AddGroup("HARMFUL", {
			maxFrameCount = maxFrameCount,
			size = size,
			showCount = true,
			showDebuffTypeShadow = true,
			tooltipAnchor = "ANCHOR_BOTTOMRIGHT",
			layout = {
				elementSpacing = spacing,
				lineSpacing = spacing,
			},
		})

		self.Debuffs = Debuffs
		return Debuffs
	end
end

-- 目標的目標直式光環
T.CreateVToTAuras = function(self)
	local size = C.AuraSize
	local spacing = 5
	local maxFrameCount = 2

	if UnitCanAttack("player", self.unit) then
		local Buffs = self:CreateAuras({
			layout = VERTICAL,
			layoutLimit = size * maxFrameCount + spacing * (maxFrameCount - 1),
			initialAnchor = "TOP",
			growthX = "RIGHT",
			growthY = "DOWN",
		})
		Buffs:SetFrameLevel(self:GetFrameLevel() + 4)
		Buffs:SetPoint("TOPLEFT", self.Power, "TOPRIGHT", C.PPOffset, -2)
		Buffs.PostCreateButton = PostCreateAuraButton
		Buffs.showDuration = true
		Buffs.disableCooldown = true
		Buffs.durationFormatter = UF_AURA_DURATION

		Buffs:AddGroup("HELPFUL", {
			maxFrameCount = maxFrameCount,
			size = size,
			showCount = true,
			layout = {
				elementSpacing = spacing,
				lineSpacing = spacing,
			},
		})

		self.Buffs = Buffs
		return Buffs
	else
		local Debuffs = self:CreateAuras({
			layout = VERTICAL,
			layoutLimit = C.TOTWidth,
			initialAnchor = "TOP",
			growthX = "RIGHT",
			growthY = "DOWN",
		})
		Debuffs:SetFrameLevel(self:GetFrameLevel() + 4)
		Debuffs:SetPoint("TOPLEFT", self.Power, "TOPRIGHT", C.PPOffset, 0)
		Debuffs.PostCreateButton = PostCreateAuraButton
		Debuffs.showDuration = true
		Debuffs.disableCooldown = true
		Debuffs.durationFormatter = UF_AURA_DURATION

		Debuffs:AddGroup("HARMFUL", {
			maxFrameCount = maxFrameCount,
			size = size,
			showCount = true,
			showDebuffTypeShadow = true,
			tooltipAnchor = "ANCHOR_TOPRIGHT",
			layout = {
				elementSpacing = spacing,
				lineSpacing = spacing,
			},
		})

		self.Debuffs = Debuffs
		return Debuffs
	end
end

-- 焦點目標光環
T.CreateFoTAuras = function(self)
	local size = C.AuraSize
	local spacing = 5
	local maxFrameCount = 2
	local showAboveTarget = F.GetRuriOption("vertTarget")
	local initialAnchor = showAboveTarget and "BOTTOMLEFT" or "BOTTOMRIGHT"
	local growthX = showAboveTarget and "RIGHT" or "LEFT"

	if UnitCanAttack("player", self.unit) then
		local Buffs = self:CreateAuras({
			layout = HORIZONTAL,
			layoutLimit = size * maxFrameCount + spacing * (maxFrameCount - 1),
			initialAnchor = initialAnchor,
			growthX = growthX,
			growthY = "UP",
		})
		Buffs:SetFrameLevel(self:GetFrameLevel() + 4)
		if showAboveTarget then
			Buffs:SetPoint("BOTTOMLEFT", self.Health, "TOPLEFT", 0, C.PPOffset * 2 + C.PPHeight)
		else
			Buffs:SetPoint("RIGHT", self.Health, "LEFT", -6, 0)
		end
		Buffs.PostCreateButton = PostCreateAuraButton
		Buffs.showDuration = true
		Buffs.disableCooldown = true
		Buffs.durationFormatter = UF_AURA_DURATION

		Buffs:AddGroup("HELPFUL", {
			maxFrameCount = maxFrameCount,
			size = size,
			showCount = true,
			layout = {
				elementSpacing = spacing,
				lineSpacing = spacing,
			},
		})

		self.Buffs = Buffs
		return Buffs
	else
		local Debuffs = self:CreateAuras({
			layout = HORIZONTAL,
			layoutLimit = size * maxFrameCount + spacing * (maxFrameCount - 1),
			initialAnchor = initialAnchor,
			growthX = growthX,
			growthY = "UP",
		})
		Debuffs:SetFrameLevel(self:GetFrameLevel() + 4)
		if showAboveTarget then
			Debuffs:SetPoint("BOTTOMLEFT", self.Health, "TOPLEFT", 0, C.PPOffset * 2 + C.PPHeight)
		else
			Debuffs:SetPoint("RIGHT", self.Health, "LEFT", -6, 0)
		end
		Debuffs.PostCreateButton = PostCreateAuraButton
		Debuffs.showDuration = true
		Debuffs.disableCooldown = true
		Debuffs.durationFormatter = UF_AURA_DURATION

		Debuffs:AddGroup("HARMFUL", {
			maxFrameCount = maxFrameCount,
			size = size,
			showCount = true,
			showDebuffTypeShadow = true,
			tooltipAnchor = "ANCHOR_BOTTOMRIGHT",
			layout = {
				elementSpacing = spacing,
				lineSpacing = spacing,
			},
		})

		self.Debuffs = Debuffs
		return Debuffs
	end
end

-- 簡易焦點目標光環
T.CreateSimpleFoTAuras = function(self)
	local size = C.AuraSize
	local spacing = 5
	local maxFrameCount = 2
	local layoutLimit = size * maxFrameCount + spacing * (maxFrameCount - 1)

	if UnitCanAttack("player", self.unit) then
		local Buffs = self:CreateAuras({
			layout = HORIZONTAL,
			layoutLimit = layoutLimit,
			initialAnchor = "RIGHT",
			growthX = "LEFT",
			growthY = "UP",
		})
		Buffs:SetFrameLevel(self:GetFrameLevel() + 4)
		Buffs:SetPoint("RIGHT", self, "LEFT", -C.PPOffset, -C.PPOffset)
		Buffs.PostCreateButton = PostCreateAuraButton
		Buffs.showDuration = true
		Buffs.disableCooldown = true
		Buffs.durationFormatter = UF_AURA_DURATION

		Buffs:AddGroup("HELPFUL", {
			maxFrameCount = maxFrameCount,
			size = size,
			showCount = true,
			layout = {
				elementSpacing = spacing,
				lineSpacing = spacing,
			},
		})

		self.Buffs = Buffs
		return Buffs
	else
		local Debuffs = self:CreateAuras({
			layout = HORIZONTAL,
			layoutLimit = layoutLimit,
			initialAnchor = "RIGHT",
			growthX = "LEFT",
			growthY = "UP",
		})
		Debuffs:SetFrameLevel(self:GetFrameLevel() + 4)
		Debuffs:SetPoint("RIGHT", self, "LEFT", -C.PPOffset, -C.PPOffset)
		Debuffs.PostCreateButton = PostCreateAuraButton
		Debuffs.showDuration = true
		Debuffs.disableCooldown = true
		Debuffs.durationFormatter = UF_AURA_DURATION

		Debuffs:AddGroup("HARMFUL", {
			maxFrameCount = maxFrameCount,
			size = size,
			showCount = true,
			showDebuffTypeShadow = true,
			tooltipAnchor = "ANCHOR_TOPRIGHT",
			layout = {
				elementSpacing = spacing,
				lineSpacing = spacing,
			},
		})

		self.Debuffs = Debuffs
		return Debuffs
	end
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
	Debuffs:SetPoint("BOTTOMLEFT", self.Health, "TOPLEFT", 0, C.PPOffset * 2 + C.PPHeight)
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
	Buffs:SetPoint("BOTTOMRIGHT", self.Health, "TOPRIGHT", 0, C.PPOffset * 2 + C.PPHeight)
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
	Debuffs:SetPoint("BOTTOMLEFT", self.Health, "TOPLEFT", 0, C.PHeight / 2 + C.PPOffset)
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
	Buffs:SetPoint("BOTTOMRIGHT", self.Health, "TOPRIGHT", 0, C.PHeight / 2 + C.PPOffset)
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

-- 玩家名條增益
T.CreatePlayerPlateBuffs = function(self)
	local size = C.NPAuraSize + 6
	local spacing = 5

	local Buffs = self:CreateAuras({
		layout = HORIZONTAL,
		layoutLimit = size * C.NPMaxAura + spacing * (C.NPMaxAura - 1),
		initialAnchor = "BOTTOMLEFT",
		growthX = "RIGHT",
		growthY = "UP",
	})
	Buffs:SetFrameLevel(self:GetFrameLevel() + 4)
	Buffs.PostCreateButton = PostCreateAuraButton
	Buffs.showDuration = true
	Buffs.disableCooldown = true
	Buffs.durationFormatter = RAID_AURA_DURATION

	Buffs:AddGroup("HELPFUL|PLAYER", {
		maxFrameCount = C.NPMaxAura,
		size = size,
		showCount = true,
		disableMouse = true,
		candidateFilters = {
			maxDuration = 30,
		},
		layout = {
			elementSpacing = spacing,
			lineSpacing = spacing,
		},
	})

	self.Buffs = Buffs
	return Buffs
end
