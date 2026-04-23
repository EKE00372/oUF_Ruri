local addon, ns = ...
local oUF = ns.oUF
local C, F, G, T = unpack(ns)

local UnitGetIncomingHeals, UnitGetTotalAbsorbs, UnitClass, UnitAffectingCombat = UnitGetIncomingHeals, UnitGetTotalAbsorbs, UnitClass, UnitAffectingCombat
local UnitHealth, UnitHealthMax, UnitPowerType, GetRuneCooldown = UnitHealth, UnitHealthMax, UnitPowerType, GetRuneCooldown
local UnitIsConnected, UnitIsDead, UnitIsGhost, UnitGUID, UnitIsPlayer = UnitIsConnected, UnitIsDead, UnitIsGhost, UnitGUID, UnitIsPlayer
local GetTime, format = GetTime, format
local GetFrameLevel, SetFrameLevel = GetFrameLevel, SetFrameLevel

-- 在 CreateCastbar 等創建元素的的 function 裡，self.Castbar 中的 self 指的是頭像本身
-- 而在施法條、光環、副資源等元素的 PostUpdate 中，self 指的是 self.Castbar，即施法條元素自身
-- 為了防止搞混，PostUpdate 寫為 function(element, unit)


--===================================================--
-----------------    [[ General ]]    -----------------
--===================================================--

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
	local index = GetSpecialization() or 0
	local id = GetSpecializationInfo(index)
	
	local ClassPower = {}
	
	for i = 1, maxPoint do
		-- 創建總體條
		ClassPower[i] = F.CreateStatusbar(self, G.addon..unit.."_ClassPowerBar"..i, "ARTWORK", nil, nil, 1, 1, 0, 1)
		ClassPower[i].border = F.CreateSD(ClassPower[i], ClassPower[i], 4)
		ClassPower[i]:SetFrameLevel(self:GetFrameLevel() + 2)
		-- 背景
		ClassPower[i].bg = ClassPower[i]:CreateTexture(nil, "BACKGROUND")
		ClassPower[i].bg:SetAllPoints()
		ClassPower[i].bg:SetTexture(G.media.blank)
		ClassPower[i].bg.multiplier = .3
		-- 直式判斷：定位每個豆子
		if self.mystyle == "VL" then
			ClassPower[i]:SetOrientation("VERTICAL")
			ClassPower[i]:SetSize(C.PPHeight, (C.PWidth - (maxPoint-1)*C.PPOffset)/maxPoint)
			
			if i == 1 then
				ClassPower[i]:SetPoint("BOTTOMLEFT", self, "BOTTOMRIGHT", C.PPOffset, 0)  
			else
				ClassPower[i]:SetPoint("BOTTOM", ClassPower[i-1], "TOP", 0, C.PPOffset)
			end
		elseif self.mystyle == "NPP" or self.mystyle == "BPP" then
			ClassPower[i]:SetSize((C.PlayerNPWidth - (maxPoint-1)*C.PPOffset)/maxPoint, C.PPHeight)
			
			if C.NumberStylePP then
				if i == 1 then
					ClassPower[i]:SetPoint("TOP", self.HealthText, "BOTTOM", -(C.PlayerNPWidth - 3*C.PPOffset)/2, -C.PPOffset)
				else
					ClassPower[i]:SetPoint("LEFT", ClassPower[i-1], "RIGHT", C.PPOffset, 0)
				end
			else
				if i == 1 then
					ClassPower[i]:SetPoint("TOPLEFT", self.Power, "BOTTOMLEFT", 0, -4)
				else
					ClassPower[i]:SetPoint("LEFT", ClassPower[i-1], "RIGHT", C.PPOffset, 0)
				end
			end
		else
			ClassPower[i]:SetSize((C.PWidth - (maxPoint-1)*C.PPOffset)/maxPoint, C.PPHeight)
			
			if i == 1 then
				ClassPower[i]:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 0, C.PPOffset)
			else
				ClassPower[i]:SetPoint("LEFT", ClassPower[i-1], "RIGHT", C.PPOffset, 0)
			end
		end
		
		if isDK or isEVOKER then
			ClassPower[i].timer = F.CreateText(ClassPower[i], "OVERLAY", G.Font, G.NameFS, G.FontFlag, "CENTER")
			ClassPower[i].timer:SetPoint("CENTER", 0, 0)
		end
	end
	
	-- 註冊到ouf並整合符文顯示
	if isDK then
		ClassPower.colorSpec = true
		ClassPower.sortOrder = "asc"
		self.Runes = ClassPower
		self.Runes.PostUpdate = T.PostUpdateRunes
	elseif isEVOKER then
		self.Essence = ClassPower
		self.Essence.color = {0.02, 0.9, 0.9}
		self.updateInterval = .1
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
	
	if C.vertPlayer then
		AddPower:SetWidth(C.PPHeight)
		AddPower:SetOrientation("VERTICAL")
		AddPower:SetPoint("BOTTOMLEFT", self.Health, "BOTTOMRIGHT", C.PPOffset, 0)
		AddPower:SetPoint("TOPLEFT", self.Health, "TOPRIGHT", C.PPOffset, 0)
	else
		AddPower:SetHeight(C.PPHeight)
		AddPower:SetPoint("BOTTOMLEFT", self.Health, "TOPLEFT", 0, C.PPOffset)
		AddPower:SetPoint("BOTTOMRIGHT", self.Health, "TOPRIGHT", 0, C.PPOffset)
	end
	
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
	self.AdditionalPower.PostUpdateColor = T.PostUpdatemMultiBGColor
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
	AltPower.bg = F.CreateBD(AltPower, AltPower, 1, .15, .15, .15, .6)
	-- 陰影
	AltPower.border = F.CreateSD(AltPower, AltPower, 4)
	-- 註冊到ouf
	self.AlternativePower = AltPower
	self.AlternativePower.PostUpdate = T.PostUpdateAltPower
	--self.AlternativePower.PostUpdateColor = T.PostUpdatemMultiBGColor
	-- 文本
	self.AlternativePower.value = F.CreateText(self.AlternativePower, "OVERLAY", G.Font, G.NameFS, G.FontFlag, "CENTER")
	--self:Tag(self.AlternativePower.value, "[altpower]") --不用這個，用postupdate
end

-- [[ 酒池 ]] --

T.CreateStagger = function(self, unit)
	if G.myClass ~= "MONK" then return end
	
	local Stagger = F.CreateStatusbar(self, G.addon..unit.."_StaggerBar", "ARTWORK", nil, nil, 1, 1, 0, 1)
	Stagger:SetFrameLevel(self:GetFrameLevel() + 2)
	
	if C.vertPlayer then
		Stagger:SetWidth(C.PPHeight)
		Stagger:SetOrientation("VERTICAL")
		Stagger:SetPoint("BOTTOMLEFT", self.Health, "BOTTOMRIGHT", C.PPOffset, 0)
		Stagger:SetPoint("TOPLEFT", self.Health, "TOPRIGHT", C.PPOffset, 0)
	else	
		Stagger:SetHeight(C.PPHeight)
		Stagger:SetPoint("BOTTOMLEFT", self.Health, "TOPLEFT", 0, C.PPOffset)
		Stagger:SetPoint("BOTTOMRIGHT", self.Health, "TOPRIGHT", 0, C.PPOffset)
	end
	
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
	-- 註冊到ouf
	self.Stagger = Stagger
	self.Stagger.PostUpdate = T.PostUpdateStagger
	self.Stagger.PostUpdateColor = T.PostUpdatemMultiBGColor
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

    for i = 1, maxLength do
		TankResource[i] = F.CreateStatusbar(self, G.addon..unit.."_TankResourceBar"..i, "ARTWORK", nil, nil, 1, 1, 0, 1)
		TankResource[i].border = F.CreateSD(TankResource[i], TankResource[i], 4)
		TankResource[i]:SetFrameLevel(self:GetFrameLevel() + 2)
		
		-- 背景
		TankResource[i].bg = TankResource[i]:CreateTexture(nil, "BACKGROUND")
		TankResource[i].bg:SetAllPoints()
		TankResource[i].bg:SetTexture(G.media.blank)
		TankResource[i].bg.multiplier = .4

		if self.mystyle == "VL" then
			-- 單獨的每個豆子
			TankResource[i]:SetOrientation("VERTICAL")
			TankResource[i]:SetSize(C.PPHeight, (C.PWidth - C.PPOffset)/2)
			
			if F.IsAny(G.myClass, "DEATHKNIGHT", "MONK") then
				-- DK的在符文前面，武僧的在酒池前面
				if i == 1 then
					TankResource[i]:SetPoint("BOTTOMLEFT", self, "BOTTOMRIGHT", C.PPOffset*2+C.PPHeight, 0)
				else
					TankResource[i]:SetPoint("BOTTOM", TankResource[i-1], "TOP", 0, C.PPOffset)
				end
			else
				if i == 1 then
					TankResource[i]:SetPoint("BOTTOMLEFT", self, "BOTTOMRIGHT", C.PPOffset, 0)
				else
					TankResource[i]:SetPoint("BOTTOM", TankResource[i-1], "TOP", 0, C.PPOffset)
				end
			end
		else
			TankResource[i]:SetSize((C.PWidth - C.PPOffset)/2, C.PPHeight)
			
			if F.IsAny(G.myClass, "DEATHKNIGHT", "MONK") then
				-- DK的在符文上面，武僧的在酒池上面
				if i == 1 then
					TankResource[i]:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 0, C.PPOffset*2+C.PPHeight)
				else
					TankResource[i]:SetPoint("LEFT", TankResource[i-1], "RIGHT", C.PPOffset, 0)
				end
			else
				if i == 1 then
					TankResource[i]:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 0, C.PPOffset)
				else
					TankResource[i]:SetPoint("LEFT", TankResource[i-1], "RIGHT", C.PPOffset, 0)
				end
			end
		end
    end
	--[[
	TankResource.colors = {
		["WARRIOR"] = {.2,.5,.7},
		["PALDAIN"] = {1, 1, 0},
		["DEMONHUNTER"] = {.7,.6,.4},
		["MONK"] = {.7,.6,.4},
	}
	]]--
    -- Register with oUF
    self.TankResource = TankResource
end
