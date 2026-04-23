
local addon, ns = ...
local oUF = ns.oUF
local C, F, G, T = unpack(ns)

local GetFrameLevel, SetFrameLevel = GetFrameLevel, SetFrameLevel

--=========================================================--
-------------------    [[ Post Update ]]    -----------------
--=========================================================--

-- [[ 顯示光環時間 ]] --
--[[
T.CreateAuraTimer = function(self, elapsed)
	self.elapsed = (self.elapsed or 0) + elapsed
	
	if self.elapsed >= 0.1 then
		local timeLeft = self.timeLeft - GetTime()
		if timeLeft > 0 then
			self.Cooldown:SetText(F.FormatTime(timeLeft))
		else
			self:SetScript("OnUpdate", nil)
			self.Cooldown:SetText("")
		end
	self.elapsed = 0
	end
end
]]--
-- [[ 顯示團隊框架光環時間 ]] --
--[[
T.CreateRaidAuraTimer = function(self, elapsed)
	self.elapsed = (self.elapsed or 0) + elapsed
	
	if self.elapsed >= 0.1 then
		local timeLeft = self.timeLeft - GetTime()
		if timeLeft > 0 then
			-- 只在小於60秒時顯示計數
			self.Cooldown:SetText((timeLeft > 60 and "") or F.FormatTime(timeLeft))
		else
			self:SetScript("OnUpdate", nil)
			self.Cooldown:SetText("")
		end
	self.elapsed = 0
	end
end
]]--
-- [[ 獲得光環時創建光環 ]] --

T.PostCreateIcon = function(element, button)
	-- 切邊
	button.Icon:SetTexCoord(.08, .92, .08, .92)
	-- button.Overlay 被保護了所以邊框和陰影都自行創建
	--[[button.Overlay:SetTexture(G.media.blank)
	button.Overlay:SetDrawLayer("BACKGROUND")
	button.Overlay:SetPoint("TOPLEFT", button.Icon, "TOPLEFT", -1, 1)
	button.Overlay:SetPoint("BOTTOMRIGHT", button.Icon, "BOTTOMRIGHT", 1, -1)
	button.Overlay:SetTexCoord(0, 1, 0, 1)]]--
	button.Overlay:Hide()
	button.Overlay = nil
	-- 邊框
	button.border = F.CreateBD(button, button, 1, .2, .2, .2, 1)
	-- 陰影
	button.shadow = F.CreateSD(button, button.border, 3)

	-- 冷卻計時
	local cd = CreateFrame("Cooldown", "$parentCooldown", button, "CooldownFrameTemplate")
	cd:SetAllPoints()
	cd:SetDrawSwipe(false)
    cd:SetDrawEdge(false)
	cd:SetReverse(true)
	cd:SetDrawBling(false)
	cd:SetHideCountdownNumbers(false)
	-- 冷卻計時文字
	local cdText = cd:GetRegions()
	cdText:SetFont(G.NFont, G.NumberFS, G.FontFlag)
	cdText:ClearAllPoints()
	cdText:SetPoint("TOP", button, 0, 3)
	button.Cooldown = cd

	-- 層數
	button.Count = F.CreateText(button, "OVERLAY", G.NFont, G.NumberFS, G.FontFlag, "RIGHT")
	button.Count:ClearAllPoints()
	button.Count:SetPoint("BOTTOMRIGHT", button, 0, -2)
	button.Count:SetTextColor(.9, .9, .1)
end

-- [[ 更新光環 ]] --

T.PostUpdateIcon = function(element, button, unit, data)
	local style = element.__owner.mystyle
	local color = C_UnitAuras.GetAuraDispelTypeColor(unit, data.auraInstanceID, element.dispelColorCurve)
	local duration = C_UnitAuras.GetAuraDuration(unit, data.auraInstanceID)

	if duration then button.border:Show() button.shadow:Show() end

	-- 邊框顏色
	if F.IsAny(style, "NP", "BP") then
		-- Nameplates 的光環一律按類型染色
		button.border:SetBackdropColor(0, 0, 0)
		button.shadow:SetBackdropBorderColor(color.r, color.g, color.b)
	else
		-- Unitframes 的減益效果按類型染色
		if data.isHarmfulAura and element.showDebuffType then
			button.border:SetBackdropColor(0, 0, 0)
			button.shadow:SetBackdropBorderColor(color.r, color.g, color.b)
		else
			button.border:SetBackdropColor(.2, .2, .2)
			button.shadow:SetBackdropBorderColor(0, 0, 0)
		end
	end
	
	-- 更新時間
	--[[if data.duration and data.duration > 0 then
		button.timeLeft = data.expirationTime
		button:SetScript("OnUpdate", (style == "R" and T.CreateRaidAuraTimer) or T.CreateAuraTimer)
		button.Cooldown:Show()
	else
		button:SetScript("OnUpdate", nil)
		button.Cooldown:Hide()
	end]]--
end

--[[ 分隔增減益的隱藏圖示 ]] --

T.PostUpdateGapIcon = function(element, _, gapButton)
	-- 因為 .border 和 .shadow 是自行創建的，所以需要手動隱藏
	if gapButton.shadow and gapButton.shadow:IsShown() then
		gapButton.shadow:Hide()
	end

	if gapButton.border and gapButton.border:IsShown() then
		gapButton.border:Hide()
	end
	
	if gapButton.time and gapButton.time:IsShown() then
		gapButton.time:Hide()
	end
end

-- [[ 視不同專精的副資源存在與否，調整玩家頭像旁減益光環的位置 ]] --

T.PostUpdatePlayerDebuffs = function(element, unit)
	if not unit and UnitIsUnit(unit, "player") then return end
	
	local style = element.__owner.mystyle
	local spec = F.SpecCheck()
	
	if spec == 1 then   	-- 雙資源專精
		if style == "VL" then
			element:SetPoint("BOTTOMLEFT", element.__owner.Health, "BOTTOMRIGHT", C.PPHeight + C.PPOffset*2, 1)
		else
			element:SetPoint("BOTTOMLEFT", element.__owner.Health, "TOPLEFT", 1, C.PPHeight + C.PPOffset*2)
		end
	elseif spec == 2 then	-- 三資源專精
		if style == "VL" then
			element:SetPoint("BOTTOMLEFT", element.__owner.Health, "BOTTOMRIGHT", C.PPHeight*2 + C.PPOffset*3, 1)
		else
			element:SetPoint("BOTTOMLEFT", element.__owner.Health, "TOPLEFT", 1, C.PPHeight*2 + C.PPOffset*3)
		end
	else
		if style == "VL" then
			element:SetPoint("BOTTOMLEFT", element.__owner.Health, "BOTTOMRIGHT", C.PPOffset, 1)
		else
			element:SetPoint("BOTTOMLEFT", element.__owner.Health, "TOPLEFT", 1, C.PPOffset)
		end
	end
end

-- [[ 替垂直樣式重做光環排列與成長方向 ]] --

T.SetPosition = function(element, from, to)
	local style = element.__owner.mystyle
	
	local sizex = (element.size or 16) + (element["spacing-x"] or element.spacing or 0)
	local sizey = (element.size or 16) + (element["spacing-y"] or element.spacing or 0)
	
	local anchor = element.initialAnchor or "BOTTOMLEFT"
	
	local growthx = (element["growth-x"] == "LEFT" and -1) or 1
	local growthy = (element["growth-y"] == "DOWN" and -1) or 1
	
	local cols = math.floor(element:GetWidth() / sizex + 0.5)	-- 一行的數量
	local rows = math.floor(element:GetHeight() / sizey + 0.5)	-- 一列的數量

	for i = from, to do
		local button = element[i]
		if not button then break end
		
		if F.IsAny(style, "VR", "VL") then
			-- 直式排列
			local row = (i - 1) % rows
			local col = math.floor((i - 1) / rows)
			
			button:ClearAllPoints()
			button:SetPoint(anchor, element, anchor, col * sizex * growthx, row * sizey * growthy)
		else
			-- 標準的橫式排列
			local col = (i - 1) % cols
			local row = math.floor((i - 1) / cols)
			
			button:ClearAllPoints()
			button:SetPoint(anchor, element, anchor, col * sizex * growthx, row * sizey * growthy)
		end
	end
end

-- [[ 光環過濾 ]] --

--[[
T.BolsterPostUpdateInfo = function(element, unit, _, debuffsChanged)
	-- 替激勵設一個初始層數並用於重置
	element.bolsterStacks = 0
	element.bolsterInstanceID = nil

	for auraInstanceID, data in next, element.allBuffs do
		if data.spellId == 209859 then
			if not element.bolsterInstanceID then
				element.bolsterInstanceID = auraInstanceID
				element.activeBuffs[auraInstanceID] = true
			end
			element.bolsterStacks = element.bolsterStacks + 1
			if element.bolsterStacks > 1 then
				element.activeBuffs[auraInstanceID] = nil
			end
		end
	end
	if element.bolsterStacks > 0 then
		for i = 1, element.visibleButtons do
			local button = element[i]
			if element.bolsterInstanceID and element.bolsterInstanceID == button.auraInstanceID then
				button.Count:SetText(element.bolsterStacks)
				break
			end
		end
	end
end
]]--

-- 光環過濾
--[[
T.CustomFilter = function(self, unit, data)
	if not unit then return end
	local style = self.__owner.mystyle
	local npc = not UnitIsPlayer(unit)
	
	--if data.name and data.spellId == 209859 then
		-- < 激勵為true，才能被postupdateinfo處理 >
		-- 新光環是table，只在創建時才會fullupdate，導致名條需要update激勵時無法被postupdateinfo處理
		-- 所以必需在filter裡返回true，才能觸發ouf的buffsChanged/debuffsChanged
		-- 使已acvite但非fullupdate的auraupdate(add/remove)被postupdateinfo處理
		--return true
	--elseif style == "NP" or style == "BP" then
	if style == "NP" or style == "BP" then
		if UnitIsUnit("player", unit) then
			-- 當該名條單位是玩家自己時隱藏，預防有人把系統的個人資源打開搞事情
			return false
		elseif self.showStealableBuffs and data.isStealable and npc then
			-- 非玩家，可驅散，則顯示
			return true
		elseif C.BlackList[data.spellId] then
			-- 黑名單，則隱藏
			return false
		elseif C.WhiteList[data.spellId] then
			-- 白名單，補足預設白名單沒有的法術，額外顯示
			return true
		else
			-- 預設的控場白名單和玩家/寵物/載具的法術
			return data.nameplateShowAll or data.isPlayerAura
		end
	elseif style == "NPP" or style == "BPP" then
		if C.PlayerBlackList[data.spellId] then
			-- 黑名單，則隱藏
			return false
		elseif C.PlayerWhiteList[data.spellId] then
			-- 白名單，補足會超出30秒但需監控的法術，額外顯示
			return true
		else
			-- 個人資源條顯示30秒(含)以下的光環
			return data.isPlayerAura and data.duration <= 30 and data.duration ~= 0
		end
	elseif style == "R" then
		if C.RaidBlackList[data.spellId] then
			-- 黑名單，則隱藏
			return false
		elseif data.isBossAura or SpellIsPriorityAura(data.spellId) then
			-- 暴雪內建的首領光環和優先顯示等等
			return true
		else
			-- 暴雪內建的其他，直接調用原生團隊框架的規則
			local hasCustom, alwaysShowMine, showForMySpec = SpellGetVisibilityInfo(data.spellId, UnitAffectingCombat("player") and "RAID_INCOMBAT" or "RAID_OUTOFCOMBAT")
			if hasCustom then
				-- 監視自身所有
				return showForMySpec or (alwaysShowMine and data.isPlayerAura)
			else
				return true
			end
		end
	else
		return true
	end
end
]]--


--=============================================================--
-------------------    [[ Create elements ]]    -----------------
--=============================================================--

-- [[ 減益 ]] --

T.CreateDebuffs = function(self, button)
	local Debuffs = CreateFrame("Frame", nil, self)
	Debuffs.spacing = 6
	Debuffs:SetFrameLevel(self:GetFrameLevel() + 4)
	
	-- 選項
	Debuffs.showDebuffType = true
	-- 註冊到ouf
	self.Debuffs = Debuffs
	self.Debuffs.PostCreateButton = T.PostCreateIcon
	self.Debuffs.PostUpdateButton = T.PostUpdateIcon
	--self.Debuffs.FilterAura = T.CustomFilter
end

-- [[ 增益 ]] --

T.CreateBuffs = function(self, button)
	local Buffs = CreateFrame("Frame", nil, self)
	Buffs.spacing = 6
	Buffs:SetFrameLevel(self:GetFrameLevel() + 4)
	
	-- 選項
	Buffs.disableCooldown = true
	-- 註冊到ouf
	self.Buffs = Buffs
	self.Buffs.PostCreateButton = T.PostCreateIcon
	self.Buffs.PostUpdateButton = T.PostUpdateIcon
	--self.Buffs.FilterAura = T.CustomFilter
end

-- [[ 光環 ]] --

T.CreateAuras = function(self, button)
	local Auras = CreateFrame("Frame", nil, self)
	Auras.spacing = 6
	Auras.size = C.buSize
	Auras:SetFrameLevel(self:GetFrameLevel() + 4)
	
	if self.mystyle == "S" then
		-- Simple focus
		Auras.numBuffs = 0
		Auras.numDebuffs = 4
		Auras.numTotal = 4
		Auras.gap = false
		
		Auras.iconsPerRow = 4
		Auras.initialAnchor = "BOTTOMLEFT"
		Auras.tooltipAnchor = "ANCHOR_TOPRIGHT"
		Auras["growth-x"] = "RIGHT"
		Auras["growth-y"] = "UP"
		Auras:SetPoint("BOTTOMLEFT", self.HealthText, "TOPLEFT", 3, 0)
		Auras:SetWidth(C.buSize * Auras.numTotal + Auras.spacing * (Auras.numTotal - 1))
		Auras:SetHeight(C.buSize)
	else
		if self.mystyle == "H" then
			-- Player/Target/Focus
			local iconsPerLine = math.floor(self:GetWidth() / (C.buSize + Auras.spacing) + 0.5)
			
			Auras.numBuffs = iconsPerLine
			Auras.numDebuffs = C.maxAura
			Auras.numTotal = C.maxAura
			Auras.gap = true

			Auras.initialAnchor = "BOTTOMLEFT"
			Auras.tooltipAnchor = "ANCHOR_TOPLEFT"
			Auras["growth-x"] = "RIGHT"
			Auras["growth-y"] = "UP"
			Auras:SetPoint("BOTTOMLEFT", self.Health, "TOPLEFT", 1, C.PPOffset * 2 + C.PPHeight)
			Auras:SetWidth(self:GetWidth())
			Auras:SetHeight(C.buSize * (Auras.numTotal/iconsPerLine) + Auras.spacing * (Auras.numTotal/iconsPerLine-1))
		else
			-- VL=Player/VR=Target
			local iconsPerLine = math.floor(self:GetHeight() / (C.buSize + Auras.spacing) + 0.5)
			
			Auras.numBuffs = iconsPerLine
			Auras.numDebuffs = C.maxAura
			Auras.numTotal = C.maxAura
			Auras.gap = true
	
			Auras.initialAnchor = "BOTTOMRIGHT"
			Auras["growth-x"] = "LEFT"
			Auras["growth-y"] = "UP"
			Auras:SetPoint("BOTTOMRIGHT", self.Health, "BOTTOMLEFT", -C.PPOffset - 1, 1)
			Auras:SetWidth(C.buSize * (Auras.numTotal/iconsPerLine) + Auras.spacing * (Auras.numTotal/iconsPerLine-1))
			Auras:SetHeight(self:GetHeight())
		end
	end
	
	-- 選項
	Auras.showDebuffType = true
	-- 註冊到ouf
	self.Auras = Auras
	--self.Auras.SetPosition = T.SetPosition					-- 為垂直排列重寫set position
	self.Auras.PostCreateButton = T.PostCreateIcon
	self.Auras.PostUpdateButton = T.PostUpdateIcon
	if self.mystyle ~= "S" then
		self.Auras.PostUpdateGapButton = T.PostUpdateGapIcon	-- 間隔圖示
	end
	--self.Auras.FilterAura = T.CustomFilter					-- 光環過濾	
end
