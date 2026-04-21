local addon, ns = ...
local oUF = ns.oUF
local C, F, G, T = unpack(ns)

if not C.UnitFrames then return end

--===================================================--
---------------    [[ UnitShared ]]     ---------------
--===================================================--

-- 框體共享的設定
local function CreateUnitShared(self, unit)

	-- [[ 前置作業 ]] --	
	local u = unit:match("[^%d]+") -- boss1 -> boss
	self:RegisterForClicks("AnyUp")	-- Make mouse active
	
	-- [[ 高亮 ]] --
	
	local hl = self:CreateTexture(nil, "HIGHLIGHT")
	hl:SetAllPoints(self)
	hl:SetTexture(G.media.barhightlight)
	hl:SetVertexColor(1, 1, 1, .5)
	hl:SetBlendMode("ADD")
	-- 高亮方向
	if self.mystyle == "VL" then
		hl:SetTexCoord(0, 1, 1, 1, 0, 0, 1, 0)  -- -90度
	elseif  self.mystyle == "VR" then
		hl:SetTexCoord(1, 0, 0, 0, 1, 1, 0, 1)	-- 90度
	else
		hl:SetTexCoord(1, 0, 0, 1)
	end
	-- 指向高亮
	self.Highlight = hl
	self:HookScript("OnEnter", function()
		UnitFrame_OnEnter(self)
		self.Highlight:Show()
	end)
	self:HookScript("OnLeave", function()
		UnitFrame_OnLeave(self)
		self.Highlight:Hide()
	end)
	
	-- [[ 血量條 ]] --
	
	-- 創建一個條
	local Health = F.CreateStatusbar(self, G.addon..unit.."_HealthBar", "ARTWORK", nil, nil, 0, 0, 0, .4)
	Health:SetAllPoints(self)
	Health:SetFrameLevel(self:GetFrameLevel())
	-- 直式判定
	if self.mystyle ~= "H" then Health:SetOrientation("VERTICAL") end
	-- 背景
	local bg = Health:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture(G.media.blank)
	-- 背景的位置：在反轉血量條中，血條是透明的，背景才是表示血量的實質，其長度依附於血量條本體，隨血量而變化
    if self.mystyle == "VL" or self.mystyle == "VR" then
		-- 直式血條：由下往上
		bg:SetPoint("BOTTOMLEFT", Health:GetStatusBarTexture(), "TOPLEFT", 0, 0)
		bg:SetPoint("TOPRIGHT", Health, "TOPRIGHT", 0, 0)
	else
		-- 橫式血條：由左往右
		bg:SetPoint("TOPLEFT", Health:GetStatusBarTexture(), "TOPRIGHT", 0, 0)
		bg:SetPoint("BOTTOMRIGHT", Health, "BOTTOMRIGHT", 0, 0)
	end
    Health.bg = bg
	-- 邊框
	Health.border = F.CreateSD(Health, Health, 4)
	-- 註冊到ouf
	self.Health = Health
	self.Health.PostUpdate = T.PostUpdateHealth	-- 更新機制：血量漸變色背景

	-- [[ 能量條 ]] --
	
	-- 創建一個條
	local Power = F.CreateStatusbar(self, G.addon..unit.."_PowerBar", "ARTWORK", nil, nil, 1, 1, 1, 1)	-- 不透明的
	-- 直式判定：橫式與血量條等寬，直式與血量條等高
	if self.mystyle == "H" then
		Power:SetHeight(C.PPHeight)
		Power:SetPoint("TOPLEFT", self.Health, "BOTTOMLEFT", 0, -C.PPOffset)
		Power:SetPoint("TOPRIGHT", self.Health, "BOTTOMRIGHT", 0, -C.PPOffset)
	else
		Power:SetWidth(C.PPHeight)
		Power:SetOrientation("VERTICAL")

		if self.mystyle == "VL" then
			Power:SetPoint("BOTTOMRIGHT", self.Health, "BOTTOMLEFT", -C.PPOffset, 0)	
			Power:SetPoint("TOPRIGHT", self.Health, "TOPLEFT", -C.PPOffset, 0)
		elseif  self.mystyle == "VR" then
			Power:SetPoint("BOTTOMLEFT", self.Health, "BOTTOMRIGHT", C.PPOffset, 0)
			Power:SetPoint("TOPLEFT", self.Health, "TOPRIGHT", C.PPOffset, 0)
		end
	end
	-- 若要使其浮於血量條之上，應使其框體層級高於父級框體
	Power:SetFrameLevel(self:GetFrameLevel() + 2)
	-- 選項
	Power.frequentUpdates = true	-- 更新速率
	Power.colorClass = true			-- 職業染色
	Power.colorReaction = true		-- 陣營染色
	Power.colorDisconnected = true	-- 離線染色
	-- 背景
	Power.bg = Power:CreateTexture(nil, "BACKGROUND")
	Power.bg:SetAllPoints()
	Power.bg:SetTexture(G.media.blank)
	Power.bg.multiplier = .3
	-- 邊框
	Power.border = F.CreateSD(Power, Power, 4)
	-- 註冊到ouf
	self.Power = Power
	self.Power.PostUpdateColor = T.PostUpdatemMultiBGColor	-- 背景顏色

	-- [[ 圖示 ]] --
	
	-- 建立一個提供給圖示依附的父級框體，框體層級高，避免被蓋住
	local StringParent = CreateFrame("Frame", nil, self)
	--StringParent:SetAllPoints(self)
	StringParent:SetFrameLevel(self:GetFrameLevel() + 8)
	self.StringParent = StringParent
	-- 團隊標記
	local RaidTarget = StringParent:CreateTexture(nil, "OVERLAY")
	RaidTarget:SetSize(28, 28)
	RaidTarget:SetTexture(G.media.raidicon)
	self.RaidTargetIndicator = RaidTarget
	-- 團隊助手
	local Assistant = StringParent:CreateTexture(nil, "OVERLAY")
	Assistant:SetSize(14, 14)
	self.AssistantIndicator = Assistant
	-- 	隊伍領袖
	local Leader = StringParent:CreateTexture(nil, "OVERLAY")
	Leader :SetSize(14, 14)
	self.LeaderIndicator = Leader
	-- 戰鬥狀態
	local Combat = StringParent:CreateTexture(nil, "OVERLAY")
	Combat:SetSize(24, 24)
	Combat:SetTexture(G.media.combat)
	Combat:SetVertexColor(1, 1, 0)
	self.CombatIndicator = Combat
	self.CombatIndicator.PostUpdate = T.CombatPostUpdate
	-- 休息狀態
	local Resting = StringParent:CreateTexture(nil, "OVERLAY")
	Resting:SetSize(20, 20)
	Resting:SetTexture(G.media.resting)
	self.RestingIndicator = Resting
	-- 位面狀態
	local Phase = StringParent:CreateTexture(nil, "OVERLAY")
	Phase:SetSize(20, 20)
	--Phase:SetTexture()
	Phase:SetPoint("CENTER", self.Health, 0, 0)
	self.PhaseIndicator = Phase

	-- [[ 文本/TAGS ]] --
	
	-- 血量
	self.Health.value = F.CreateText(StringParent, "OVERLAY", G.Font, G.NameFS, G.FontFlag, "LEFT")
	self:Tag(self.Health.value, "[unit:hp]")
	-- 能量
	self.Power.value = F.CreateText(StringParent, "OVERLAY", G.Font, G.NameFS, G.FontFlag, "RIGHT")
	self:Tag(self.Power.value, "[unit:pp]")
	-- 名字
	self.Name = F.CreateText(self.Health, "OVERLAY", G.Font, G.NameFS, G.FontFlag, nil)
	self:Tag(self.Name, "[namecolor][name]")
	-- 狀態：暫離/忙錄/等級
	self.Status = F.CreateText(self.Health, "OVERLAY", G.Font, G.NameFS, G.FontFlag, nil)
	self:Tag(self.Status, "[afkdnd][difficulty][smartlevel][quest] ")
end

-- 玩家橫式 / Player
local function CreatePlayerStyle(self, unit)
	self.mystyle = "H"
	
	-- 框體
    CreateUnitShared(self, unit)		-- 繼承通用樣式
	self:SetSize(C.PWidth, C.PHeight)	-- 主框體尺寸
	
	-- 文本
	self.Health.value:SetPoint("LEFT", self.Power, 0, 2)
	self.Power.value:SetPoint("RIGHT", self.Power, 0, 2)
	
	-- 特殊能量
	--T.CreateAltPowerBar(self, unit)
	--self.AlternativePower.value:SetPoint("CENTER",  0, -3)
	
	-- 吸收盾
	--T.CreateHealthPrediction(self, unit)	
	-- 職業資源
	T.CreateClassPower(self, unit)
	--T.CreateAddPower(self, unit)
	T.CreateStagger(self, unit)
	--if C.TankResource then T.CreateTankResource(self, unit) end
	--if C.Totems then T.CreateTotemBar(self) end

	-- 施法條
	--[[if C.StandaloneCastbar then
		T.CreateStandaloneCastbar(self, unit)
		self.Castbar:SetWidth(C.CastbarWidth)
		self.Castbar.Icon:SetPoint(unpack(C.Position.PlayerCastbar))
		self.Castbar:SetPoint("LEFT", self.Castbar.Icon, "RIGHT", C.PPOffset, 0)
	else
		T.CreateCastbar(self, unit)
		self.Castbar.Icon:SetPoint("TOPLEFT", self.Health, "TOPRIGHT", 6, -1)
		self.Castbar.Text:SetPoint("CENTER", self.Health, 0, 2)
		self.Castbar.Text:SetJustifyH("CENTER")
		self.Castbar.Text:SetWidth(self:GetWidth())
		self.Castbar.Time:SetPoint("CENTER", self.Power, "CENTER", 0, 2)
		self.Castbar.Time:SetJustifyH("CENTER")
	end]]--
	
	-- 減益
	--[[if C.PlayerDebuffs then
		T.CreateDebuffs(self)		
		self.Debuffs["growth-x"] = "RIGHT"
		self.Debuffs["growth-y"] = "UP"
		self.Debuffs.num = 6
		self.Debuffs.size = C.buSize + 4
		self.Debuffs:SetSize(C.PWidth, C.buSize + 4)
		--self.Debuffs:SetPoint("BOTTOMLEFT", self.Health, "TOPLEFT", 1, C.PHeight/2 + C.PPOffset)
		self.Debuffs.PreUpdate = T.PostUpdatePlayerDebuffs
	end]]--
	
	-- 圖示和標記
	self.RaidTargetIndicator:SetPoint("TOP", self.Health, 0, 16)
	self.AssistantIndicator:SetPoint("TOPRIGHT", self.Health, -4, C.PHeight/2)
	self.LeaderIndicator:SetPoint("TOPRIGHT", self.Health, -4, C.PHeight/2)
	self.CombatIndicator:SetPoint("TOPLEFT", self.Health, 4, -4)
	self.RestingIndicator:SetPoint("TOPLEFT", self.Health, 4, -4)
end

--===================================================--
--------------    [[ RegisterStyle ]]     -------------
--===================================================--
-- 註冊樣式

--oUF:RegisterStyle(G.addon, CreateUnitShared)

if C.vertPlayer then
	oUF:RegisterStyle("Player", CreateVPlayerStyle)
else
	oUF:RegisterStyle("Player", CreatePlayerStyle)
end

--===================================================--
-----------------    [[ Spawn ]]     ------------------
--===================================================--
-- 生成

oUF:Factory(function(self)
	-- Should not disable it, may cause refresh delay issue
	SetCVar("predictedHealth", 1)
	
	if C.vertPlayer then
		-- 玩家
		self:SetActiveStyle("Player")
		local player = self:Spawn("player", "oUF_Player")
		player:SetPoint(unpack(C.Position.VPlayer))

	else
		-- 玩家
		self:SetActiveStyle("Player")
		local player = self:Spawn("player", "oUF_Player")
		player:SetPoint(unpack(C.Position.Player))

	end
end)