local _, ns = ...
local C, F, G, T = unpack(ns)

local UnitAffectingCombat = UnitAffectingCombat
local GetRuneCooldown = GetRuneCooldown
local UnitIsConnected, UnitIsGhost = UnitIsConnected, UnitIsGhost
local CreateFrame = CreateFrame
local C_Timer_After = C_Timer.After
local C_UnitAuras_GetPlayerAuraBySpellID = C_UnitAuras.GetPlayerAuraBySpellID

-- 在施法條等元素的建立函式裡，self.Castbar 中的 self 指的是所屬框架，即頭像本身
-- 而在施法條、光環、副資源等元素的 PostUpdate 中，self 指的是施法條等元素自身
-- 為了防止搞混，PostUpdate 寫為 function(element, unit)
-- 如果在這裡需要調用頭像本身，element.__owner 快取時命名為 parentFrame

--===================================================--
-----------------    [[ General ]]    -----------------
--===================================================--

-- [[ 通用的 multiplier postupdate ]] -- 

-- 建立著色背景與固定黑色底層
T.CreateMultiplierBG = function(element, multiplier)
	local bg = element:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	bg:SetTexture(G.media.blank)
	bg.multiplier = multiplier or 0.3
	element.bg = bg

	bg:SetDrawLayer("BACKGROUND", 1)

	local shade = element:CreateTexture(nil, "BACKGROUND", nil, 0)
	shade:SetAllPoints(bg)
	shade:SetColorTexture(0, 0, 0, 1)
	element.bgShade = shade
end

local function UpdateMultiplierBG(element, color, r, g, b)
	if not element.bg then return end

	if color and color.GetRGB then
		element.bg:SetVertexColor(color:GetRGB())
	elseif r then
		element.bg:SetVertexColor(r, g, b)
	else
		return
	end

	-- alpha 是單獨選項，與 RGB 分開設定避免 secret value
	element.bg:SetAlpha(element.bg.multiplier)
end

local function PostUpdateColor_ElementMultiBGColor(element, color)
	UpdateMultiplierBG(element, color)
end

T.PostUpdateColor_MultiBGColor = function(element, unit, color, r, g, b)
	UpdateMultiplierBG(element, color, r, g, b)
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

T.PostUpdateRestingIndicator = function(self, event, unit)
	if unit and unit ~= self.__unit then return end

	local element = self.RestingIndicator
	if not element then return end

	if IsResting() and (not UnitAffectingCombat(self.__unit)) then
		element:Show()
	else
		element:Hide()
	end
end

-- [[ 吸收盾 ]] --

local function SkinHealthAbsorbBar(bar, texture, r, g, b, a, tiled, blendMode)
	bar:SetStatusBarColor(r, g, b, a)

	local statusTexture = bar:GetStatusBarTexture()
	local addressMode = (tiled and "REPEAT") or "CLAMP"	-- 必須 REPEAT，只設定 SetHorizTile/SetVertTile 只會拉伸材質
	statusTexture:SetTexture(texture, addressMode, addressMode)
	statusTexture:SetHorizTile(tiled)
	statusTexture:SetVertTile(tiled)
	if blendMode then
		statusTexture:SetBlendMode(blendMode)
	end

	bar:SetMinMaxValues(0, 1)
	bar:SetValue(0)
	bar:EnableMouse(false)
end

-- 將 Health.DamageAbsorb 獲取的吸收盾數值同步給自訂的 OverDamageAbsorb，避免重複執行 prediction 查詢，節省資源
local function PostUpdateHealthPrediction(element, unit, cur, max, lossPerc)
	if element.__ruriPostUpdate then
		element.__ruriPostUpdate(element, unit, cur, max, lossPerc)
	end

	-- 限制 oUF Health calculator 取得的盾量上限為最大血量
	local overAbsorb = element.OverDamageAbsorb
	local amount = element.values:GetDamageAbsorbs()
	overAbsorb:SetMinMaxValues(0, max)
	overAbsorb:SetValue(amount)
end

-- [[ 吸收盾 ]] --

--創建時，增加一個是否創建治療吸收盾的判斷值

T.CreateHealthPrediction = function(self, createHealAbsorb)
	local Health = self.Health
	if not Health then return end

	-- 設定 Health calculator 對傷害吸收與治療吸收的截斷方式，吸收盾最多只到最大血量，治療吸收盾最多只到當前血量
	Health.damageAbsorbClampMode = Enum.UnitDamageAbsorbClampMode.MaximumHealth
	if createHealAbsorb then
		Health.healAbsorbClampMode = Enum.UnitHealAbsorbClampMode.CurrentHealth
	end

	local isVertical = F.IsAny(self.mystyle, "VL", "VR")
	local healthTexture = Health:GetStatusBarTexture()
	local frameLevel = Health:GetFrameLevel()

	-- 傷害吸收盾

	-- 顯示邏輯：
	-- 吸收盾：實際血量未滿時，盾先從血量往前長，形成有效血量條
	-- 溢出傷害吸收盾：有效血量 (血量+盾量) > 最大血量，溢出的盾從當前血量的位置往回長
	-- 舉例：
	-- 目前血量 80%、吸收盾數值為 50% 最大血量
	-- DamageAbsorbClip：由 80% 向 130% 填充，裁切後顯示 80%～100%，顯示長度為最大血量的 20%
	-- OverDamageAbsorbClip：由 100% 反向填充至 50%，裁切後顯示 50%～80%，顯示長度為最大血量的 30%

	local DamageAbsorbClip = CreateFrame("Frame", nil, Health)
	DamageAbsorbClip:SetAllPoints(Health)
	DamageAbsorbClip:SetFrameLevel(frameLevel + 1)
	DamageAbsorbClip:EnableMouse(false)
	DamageAbsorbClip:SetClipsChildren(true)

	local DamageAbsorb = F.CreateStatusbar(DamageAbsorbClip, nil, "ARTWORK")
	DamageAbsorb:SetFrameLevel(DamageAbsorbClip:GetFrameLevel() + 1)
	SkinHealthAbsorbBar(DamageAbsorb, G.media.absorb, .45, .8, .45, .6, true, "ADD")

	local OverDamageAbsorbClip = CreateFrame("Frame", nil, Health)
	OverDamageAbsorbClip:SetFrameLevel(frameLevel + 2)
	OverDamageAbsorbClip:EnableMouse(false)
	OverDamageAbsorbClip:SetClipsChildren(true)

	local OverDamageAbsorb = F.CreateStatusbar(OverDamageAbsorbClip, nil, "ARTWORK")
	OverDamageAbsorb:SetAllPoints(Health)
	OverDamageAbsorb:SetFrameLevel(OverDamageAbsorbClip:GetFrameLevel() + 1)
	OverDamageAbsorb:SetReverseFill(true)
	SkinHealthAbsorbBar(OverDamageAbsorb, G.media.absorb, .5, .9, .6, .5, true, "ADD")

	-- 治療吸收盾

	local HealAbsorb, OverHealAbsorbIndicator
	if createHealAbsorb then
		-- 從目前血量端點反向覆蓋血量
		HealAbsorb = F.CreateStatusbar(Health, nil, "ARTWORK")
		HealAbsorb:SetFrameLevel(frameLevel + 4)
		HealAbsorb:SetReverseFill(true)
		SkinHealthAbsorbBar(HealAbsorb, G.media.blank, 0, .8, 1, .5, false)

		-- 治療吸收大於當前血量時，在零血量端顯示溢出提示
		OverHealAbsorbIndicator = HealAbsorb:CreateTexture(nil, "OVERLAY")
		OverHealAbsorbIndicator:SetTexture("Interface\\RaidFrame\\Absorb-Overabsorb")
		OverHealAbsorbIndicator:SetBlendMode("ADD")
		OverHealAbsorbIndicator:SetDesaturated(true)
		OverHealAbsorbIndicator:SetVertexColor(0, .8, 1)
		OverHealAbsorbIndicator:SetAlpha(0)
	end

	if isVertical then
		DamageAbsorb:SetOrientation("VERTICAL")
		DamageAbsorb:SetPoint("LEFT", Health, "LEFT")
		DamageAbsorb:SetPoint("RIGHT", Health, "RIGHT")
		DamageAbsorb:SetPoint("BOTTOM", healthTexture, "TOP")

		OverDamageAbsorb:SetOrientation("VERTICAL")
		OverDamageAbsorbClip:SetPoint("BOTTOMLEFT", Health, "BOTTOMLEFT")
		OverDamageAbsorbClip:SetPoint("TOPRIGHT", healthTexture, "TOPRIGHT")

		if HealAbsorb then
			HealAbsorb:SetOrientation("VERTICAL")
			HealAbsorb:SetPoint("LEFT", Health, "LEFT")
			HealAbsorb:SetPoint("RIGHT", Health, "RIGHT")
			HealAbsorb:SetPoint("TOP", healthTexture, "TOP")

			-- 用 SetTexCoord 重新映射四角座標，SetRotation 旋轉非正方形材質可能顯示異常
			OverHealAbsorbIndicator:SetTexCoord(0, 1, 1, 1, 0, 0, 1, 0)
			OverHealAbsorbIndicator:SetPoint("BOTTOMLEFT", Health, "BOTTOMLEFT")
			OverHealAbsorbIndicator:SetPoint("BOTTOMRIGHT", Health, "BOTTOMRIGHT")
			OverHealAbsorbIndicator:SetHeight(6)
		end
	else
		DamageAbsorb:SetPoint("TOP", Health, "TOP")
		DamageAbsorb:SetPoint("BOTTOM", Health, "BOTTOM")
		DamageAbsorb:SetPoint("LEFT", healthTexture, "RIGHT")

		OverDamageAbsorbClip:SetPoint("TOPLEFT", Health, "TOPLEFT")
		OverDamageAbsorbClip:SetPoint("BOTTOMRIGHT", healthTexture, "BOTTOMRIGHT")

		if HealAbsorb then
			HealAbsorb:SetPoint("TOP", Health, "TOP")
			HealAbsorb:SetPoint("BOTTOM", Health, "BOTTOM")
			HealAbsorb:SetPoint("RIGHT", healthTexture, "RIGHT")

			OverHealAbsorbIndicator:SetPoint("TOPLEFT", Health, "TOPLEFT")
			OverHealAbsorbIndicator:SetPoint("BOTTOMLEFT", Health, "BOTTOMLEFT")
			OverHealAbsorbIndicator:SetWidth(6)
		end
	end

	Health.DamageAbsorb = DamageAbsorb
	Health.OverDamageAbsorb = OverDamageAbsorb
	if HealAbsorb then
		Health.HealAbsorb = HealAbsorb
		Health.OverHealAbsorbIndicator = OverHealAbsorbIndicator
	end
	-- 自製的溢出吸收盾，顯示精確長度，而非原生只有 Spark
	if Health.PostUpdate ~= PostUpdateHealthPrediction then
		Health.__ruriPostUpdate = Health.PostUpdate
		Health.PostUpdate = PostUpdateHealthPrediction
	end
end

--==================================================================--
------------------    [[ Resource: Post update ]]    -----------------
--==================================================================--

-- [[ 特殊能量文本 ]] --

local function PostUpdateAltPower(element, unit, cur)
	element.value:SetText(cur)
end

-- [[ 酒池文本 ]] --

local function PostUpdateStagger(element, cur)
	element.value:SetText(F.NumberAbbrValue(cur))
end

-- [[ 玩家資源布局更新 ]] --

-- 獲得職業資源排序
local function GetPlayerResourceOffsets(self)
	-- 坦克資源判斷
	local tankResource = self.TankResource
	local rows = tankResource and tankResource.rechargeBar:IsShown() and 1 or 0

	-- 職業資源判斷
	local classPower = self.ClassPower or self.Runes or self.Essence
	local hasClassResource =
		(classPower and classPower[1]:IsShown()) or
		(self.Stagger and self.Stagger:IsShown()) or
		(self.AdditionalPower and self.AdditionalPower:IsShown())

	-- 資源總數
	if hasClassResource then
		rows = rows + 1
	end

	-- 位置偏移
	local firstOffset = C.PPOffset
	local classOffset = (rows == 2 and C.PPOffset*2 + C.PPHeight) or firstOffset
	local auraOffset = C.PPOffset*(rows + 1) + C.PPHeight*rows

	return firstOffset, classOffset, auraOffset
end

-- 視目前副資源的顯示層數，更新玩家減益光環位置
T.UpdatePlayerDebuffsPosition = function(element, auraOffset)
	local parentFrame = element.__owner
	if not parentFrame then return end

	auraOffset = auraOffset or select(3, GetPlayerResourceOffsets(parentFrame))

	element:ClearAllPoints()

	-- AuraButton 背景向外擴 1px；分隔軸補足間距，另一軸則對齊狀態條邊緣。
	if parentFrame.mystyle == "VL" then
		element:SetPoint("BOTTOMLEFT", parentFrame.Health, "BOTTOMRIGHT", auraOffset + 1, 1)
	else
		element:SetPoint("BOTTOMLEFT", parentFrame.Health, "TOPLEFT", 1, auraOffset + 1)
	end
end

-- 更新職業資源位置
local function UpdateClassPowerPosition(element, classPowerOffset)
	local parentFrame = element.__owner
	if not parentFrame then return end

	local bar = element[1]
	if not bar then return end

	local style = parentFrame.mystyle

	bar:ClearAllPoints()
	if style == "BPP" then
		bar:SetPoint("TOPLEFT", parentFrame.Power, "BOTTOMLEFT", 0, -4)
		return
	end

	classPowerOffset = classPowerOffset or select(2, GetPlayerResourceOffsets(parentFrame))
	if style == "VL" then
		bar:SetPoint("BOTTOMLEFT", parentFrame, "BOTTOMRIGHT", classPowerOffset, 0)
	else
		bar:SetPoint("BOTTOMLEFT", parentFrame, "TOPLEFT", 0, classPowerOffset)
	end
end

-- 更新職業資源內部豆子排列
local function UpdateClassPowerBars(element, max)
	local parentFrame = element.__owner
	if not parentFrame then return end

	max = max or #element
	if max <= 0 then return end

	local style = parentFrame.mystyle

	for i = 1, max do
		local bar = element[i]
		if not bar then break end

		bar:ClearAllPoints()

		if style == "VL" then
			bar:SetOrientation("VERTICAL")
			bar:SetSize(C.PPHeight, (C.PWidth - (max-1)*C.PPOffset)/max)

			if i > 1 then
				bar:SetPoint("BOTTOM", element[i-1], "TOP", 0, C.PPOffset)
			end
		elseif style == "BPP" then
			bar:SetSize((C.PlayerPlateWidth - (max-1)*C.PPOffset)/max, C.PPHeight)

			if i > 1 then
				bar:SetPoint("LEFT", element[i-1], "RIGHT", C.PPOffset, 0)
			end
		else
			bar:SetSize((C.PWidth - (max-1)*C.PPOffset)/max, C.PPHeight)

			if i > 1 then
				bar:SetPoint("LEFT", element[i-1], "RIGHT", C.PPOffset, 0)
			end
		end
	end

	UpdateClassPowerPosition(element)
end

-- 更新坦克資源位置
local function UpdateTankResourcePosition(element, tankResourceOffset)
	local parentFrame = element.__owner
	if not parentFrame then return end

	local bar = element[1] or element.rechargeBar or element.__rechargeBar
	if not bar then return end

	local style = parentFrame.mystyle
	tankResourceOffset = tankResourceOffset or GetPlayerResourceOffsets(parentFrame)

	bar:ClearAllPoints()

	if style == "VL" then
		bar:SetPoint("BOTTOMLEFT", parentFrame, "BOTTOMRIGHT", tankResourceOffset, 0)
	else
		bar:SetPoint("BOTTOMLEFT", parentFrame, "TOPLEFT", 0, tankResourceOffset)
	end
end

-- 更新坦克資源內部排列
local function UpdateTankResourceBars(element)
	local parentFrame = element.__owner
	if not parentFrame then return end

	local max = #element
	if max <= 0 then return end

	local style = parentFrame.mystyle
	local rechargeBar = element.rechargeBar or element.__rechargeBar
	local chargeBarCount = element.chargeBarCount or element.__chargeBarCount

	if rechargeBar and chargeBarCount == 2 and element[1] and element[2] then
		local charge1 = element[1]
		local charge2 = element[2]
		local unitLength = (C.PWidth - 2*C.PPOffset) / 4

		charge1:ClearAllPoints()
		charge2:ClearAllPoints()
		rechargeBar:ClearAllPoints()

		if style == "VL" then
			charge1:SetOrientation("VERTICAL")
			charge2:SetOrientation("VERTICAL")
			rechargeBar:SetOrientation("VERTICAL")

			charge1:SetSize(C.PPHeight, unitLength)
			charge2:SetSize(C.PPHeight, unitLength)
			rechargeBar:SetSize(C.PPHeight, unitLength*2)

			charge2:SetPoint("BOTTOM", charge1, "TOP", 0, C.PPOffset)
			rechargeBar:SetPoint("BOTTOM", charge2, "TOP", 0, C.PPOffset)
		else
			charge1:SetSize(unitLength, C.PPHeight)
			charge2:SetSize(unitLength, C.PPHeight)
			rechargeBar:SetSize(unitLength*2, C.PPHeight)

			charge2:SetPoint("LEFT", charge1, "RIGHT", C.PPOffset, 0)
			rechargeBar:SetPoint("LEFT", charge2, "RIGHT", C.PPOffset, 0)
		end

		UpdateTankResourcePosition(element)
		return
	end

	for i = 1, max do
		local bar = element[i]
		if not bar then break end

		bar:ClearAllPoints()

		if style == "VL" then
			bar:SetOrientation("VERTICAL")
			bar:SetSize(C.PPHeight, (C.PWidth - (max-1)*C.PPOffset)/max)

			if i > 1 then
				bar:SetPoint("BOTTOM", element[i-1], "TOP", 0, C.PPOffset)
			end
		else
			bar:SetSize((C.PWidth - (max-1)*C.PPOffset)/max, C.PPHeight)

			if i > 1 then
				bar:SetPoint("LEFT", element[i-1], "RIGHT", C.PPOffset, 0)
			end
		end
	end

	UpdateTankResourcePosition(element)
end

-- 更新單條職業資源位置
local function UpdateSingleResourceLayout(element, resourceOffset)
	local parentFrame = element.__owner
	if not parentFrame then return end

	resourceOffset = resourceOffset or select(2, GetPlayerResourceOffsets(parentFrame))

	element:ClearAllPoints()

	if parentFrame.mystyle == "VL" then
		element:SetWidth(C.PPHeight)
		element:SetOrientation("VERTICAL")
		element:SetPoint("BOTTOMLEFT", parentFrame.Health, "BOTTOMRIGHT", resourceOffset, 0)
		element:SetPoint("TOPLEFT", parentFrame.Health, "TOPRIGHT", resourceOffset, 0)
	else
		element:SetHeight(C.PPHeight)
		element:SetOrientation("HORIZONTAL")
		element:SetPoint("BOTTOMLEFT", parentFrame.Health, "TOPLEFT", 0, resourceOffset)
		element:SetPoint("BOTTOMRIGHT", parentFrame.Health, "TOPRIGHT", 0, resourceOffset)
	end
end

local function ForceUpdateResource(element)
	if element and element.ForceUpdate then
		element:ForceUpdate()
	end
end

local function IsPlayerFrame(self)
	return self and (self.__unit == "player" or self.__realUnit == "player")
end

-- 同步 element 狀態後，使用同一份 offset 更新全部資源與光環位置。
local function UpdateResourceLayout(self)
	if not IsPlayerFrame(self) then return end

	ForceUpdateResource(self.TankResource)
	ForceUpdateResource(self.ClassPower)
	ForceUpdateResource(self.AdditionalPower)
	ForceUpdateResource(self.Runes)
	ForceUpdateResource(self.Essence)
	ForceUpdateResource(self.Stagger)

	local tankResourceOffset, classPowerOffset, auraOffset = GetPlayerResourceOffsets(self)

	if self.TankResource then UpdateTankResourcePosition(self.TankResource, tankResourceOffset) end
	if self.ClassPower then UpdateClassPowerPosition(self.ClassPower, classPowerOffset) end
	if self.AdditionalPower then UpdateSingleResourceLayout(self.AdditionalPower, classPowerOffset) end
	if self.Runes then UpdateClassPowerPosition(self.Runes, classPowerOffset) end
	if self.Essence then UpdateClassPowerPosition(self.Essence, classPowerOffset) end
	if self.Stagger then UpdateSingleResourceLayout(self.Stagger, classPowerOffset) end
	if self.Debuffs then T.UpdatePlayerDebuffsPosition(self.Debuffs, auraOffset) end
end

-- 合併同一批 visibility callback，並避免 ForceUpdate 期間重入
local playerResourceLayoutQueued
local function QueueResourceLayoutUpdate(self)
	if not IsPlayerFrame(self) then return end
	if playerResourceLayoutQueued then return end
	playerResourceLayoutQueued = true

	C_Timer_After(0.1, function()
		UpdateResourceLayout(self)
		playerResourceLayoutQueued = nil
	end)
end

local function PostResourceVisibility(element)
	QueueResourceLayoutUpdate(element.__owner)
end

T.InitializeResourceLayout = function(self)
	QueueResourceLayoutUpdate(self)
end

-- [[ 職業資源顏色 ]] --

-- 連擊點顏色
local cpColor = {
	{1, .7, .1},
	{1, .95, .4}, -- 滿豆
}

local POWER_TYPE_SOUL_FRAGMENTS = "SOUL_FRAGMENTS"
local SPELL_DARK_HEART = Constants.UnitPowerSpellIDs.DARK_HEART_SPELL_ID or 1225789
local SPELL_SILENCE_THE_WHISPERS = Constants.UnitPowerSpellIDs.SILENCE_THE_WHISPERS_SPELL_ID or 1227702
local SPELL_VOID_METAMORPHOSIS = Constants.UnitPowerSpellIDs.VOID_METAMORPHOSIS_SPELL_ID or 1217607

-- 更新顏色
local function PostUpdateClassPower(element, cur, max, hasCurChanged, hasMaxChanged, powerType)
	if not max or not cur then return end

	-- oUF 回傳順序為 cur, max, hasCurChanged, hasMaxChanged, powerType。
	-- 只在最大豆子數變化時重排，避免登入後等到數量變化才修正位置。
	if hasMaxChanged then
		UpdateClassPowerBars(element, max)
	end

	for i = 1, #element do
		-- 連擊點滿豆時變色
		if powerType == "COMBO_POINTS" then
			if max > 0 and cur == max then
				element[i]:SetStatusBarColor(unpack(cpColor[2]))
			else
				element[i]:SetStatusBarColor(unpack(cpColor[1]))
			end
		end
		-- 背景沿用目前資源條顏色
		if element[i].bg then
			local mu = element[i].bg.multiplier or 0.3
			local r, g, b = element[i]:GetStatusBarColor()
			element[i].bg:SetVertexColor(r * mu, g * mu, b * mu)
		end
	end
end

-- 靈魂碎片
local function PostUpdateSoulFragments(element, cur, max, hasCurChanged, hasMaxChanged, powerType, ...)
	PostUpdateClassPower(element, cur, max, hasCurChanged, hasMaxChanged, powerType, ...)

	local value = element.value
	if powerType ~= POWER_TYPE_SOUL_FRAGMENTS then
		value:SetText(nil)
		return
	end

	-- 從光環層數取得靈魂碎片數量
	local auraInfo
	if C_UnitAuras_GetPlayerAuraBySpellID(SPELL_VOID_METAMORPHOSIS) then
		auraInfo = C_UnitAuras_GetPlayerAuraBySpellID(SPELL_SILENCE_THE_WHISPERS)
	else
		auraInfo = C_UnitAuras_GetPlayerAuraBySpellID(SPELL_DARK_HEART)
	end

	value:SetText((auraInfo and auraInfo.applications) or 0)
	value:SetTextColor(element[1]:GetStatusBarColor())
end

-- [[ 符文 ]] --

local function OnUpdateRunes(element, elapsed)
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

local function PostUpdateRunes(element, runemap)
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
				rune:SetScript("OnUpdate", OnUpdateRunes)
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

--======================================================================--
------------------    [[ Resource: Create elements ]]    -----------------
--======================================================================--

-- [[ 職業資源 ]] --

T.CreateClassPower = function(self, unit)
	if not F.IsAny(G.myClass, "DEATHKNIGHT", "DEMONHUNTER", "DRUID", "EVOKER", "HUNTER", "MAGE", "MONK", "PALADIN", "ROGUE", "SHAMAN", "WARLOCK") then return end
	
	local isDK = G.myClass == "DEATHKNIGHT"
	local isDemonHunter = G.myClass == "DEMONHUNTER"
	local isEVOKER = G.myClass == "EVOKER"
	-- 同一個 player 可同時顯示在主玩家框與 BPP，後者需要獨立的全域框體名。
	local namePrefix = G.addon..unit..(self.mystyle == "BPP" and "_PlayerPlate" or "")
	-- DK 與自製 Essence 固定建立六格；官方 ClassPower 需要十格容納漩渦武器。
	local maxPoint = ((isDK or isEVOKER) and 6) or 10
	
	local ClassPower = {}
	
	for i = 1, maxPoint do
		ClassPower[i] = F.CreateStatusbar(self, namePrefix.."_ClassPowerBar"..i, "ARTWORK", nil, nil, 1, 1, 0, 1)
		ClassPower[i].border = F.CreateSD(ClassPower[i], ClassPower[i], 4)
		ClassPower[i]:SetFrameLevel(self:GetFrameLevel() + 2)
		
		-- 背景
		ClassPower[i].bg = ClassPower[i]:CreateTexture(nil, "BACKGROUND")
		ClassPower[i].bg:SetAllPoints()
		ClassPower[i].bg:SetTexture(G.media.blank)
		ClassPower[i].bg.multiplier = .3
		
		-- 只有 DK 符文需要在資源條上顯示冷卻秒數。
		if isDK then
			ClassPower[i].timer = F.CreateText(ClassPower[i], "OVERLAY", G.Font, G.NameFS, G.FontFlag, "CENTER")
			ClassPower[i].timer:SetPoint("CENTER", 0, 0)
		end
	end
	
	ClassPower.__owner = self
	UpdateClassPowerBars(ClassPower, maxPoint)
	
	if isDK then
		ClassPower.colorSpec = true
		ClassPower.sortOrder = "asc"
		self.Runes = ClassPower
		self.Runes.PostUpdate = PostUpdateRunes
	elseif isEVOKER then
		self.Essence = ClassPower
		self.Essence.color = {0.02, 0.9, 0.9}
		self.Essence.updateInterval = .1
		self.Essence.MaxChangeUpdate = UpdateClassPowerBars
	else
		self.ClassPower = ClassPower
		if self.mystyle ~= "BPP" then
			self.ClassPower.PostVisibility = PostResourceVisibility
		end

		if isDemonHunter and self.mystyle ~= "BPP" then
			ClassPower.value = F.CreateText(ClassPower[1], "OVERLAY", G.Font, G.NameFS, G.FontFlag, "RIGHT")
			ClassPower.value:SetPoint("RIGHT", self.Power.value, "LEFT", -C.PPOffset, 0)
			self.ClassPower.PostUpdate = PostUpdateSoulFragments
		else
			self.ClassPower.PostUpdate = PostUpdateClassPower
		end
	end
end

-- [[ 額外能量：暗牧鳥德元薩的法力 ]] --

T.CreateAddPower = function(self, unit)
	if not F.IsAny(G.myClass, "DRUID", "SHAMAN", "PRIEST") then return end
	
	-- 創建一個條
	local AddPower = F.CreateStatusbar(self, G.addon..unit.."_AddPowerBar", "ARTWORK", nil, nil, 1, 1, 0, 1)
	AddPower:SetFrameLevel(self:GetFrameLevel() + 2)
	AddPower.__owner = self
	UpdateSingleResourceLayout(AddPower)
	
	-- 選項
	AddPower.colorPower = true
	-- 背景
	T.CreateMultiplierBG(AddPower)
	-- 陰影
	AddPower.border = F.CreateSD(AddPower, AddPower, 4)
	-- 註冊到ouf
	self.AdditionalPower = AddPower
	self.AdditionalPower.PostUpdateColor = PostUpdateColor_ElementMultiBGColor
	self.AdditionalPower.PostVisibility = PostResourceVisibility
	-- 文本
	self.AdditionalPower.value = F.CreateText(self.AdditionalPower, "OVERLAY", G.Font, G.NameFS, G.FontFlag, "LEFT")
end

-- [[ 特殊能量 ]] --

T.CreateAltPowerBar = function(self, unit)
	local AltPower = F.CreateStatusbar(self, G.addon..unit.."_AltPowerBar", "ARTWORK", nil, nil, 1, 1, 0, 1)
	AltPower:SetFrameLevel(self:GetFrameLevel() + 2)
	
	-- 根據樣式創建條
	if self.mystyle == "H" then
		AltPower:SetHeight(C.PPHeight)
		AltPower:SetPoint("TOPLEFT", self.Power, "BOTTOMLEFT", 0, -C.PPOffset)
		AltPower:SetPoint("TOPRIGHT", self.Power, "BOTTOMRIGHT", 0, -C.PPOffset)
	else
		AltPower:SetWidth(C.PPHeight)
		AltPower:SetOrientation("VERTICAL")
		-- 垂直模式分別在左右兩側
		if self.mystyle == "VL" then
			AltPower:SetPoint("TOPRIGHT", self.Power, "TOPLEFT", -C.PPOffset, 0)
			AltPower:SetPoint("BOTTOMRIGHT", self.Power, "BOTTOMLEFT", -C.PPOffset, (C.PWidth - C.TOTWidth))
		elseif  self.mystyle == "VR" then
			AltPower:SetPoint("TOPLEFT", self.Power, "TOPRIGHT", C.PPOffset, 0)
			AltPower:SetPoint("BOTTOMLEFT", self.Power, "BOTTOMRIGHT", C.PPOffset, (C.PWidth - C.TOTWidth))
		end
	end
	
	-- 背景
	AltPower.bg = F.CreateBD(AltPower, AltPower, 1, .15, .15, .15, .6, 1)
	-- 陰影
	AltPower.border = F.CreateSD(AltPower, AltPower, 4)
	-- 註冊到ouf
	self.AlternativePower = AltPower
	self.AlternativePower.PostUpdate = PostUpdateAltPower
	-- 文本
	self.AlternativePower.value = F.CreateText(self.AlternativePower, "OVERLAY", G.Font, G.NameFS, G.FontFlag, "CENTER")
end

-- [[ 酒池 ]] --

T.CreateStagger = function(self, unit)
	if G.myClass ~= "MONK" then return end
	
	local Stagger = F.CreateStatusbar(self, G.addon..unit.."_StaggerBar", "ARTWORK", nil, nil, 1, 1, 0, 1)
	Stagger:SetFrameLevel(self:GetFrameLevel() + 2)
	Stagger.__owner = self
	UpdateSingleResourceLayout(Stagger)
	
	-- 背景
	T.CreateMultiplierBG(Stagger)
	-- 陰影
	Stagger.border = F.CreateSD(Stagger, Stagger, 4)
	-- 文本
	Stagger.value = F.CreateText(Stagger, "OVERLAY", G.Font, G.NameFS, G.FontFlag, nil)
	if self.mystyle == "VL" then
		Stagger.value:SetPoint("BOTTOMRIGHT", self.Power, "BOTTOMLEFT", -C.PPOffset, (G.NameFS + 2)*2)
		Stagger.value:SetJustifyH("RIGHT")
	else
		Stagger.value:SetPoint("CENTER", Stagger, 0, 0)
		Stagger.value:SetJustifyH("CENTER")
	end
	
	self.Stagger = Stagger
	self.Stagger.PostUpdate = PostUpdateStagger
	self.Stagger.PostUpdateColor = PostUpdateColor_ElementMultiBGColor
	self.Stagger.PostVisibility = PostResourceVisibility
end

-- [[ 坦克資源 ]] --

T.CreateTankResource = function(self, unit)
	-- 只為可能擁有坦克資源的職業建立框架，是否顯示交給 oUF_TankResource 判斷
	if not F.IsAny(G.myClass, "MONK", "PALADIN", "DEMONHUNTER", "WARRIOR", "DRUID") then return end

	local TankResource = {}
	local maxLength = 3

	TankResource.overrideSpellOptions = {
		["PALADIN"] = {
			[432472] = {1, .92, .55}
		}
	}
	TankResource.chargeBarCount = 2

    for i = 1, maxLength do
		TankResource[i] = F.CreateStatusbar(self, G.addon..unit.."_TankResourceBar"..i, "ARTWORK", nil, nil, 1, 1, 0, 1)
		TankResource[i].border = F.CreateSD(TankResource[i], TankResource[i], 4)
		TankResource[i]:SetFrameLevel(self:GetFrameLevel() + 2)
		
		-- 背景
		TankResource[i].bg = TankResource[i]:CreateTexture(nil, "BACKGROUND")
		TankResource[i].bg:SetAllPoints()
		TankResource[i].bg:SetTexture(G.media.blank)
		TankResource[i].bg.multiplier = .4

	end
	TankResource.rechargeBar = TankResource[maxLength]
	TankResource.__owner = self
	TankResource.PostVisibility = PostResourceVisibility
	UpdateTankResourceBars(TankResource)

	-- 建立後先隱藏，等 oUF_TankResource 接管顯示
	for i = 1, #TankResource do
		TankResource[i]:Hide()
	end

    -- 註冊到 oUF
    self.TankResource = TankResource
end
