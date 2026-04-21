local addon, ns = ...
local oUF = ns.oUF
local C, F, G, T = unpack(ns)

local UnitGetIncomingHeals, UnitGetTotalAbsorbs, UnitClass, UnitAffectingCombat = UnitGetIncomingHeals, UnitGetTotalAbsorbs, UnitClass, UnitAffectingCombat
local UnitHealth, UnitHealthMax, UnitPowerType, GetRuneCooldown = UnitHealth, UnitHealthMax, UnitPowerType, GetRuneCooldown
local UnitIsConnected, UnitIsDead, UnitIsGhost, UnitGUID, UnitIsPlayer = UnitIsConnected, UnitIsDead, UnitIsGhost, UnitGUID, UnitIsPlayer
local GetTime, format = GetTime, format

-- core: replace ouf default post update function
-- note:
-- 在CreateCastbar等創建元素的的function裡，self.Castbar中的self指的是頭像本身
-- 而在施法條、光環、副資源等元素的PostUpdate中，self指的是self.Castbar，即施法條元素自身
-- 為了防止搞混，這裡的function(self, unit)有些會寫為function(element, unit)，例如ouf core、ndui等
-- 有些仍寫為function(castbar, unit)，例如ouf_mlight、farva等
-- 將來要統一替換為不混淆的寫法

--===============================-===================--
-----------------    [[ General ]]    -----------------
--=====================================-=============--

-- [[ 通用的 multiplier postupdate ]] -- 

T.PostUpdatemMultiBGColor = function(element, arg1, arg2)
	if not element.bg then return end

	local r, g, b
	if arg2 == nil then
		r, g, b = arg1:GetRGB() -- function(element, color)
	else
		r, g, b = arg2:GetRGB() -- function(element, unit, color)
	end

	if element.bg then
		local mu = element.bg.multiplier or 0.3
		element.bg:SetVertexColor(r * mu, g * mu, b * mu)
	end
end

--==================================================--
-----------------    [[ Health ]]    -----------------
--==================================================--

-- [[ 在背景更新血量漸變色 ]] --

local bgCurve = C_CurveUtil.CreateColorCurve()
bgCurve:SetType(Enum.LuaCurveType.Linear)
bgCurve:AddPoint(0.0, CreateColor(1, 0, 0))
bgCurve:AddPoint(0.5, CreateColor(1, .8, .1))
bgCurve:AddPoint(1.0, CreateColor(1, .8, .1))

T.PostUpdateHealth = function(element, unit)
	local disconnected = not UnitIsConnected(unit)
	local isGhost = UnitIsGhost(unit)
	if disconnected or isGhost then
		element.bg:SetVertexColor(0.3, 0.3, 0.3)
	else
		local color = UnitHealthPercent(unit, true, bgCurve)
		element.bg:SetVertexColor(color:GetRGB())
	end
end

-- [[ 戰鬥狀態隱藏休息指示器 ]] --

T.CombatPostUpdate = function(element, inCombat)
	local rest = IsResting() 
	if inCombat then
		element.__owner.RestingIndicator:Hide()
	elseif rest then
		element.__owner.RestingIndicator:Show()
	end
end

--===================================================--
-----------------    [[ Castbar ]]    -----------------
--===================================================--

-- [[ 更新施法目標 ]] --

T.UpdateSpellTarget = function(element, unit)
	if not unit then return end
	if (F.GetNPCID(UnitGUID(unit)) ~= C.UnitSpellTarget[element.npcID]) then return end
	
	local unitTarget = unit.."target"
	if UnitExists(unitTarget) then
		local nameString
		if UnitIsUnit(unitTarget, "player") then
			nameString = format("|cffff0000%s|r", ">"..strupper(YOU).."<")
		else
			local class = select(2, UnitClass(unitTarget))
			nameString = F.Hex(oUF.colors.class[class])..UnitName(unitTarget)
		end
		element.Text:SetText(nameString)
	end
end

-- [[ 重置施法目標 ]] --

T.ResetSpellTarget = function(element)
	if element.Text then
		element.Text:SetText("")
	end
end

-- [[ 獨立施法條：開始施法 ]] --

T.PostStandaloneCastStart = function(element, unit)
	local frame = element:GetParent()

	if frame.mystyle == "NP" then
		-- 數字模式名條名字上移
		frame.Name:SetPoint("BOTTOM", 0, 6+G.NPNameFS)
	elseif frame.mystyle == "BP" then
		-- 條形模式施法目標
		T.UpdateSpellTarget(element, unit)
	else
		element.Spark:SetAlpha(.5)
	end

	if unit == "player" then
		element:SetStatusBarColor(unpack(C.CastNormal))
	else
		if element.notInterruptible then
			element:SetStatusBarColor(unpack(C.CastShield))	-- 紫色條
		else
			element:SetStatusBarColor(unpack(C.CastNormal))
		end
	end
end

-- [[ 嵌入施法條：開始施法 ]] --

T.PostCastStart = function(element, unit)
	-- 進度高亮
	element.Spark:SetAlpha(.8)
	
	-- 施法開始時隱藏名字
	element:GetParent().Name:Hide()
	element:GetParent().Status:Hide()
	
	-- 打斷染色
	if unit == "player" then
		element:SetStatusBarColor(.6, .6, .6, .5)
		element.Border:SetBackdropBorderColor(.6, .6, .6)
	else
		if element.notInterruptible then
			element:SetStatusBarColor(.54, 0, .6, .5)			-- 淡紫色條
			element.Border:SetBackdropBorderColor(.9, 0, 1)	-- 紫色邊框
		else
			element:SetStatusBarColor(.6, .6, .6, .5)
			element.Border:SetBackdropBorderColor(.6, .6, .6)
		end
	end
end

-- [[ 施法條：停止施法 ]] --

T.PostCastStop = function(element, unit)
	local frame = element:GetParent()
	if frame.mystyle == "NP" then
		-- 使數字模式名條的名字復位
		frame.Name:SetPoint("BOTTOM", 0, 6)
	elseif frame.mystyle == "BP" then
		-- 清空施法目標
		T.ResetSpellTarget(element)
	else
		-- 施法結束時顯示名字
		frame.Name:Show()
		frame.Status:Show()
	end
end

-- [[ 狀態更新 ]] --

T.PostCastStopUpdate = function(element, event, unit)
	-- 用於頭像上的依附型施法條
	-- 施法過程中切換目標、新生成的名條，按施法結束處理
	if unit ~= element.unit then return end
	return T.PostCastStop(element.Castbar, unit)
end

-- [[ 名條條形施法條：施法目標更新 ]] --

T.PostCastUpdate = function(element, unit)
	T.ResetSpellTarget(element)
	T.UpdateSpellTarget(element, unit)
end

-- [[ 嵌入施法條：施法失敗 ]] --

T.PostCastFailed = function(element, unit)
	local frame = element:GetParent()
	if frame.mystyle == "NP" then
		-- 使數字模式名條的名字復位
		frame.Name:SetPoint("BOTTOM", 0, 6)
	else
		-- 施法結束時顯示名字
		frame.Name:Show()
		frame.Status:Show()
	end
	
	-- 一閃而過的施法失敗紅色條
	element:SetStatusBarColor(.5, .2, .2, .4)
	element:SetValue(element.max)
	element.Spark:SetAlpha(0)
	-- 不要顯示"被打斷"
	element.Text:SetText("")
	element:Show()
end

-- [[ 獨立施法條：施法失敗 ]] --

T.PostStandaloneCastFailed = function(element, unit)
	local frame = element:GetParent()
	if frame.mystyle == "BP" then
		-- 條形模式清空施法目標
		T.ResetSpellTarget(element)
	end
	
	-- 一閃而過的施法失敗紅色條
	element:SetStatusBarColor(unpack(C.CastFailed))
	element:SetValue(element.max)
	element:Show()
end

-- [[ 嵌入施法條：施法過程中打斷狀態更新 ]] --

-- 例子：燃燒王座三王小怪
T.PostUpdateCast = function(element, unit)
	if not UnitIsUnit(unit, "player") and element.notInterruptible then
		element:SetStatusBarColor(.54, 0, .6, .5)			-- 淡紫色條
		element.Border:SetBackdropBorderColor(.9, 0, 1)	-- 紫色邊框
	else
		element:SetStatusBarColor(.6, .6, .6, .5)
		element.Border:SetBackdropBorderColor(.6, .6, .6)
	end
end

-- [[ 獨立施法條：施法過程中打斷狀態更新 ]] --

-- 例子：燃燒王座三王小怪
T.PostUpdateStandaloneCast = function(element, unit)
	if not UnitIsUnit(unit, "player") and element.notInterruptible then
		element:SetStatusBarColor(unpack(C.CastShield))	-- 紫色條
	else
		element:SetStatusBarColor(unpack(C.CastNormal))
	end
end

-- [[ 自定格式的施法時間 ]] --

T.CustomTimeText = function(element, durationObject)
	if durationObject then
		local duration = durationObject:GetRemainingDuration()
		local total = durationObject:GetTotalDuration()
		local delayText = ""
		if element.delay ~= 0 then
			delayText = format("|cffff0000%s%.2f|r", element.channeling and '-' or '+', element.delay)
		end
		element.Time:SetFormattedText('%.1f%s%.1f', duration, delayText, total)
	end
end

--===================================================--
-------------------    [[ Auras ]]    -----------------
--===================================================--

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
	-- 邊框
	button.Overlay:SetTexture(G.media.blank)
	button.Overlay:SetDrawLayer("BACKGROUND")
	button.Overlay:SetPoint("TOPLEFT", button.Icon, "TOPLEFT", -1, 1)
	button.Overlay:SetPoint("BOTTOMRIGHT", button.Icon, "BOTTOMRIGHT", 1, -1)
	button.Overlay:SetTexCoord(0, 1, 0, 1)
	-- 時間
	button.Cooldown = F.CreateText(button, "OVERLAY", G.NFont, G.NumberFS, G.FontFlag, "LEFT")
	button.Cooldown:ClearAllPoints()
	button.Cooldown:SetPoint("TOP", button, 0, 4)
	-- 層數
	button.Count = F.CreateText(button, "OVERLAY", G.NFont, G.NumberFS, G.FontFlag, "RIGHT")
	button.Count:ClearAllPoints()
	button.Count:SetPoint("BOTTOMRIGHT", button, 0, -2)
	button.Count:SetTextColor(.9, .9, .1)
	-- 陰影
	button.shadow = F.CreateSD(button, button.Overlay, 3)
end

-- [[ 更新光環 ]] --

T.PostUpdateIcon = function(element, button, unit, data)
	local style = element.__owner.mystyle
	local color = C_UnitAuras.GetAuraDispelTypeColor(unit, data.auraInstanceID, element.dispelColorCurve)
	local duration = C_UnitAuras.GetAuraDuration(unit, data.auraInstanceID)

	-- 顯示陰影
	if data.duration then button.shadow:Show() end
	
	-- 邊框顏色
	if style == "NPP" or style == "BPP" then
		-- 玩家名條固定灰色
		button.Overlay:SetVertexColor(.6, .6, .6)
	elseif F.IsAny(style, "NP", "BP") then
		-- 名條上的光環一率按類型染色
		button.Overlay:SetVertexColor(0, 0, 0)
		button.shadow:SetBackdropBorderColor(color.r, color.g, color.b)
	else
		-- 只在有圖示的時候才顯示overlay，並顯示debuff type
		-- 避免啟用gap時，間隔buff和debuff的占位空aura icon出現陰影
		button.Overlay:Show()
		-- 頭像上減益效果按類型染色，增益效果固定灰色
		if data.isHarmfulAura and element.showDebuffType then
			button.Overlay:SetVertexColor(0, 0, 0)
			button.shadow:SetBackdropBorderColor(color.r, color.g, color.b)
		else
			button.shadow:SetBackdropBorderColor(.6, .6, .6)
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

--[[ 隱藏gap的文字和陰影 ]] --

T.PostUpdateGapIcon = function(element, _, gapButton)
	-- gap是人為製造、用來隔開buff和debuff的隱藏圖示
	-- 其繼承debuff的持續時間，所以一併隱藏
	if gapButton.shadow and gapButton.shadow:IsShown() then
		gapButton.shadow:Hide()
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
	
	if spec == 1 then	-- 雙資源專精
		if style == "VL" then
			element:SetPoint("BOTTOMLEFT", element.__owner.Health, "BOTTOMRIGHT", C.PPHeight + C.PPOffset*2, 1)
		else
			element:SetPoint("BOTTOMLEFT", element.__owner.Health, "TOPLEFT", 1, C.PPHeight + C.PPOffset*2)
		end
	elseif spec == 2 then
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
--=================================================--
-----------------    [[ Power ]]    -----------------
--=================================================--

-- [[ 特殊能量文本 ]] --

T.PostUpdateAltPower = function(element, unit, cur)
	element.value:SetText(cur)
end

-- [[ 酒池文本 ]] --

T.PostUpdateStagger = function(element, cur, max)
	local perc = cur / max
	
	if cur == 0 then
		element.value:SetText("")
	else
		element.value:SetText(F.ShortValue(cur) .. " |cff70C0F5" .. F.ShortValue(perc * 100) .. "|r")
	end
end

-- [[ 連擊點的天賦更新 ]] --

T.PostUpdateClassPower = function(element, cur, max, MaxChanged, powerType)
	if not max or not cur then return end
	
	local style = element.__owner.mystyle
	local cpColor = {
		{1, .7, .1},
		{1, .95, .4},	-- 滿星
	}
	
	for i = 1, 7 do
		if MaxChanged then
			if style == "VL" then
				element[i]:SetHeight((C.PWidth - (max-1) * C.PPOffset) / max)
			elseif style == "NPP" or style == "BPP" then
				element[i]:SetWidth((C.PlayerNPWidth - (max-1) * C.PPOffset) / max)
			else
				element[i]:SetWidth((C.PWidth - (max-1) * C.PPOffset) / max)
			end
		end
		--[[ -- 坦克資源和神聖能量
		if i == 1 and powerType == "HOLY_POWER" then
			if C.TankResource and IsSpellKnown(432459) then
				if style == "VL" then
					element[i]:SetPoint("BOTTOMLEFT", element.__owner, "BOTTOMRIGHT", C.PPOffset*2+C.PPHeight, 0)
				elseif style == "H" then
					element[i]:SetPoint("BOTTOMLEFT", element.__owner, "TOPLEFT", 0, C.PPOffset*2+C.PPHeight)
				end
			else
				if style == "VL" then
					element[i]:SetPoint("BOTTOMLEFT", element.__owner, "BOTTOMRIGHT", C.PPOffset, 0)
				elseif style == "H" then
					element[i]:SetPoint("BOTTOMLEFT", element.__owner, "TOPLEFT", 0, C.PPOffset)
				end
			end
		end]]--
		-- 連擊點滿星變色
		if powerType == "COMBO_POINTS" then
			if max > 0 and cur == max then
				element[i]:SetStatusBarColor(unpack(cpColor[2]))
			else
				element[i]:SetStatusBarColor(unpack(cpColor[1]))
			end
		end
		-- 背景
		if element[i].bg then
			local mu = element[i].bg.multiplier or 0.3
			local r, g, b = element[i]:GetStatusBarColor()
			element[i].bg:SetVertexColor(r * mu, g * mu, b * mu)
		end
	end
end

--[[
T.PostUpdateHolyPower = function(self)
	local style = self.__owner.mystyle
	local spec = F.SpecCheck()
	
	if spec == 2 then
		if style == "VL" then
			self[i]:SetPoint("BOTTOMLEFT", self.__owner, "BOTTOMRIGHT", C.PPOffset*2+C.PPHeight, 0)
		elseif style == "H" then
			self[i]:SetPoint("BOTTOMLEFT", self.__owner, "TOPLEFT", 0, C.PPOffset*2+C.PPHeight)
		end
	else
		if style == "VL" then
			self[i]:SetPoint("BOTTOMLEFT", self.__owner, "BOTTOMRIGHT", C.PPOffset, 0)
		elseif style == "H" then
			self[i]:SetPoint("BOTTOMLEFT", self.__owner, "TOPLEFT", 0, C.PPOffset)
		end
	end
end
]]--

-- [[ 符文 ]] --

T.OnUpdateRunes = function(element, elapsed)
	local duration = element.duration + elapsed
	element.duration = duration
	element:SetValue(duration)

	if element.timer then
		local remain = element.runeDuration - duration
		if remain > 0 then
			element.timer:SetText(F.FormatTime(remain))
		else
			element.timer:SetText(nil)
		end
	end
end

-- [[ 符文更新 ]] --

T.PostUpdateRunes = function(element, runemap)
	for index, runeID in next, runemap do
		-- 把符文整段搬過來
		local rune = element[index]
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
		-- 背景
		if element[index].bg then
			local mu = element[index].bg.multiplier or 0.3
			local r, g, b = element[index]:GetStatusBarColor()
			element[index].bg:SetVertexColor(r * mu, g * mu, b * mu)
		end
	end
end

-- [[ 更新預估治療 ]] --
--[[
T.PostUpdateHealthPrediction = function(self, unit, myIncomingHeal, otherIncomingHeal, absorb, healAbsorb, hasOverAbsorb, hasOverHealAbsorb)
	local health = self.__owner.Health
	local style = self.__owner.mystyle
	local cur, max = UnitHealth(unit), UnitHealthMax(unit)
	local ab, income = UnitGetTotalAbsorbs(unit) or 0, UnitGetIncomingHeals(unit) or 0
	
	-- 合併預估治療和吸收盾
	-- 不要這麼做，會誤判血量
	--self.absorbBar:SetValue(ab + income)
	
	if self.overAbsorb and hasOverAbsorb then
	--if self.overAbsorb and (cur + ab > max) then
		local totalAbsorb = (ab + income)
		local lostHealth = (max - cur) -- 目標當前缺口
		local curHealth = cur/max -- 目標當前血量百分比
		local perAbsorb = (totalAbsorb > lostHealth) and (totalAbsorb - lostHealth)/max or 0 -- 盾吸收值轉換血量百分比
		
		-- 轉換計量條的相乘係數
		local value
		if totalAbsorb >= max then
			-- 盾大於總血量：長度等於當前血量
			value = curHealth
		else
			-- 盾小於總血量：長度等於百分比
			value = perAbsorb
		end

		if perAbsorb == 0 then
			-- value 偶爾會無法運算，hasOverAbsorb成立但不滿足perAbsorb條件？
			self.overAbsorb:Hide()
		else
			self.overAbsorb:Show()
			
			if F.IsAny(style, "VL", "VR") then
				self.overAbsorb:SetHeight(value * health:GetHeight())
			elseif F.IsAny(style, "H", "BP", "BPP", "R") then
				self.overAbsorb:SetWidth(value * health:GetWidth())
			end
		end
	end
end
]]--