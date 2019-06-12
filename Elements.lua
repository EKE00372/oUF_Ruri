local addon, ns = ...
local C, F, G, T = unpack(ns)

--===================================================--
-----------------    [[ Castbar ]]    -----------------
--===================================================--

-- [[ 施法條 ]] --

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
	Castbar.Shadow = F.CreateSD(Castbar, Castbar.Border, 3)
	
	-- 文本
	Castbar.Text = F.CreateText(Castbar, "OVERLAY", G.Font, G.NameFS, G.FontFlag, nil)
	Castbar.Time = F.CreateText(Castbar, "OVERLAY", G.Font, G.NameFS, G.FontFlag, nil)
	
	-- 進度高亮
	Castbar.Spark = Castbar:CreateTexture(nil, "OVERLAY", nil, -1)
	Castbar.Spark:SetTexture(G.media.spark)
	Castbar.Spark:SetBlendMode("ADD")
	Castbar.Spark:SetVertexColor(1, 1, .85, .8)
	
	-- 橫豎的spark不一樣
	if self.mystyle ~= "H" then
		Castbar:SetOrientation("VERTICAL")
		Castbar.Spark:SetRotation(math.rad(90))
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
	self.Castbar.PostChannelStart = T.PostCastStart			-- 開始引導施法	
	self.Castbar.PostCastStop = T.PostCastStop				-- 施法結束
	self.Castbar.PostChannelStop = T.PostCastStop			-- 引導施法結束
	self.Castbar.CustomTimeText = T.CustomTimeText			-- 施法時間	
	self.Castbar.PostCastFailed = T.PostCastFailed			-- 施法失敗
	self.Castbar.PostCastInterrupted = T.PostCastFailed		-- 引導施法失敗	
	-- 當前目標正在施法時，切換目標會重新獲取名字，防止丟失
	self:RegisterEvent("UNIT_NAME_UPDATE", T.PostCastStopUpdate)
	self:RegisterEvent("PLAYER_TARGET_CHANGED", T.PostCastStopUpdate, true)
	table.insert(self.__elements, T.PostCastStopUpdate)
	-- 打斷狀態刷新
	self.Castbar.PostCastInterruptible = T.PostUpdateCast	
	self.Castbar.PostCastNotInterruptible = T.PostUpdateCast
	--self.PostCastDelayed
end

-- [[ 獨立施法條 ]] --

T.CreateStandaloneCastbar = function(self, unit)
	-- 創建一個條
	local Castbar = F.CreateStatusbar(self, G.addon..unit.."_CastBar", "ARTWORK", nil, nil, .6, .6, .6, 1)
	Castbar:SetFrameLevel(self:GetFrameLevel()+4)
	-- 背景與邊框
	Castbar.BarBG = F.CreateBD(Castbar, Castbar, 1, .15, .15, .15, .4)
	-- 陰影
	Castbar.BarShadow = F.CreateSD(Castbar, Castbar, 3)
	
	-- 圖示
	Castbar.Icon = Castbar:CreateTexture(nil, "OVERLAY", nil, 1)
	Castbar.Icon:SetTexCoord(.08, .92, .08, .92)
	-- 圖示邊框
	Castbar.Shadow = F.CreateSD(Castbar, Castbar.Icon, 3)
	
	-- 進度高亮
	Castbar.Spark = Castbar:CreateTexture(nil, "OVERLAY", nil, -1)
	Castbar.Spark:SetTexture(G.media.spark)
	Castbar.Spark:SetBlendMode("ADD")
	Castbar.Spark:SetVertexColor(1, 1, .85, .5)
	
	-- 不同模式的布局
	if self.mystyle == "S" then
		-- 簡易模式(簡易焦點)
		Castbar:SetSize(C.PWidth/2, C.PHeight)
		Castbar.Icon:SetSize(C.PHeight*1.5, C.PHeight*1.5)
		
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
		
		Castbar.Spark:SetRotation(math.rad(90))	-- 旋轉材質
		Castbar.Spark:SetSize(C.PHeight, C.PHeight)
		Castbar.Spark:SetPoint("TOP", Castbar:GetStatusBarTexture(), 0, 0)

		Castbar.Text = F.CreateText(Castbar, "OVERLAY", G.Font, G.NameFS, G.FontFlag, nil)
		Castbar.Time = F.CreateText(Castbar, "OVERLAY", G.Font, G.NameFS, G.FontFlag, nil)
	end
	
	-- 選項
	Castbar.timeToHold = 0.05	
	-- 註冊到ouf
	self.Castbar = Castbar	
	self.Castbar.PostCastStart = T.PostSCastStart			-- 開始施法
	self.Castbar.PostChannelStart = T.PostSCastStart		-- 開始引導施法	
	self.Castbar.CustomTimeText = T.CustomTimeText			-- 施法時間	
	self.Castbar.PostCastFailed = T.PostSCastFailed			-- 施法失敗
	self.Castbar.PostCastInterrupted = T.PostSCastFailed	-- 引導施法失敗	
	-- 打斷狀態刷新
	self.Castbar.PostCastInterruptible = T.PostUpdateSCast	
	self.Castbar.PostCastNotInterruptible = T.PostUpdateSCast
	--self.PostCastDelayed
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
	self.Debuffs.PostCreateIcon = T.PostCreateIcon
	self.Debuffs.PostUpdateIcon = T.PostUpdateIcon
	self.Debuffs.CustomFilter = T.CustomFilter
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
	self.Buffs.PostCreateIcon = T.PostCreateIcon
	self.Buffs.PostUpdateIcon = T.PostUpdateIcon
	self.Buffs.CustomFilter = T.CustomFilter
end


-- [[ 光環 ]] --

T.CreateAuras = function(self, button)
	local Auras = CreateFrame("Frame", nil, self)
	Auras.spacing = 6
	Auras.size = C.buSize
	Auras:SetFrameLevel(self:GetFrameLevel() + 2)
	
	if self.mystyle == "S" then
		Auras.numBuffs = 2
		Auras.numDebuffs = 4
		Auras.numTotal = 4
		Auras.gap = false
		
		Auras.iconsPerRow = 4
		Auras.initialAnchor = "BOTTOMLEFT"
		Auras["growth-x"] = "RIGHT"
		Auras["growth-y"] = "UP"
		Auras:SetPoint("BOTTOMLEFT", self.HealthText, "TOPLEFT", 3, 0)
		Auras:SetWidth(C.buSize * Auras.numTotal + Auras.spacing * (Auras.numTotal-1))
		Auras:SetHeight(C.buSize)
	else
		if self.mystyle == "H" then
			local iconsPerLine = math.floor(self:GetWidth() / (C.buSize+Auras.spacing) + 0.5)
			Auras.numBuffs = iconsPerLine
			Auras.numDebuffs = C.maxAura
			Auras.numTotal = C.maxAura
			Auras.gap = true

			Auras.initialAnchor = "BOTTOMLEFT"
			Auras["growth-x"] = "RIGHT"
			Auras["growth-y"] = "UP"
			Auras:SetPoint("BOTTOMLEFT", self.Health, "TOPLEFT", 1, C.PPOffset*2+C.PPHeight)
			Auras:SetWidth(self:GetWidth())
			Auras:SetHeight(C.buSize * (Auras.numTotal/iconsPerLine) + Auras.spacing * (Auras.numTotal/iconsPerLine-1))
		else
			local iconsPerLine = math.floor(self:GetHeight() / (C.buSize+Auras.spacing) + 0.5)
			Auras.numBuffs = iconsPerLine
			Auras.numDebuffs = C.maxAura
			Auras.numTotal = C.maxAura
			Auras.gap = true
				
			Auras.initialAnchor = "BOTTOMRIGHT"
			Auras["growth-x"] = "LEFT"
			Auras["growth-y"] = "UP"	
			Auras:SetPoint("BOTTOMRIGHT", self.Health, "BOTTOMLEFT", -C.PPOffset-1, 1)
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
	self.Auras.PostCreateIcon = T.PostCreateIcon
	self.Auras.PostUpdateIcon = T.PostUpdateIcon
	
	if self.mystyle ~= "S" then
		self.Auras.PostUpdateGapIcon = T.PostUpdateGapIcon	-- 間隔圖示
	end
	
	self.Auras.CustomFilter = T.CustomFilter				-- 光環過濾	
	self.Auras.PreUpdate = T.BolsterPreUpdate				-- 激勵
	self.Auras.PostUpdate = T.BolsterPostUpdate				-- 激勵計數
end

--===================================================--
------------------    [[ Others ]]    -----------------
--===================================================--

-- [[ 職業資源 ]] --

T.CreateClassPower = function(self, unit)
	if G.myClass ~= "ROUGE" then return end
	
	local ClassPower = {}
	
	for i = 1, 6 do
		ClassPower[i] = F.CreateStatusbar(self, G.addon..unit.."_ClassPowerBar"..i, "ARTWORK", nil, nil, 1, 1, 0, 1)
		ClassPower[i].border = F.CreateSD(ClassPower[i], ClassPower[i], 3)
		ClassPower[i]:SetFrameLevel(self:GetFrameLevel() + 2)
		
		if self.mystyle == "VL" then
			ClassPower[i]:SetOrientation("VERTICAL")
			ClassPower[i]:SetSize(C.PPHeight, (C.PWidth-5*C.PPOffset)/6)
			
			if i == 1 then
				ClassPower[i]:SetPoint("BOTTOMLEFT", self, "BOTTOMRIGHT", C.PPOffset, 0)  
			else
				ClassPower[i]:SetPoint("BOTTOM", ClassPower[i-1], "TOP", 0, C.PPOffset)
			end
		elseif self.mystyle == "PP" then
			ClassPower[i]:SetSize((C.NPWidth-5*C.PPOffset)/6, C.PPHeight)
			
			if C.NumberStyle then
				if i == 1 then
					ClassPower[i]:SetPoint("TOP", self.HealthText, "BOTTOM", -(C.NPWidth-3*C.PPOffset)/2, -C.PPOffset)  
				else
					ClassPower[i]:SetPoint("LEFT", ClassPower[i-1], "RIGHT", C.PPOffset, 0)
				end
			else
				if i == 1 then
					ClassPower[i]:SetPoint("TOP", self.Power, "BOTTOM", -(C.NPWidth-3*C.PPOffset)/2, -4)  
				else
					ClassPower[i]:SetPoint("LEFT", ClassPower[i-1], "RIGHT", C.PPOffset, 0)
				end
			end
		else
			ClassPower[i]:SetSize((C.PWidth-5*C.PPOffset)/6, C.PPHeight)
			
			if i == 1 then
				ClassPower[i]:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 0, C.PPOffset)  
			else
				ClassPower[i]:SetPoint("LEFT", ClassPower[i-1], "RIGHT", C.PPOffset, 0)
			end
		end
	end
	
	self.ClassPower = ClassPower
	self.ClassPower.PostUpdate = T.PostUpdateClassPower
end