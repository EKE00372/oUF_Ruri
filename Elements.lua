local addon, ns = ...
local oUF = ns.oUF
local C, F, G, T = unpack(ns)

-- elements: create elements

--===================================================--
-----------------    [[ Castbar ]]    -----------------
--===================================================--

-- [[ 嵌入施法條 ]] --

T.CreateCastbar = function(self, unit)
	-- 創建一個條
	local Castbar = F.CreateStatusbar(self, G.addon..unit.."_CastBar", "ARTWORK", nil, nil, 0, 0, 0, 0)
	Castbar:SetAllPoints(self.Health)
	Castbar:SetFrameLevel(self:GetFrameLevel() + 4)
	
	-- 圖示
	Castbar.Icon = Castbar:CreateTexture(nil, "OVERLAY", nil, 1)
	Castbar.Icon:SetSize(C.PHeight + C.PPHeight*2, C.PHeight + C.PPHeight*2)
	Castbar.Icon:SetTexCoord(.08, .92, .08, .92)
	-- 邊框
	Castbar.Border = F.CreateBD(Castbar, Castbar.Icon, 1, 0, 0, 0, 1)
	-- 陰影
	Castbar.Shadow = F.CreateSD(Castbar, Castbar.Border, 4)
	
	-- 文本
	Castbar.Text = F.CreateText(Castbar, "OVERLAY", G.Font, G.NameFS, G.FontFlag, nil)
	Castbar.Time = F.CreateText(Castbar, "OVERLAY", G.Font, G.NameFS, G.FontFlag, nil)
	
	-- 進度高亮
	Castbar.Spark = Castbar:CreateTexture(nil, "OVERLAY", nil, -1)
	Castbar.Spark:SetTexture(G.media.spark)
	Castbar.Spark:SetBlendMode("ADD")
	Castbar.Spark:SetVertexColor(1, 1, .85, .8)
	
	-- 隊列
	--Castbar.SafeZone = Castbar:CreateTexture(nil, "OVERLAY")
	--Castbar.SafeZone:SetAlpha(.6)
	
	-- 橫豎的spark不一樣
	if self.mystyle ~= "H" then
		Castbar:SetOrientation("VERTICAL")
		Castbar.Spark:SetRotation(math.rad(90))	-- spark材質也要轉90度
		Castbar.Spark:SetSize(C.PHeight, C.PHeight)
		Castbar.Spark:SetPoint("TOP", Castbar:GetStatusBarTexture(), 0, 0)
	else
		Castbar.Spark:SetSize(C.PHeight, C.PHeight)
		Castbar.Spark:SetPoint("RIGHT", Castbar:GetStatusBarTexture(), 0, 0)
	end
	
	-- 選項
	Castbar.timeToHold = 0.05
	-- 註冊到ouf
	self.Castbar = Castbar
	self.Castbar.PostCastStart = T.PostCastStart			-- 開始施法
	self.Castbar.PostCastStop = T.PostCastStop				-- 施法結束
	self.Castbar.CustomTimeText = T.CustomTimeText			-- 施法時間
	self.Castbar.CustomDelayText = T.CustomTimeText			-- 施法時間
	self.Castbar.PostCastFail = T.PostCastFailed			-- 施法失敗
	self.Castbar.PostCastInterruptible = T.PostUpdateCast	-- 打斷狀態刷新
	-- 當前目標正在施法時，切換目標會重新獲取名字，防止丟失
	self:RegisterEvent("UNIT_NAME_UPDATE", T.PostCastStopUpdate)
	table.insert(self.__elements, T.PostCastStopUpdate)
end

-- [[ 獨立施法條 ]] --

T.CreateStandaloneCastbar = function(self, unit)
	-- 創建一個條
	local Castbar = F.CreateStatusbar(self, G.addon..unit.."_CastBar", "ARTWORK", nil, nil, .6, .6, .6, 1)
	Castbar:SetFrameLevel(self:GetFrameLevel() + 4)	
	-- 背景與邊框
	Castbar.BarBG = F.CreateBD(Castbar, Castbar, 1, .15, .15, .15, .4)
	-- 陰影
	Castbar.BarShadow = F.CreateSD(Castbar, Castbar, 4)
	
	-- 圖示
	Castbar.Icon = Castbar:CreateTexture(nil, "OVERLAY", nil, 1)
	Castbar.Icon:SetTexCoord(.08, .92, .08, .92)
	-- 圖示邊框
	Castbar.Shadow = F.CreateSD(Castbar, Castbar.Icon, 4)
	
	-- 進度高亮
	Castbar.Spark = Castbar:CreateTexture(nil, "OVERLAY", nil, -1)
	Castbar.Spark:SetTexture(G.media.spark)
	Castbar.Spark:SetBlendMode("ADD")
	Castbar.Spark:SetVertexColor(1, 1, .85, .5)
	
	-- 不同模式的布局
	if self.mystyle == "S" then
		-- 簡易焦點
		Castbar:SetSize(C.PWidth/2, C.PHeight)
		Castbar.Icon:SetSize(C.PHeight * 1.5, C.PHeight * 1.5)
		
		Castbar.Spark:SetSize(C.PHeight, C.PHeight)
		Castbar.Spark:SetPoint("RIGHT", Castbar:GetStatusBarTexture(), 0, 0)

		Castbar.Text = F.CreateText(Castbar, "OVERLAY", G.Font, G.NameFS, G.FontFlag, "LEFT")
		Castbar.Text:SetPoint("LEFT", 5, 0)
		Castbar.Text:SetWidth(self:GetWidth())		
	elseif self.mystyle == "H" then
		-- 橫式
		Castbar:SetHeight(C.PHeight)
		Castbar.Icon:SetSize(C.PHeight, C.PHeight)
		
		Castbar.Spark:SetSize(C.PHeight, C.PHeight)
		Castbar.Spark:SetPoint("RIGHT", Castbar:GetStatusBarTexture(), 0, 0)

		Castbar.Text = F.CreateText(Castbar, "OVERLAY", G.Font, G.NameFS, G.FontFlag, "LEFT")
		Castbar.Text:SetPoint("LEFT", 5, 0)
		Castbar.Time = F.CreateText(Castbar, "OVERLAY", G.Font, G.NameFS, G.FontFlag, "RIGHT")
		Castbar.Time:SetPoint("RIGHT", -5, 0)
	else
		-- 直式
		Castbar:SetSize(C.PHeight, C.PWidth-C.PHeight-C.PPOffset)
		Castbar.Icon:SetSize(C.PHeight, C.PHeight)
		Castbar:SetOrientation("VERTICAL")
		
		Castbar.Spark:SetRotation(math.rad(90))	-- spark材質也要轉90度
		Castbar.Spark:SetSize(C.PHeight, C.PHeight)
		Castbar.Spark:SetPoint("TOP", Castbar:GetStatusBarTexture(), 0, 0)

		Castbar.Text = F.CreateText(Castbar, "OVERLAY", G.Font, G.NameFS, G.FontFlag, nil)
		Castbar.Time = F.CreateText(Castbar, "OVERLAY", G.Font, G.NameFS, G.FontFlag, nil)
	end
	
	-- 選項
	Castbar.timeToHold = 0.05
	-- 註冊到ouf
	self.Castbar = Castbar	
	self.Castbar.PostCastStart = T.PostStandaloneCastStart			-- 施法開始
	self.Castbar.CustomTimeText = T.CustomTimeText					-- 施法時間	
	self.Castbar.PostCastFail = T.PostStandaloneCastFailed			-- 施法失敗
	self.Castbar.PostCastInterruptible = T.PostUpdateStandaloneCast	-- 打斷狀態更新
end

--===================================================--
-------------------    [[ Auras ]]    -----------------
--===================================================--

-- [[ 減益 ]] --

T.CreateDebuffs = function(self, button)
	local Debuffs = CreateFrame("Frame", nil, self)
	Debuffs.spacing = 6
	Debuffs:SetFrameLevel(self:GetFrameLevel() + 2)
	
	-- 選項
	Debuffs.disableCooldown = true
	Debuffs.showDebuffType = true
	-- 註冊到ouf
	self.Debuffs = Debuffs
	self.Debuffs.PostCreateButton = T.PostCreateIcon
	self.Debuffs.PostUpdateButton = T.PostUpdateIcon
	self.Debuffs.FilterAura = T.CustomFilter
end

-- [[ 增益 ]] --

T.CreateBuffs = function(self, button)
	local Buffs = CreateFrame("Frame", nil, self)
	Buffs.spacing = 6
	Buffs:SetFrameLevel(self:GetFrameLevel() + 2)
	
	-- 選項
	Buffs.disableCooldown = true
	-- 註冊到ouf
	self.Buffs = Buffs
	self.Buffs.PostCreateButton = T.PostCreateIcon
	self.Buffs.PostUpdateButton = T.PostUpdateIcon
	self.Buffs.FilterAura = T.CustomFilter
end

-- [[ 光環 ]] --

T.CreateAuras = function(self, button)
	local Auras = CreateFrame("Frame", nil, self)
	Auras.spacing = 6
	Auras.size = C.buSize
	Auras:SetFrameLevel(self:GetFrameLevel() + 2)
	
	if self.mystyle == "S" then
		-- Simple focus
		Auras.numBuffs = 2
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
	Auras.disableCooldown = true
	Auras.showDebuffType = true
	-- 註冊到ouf
	self.Auras = Auras
	self.Auras.SetPosition = T.SetPosition					-- 為垂直排列重寫set position
	self.Auras.PostCreateButton = T.PostCreateIcon
	self.Auras.PostUpdateButton = T.PostUpdateIcon
	
	if self.mystyle ~= "S" then
		self.Auras.PostUpdateGapButton = T.PostUpdateGapIcon	-- 間隔圖示
	end
	
	self.Auras.FilterAura = T.CustomFilter					-- 光環過濾	
	self.Auras.PostUpdateInfo = T.BolsterPostUpdateInfo		-- 激勵
end

--===================================================--
------------------    [[ Others ]]    -----------------
--===================================================--

-- [[ 職業資源 ]] --

T.CreateClassPower = function(self, unit)
	if not F.Multicheck(G.myClass, "PRIEST", "MAGE", "WARLOCK", "ROGUE", "MONK", "DRUID", "PALADIN", "DEATHKNIGHT", "EVOKER") then return end
	--if F.Multicheck(G.myClass, "WARRIOR", "HUNTER", "SHAMAN") then return end
	
	local isDK = G.myClass == "DEATHKNIGHT"
	local maxPoint = (isDK and 6) or 7
	
	local ClassPower = {}
	
	for i = 1, maxPoint do
		-- 創建總體條
		ClassPower[i] = F.CreateStatusbar(self, G.addon..unit.."_ClassPowerBar"..i, "ARTWORK", nil, nil, 1, 1, 0, 1)
		ClassPower[i].border = F.CreateSD(ClassPower[i], ClassPower[i], 4)
		ClassPower[i]:SetFrameLevel(self:GetFrameLevel() + 2)
		
		if self.mystyle == "VL" then
			-- 單獨的每個豆子
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
			ClassPower[i]:SetSize((C.PWidth - 6*C.PPOffset)/maxPoint, C.PPHeight)
			
			if i == 1 then
				ClassPower[i]:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 0, C.PPOffset)
			else
				ClassPower[i]:SetPoint("LEFT", ClassPower[i-1], "RIGHT", C.PPOffset, 0)
			end
		end
		
		if isDK then
			ClassPower[i].bg = ClassPower[i]:CreateTexture(nil, "BACKGROUND")
			ClassPower[i].bg:SetAllPoints()
			ClassPower[i].bg:SetTexture(G.media.blank)
			ClassPower[i].bg.multiplier = .4
			ClassPower[i].timer = F.CreateText(ClassPower[i], "OVERLAY", G.Font, G.NameFS, G.FontFlag, "CENTER")
			ClassPower[i].timer:SetPoint("CENTER", 0, 0)
		end
		
		--[[if G.myClass == "EVOKER" then
			ClassPower[i].bg = ClassPower[i]:CreateTexture(nil, "BACKGROUND")
			ClassPower[i].bg:SetAllPoints()
			ClassPower[i].bg:SetTexture(G.media.blank)
			ClassPower[i].bg.multiplier = .4
			ClassPower[i].timer = F.CreateText(ClassPower[i], "OVERLAY", G.Font, G.NameFS, G.FontFlag, "CENTER")
			ClassPower[i].timer:SetPoint("CENTER", 0, 0)
		end]]--
	end
	
	-- 註冊到ouf並整合符文顯示
	if isDK then
		ClassPower.colorSpec = true
		ClassPower.sortOrder = "asc"
		--ClassPower.__max = 6
		self.Runes = ClassPower
		self.Runes.PostUpdate = T.PostUpdateRunes
	else
		self.ClassPower = ClassPower
		self.ClassPower.PostUpdate = T.PostUpdateClassPower
	end
end

-- [[ 額外能量 暗牧鳥德薩滿的法力 ]] --

T.CreateAddPower = function(self, unit)
	if not F.Multicheck(G.myClass, "DRUID", "SHAMAN", "PRIEST") then return end
	
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
	
	-- 註冊到ouf	
	self.Stagger = Stagger
	self.Stagger.PostUpdate = T.PostUpdateStagger
	-- 文本
	self.Stagger.value = F.CreateText(self.Stagger, "OVERLAY", G.Font, G.NameFS, G.FontFlag, nil)
	if self.mystyle == "VL" then
		self.Stagger.value:SetPoint("BOTTOMRIGHT", self.Power, "BOTTOMLEFT", -C.PPOffset, (G.NameFS + 2)*2)
		self.Stagger.value:SetJustifyH("RIGHT")
	else
		self.Stagger.value:SetPoint("CENTER", self.Stagger, 0, 0)
		self.Stagger.value:SetJustifyH("CENTER")
	end
end

-- [[ 預估治療 ]] --

T.CreateHealthPrediction = function(self, unit)
	-- 吸收盾
	local abb = F.CreateStatusbar(self, G.addon..unit.."_AbsorbBar", "ARTWORK", nil, nil, 0, .5, .8, .5)
	abb:SetFrameLevel(self:GetFrameLevel() + 2)
	
	if self.mystyle == "VL" or self.mystyle == "VR" then
		-- 直式
		abb:SetOrientation("VERTICAL")
		abb:SetPoint("LEFT")
		abb:SetPoint("RIGHT")
		abb:SetPoint("BOTTOM", self.Health:GetStatusBarTexture(), "BOTTOM")
	elseif F.Multicheck(self.mystyle, "H", "BP", "BPP", "R") then
		-- 橫式
		abb:SetPoint("TOP")
		abb:SetPoint("BOTTOM")
		abb:SetPoint("LEFT", self.Health:GetStatusBarTexture(), "LEFT")
	end
	
	-- 滿血時的吸收盾
	local abbo = F.CreateStatusbar(self, G.addon..unit.."_OverAbsorbBar", "ARTWORK", nil, nil, 0, .5, .8, .5)
	abbo:SetFrameLevel(self:GetFrameLevel() + 2)
	
	if self.mystyle == "VL" or self.mystyle == "VR" then
		-- 直式
		abbo:SetOrientation("VERTICAL")
		abbo:SetPoint("RIGHT")
		abbo:SetPoint("LEFT")
		abbo:SetPoint("TOP", self.Health:GetStatusBarTexture(), "BOTTOM")
	elseif F.Multicheck(self.mystyle, "BP", "H", "BPP", "R") then
		-- 橫式
		abbo:SetPoint("TOP")
		abbo:SetPoint("BOTTOM")
		abbo:SetPoint("RIGHT", self.Health:GetStatusBarTexture(), "LEFT")
	end

	self.HealthPrediction = {
        absorbBar = abb,	-- 吸收盾
        -- healAbsorbBar
		overAbsorb = abbo,	-- 過量吸收盾
		-- overHealAbsorb
        frequentUpdates = true,
		maxOverflow = 1.01,
    }
	self.HealthPrediction.PostUpdate = T.PostUpdateHealPer
end

-- [[ 坦克資源 ]] --

T.CreateTankResource = function(self, unit)
	local TankResource = {}

    for i = 1, 4 do
		TankResource[i] = F.CreateStatusbar(self, G.addon..unit.."_TankResourceBar"..i, "ARTWORK", nil, nil, 1, 1, 0, 1)
		TankResource[i].border = F.CreateSD(TankResource[i], TankResource[i], 4)
		TankResource[i]:SetFrameLevel(self:GetFrameLevel() + 2)
		
		-- 背景
		TankResource[i].bg = TankResource[i]:CreateTexture(nil, "BACKGROUND")
		TankResource[i].bg:SetAllPoints()
		TankResource[i].bg:SetTexture(G.media.blank)
		TankResource[i].bg.multiplier = .3

		if self.mystyle == "VL" then
			-- 單獨的每個豆子
			TankResource[i]:SetOrientation("VERTICAL")
			TankResource[i]:SetSize(C.PPHeight, (C.PWidth - 3*C.PPOffset)/4)
			
			if F.Multicheck(G.myClass, "DEATHKNIGHT", "MONK") then
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
			TankResource[i]:SetSize((C.PWidth - 3*C.PPOffset)/4, C.PPHeight)
			
			if F.Multicheck(G.myClass, "DEATHKNIGHT", "MONK") then
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

    -- Register with oUF
    self.TankResource = TankResource
    self.TankResource.PostUpdate = T.PostUpdateTankResource
end