local addon, ns = ...
local C, F, G, T = unpack(ns)

if not C.UnitFrames then return end

--===================================================--
---------------    [[ UnitShared ]]     ---------------
--===================================================--

-- 框體共享的設定
local function CreateUnitShared(self, unit)
	local u = unit:match("[^%d]+") -- boss1 -> boss

	-- [[ 前置作業 ]] --

	self:RegisterForClicks("AnyUp")	-- Make mouse active
	
	-- [[ 高亮 ]] --
	
	local hl = self:CreateTexture(nil, "HIGHLIGHT")
	hl:SetAllPoints(self)
	hl:SetTexture(G.media.barhightlight)
	hl:SetVertexColor(1, 1, 1, .5)
	hl:SetBlendMode("ADD")
	
	if self.mystyle == "VL" then
		hl:SetTexCoord(0, 1, 1, 1, 0, 0, 1, 0)  -- 負90度
	elseif  self.mystyle == "VR" then
		hl:SetTexCoord(1, 0, 0, 0, 1, 1, 0, 1)	-- 90度
	else
		hl:SetTexCoord(1, 0, 0, 1)
	end
	
	self.Mouseover = hl
	
	-- [[ 血量條 ]] --
	
	-- 透明模式的邏輯與一般是相反的
	-- 通常情況：製造一個有底色的背景，上面覆蓋一個狀態條，損血後狀態條縮短，露出背景，而狀態條本身顯示血量漸變色
	-- 透明模式：製造一個高透明度的背景作為血量條，上面覆蓋一個狀態條，狀態條改為顯示扣血量，然後反轉狀態條填充方向
	
	-- 創建一個條
	local Health = F.CreateStatusbar(self, G.addon..unit.."_HealthBar", "ARTWORK", nil, nil, 1, 0, 0, 1)
	Health:SetAllPoints(self)
	Health:SetFrameLevel(self:GetFrameLevel())
	Health:SetReverseFill(true)			-- 反轉狀態條
	
	if self.mystyle ~= "H" then
		Health:SetOrientation("VERTICAL")
	end
	
	-- 選項
	Health.colorTapping = true			-- 無拾取權
	Health.colorDisconnected = true		-- 離線
	Health.colorSmooth = true			-- 血量漸變色
	Health.smoothGradient = {1, 0, 0, 1, .8, .1, 1, .8, .1}
	Health.frequentUpdates = .1			-- 更新速率
	-- 陰影
	Health.border = F.CreateSD(Health, Health, 3)
	-- 註冊到ouf
	self.Health = Health
	self.Health.PreUpdate = T.OverrideHealthbar	-- 刷新機制：損血量
	self.Health.PostUpdate = T.PostUpdateHealth	-- 刷新機制：顯示損血量，使血量漸變色和透明度隨損血量改變
	
	-- 主框體背景，這實際上就是透明模式下的血條
	local HealthBG = F.CreateBD(self.Health, self, 1, .15, .15, .15, .4)

	-- [[ 能量條 ]] --
	
	local Power = F.CreateStatusbar(self, G.addon..unit.."_PowerBar", "ARTWORK", nil, nil, 1, 1, 1, 1)	-- 不透明的
	
	if self.mystyle == "H" then
		Power:SetHeight(C.PPHeight)
		Power:SetPoint("TOPLEFT", self.Health, "BOTTOMLEFT", 0, -C.PPOffset)	-- 與血量條等寬
		Power:SetPoint("TOPRIGHT", self.Health, "BOTTOMRIGHT", 0, -C.PPOffset) 
	else
		Power:SetWidth(C.PPHeight)
		Power:SetOrientation("VERTICAL")
		
		if self.mystyle == "VL" then
			Power:SetPoint("BOTTOMRIGHT", self.Health, "BOTTOMLEFT", -C.PPOffset, 0)	-- 與血量條等寬
			Power:SetPoint("TOPRIGHT", self.Health, "TOPLEFT", -C.PPOffset, 0) 
		elseif  self.mystyle == "VR" then
			Power:SetPoint("BOTTOMLEFT", self.Health, "BOTTOMRIGHT", C.PPOffset, 0)		-- 與血量條等寬
			Power:SetPoint("TOPLEFT", self.Health, "TOPRIGHT", C.PPOffset, 0) 
		end
	end

	Power:SetFrameLevel(self:GetFrameLevel() + 2)	-- 若要使用層次浮於血量條之上，應使其框體層級高於父級框體
	-- 選項
	Power.frequentUpdates = true	-- 更新速率
	Power.colorPower = false		-- 能量類型染色
	Power.colorClass = true			-- 職業染色
	Power.colorReaction = true		-- 陣營染色
	-- 背景
	Power.bg = Power:CreateTexture(nil, "BACKGROUND")
	Power.bg:SetAllPoints()
	Power.bg:SetTexture(G.media.blank)
	Power.bg.multiplier = .3
	-- 陰影
	Power.border = F.CreateSD(Power, Power, 3)
	-- 註冊到ouf
	self.Power = Power
	self.Power.PostUpdate = T.PostUpdatePower	

	-- [[ 圖示 ]] --
	
	-- 建立一個提供給圖示依附的父級框體，框體層級高，避免被蓋住
	local StringParent = CreateFrame("Frame", nil, self)
	StringParent:SetFrameLevel(self:GetFrameLevel() + 8)
	self.StringParent = StringParent	
	-- 團隊標記
	local RaidIcon = StringParent:CreateTexture(nil, "OVERLAY")
	RaidIcon:SetSize(28, 28)
	RaidIcon:SetTexture(G.media.raidicon)
	self.RaidTargetIndicator = RaidIcon
	-- 助手
	local Assistant = StringParent:CreateTexture(nil, "OVERLAY")
	Assistant:SetSize(14, 14)
	self.AssistantIndicator = Assistant
	-- 領隊
	local Leader = StringParent:CreateTexture(nil, "OVERLAY")
	Leader :SetSize(14, 14)
	self.LeaderIndicator = Leader
	-- 戰鬥中
	local combat = StringParent:CreateTexture(nil, "OVERLAY")
	combat:SetSize(24, 24)
	combat:SetTexture(G.media.combat)
	combat:SetVertexColor(1, 1, 0)
	self.CombatIndicator = combat
	self.CombatIndicator.PostUpdate = T.CombatPostUpdate
	-- 休息
	local rest = StringParent:CreateTexture(nil, "OVERLAY")
	rest:SetSize(20, 20)
	rest:SetTexture(G.media.resting)
	self.RestingIndicator = rest
	-- 職責
	--[[local role = StringParent:CreateTexture(nil, "OVERLAY")
	role:SetSize(14, 14)
	self.GroupRoleIndicator = role]]--

	-- [[ 文本/TAGS ]] --
	
	-- 血量
	self.Health.value = F.CreateText(self.Power, "OVERLAY", G.Font, G.NameFS, G.FontFlag, "LEFT")
	self:Tag(self.Health.value, "[unit:hp]")
	-- 能量
	self.Power.value = F.CreateText(self.Power, "OVERLAY", G.Font, G.NameFS, G.FontFlag, "RIGHT")
	--self:Tag(self.Power.value, "[unit:mp]") --不用這個，用postupdate
	-- 名字
	self.Name = F.CreateText(self.Health, "OVERLAY", G.Font, G.NameFS, G.FontFlag, nil)
	self:Tag(self.Name, "[namecolor][name]")
	-- 狀態：暫離/忙錄/等級
	self.Status = F.CreateText(self.Health, "OVERLAY", G.Font, G.NameFS, G.FontFlag, nil)
	--self:Tag(self.Status, "[afkdnd][difficulty][smartlevel] ")
	self:Tag(self.Status, "[afkdnd][smartlevel] ")
	
	--if u == "pet" then
		-- 獵人寵物快樂值
		self.Happy = F.CreateText(self.Health, "OVERLAY", G.Font, G.NameFS, G.FontFlag, "RIGHT")
		self:Tag(self.Happy, "[happy]")
	--end
end

--===================================================--
--------------    [[ UnitSpecific ]]     --------------
--===================================================--

-- 玩家橫式
local function CreatePlayerStyle(self, unit)
	self.mystyle = "H"
	
	-- 框體
    CreateUnitShared(self, unit)		-- 繼承通用樣式
	self:SetSize(C.PWidth, C.PHeight)	-- 主框體尺寸
	
	-- 文本
	self.Health.value:SetPoint("LEFT", 0, 2)
	self.Power.value:SetPoint("RIGHT", 0, 2)
	
	-- 職業資源
	T.CreateClassPower(self, unit)
		
	-- 施法條
	if C.Castbar then
		if C.StandaloneCastbar then
			T.CreateStandaloneCastbar(self, unit)
			self.Castbar:SetWidth(C.CastbarWidth)
			self.Castbar.Icon:SetPoint(unpack(C.Position.PlayerCastbar))
			self.Castbar:SetPoint("LEFT", self.Castbar.Icon, "RIGHT", C.PPOffset, 0)
		else
			T.CreateCastbar(self, unit)
			self.Castbar.Icon:SetPoint("TOPLEFT", self.Health, "TOPRIGHT", C.PPOffset, 0)
			self.Castbar.Text:SetPoint("CENTER", self.Health, 0, 2)
			self.Castbar.Text:SetJustifyH("CENTER")
			self.Castbar.Text:SetWidth(self:GetWidth())
			self.Castbar.Time:SetPoint("CENTER", self.Power, "CENTER", 0, 2)
			self.Castbar.Time:SetJustifyH("CENTER")
		end
	end
	
	-- 減益
	if C.PlayerDebuffs then
		T.CreateDebuffs(self)		
		self.Debuffs:SetPoint("BOTTOMLEFT", self.Health, "TOPLEFT", 1, C.PHeight/2+C.PPOffset)
		self.Debuffs["growth-x"] = "RIGHT"
		self.Debuffs["growth-y"] = "UP"
		self.Debuffs.num = 6
		self.Debuffs.size = C.buSize + 6
		self.Debuffs.spacing = 6
		self.Debuffs:SetSize(C.PWidth, C.buSize)
	end
	
	-- 圖示和標記
	self.RaidTargetIndicator:SetPoint("TOP", self.Health, 0, 16)
	self.AssistantIndicator:SetPoint("TOPRIGHT", self.Health, -4, C.PHeight/2)
	self.LeaderIndicator:SetPoint("TOPRIGHT", self.Health, -4, C.PHeight/2)
	self.CombatIndicator:SetPoint("TOPLEFT", self.Health, 4, -4)
	self.RestingIndicator:SetPoint("TOPLEFT", self.Health, 4, -4)
end

-- 玩家直式
local function CreateVPlayerStyle(self, unit)
	self.mystyle = "VL"
	
	-- 框體
    CreateUnitShared(self, unit)		-- 繼承通用樣式
	self:SetSize(C.PHeight, C.PWidth)	-- 主框體尺寸
	
	-- 文本
	self.Health.value:SetPoint("BOTTOMRIGHT", self.Power, "BOTTOMLEFT", -C.PPOffset, 0)
	self.Health.value:SetJustifyH("RIGHT")
	self.Power.value:SetPoint("BOTTOMRIGHT", self.Power, "BOTTOMLEFT", -C.PPOffset, G.NameFS+2)
	self.Power.value:SetJustifyH("RIGHT")
	
	-- 職業資源
	T.CreateClassPower(self, unit)
	
	-- 減益
	if C.PlayerDebuffs then
		T.CreateDebuffs(self)
		self.Debuffs:SetPoint("BOTTOMLEFT", self.Health, "BOTTOMRIGHT", (C.PPHeight+C.PPOffset*2), 1)
		self.Debuffs["growth-x"] = "UP"
		self.Debuffs["growth-y"] = "RIGHT"
		self.Debuffs.num = 6
		self.Debuffs.size = C.buSize + 4
		self.Debuffs.spacing = 5
		self.Debuffs:SetSize(C.buSize+4, C.PWidth)
	end

	-- 施法條
	if C.Castbar then
		if C.StandaloneCastbar then
			T.CreateStandaloneCastbar(self, unit)		
			--self.Castbar.Icon:SetPoint(unpack(C.Position.VPlayerCastbar))
			self.Castbar.Icon:SetPoint("BOTTOMLEFT", self.Health, "BOTTOMRIGHT", self.Debuffs:GetWidth()+C.PPOffset*3+C.PPHeight, 0)
			self.Castbar:SetPoint("BOTTOM", self.Castbar.Icon, "TOP", 0, C.PPOffset)
			self.Castbar.Text:SetPoint("BOTTOMLEFT", self.Castbar.Icon, "BOTTOMRIGHT", C.PPOffset, 0)
			self.Castbar.Text:SetJustifyH("LEFT")
			self.Castbar.Time:SetPoint("BOTTOMLEFT", self.Castbar.Icon, "BOTTOMRIGHT", C.PPOffset, G.NameFS+2)
			self.Castbar.Time:SetJustifyH("LEFT")
		else
			T.CreateCastbar(self, unit)
			self.Castbar.Icon:SetPoint("TOP", self.Health, "BOTTOM", -C.PPHeight, -6)
			self.Castbar.Text:SetPoint("BOTTOMRIGHT", self.Power, "BOTTOMLEFT", -C.PPOffset, (G.NameFS+2) * 3)
			self.Castbar.Text:SetJustifyH("RIGHT")
			self.Castbar.Time:SetPoint("BOTTOMRIGHT", self.Power, "BOTTOMLEFT", -C.PPOffset, (G.NameFS+2) * 4)
			self.Castbar.Time:SetJustifyH("RIGHT")
		end
	end
	
	-- 圖示和標記
	self.RaidTargetIndicator:SetPoint("BOTTOM", self.Health, "TOP", 0, -10)
	self.AssistantIndicator:SetPoint("CENTER", self.Health, "BOTTOM", 0, 4)
	self.LeaderIndicator:SetPoint("CENTER", self.Health, "BOTTOM", 0, 4)
	self.CombatIndicator:SetPoint("CENTER", self.Health, "BOTTOM", 0, 20)
	self.RestingIndicator:SetPoint("CENTER", self.Health, "BOTTOM", 0, 20)
end

-- 目標橫式
local function CreateTargetStyle(self, unit)
	self.mystyle = "H"
	-- 框體
	CreateUnitShared(self, unit)		-- 繼承通用樣式
	self:SetSize(C.PWidth, C.PHeight)	-- 主框體尺寸
	--[[self.Range = {
		insideAlpha = 1, outsideAlpha = .5,
	}]]--
	
	-- 文本
	self.Name:SetPoint("TOPRIGHT", self.Health, 0, G.NameFS/2 + C.PPHeight)
	self.Name:SetJustifyH("RIGHT")
	self.Status:SetPoint("RIGHT", self.Name, "LEFT", 0, 0)
	self.Health.value:SetPoint("RIGHT", 0, 2)
	self.Health.value:SetJustifyH("RIGHT")
	self.Power.value:SetPoint("LEFT", 0, 2)
	self.Power.value:SetJustifyH("LEFT")
	
	-- 施法條
	if C.Castbar then
		if C.StandaloneCastbar then
			T.CreateStandaloneCastbar(self, unit)
			self.Castbar:SetWidth(C.CastbarWidth)
			self.Castbar.Icon:SetPoint(unpack(C.Position.TargetCastbar))
			self.Castbar:SetPoint("RIGHT", self.Castbar.Icon, "LEFT", -C.PPOffset, 0)
		else
			T.CreateCastbar(self, unit)
			self.Castbar.Icon:SetPoint("TOPRIGHT", self.Health, "TOPLEFT", -6, 0)
			self.Castbar.Text:SetPoint("TOPRIGHT", self.Health, 0, G.NameFS/2+C.PPHeight)
			self.Castbar.Text:SetJustifyH("RIGHT")
			self.Castbar.Text:SetWidth(self:GetWidth() * 0.7)
			self.Castbar.Time:SetPoint("TOPLEFT", self.Health, 0, G.NameFS/2 + C.PPHeight)
			self.Castbar.Time:SetJustifyH("LEFT")
			self.Castbar.Time:SetWidth(self:GetWidth() * 0.5)
		end
	end
	
	-- 光環
	T.CreateAuras(self)
	
	-- 圖示和標記
	self.RaidTargetIndicator:SetPoint("RIGHT", self.Health, 14, 0)
	self.AssistantIndicator:SetPoint("BOTTOM", self.Health, -10, -2)
	self.LeaderIndicator:SetPoint("BOTTOM", self.Health, -10, -2)
end

-- 目標直式
local function CreateVTargetStyle(self, unit)
	self.mystyle = "VR"
	
	-- 框體
	CreateUnitShared(self, unit)		-- 繼承通用樣式
	self:SetSize(C.PHeight, C.PWidth)	-- 主框體尺寸
	--[[self.Range = {
		insideAlpha = 1, outsideAlpha = .5,
	}]]--
	
	-- 光環
	T.CreateAuras(self)
		
	-- 施法條
	if C.Castbar then
		if C.StandaloneCastbar then
			T.CreateStandaloneCastbar(self, unit)
			--self.Castbar.Icon:SetPoint(unpack(C.Position.VTargetCastbar))		
			self.Castbar.Icon:SetPoint("BOTTOMRIGHT", self.Health, "BOTTOMLEFT", -(C.PPOffset*2 + self.Auras:GetWidth()), 0)
			self.Castbar:SetPoint("BOTTOM", self.Castbar.Icon, "TOP", 0, C.PPOffset)
			self.Castbar.Text:SetPoint("BOTTOMRIGHT", self.Castbar.Icon, "BOTTOMLEFT", -C.PPOffset, 0)
			self.Castbar.Text:SetJustifyH("RIGHT")
			self.Castbar.Time:SetPoint("BOTTOMRIGHT", self.Castbar.Icon, "BOTTOMLEFT", -C.PPOffset, G.NameFS + 2)
			self.Castbar.Time:SetJustifyH("RIGHT")
		else
			T.CreateCastbar(self, unit)
			self.Castbar.Icon:SetPoint("TOP", self.Health, "BOTTOM", C.PPHeight, -6)
			self.Castbar.Text:SetPoint("BOTTOMLEFT", self.Power, "BOTTOMRIGHT", C.PPOffset, (G.NameFS+2) * 3)
			self.Castbar.Text:SetJustifyH("LEFT")
			self.Castbar.Time:SetPoint("BOTTOMLEFT", self.Power, "BOTTOMRIGHT", C.PPOffset, (G.NameFS+2) * 4)
			self.Castbar.Time:SetJustifyH("LEFT")
		end
	end
	
	-- 文本
	self.Status:SetPoint("BOTTOMLEFT", self.Power, "BOTTOMRIGHT", C.PPOffset, (G.NameFS+2)*3)
	self.Status:SetJustifyH("LEFT")	
	self.Name:SetPoint("LEFT", self.Status, "RIGHT", 0, 0)
	self.Name:SetJustifyH("LEFT")
	self.Health.value:SetPoint("BOTTOMLEFT", self.Power, "BOTTOMRIGHT", C.PPOffset, 0)
	self.Health.value:SetJustifyH("LEFT")
	self.Power.value:SetPoint("BOTTOMLEFT", self.Power, "BOTTOMRIGHT", C.PPOffset, G.NameFS+2)
	self.Power.value:SetJustifyH("LEFT")
		
	-- 圖示和標記
	self.RaidTargetIndicator:SetPoint("BOTTOM", self.Health, "TOP", 0, -10)
	self.AssistantIndicator:SetPoint("BOTTOM", self.Health, 0, -4)
	self.LeaderIndicator:SetPoint("BOTTOM", self.Health, 0, -4)
end

-- 寵物
local function CreatePetStyle(self, unit)
	self.mystyle = "H"
	
	-- 框體
	CreateUnitShared(self, unit)		-- 繼承通用樣式
	self:SetSize(C.TOTWidth, C.PHeight)	-- 主框體尺寸
	
	-- 文本
	self.Name:SetPoint("TOPLEFT", self.Health, 0, G.NameFS/2 + C.PPHeight)
	self.Name:SetJustifyH("LEFT")
	self.Name:SetWidth(self:GetWidth()*0.9)
	self.Happy:SetPoint("RIGHT", self.Name, "LEFT" , 1, 0)
	
	-- 光環
	T.CreateDebuffs(self)
	self.Debuffs:SetPoint("LEFT", self.Health, "RIGHT", 6, -2)
	self.Debuffs.initialAnchor = "LEFT"
	self.Debuffs["growth-x"] = "RIGHT"
	self.Debuffs.num = 2
	self.Debuffs.size = C.buSize
	self.Debuffs.spacing = 5
	self.Debuffs:SetSize(C.buSize*2, C.buSize)
	
	-- 圖示和標記
	self.RaidTargetIndicator:SetPoint("LEFT", self.Health, -14, 0)
end

-- 寵物直式
local function CreateVPetStyle(self, unit)
	self.mystyle = "VL"
	-- 框體
	CreateUnitShared(self, unit)		-- 繼承通用樣式
	self:SetSize(C.PHeight, C.TOTWidth)	-- 主框體尺寸
	
	-- 文本
	self.Name:SetPoint("BOTTOMRIGHT", self.Power, "BOTTOMLEFT", -C.PPOffset, 0)
	self.Name:SetJustifyH("RIGHT")
	self.Happy:SetPoint("BOTTOMRIGHT", self.Health, "BOTTOMLEFT", -C.PPOffset, (G.NameFS+2) * 2)
	
	-- 光環
	T.CreateDebuffs(self)
	self.Debuffs:SetPoint("TOPRIGHT", self.Power, "TOPLEFT", -6, -2)
	self.Debuffs.initialAnchor = "TOP"
	self.Debuffs["growth-y"] = "DOWN"
	self.Debuffs.num = 2
	self.Debuffs.size = C.buSize
	self.Debuffs.spacing = 5
	self.Debuffs:SetSize(C.buSize, C.buSize*2)
	-- 圖示和標記
	self.RaidTargetIndicator:SetPoint("BOTTOM", self.Health, "TOP", 0, -10)
end

-- 目標的目標橫式
local function CreateToTStyle(self, unit)
	self.mystyle = "H"
	
	-- 框體
	CreateUnitShared(self, unit)		-- 繼承通用樣式	
	self:SetSize(C.TOTWidth, C.PHeight)	-- 主框體尺寸

	-- 文本
	self.Name:SetPoint("TOPRIGHT", self.Health, 0, G.NameFS/2 + C.PPHeight)
	self.Name:SetJustifyH("RIGHT")
	self.Name:SetWidth(self:GetWidth()*0.9)
	
	-- 光環
	if UnitCanAttack("player", unit) then
		-- 敵方顯示增益
		T.CreateBuffs(self)
		self.Buffs:SetPoint("RIGHT", self.Health, "LEFT", -6, -2)
		self.Buffs.initialAnchor = "RIGHT"
		self.Buffs["growth-x"] = "LEFT"
		self.Buffs.num = 2
		self.Buffs.size = C.buSize
		self.Buffs.spacing = 5
		self.Buffs:SetSize(C.buSize*2, C.buSize)
	else
		-- 友方顯示減益
		T.CreateDebuffs(self)
		self.Debuffs:SetPoint("RIGHT", self.Health, "LEFT", -6, -2)
		self.Debuffs.initialAnchor = "RIGHT"
		self.Debuffs["growth-x"] = "LEFT"
		self.Debuffs.num = 2
		self.Debuffs.size = C.buSize
		self.Debuffs.spacing = 5
		self.Debuffs:SetSize(C.buSize*2, C.buSize)
	end
	
	-- 圖示和標記
	self.RaidTargetIndicator:SetPoint("RIGHT", self.Health, 14, 0)
end

-- 目標的目標直式
local function CreateVToTStyle(self, unit)
	self.mystyle = "VR"
	
	-- 框體
	CreateUnitShared(self, unit)		-- 繼承通用樣式	
	self:SetSize(C.PHeight, C.TOTWidth)	-- 主框體尺寸

	-- 文本
	self.Name:SetPoint("BOTTOMLEFT", self.Power, "BOTTOMRIGHT", C.PPOffset, 0)
	
	-- 光環
	if UnitCanAttack("player", unit) then
		-- 敵方顯示增益
		T.CreateBuffs(self)
		self.Buffs:SetPoint("TOPLEFT", self.Power, "TOPRIGHT", 6, -2)
		self.Buffs.initialAnchor = "TOP"
		self.Buffs["growth-y"] = "DOWN"
		self.Buffs.num = 2
		self.Buffs.size = C.buSize
		self.Buffs.spacing = 5
		self.Buffs:SetSize(C.buSize, C.buSize*2)
	else
		-- 友方顯示減益
		T.CreateDebuffs(self)
		self.Debuffs:SetPoint("TOPLEFT", self.Power, "TOPRIGHT", 6, -2)
		self.Debuffs.initialAnchor = "TOP"
		self.Debuffs["growth-y"] = "DOWN"
		self.Debuffs.num = 2
		self.Debuffs.size = C.buSize
		self.Debuffs.spacing = 5
		self.Debuffs:SetSize(C.buSize, C.buSize*2)
	end
	
	-- 圖示和標記
	self.RaidTargetIndicator:SetPoint("BOTTOM", self.Health, "TOP", 0, -10)
end

-- 首領
local function CreateBossStyle(self, unit)
	self.mystyle = "H"
	
	-- 框體
	CreateUnitShared(self, unit)		-- 繼承通用樣式	
	self:SetSize(C.BWidth, C.PHeight)	-- 主框體尺寸

	-- 文本
	self.Status:SetPoint("TOPLEFT", self.Health, 0, G.NameFS/2+C.PPHeight)
	self.Status:SetJustifyH("LEFT")
	self.Name:SetPoint("LEFT", self.Status, "RIGHT", 0, 0)
	self.Name:SetJustifyH("LEFT")
	self.Name:SetWidth(self:GetWidth()*0.9)
	self.Name:SetWidth(self:GetWidth() * 0.8)
	self.Health.value:SetPoint("LEFT", 0, 5)
	self.Power.value:SetPoint("RIGHT", 0, 5)
	
	-- 施法條
	if C.Castbar then
		T.CreateCastbar(self, unit)
		self.Castbar.Icon:SetPoint("TOPLEFT", self.Health, "TOPRIGHT", 6, 0)
		self.Castbar.Text:SetPoint("TOPLEFT", self.Health, 0, G.NameFS/2+C.PPHeight)
		self.Castbar.Text:SetJustifyH("LEFT")
		self.Castbar.Text:SetWidth(self:GetWidth() * 0.7)
		self.Castbar.Time:SetPoint("TOPRIGHT", self.Health, 0, G.NameFS/2+C.PPHeight)
		self.Castbar.Time:SetJustifyH("RIGHT")
	end
	
	-- 減益
	T.CreateDebuffs(self)		
	self.Debuffs:SetPoint("BOTTOMLEFT", self.Health, "TOPLEFT", 1, C.PPOffset*2+C.PPHeight)
	self.Debuffs.initialAnchor = "LEFT"
	self.Debuffs["growth-x"] = "RIGHT"
	self.Debuffs.onlyShowPlayer = true
	self.Debuffs.num = 3
	self.Debuffs.size = C.buSize
	self.Debuffs.spacing = 5
	self.Debuffs:SetSize(C.PWidth, C.buSize)
	
	-- 增益
	T.CreateBuffs(self)		
	self.Buffs:SetPoint("BOTTOMRIGHT", self.Health, "TOPRIGHT", -1, C.PPOffset*2+C.PPHeight)
	self.Buffs.initialAnchor = "RIGHT"
	self.Buffs["growth-x"] = "LEFT"
	self.Buffs.num = 2
	self.Buffs.size = C.buSize
	self.Buffs.spacing = 5
	self.Buffs:SetSize(C.PWidth, C.buSize)
	
	-- 圖示和標記
	self.RaidTargetIndicator:SetPoint("RIGHT", self.Health, 14, 0)
end

--===================================================--
--------------    [[ RegisterStyle ]]     -------------
--===================================================--
-- 註冊樣式

oUF:RegisterStyle(G.addon, CreateUnitShared)

if C.vertPlayer then
	oUF:RegisterStyle("Player", CreateVPlayerStyle)
	oUF:RegisterStyle("Pet", CreateVPetStyle)
else
	oUF:RegisterStyle("Player", CreatePlayerStyle)
	oUF:RegisterStyle("Pet", CreatePetStyle)
end

if C.vertTarget then
	oUF:RegisterStyle("Target", CreateVTargetStyle)
	oUF:RegisterStyle("ToT", CreateVToTStyle)
else
	oUF:RegisterStyle("Target", CreateTargetStyle)
	oUF:RegisterStyle("ToT", CreateToTStyle)
end

if C.Boss then
	oUF:RegisterStyle("Boss", CreateBossStyle)
end


--===================================================--
-----------------    [[ Spawn ]]     ------------------
--===================================================--
-- 生成

oUF:Factory(function(self)
	
	if C.vertPlayer then
		-- 玩家
		self:SetActiveStyle("Player")
		local player = self:Spawn("player", "oUF_Player")
		player:SetPoint(unpack(C.Position.VPlayer))
		-- 寵物
		self:SetActiveStyle("Pet")
		local pet = self:Spawn("pet", "oUF_Pet")
		pet:SetPoint(unpack(C.Position.VPet))
	else
		-- 玩家
		self:SetActiveStyle("Player")
		local player = self:Spawn("player", "oUF_Player")
		player:SetPoint(unpack(C.Position.Player))
		-- 寵物
		self:SetActiveStyle("Pet")
		local pet = self:Spawn("pet", "oUF_Pet")
		pet:SetPoint(unpack(C.Position.Pet))
	end
	
	if C.vertTarget then
		-- 目標
		self:SetActiveStyle("Target")
		local target = self:Spawn("target", "oUF_Target")
		target:SetPoint(unpack(C.Position.VTarget))
		-- 目標的目標
		self:SetActiveStyle("ToT")
		local targettarget = self:Spawn("targettarget", "oUF_ToT")
		targettarget:SetPoint(unpack(C.Position.VTOT))
	else
	-- 目標
		self:SetActiveStyle("Target")
		local target = self:Spawn("target", "oUF_Target")
		target:SetPoint(unpack(C.Position.Target))
		-- 目標的目標
		self:SetActiveStyle("ToT")
		local targettarget = self:Spawn("targettarget", "oUF_ToT")
		targettarget:SetPoint(unpack(C.Position.TOT))
	end
	
	if C.Boss then
		-- 首領
		self:SetActiveStyle("Boss")
		local boss = {}
		for i = 1, MAX_BOSS_FRAMES do
			local unit = self:Spawn("boss"..i, "oUF_Boss"..i)
			if i == 1 then
				unit:SetPoint(unpack(C.Position.Boss))
			else
				unit:SetPoint("TOP", boss[i-1], "BOTTOM", 0, -(C.PHeight+C.buSize+C.PPOffset*2))
			end
			boss[i] = unit
		end
	end
end)