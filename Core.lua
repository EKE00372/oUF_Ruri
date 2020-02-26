local addon, ns = ...
local C, F, G, T = unpack(ns)

-- note:
-- 在CreateCastbar裡的self.Castbar中，self指的是頭像本身
-- 而在施法條、光環、副資源等元素的PostUpdate中，self指的是self.Castbar，即施法條元素自身
-- 為了防止搞混，這裡的function(self, unit)有些會寫為function(element, unit)，例如ouf core、ndui等
-- 有些仍寫為function(castbar, unit)，例如ouf_mlight、farva等

--==================================================--
-----------------    [[ Health ]]    -----------------
--==================================================--

-- [[ 重寫PreUpdate，為透明模式的反轉血量漸變色打造一個專用的顯示方式 ]] --
	
T.OverrideHealthbar = function(self, event, unit)
	if (not unit or self.unit ~= unit) then return end
	
	local health = self.Health	-- 這裡的self是頭像本身
	local cur, max = UnitHealth(unit), UnitHealthMax(unit)
	local disconnected = not UnitIsConnected(unit)
	local perc
	
	health:SetMinMaxValues(0, max)
	
	if disconnected then
		-- 離線時顯示為滿血
		health:SetValue(max)
	else
		-- 血量反轉為顯示損失量
		health:SetValue(max - cur)
	end
end

-- [[ 更新血量 ]] --

T.PostUpdateHealth = function(self, unit, min, max)
	local disconnected = not UnitIsConnected(unit)
	
	if disconnected then
		self:SetValue(max)
	else
		self:SetValue(max - min)
	end
end

-- [[ 戰鬥狀態隱藏休息指示器 ]] --

T.CombatPostUpdate = function(self, inCombat)
	local rest = IsResting() 
	if inCombat then
		self.__owner.RestingIndicator:Hide()
	elseif rest then
		self.__owner.RestingIndicator:Show()
	end
end

--===================================================--
-----------------    [[ Castbar ]]    -----------------
--===================================================--

-- [[ 開始施法 ]] --
--[[
T.VSafeZone = function(self)
	local safeZone = self.SafeZone
	local height = self:GetHeight()
	local _, _, _, ms = GetNetStats()

	local safeZoneRatio = (ms / 1e3) / self.max
	if(safeZoneRatio > 1) then
		safeZoneRatio = 1
	end

	safeZone:SetHeight(height * safeZoneRatio)
end]]--

T.PostSCastStart = function(self, unit)
	local frame = self:GetParent()
	
	if frame.mystyle == "NP" then
		-- 數字模式名條上移
		frame.Name:SetPoint("BOTTOM", 0, 24)
	else
		self.Spark:SetAlpha(.5)
	end

	if unit == "player" then
		self:SetStatusBarColor(.6, .6, .6)
	else
		if self.notInterruptible then
			self:SetStatusBarColor(.9, 0, 1)			-- 紫色條
		else
			self:SetStatusBarColor(.6, .6, .6)
		end
	end
end

T.PostCastStart = function(self, unit)
	-- 進度高亮
	self.Spark:SetAlpha(.8)
	
	-- 施法開始時隱藏名字
	self:GetParent().Name:Hide()
	self:GetParent().Status:Hide()
	
	-- 打斷染色
	if unit == "player" then
		self:SetStatusBarColor(.6, .6, .6, .5)
		self.Border:SetBackdropBorderColor(.6, .6, .6)
		
		--[[if frame.mystyle ~= "H" then
			self.SafeZone:ClearAllPoints()
			self.SafeZone:SetPoint("TOP")
			self.SafeZone:SetPoint("LEFT")
			self.SafeZone:SetPoint("RIGHT")
			T.VSafeZone(self)
		end]]--
	else
		if self.notInterruptible then
			self:SetStatusBarColor(.54, 0, .6, .5)			-- 淡紫色條
			self.Border:SetBackdropBorderColor(.9, 0, 1)	-- 紫色邊框
		else
			self:SetStatusBarColor(.6, .6, .6, .5)
			self.Border:SetBackdropBorderColor(.6, .6, .6)
		end
	end
end

-- [[ 停止施法 ]] --

T.PostCastStop = function(self, unit)
	local frame = self:GetParent()
	if frame.mystyle == "NP" then
		frame.Name:SetPoint("BOTTOM", 0, 6)
	else
		-- 施法結束時顯示名字
		frame.Name:Show()
		frame.Status:Show()
	end
end

-- [[ 狀態更新 ]] --

T.PostCastStopUpdate = function(self, event, unit)
	-- 施法過程中切換目標、新生成的名條，按施法結束處理
	if unit ~= self.unit then return end
	return T.PostCastStop(self.Castbar, unit)
end

T.PostCastFailed = function(self, unit)
	-- 一閃而過的施法失敗紅色條
	self:SetStatusBarColor(.5, .2, .2, .4)
	self:SetValue(self.max)
	self.Spark:SetAlpha(0)
	-- 不要顯示"被打斷"
	self.Text:SetText("")
	self:Show()
end

T.PostSCastFailed = function(self, unit)
	local frame = self:GetParent()
	-- 一閃而過的施法失敗紅色條
	self:SetStatusBarColor(.5, .2, .2)
	self:SetValue(self.max)
	if frame.mystyle ~= "NP" then
		self.Spark:SetAlpha(0)
	end
	self:Show()
end

-- [[ 施法過程中更新打斷狀態 ]] --

-- 例子：燃燒王座三王小怪
T.PostUpdateCast = function(self, unit)
	if not UnitIsUnit(unit, "player") and self.notInterruptible then
		self:SetStatusBarColor(.54, 0, .6, .5)			-- 淡紫色條
		self.Border:SetBackdropBorderColor(.9, 0, 1)	-- 紫色邊框
	else
		self:SetStatusBarColor(.6, .6, .6, .5)
		self.Border:SetBackdropBorderColor(.6, .6, .6)
	end
end

-- 例子：燃燒王座三王小怪
T.PostUpdateSCast = function(self, unit)
	if not UnitIsUnit(unit, "player") and self.notInterruptible then
		self:SetStatusBarColor(.9, 0, 1)				-- 紫色條
	else
		self:SetStatusBarColor(.6, .6, .6)
	end
end

-- [[ 自定格式的施法時間 ]] --

T.CustomTimeText = function(self, duration)
	if self.__owner.unit == "player" and self.delay ~= 0 then
		if self.casting then
			self.Time:SetFormattedText("%.1f/%.1f |cffff0000+%.1f|r", duration, self.max, self.delay)
		elseif self.channeling then
			self.Time:SetFormattedText("%.1f/%.1f |cffff0000+%.1f|r", self.max - duration, self.max, self.delay)
		end
	else
		if self.casting then
			self.Time:SetFormattedText("%.1f/%.1f", duration, self.max)
		elseif self.channeling then
			self.Time:SetFormattedText("%.1f/%.1f", self.max - duration, self.max)
		end
	end
end

--===================================================--
-------------------    [[ Auras ]]    -----------------
--===================================================--

-- [[ 顯示光環時間 ]] --

T.CreateAuraTimer = function(self, elapsed)
	self.elapsed = (self.elapsed or 0) + elapsed
	
	if self.elapsed >= 0.1 then
		local timeLeft = self.timeLeft - GetTime()
		if timeLeft > 0 then
			self.time:SetText(F.FormatTime(timeLeft))		
		else
			self:SetScript("OnUpdate", nil)
			self.time:SetText(nil)
		end
	self.elapsed = 0
	end
end

-- [[ 獲得光環時創建光環 ]] --

T.PostCreateIcon = function(self, button)
	-- 切邊
	button.icon:SetTexCoord(.08, .92, .08, .92)
	-- 邊框
	button.overlay:SetTexture(G.media.blank)
	button.overlay:SetDrawLayer("BACKGROUND")
	button.overlay:SetPoint("TOPLEFT", button.icon, "TOPLEFT", -1, 1)
	button.overlay:SetPoint("BOTTOMRIGHT", button.icon, "BOTTOMRIGHT", 1, -1)
	button.overlay:SetTexCoord(0, 1, 0, 1)
	-- 時間
	button.time = F.CreateText(button, "OVERLAY", G.NFont, G.NumberFS, G.FontFlag, "LEFT")
	button.time:ClearAllPoints()
	button.time:SetPoint("TOP", button, 0, 4)
	-- 層數
	button.count = F.CreateText(button, "OVERLAY", G.NFont, G.NumberFS, G.FontFlag, "RIGHT")
	button.count:ClearAllPoints()
	button.count:SetPoint("BOTTOMRIGHT", button, 0, 0)
	button.count:SetTextColor(.9, .9, .1)
	-- 陰影
	button.shadow = F.CreateSD(button, button.overlay, 3)
end

-- [[ 更新光環 ]] --

T.PostUpdateIcon = function(self, unit, button, _, _, duration, expiration, debuffType)
	local style = self.__owner.mystyle
	local color = oUF.colors.debuff[debuffType] or oUF.colors.debuff.none

	-- 更新陰影
	if duration then
		button.shadow:Show()
	end
	
	-- 更新overlay
	if style == "PP" then
		-- 玩家名條固定灰色
		button.overlay:SetVertexColor(.6, .6, .6)
	elseif style == "NP" or style == "BP"  or style == "R" then
		-- 名條上的光環一率按類型染色
		button.overlay:SetVertexColor(color[1], color[2], color[3])
	else
		if button.icon:GetTexture() ~= nil then
			-- 只在有圖示的時候才顯示overlay，並顯示debuff type
			-- 避免啟用gap時，間隔buff和debuff的占位空aura icon出現陰影
			button.overlay:Show()
			-- 頭像上減益效果按類型染色，增益效果固定灰色
			if button.isDebuff then
				local color = oUF.colors.debuff[debuffType] or oUF.colors.debuff.none
				button.overlay:SetVertexColor(color[1], color[2], color[3])
			else
				button.overlay:SetVertexColor(.6, .6, .6)
			end
		else
			button.overlay:Hide()
		end	
	end
	
	-- 更新時間
	if duration and duration > 0 then
		button.timeLeft = expiration
		button:SetScript("OnUpdate", T.CreateAuraTimer)
		button.time:Show()
	else
		button:SetScript("OnUpdate", nil)
		button.time:Hide()
	end
	
	button.first = true
end

--[[ 隱藏gap的文字和陰影 ]] --

T.PostUpdateGapIcon = function(self, unit, gapButton)
	-- gap是人為製造、用來隔開buff和debuff的隱藏圖示
	-- 其繼承debuff的持續時間，所以一併隱藏
	if gapButton.shadow and gapButton.shadow:IsShown() then
		gapButton.shadow:Hide()
	end
	
	if gapButton.time and gapButton.time:IsShown() then
		gapButton.time:Hide()
	end
end

-- [[ 視不同專精的副資源存在與否調整玩家光環的位置 ]] --

T.PostUpdatePlayerDebuffs = function(self, unit)
	if not unit and UnitIsUnit(unit, "player") then return end
	
	local style = self.__owner.mystyle
	local spec = GetSpecialization() or 0
	local id = GetSpecializationInfo(spec)
	
	if (id == 268 and not C.TankResource) or 
	  F.Multicheck(G.myClass, "DEATHKNIGHT", "ROGUE", "WARLOCK") or 
	  (F.Multicheck(id, 581, 66, 73) and C.TankResource) or
	  F.Multicheck(id, 102, 103, 104, 62, 269, 70, 262, 263) then
		-- 雙資源專精：死騎、盜賊、術士；復仇、防騎、防戰；鳥貓熊、秘法、御風、懲戒、增元
		if style == "VL" then
			self:SetPoint("BOTTOMLEFT", self.__owner.Health, "BOTTOMRIGHT", (C.PPHeight + C.PPOffset*2), 1)
		else
			self:SetPoint("BOTTOMLEFT", self.__owner.Health, "TOPLEFT", 1, C.PPHeight + C.PPOffset*2)
		end
	elseif (id == 268 and C.TankResource) then
		-- 三資源專精：釀酒，就你特別
		if style == "VL" then
			self:SetPoint("BOTTOMLEFT", self.__owner.Health, "BOTTOMRIGHT", (C.PPHeight*2 + C.PPOffset*3), 1)
		else
			self:SetPoint("BOTTOMLEFT", self.__owner.Health, "TOPLEFT", 1, C.PPHeight*2 + C.PPOffset*3)
		end
	else
		-- 單資源專精
		if style == "VL" then
			self:SetPoint("BOTTOMLEFT", self.__owner.Health, "BOTTOMRIGHT", C.PPOffset, 1)
		else
			self:SetPoint("BOTTOMLEFT", self.__owner.Health, "TOPLEFT", 1, C.PPOffset)
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
		
		if F.Multicheck(style, "VR", "VL") then
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

-- 替激勵設一個初始層數並用於重置
T.BolsterPreUpdate = function(self)
	self.bolster = 0
	self.bolsterIndex = nil
end

-- 更新激勵層數
T.BolsterPostUpdate = function(self)
	if not self.bolsterIndex then return end
	for _, button in pairs(self) do
		if button == self.bolsterIndex then
			button.count:SetText(self.bolster)
			return
		end
	end
end

-- 光環過濾
T.CustomFilter = function(self, unit, button, name, _, _, _, duration, expiration, caster, isStealable, _, spellID, _, isBossDebuff, casterIsPlayer, nameplateShowAll)
	local style = self.__owner.mystyle
	local npc = not UnitIsPlayer(unit)
	
	if name and spellID == 209859 then			-- 激勵顯示為層數
		self.bolster = self.bolster + 1
		if not self.bolsterIndex then
			self.bolsterIndex = button
			return true
		end
	elseif style == "NP" or style == "BP" then
		if UnitIsUnit("player", unit) then		-- 當該單位是自己(自身名條，只是預防有人把個人資源打開搞事)
			return false
		elseif self.showStealableBuffs and isStealable and npc then	-- 可驅散
			return true
		elseif C.BlackList[spellID] then		-- 黑名單
			return false
		elseif C.WhiteList[spellID] then		-- 白名單(主要補足暴雪白名單沒有的法術)
			return true
		else									-- 暴雪內建的控場白名單和玩家/寵物/載具的法術
			return nameplateShowAll or (caster == "player" or caster == "pet" or caster == "vehicle")
		end
	elseif style == "PP" then					-- 個人資源條顯示30秒(含)以下的光環
		return duration <= 30 and duration ~= 0
	elseif style == "R" then
		if C.RaidBlackList[spellID] then			-- 黑名單
			return false
		else
			return isBossDebuff or ((caster == "player" or caster == "pet" or caster == "vehicle") and button.isDebuff)
		end
	else
		return true
	end
end

--=================================================--
-----------------    [[ Power ]]    -----------------
--=================================================--

-- [[ 平滑顯示的能量數值 ]] --

T.PostUpdatePower = function(self, unit, min, max)
	local disconnected = not UnitIsConnected(unit)
	local _, type = UnitPowerType(unit)
	local color = oUF.colors.power[type] or oUF.colors.power.FUEL
	
	self.value:SetText()
	
	if min == 0 or max == 0 or disconnected then
		self:SetValue(0)
		self.value:SetText("")
	elseif UnitIsDead(unit) or UnitIsGhost(unit) then
		self:SetValue(0)
		self.value:SetText("")
	else
		if type == "MANA" then
			-- 法力值需要縮寫
			self.value:SetText(F.Hex(unpack(color))..F.ShortValue(min))
		else
			self.value:SetText(F.Hex(unpack(color))..min)
		end
	end
end

-- [[ 特殊能量文本 ]] --

T.PostUpdateAltPower = function(self, unit, cur)
	self.value:SetText(cur)
end

-- [[ 酒池文本 ]] --

T.PostUpdateStagger = function(self, cur, max)
	local perc = cur / max
	
	if cur == 0 then
		self.value:SetText("")
	else
		self.value:SetText(F.ShortValue(cur) .. " |cff70C0F5" .. F.ShortValue(perc * 100) .. "|r")
	end
end

-- [[ 坦克資源的天賦更新 ]] --

T.PostUpdateTankResource = function(self, cur, max, MaxChanged)
	if not max or not cur then return end
	
	local style = self.__owner.mystyle

	for i = 1, 4 do
		if MaxChanged then
			if style == "VL" then
				self[i]:SetHeight((C.PWidth - (max-1) * C.PPOffset) / max)
			elseif style == "PP" then
				self[i]:SetWidth((C.NPWidth - (max-1) * C.PPOffset) / max)
			else
				self[i]:SetWidth((C.PWidth - (max-1) * C.PPOffset) / max)
			end
		end
	end
end

-- [[ 連擊點的天賦更新 ]] --

T.PostUpdateClassPower = function(self, cur, max, MaxChanged, powerType)
	if not max or not cur then return end
	
	local style = self.__owner.mystyle
	local cpColor = {
	--{1, .8, .5},
	{1, .7, .1},
	{1, .95, .4},		-- 滿星
	}
	
	for i = 1, 6 do
		if MaxChanged then
			if style == "VL" then
				self[i]:SetHeight((C.PWidth - (max-1) * C.PPOffset) / max)
			elseif style == "PP" then
				self[i]:SetWidth((C.NPWidth - (max-1) * C.PPOffset) / max)
			else
				self[i]:SetWidth((C.PWidth - (max-1) * C.PPOffset) / max)
			end
		end
		
		if F.Multicheck(G.myClass, "ROUGE", "DRUID") then
			if max > 0 and cur == max then
				self[i]:SetStatusBarColor(unpack(cpColor[2]))
			else
				self[i]:SetStatusBarColor(unpack(cpColor[1]))
			end
		end
	end
end

-- [[ 符能 ]] --

T.OnUpdateRunes = function(self, elapsed)
	local duration = self.duration + elapsed
	self.duration = duration
	self:SetValue(duration)

	if self.timer then
		local remain = self.runeDuration - duration
		if remain > 0 then
			self.timer:SetText(F.FormatTime(remain))
		else
			self.timer:SetText(nil)
		end
	end
end

-- [[ 把ouf/rune整段搬過來 ]] --

T.PostUpdateRunes = function(self, runemap)
	for index, runeID in next, runemap do
		local rune = self[index]
		local start, duration, runeReady = GetRuneCooldown(runeID)
		if rune:IsShown() then
			if runeReady then
				--rune:SetAlpha(1)
				rune:SetScript("OnUpdate", nil)
				if rune.timer then rune.timer:SetText(nil) end
			elseif start then
				--rune:SetAlpha(.6)
				rune.runeDuration = duration
				rune:SetScript("OnUpdate", T.OnUpdateRunes)
			end
		end
	end
end