local addon, ns = ...
local oUF = ns.oUF
local C, F, G, T = unpack(ns)

local UnitGetIncomingHeals, UnitGetTotalAbsorbs, UnitClass, UnitAffectingCombat = UnitGetIncomingHeals, UnitGetTotalAbsorbs, UnitClass, UnitAffectingCombat
local UnitHealth, UnitHealthMax, UnitPowerType, GetRuneCooldown = UnitHealth, UnitHealthMax, UnitPowerType, GetRuneCooldown
local UnitIsConnected, UnitIsDead, UnitIsGhost, UnitGUID, UnitIsPlayer = UnitIsConnected, UnitIsDead, UnitIsGhost, UnitGUID, UnitIsPlayer
local GetTime, format = GetTime, format
local CreateFrame, GetFrameLevel, SetFrameLevel = CreateFrame, GetFrameLevel, SetFrameLevel
local C_Timer_After = C_Timer.After
local C_ClassTalents_GetActiveConfigID = C_ClassTalents.GetActiveConfigID

-- 在 CreateCastbar 等創建元素的的 function 裡，self.Castbar 中的 self 指的是所屬框架，即頭像本身
-- 而在施法條、光環、副資源等元素的 PostUpdate 中，self 指的是施法條等元素自身
-- 為了防止搞混，PostUpdate 寫為 function(element, unit)
-- 如果在這裡需要調用頭像本身，element.__owner 快取時命名為 parentFrame

--===================================================--
-----------------    [[ General ]]    -----------------
--===================================================--

-- [[ 通用的 multiplier postupdate ]] -- 

local function UpdateMultiplierBG(element, color, r, g, b)
	if not element.bg then return end

	if color and color.GetRGB then
		r, g, b = color:GetRGB()
	end

	if not r then return end

	local mu = element.bg.multiplier or 0.3
	element.bg:SetVertexColor(r * mu, g * mu, b * mu)
end

T.PostUpdateColor_ElementMultiBGColor = function(element, color)
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
--[[
T.CombatPostUpdate = function(element, inCombat)
	local rest = IsResting() 
	if inCombat then
		element.__owner.RestingIndicator:SetAlpha(0)
	elseif rest then
		element.__owner.RestingIndicator:SetAlpha(1)
	end
end
]]--
--[[
T.PostUpdateResting = function(element, isResting)
	if isResting then
		element:SetAlpha(1)
	else
		element:SetAlpha(0)
	end
end
]]--
--==================================================================--
------------------    [[ Resource: Post update ]]    -----------------
--==================================================================--

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

-- [[ 玩家資源布局更新 ]] --

-- 位置布局
T.GetPlayerResourceLayout = function()
	-- F.SpecCheck(): 1=只有光環，2=一層資源+光環，3=兩層資源+光環
	local spec = F.SpecCheck()
	local rows = spec - 1
	local firstOffset = C.PPOffset
	local classOffset = (rows == 2 and C.PPOffset*2 + C.PPHeight) or firstOffset
	local auraOffset = C.PPOffset*(rows + 1) + C.PPHeight*rows

	return rows, firstOffset, classOffset, auraOffset
end

local playerResourceLayoutQueued

-- 更新職業資源位置
local function UpdateClassPowerPosition(element)
	local parentFrame = element.__owner
	if not parentFrame then return end

	local bar = element[1]
	if not bar then return end

	local style = parentFrame.mystyle
	local _, _, classPowerOffset = T.GetPlayerResourceLayout()

	bar:ClearAllPoints()

	if style == "VL" then
		bar:SetPoint("BOTTOMLEFT", parentFrame, "BOTTOMRIGHT", classPowerOffset, 0)
	elseif style == "NPP" or style == "BPP" then
		if C.NumberStylePP then
			bar:SetPoint("TOP", parentFrame.HealthText, "BOTTOM", -(C.PlayerNPWidth - 3*C.PPOffset)/2, -C.PPOffset)
		else
			bar:SetPoint("TOPLEFT", parentFrame.Power, "BOTTOMLEFT", 0, -4)
		end
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
		elseif style == "NPP" or style == "BPP" then
			bar:SetSize((C.PlayerNPWidth - (max-1)*C.PPOffset)/max, C.PPHeight)

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
local function UpdateTankResourcePosition(element)
	local parentFrame = element.__owner
	if not parentFrame then return end

	local bar = element[1]
	if not bar then return end

	local style = parentFrame.mystyle
	local _, tankResourceOffset = T.GetPlayerResourceLayout()

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

-- 更新酒池位置
local function UpdateStaggerLayout(element)
	local parentFrame = element.__owner
	if not parentFrame then return end

	local _, _, staggerOffset = T.GetPlayerResourceLayout()

	element:ClearAllPoints()

	if parentFrame.mystyle == "VL" then
		element:SetWidth(C.PPHeight)
		element:SetOrientation("VERTICAL")
		element:SetPoint("BOTTOMLEFT", parentFrame.Health, "BOTTOMRIGHT", staggerOffset, 0)
		element:SetPoint("TOPLEFT", parentFrame.Health, "TOPRIGHT", staggerOffset, 0)
	else
		element:SetHeight(C.PPHeight)
		element:SetPoint("BOTTOMLEFT", parentFrame.Health, "TOPLEFT", 0, staggerOffset)
		element:SetPoint("BOTTOMRIGHT", parentFrame.Health, "TOPRIGHT", 0, staggerOffset)
	end
end

-- 更新額外能量位置
local function UpdateAddPowerLayout(element)
	local parentFrame = element.__owner
	if not parentFrame then return end

	local _, _, additionalPowerOffset = T.GetPlayerResourceLayout()

	element:ClearAllPoints()

	if parentFrame.mystyle == "VL" then
		element:SetWidth(C.PPHeight)
		element:SetOrientation("VERTICAL")
		element:SetPoint("BOTTOMLEFT", parentFrame.Health, "BOTTOMRIGHT", additionalPowerOffset, 0)
		element:SetPoint("TOPLEFT", parentFrame.Health, "TOPRIGHT", additionalPowerOffset, 0)
	else
		element:SetHeight(C.PPHeight)
		element:SetOrientation("HORIZONTAL")
		element:SetPoint("BOTTOMLEFT", parentFrame.Health, "TOPLEFT", 0, additionalPowerOffset)
		element:SetPoint("BOTTOMRIGHT", parentFrame.Health, "TOPRIGHT", 0, additionalPowerOffset)
	end
end

-- 統籌更新資源位置
local function UpdateResourceLayout(self)
	if not self or self.unit ~= "player" then return end

	if self.TankResource then
		if self.TankResource.ForceUpdate then self.TankResource:ForceUpdate() end
		UpdateTankResourcePosition(self.TankResource)
	end

	if self.ClassPower then
		if self.ClassPower.ForceUpdate then self.ClassPower:ForceUpdate() end
		UpdateClassPowerPosition(self.ClassPower)
	end

	if self.AdditionalPower then
		if self.AdditionalPower.ForceUpdate then self.AdditionalPower:ForceUpdate() end
		UpdateAddPowerLayout(self.AdditionalPower)
	end

	if self.Runes then UpdateClassPowerPosition(self.Runes) end
	if self.Essence then UpdateClassPowerPosition(self.Essence) end
	if self.Stagger then UpdateStaggerLayout(self.Stagger) end
	if self.Debuffs and T.UpdatePlayerDebuffsLayout then T.UpdatePlayerDebuffsLayout(self.Debuffs) end
end

-- 執行更新，延遲以避免多事件連續觸發
local function QueueResourceLayoutUpdate(self, event, arg1)
	if event == "PLAYER_SPECIALIZATION_CHANGED" and arg1 ~= "player" then return end
	if event == "TRAIT_CONFIG_UPDATED" and C_ClassTalents_GetActiveConfigID() ~= arg1 then return end
	if playerResourceLayoutQueued then return end
	playerResourceLayoutQueued = true

	C_Timer_After(0.1, function()
		playerResourceLayoutQueued = nil

		UpdateResourceLayout(self)
	end)
end

-- 註冊更新用的事件：切專精/切天賦
T.RegisterResourceLayout = function(self)
	if not self or self.unit ~= "player" then return end

	self:RegisterEvent("PLAYER_ENTERING_WORLD", QueueResourceLayoutUpdate, true)
	self:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED", QueueResourceLayoutUpdate, true)
	self:RegisterEvent("ACTIVE_PLAYER_SPECIALIZATION_CHANGED", QueueResourceLayoutUpdate, true)
	self:RegisterEvent("PLAYER_TALENT_UPDATE", QueueResourceLayoutUpdate, true)
	self:RegisterEvent("SPELLS_CHANGED", QueueResourceLayoutUpdate, true)
	self:RegisterEvent("TRAIT_CONFIG_UPDATED", QueueResourceLayoutUpdate, true)

	UpdateResourceLayout(self)
end

-- [[ 職業資源顏色 ]] --

-- 連擊點顏色
local cpColor = {
	{1, .7, .1},
	{1, .95, .4}, -- 滿豆
}

-- 更新顏色
T.PostUpdateClassPower = function(element, cur, max, MaxChanged, powerType)
	if not max or not cur then return end

	if MaxChanged then
		UpdateClassPowerBars(element, max)
	end

	for i = 1, 7 do
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

--======================================================================--
------------------    [[ Resource: Create elements ]]    -----------------
--======================================================================--

-- [[ 職業資源 ]] --

T.CreateClassPower = function(self, unit)
	if not F.IsAny(G.myClass, "PRIEST", "MAGE", "WARLOCK", "ROGUE", "MONK", "DRUID", "PALADIN", "DEATHKNIGHT", "EVOKER") then return end
	--if F.IsAny(G.myClass, "WARRIOR", "HUNTER", "SHAMAN") then return end
	
	local isDK = G.myClass == "DEATHKNIGHT"
	local isEVOKER = G.myClass == "EVOKER"
	local maxPoint = (isDK and 6) or (isEVOKER and 5) or 7
	
	local ClassPower = {}
	
	for i = 1, maxPoint do
		ClassPower[i] = F.CreateStatusbar(self, G.addon..unit.."_ClassPowerBar"..i, "ARTWORK", nil, nil, 1, 1, 0, 1)
		ClassPower[i].border = F.CreateSD(ClassPower[i], ClassPower[i], 4)
		ClassPower[i]:SetFrameLevel(self:GetFrameLevel() + 2)
		
		-- 背景
		ClassPower[i].bg = ClassPower[i]:CreateTexture(nil, "BACKGROUND")
		ClassPower[i].bg:SetAllPoints()
		ClassPower[i].bg:SetTexture(G.media.blank)
		ClassPower[i].bg.multiplier = .3
		
		if isDK or isEVOKER then
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
		self.Runes.PostUpdate = T.PostUpdateRunes
	elseif isEVOKER then
		self.Essence = ClassPower
		self.Essence.color = {0.02, 0.9, 0.9}
		self.Essence.updateInterval = .1
	else
		self.ClassPower = ClassPower
		self.ClassPower.PostUpdate = T.PostUpdateClassPower
	end
end

-- [[ 額外能量：暗牧鳥德元薩的法力 ]] --

T.CreateAddPower = function(self, unit)
	if not F.IsAny(G.myClass, "DRUID", "SHAMAN", "PRIEST") then return end
	
	-- 創建一個條
	local AddPower = F.CreateStatusbar(self, G.addon..unit.."_AddPowerBar", "ARTWORK", nil, nil, 1, 1, 0, 1)
	AddPower:SetFrameLevel(self:GetFrameLevel() + 2)
	AddPower.__owner = self
	UpdateAddPowerLayout(AddPower)
	
	-- 選項
	AddPower.colorPower = true
	-- 背景
	AddPower.bg = AddPower:CreateTexture(nil, "BACKGROUND")
	AddPower.bg:SetAllPoints()
	AddPower.bg:SetTexture(G.media.blank)
	AddPower.bg.multiplier = .3
	-- 陰影
	AddPower.border = F.CreateSD(AddPower, AddPower, 4)
	-- 註冊到ouf
	self.AdditionalPower = AddPower
	self.AdditionalPower.PostUpdateColor = T.PostUpdateColor_ElementMultiBGColor
	self.AdditionalPower.PostVisibility = function(element)
		local parentFrame = element.__owner
		if parentFrame then UpdateResourceLayout(parentFrame) end
	end
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
	self.AlternativePower.PostUpdate = T.PostUpdateAltPower
	--self.AlternativePower.PostUpdateColor = T.PostUpdateColor_ElementMultiBGColor
	-- 文本
	self.AlternativePower.value = F.CreateText(self.AlternativePower, "OVERLAY", G.Font, G.NameFS, G.FontFlag, "CENTER")
end

-- [[ 酒池 ]] --

T.CreateStagger = function(self, unit)
	if G.myClass ~= "MONK" then return end
	
	local Stagger = F.CreateStatusbar(self, G.addon..unit.."_StaggerBar", "ARTWORK", nil, nil, 1, 1, 0, 1)
	Stagger:SetFrameLevel(self:GetFrameLevel() + 2)
	Stagger.__owner = self
	UpdateStaggerLayout(Stagger)
	
	-- 背景
	Stagger.bg = Stagger:CreateTexture(nil, "BACKGROUND")
	Stagger.bg:SetAllPoints()
	Stagger.bg:SetTexture(G.media.blank)
	Stagger.bg.multiplier = .3
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
	self.Stagger.PostUpdate = T.PostUpdateStagger
	self.Stagger.PostUpdateColor = T.PostUpdateColor_ElementMultiBGColor
end


-- [[ 預估治療 ]] --

T.CreateHealthPrediction = function(self, unit)
	-- Why GetSize()?
	-- Unitframe和Raidframe的self大小等於self.health大小，且創建時用了Custom API，size是nil
	-- Nameplate的self是點擊範圍，self.health是元素實際大小
	-- Unitframe和Raidframe的吸收盾錨點相反是因為血量條反轉
	
	-- 吸收盾
	local abb = F.CreateStatusbar(self, G.addon..unit.."_AbsorbBar", "ARTWORK", nil, nil, 0, .5, .8, .5)
	abb:SetFrameLevel(self:GetFrameLevel() + 2)
	
	if F.IsAny(self.mystyle, "VL", "VR") then
		-- 直式
		abb:SetOrientation("VERTICAL")
		abb:SetSize(self:GetSize())
		abb:SetPoint("BOTTOM", self.Health:GetStatusBarTexture(), "BOTTOM")
	elseif F.IsAny(self.mystyle, "H", "R") then
		-- 橫式
		abb:SetSize(self:GetSize())
		abb:SetPoint("LEFT", self.Health:GetStatusBarTexture(), "LEFT")
	elseif F.IsAny(self.mystyle, "BP", "BPP") then
		-- 條形名條
		abb:SetSize(self.Health:GetSize())
		abb:SetPoint("LEFT", self.Health:GetStatusBarTexture(), "RIGHT")
	end
	
	-- 過量吸收盾
	local abbo = self.Health:CreateTexture(nil, "OVERLAY")
	abbo:SetTexture(G.media.blank, true, true)
	abbo:SetBlendMode("ADD")
	abbo:SetVertexColor( 0, .5, .8, .7)
	
	if F.IsAny(self.mystyle, "VL", "VR") then
		-- 直式
		abbo:SetSize(self:GetSize())
		abbo:SetPoint("TOP", self.Health:GetStatusBarTexture(), "BOTTOM")
	elseif F.IsAny(self.mystyle, "H", "R") then
		-- 橫式
		abbo:SetSize(self:GetSize())
		abbo:SetPoint("RIGHT", self.Health:GetStatusBarTexture(), "LEFT")
	elseif F.IsAny(self.mystyle, "BP", "BPP") then
		-- 條形名條
		abbo:SetSize(self.Health:GetSize())
		abbo:SetPoint("RIGHT", self.Health:GetStatusBarTexture(), "RIGHT")
	end

	self.HealthPrediction = {
        absorbBar = abb,	-- 吸收盾
        -- healAbsorbBar
		overAbsorb = abbo,	-- 過量吸收盾
		-- overHealAbsorb
        frequentUpdates = true,
		maxOverflow = 1.01,
    }
	self.HealthPrediction.PostUpdate = T.PostUpdateHealthPrediction
end

-- [[ 坦克資源 ]] --

T.CreateTankResource = function(self, unit)
	local TankResource = {}
	local maxLength = 2

	TankResource.overrideSpellOptions = {
		["PALADIN"] = {
			[432459] = {1, 1, 0},
			[432472] = {0, 1, .92}
		}
	}
	TankResource.colors = {
		["PALADIN"] = {1, 1, 0},
	}

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
	--[[
	TankResource.colors = {
		["WARRIOR"] = {.2,.5,.7},
		["PALADIN"] = {1, 1, 0},
		["DEMONHUNTER"] = {.7,.6,.4},
		["MONK"] = {.7,.6,.4},
	}
	]]--
	TankResource.__owner = self
	UpdateTankResourceBars(TankResource)

    -- 註冊到 oUF
    self.TankResource = TankResource
end
