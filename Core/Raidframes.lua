local _, ns = ...
local oUF = ns.oUF
local C, F, G, T = unpack(ns)

local function GroupFramesEnabled()
	return F.GetRuriOption("RaidFrames") or F.GetRuriOption("PartyFrames")
end

--[[
local function ClassAuraFilter(self, unit, data)
	if C.RaidBuffList[data.spellId] then
		return true
	end
end
]]--
--====================================================--
-----------------    [[ Function ]]    -----------------
--====================================================--

-- 陰影變色：常態黑框，選中白框，仇恨高亮
local function UpdateGroupBorder(self, event, unit)
	if unit and unit ~= self.__unit then return end

	local status = UnitThreatSituation(self.__unit)
	if status and status > 1 then
		local color = oUF.colors.threat[status]
		self.Health.shadow:SetBackdropBorderColor(color:GetRGB())
	elseif UnitIsUnit("target", self.__unit) then
		self.Health.shadow:SetBackdropBorderColor(.9, .9, .9)
	else
		self.Health.shadow:SetBackdropBorderColor(.05, .05, .05)
	end
end

-- 職責圖示
local groupRoleTextures = {
	[Enum.LFGRole.Tank] = G.media.role_tank,
	[Enum.LFGRole.Healer] = G.media.role_healer,
	[Enum.LFGRole.Damage] = G.media.role_dps,
}

local function PostUpdateGroupRole(element, role)
	local texture = groupRoleTextures[role]
	if texture then
		element:SetTexture(texture)
		element:SetTexCoord(0, 1, 0, 1)
	end
end

-- 12.1 fix: 非首領戰的跨地圖或位面單位可能令 filter 失效，錯誤地納入普通光環
-- 為了避免這個情況，不在一起的隊友直接禁止光環顯示
local function PostUpdateGroupPhase(element, phaseReason)
	local owner = element.__owner
	local enabled = C_InstanceEncounter.IsEncounterInProgress()
		or (UnitIsVisible(owner.__unit) and not phaseReason)

	if owner.Debuffs then
		owner.Debuffs:SetEnabled(enabled)
	end
	if owner.Buffs then
		owner.Buffs:SetEnabled(enabled)
	end
end

--===========================================================--
-----------------    [[ Create Elements ]]    -----------------
--===========================================================--

--=========================================================--
-----------------    [[ Create Frames ]]    -----------------
--=========================================================--

local function CreateGroupShared(self, unit, width, height, powerHeight, frequentPowerUpdates)

	-- [[ 前置作業 ]] --
	self:SetScript("OnEnter", F.UnitFrameOnEnter)	-- mouseover tooltip
	self:SetScript("OnLeave", UnitFrame_OnLeave)
	self:RegisterForClicks("AnyUp")
	self:SetSize(width, height)
	
	-- [[ 高亮 ]] --
	local hl = self:CreateTexture(nil, "HIGHLIGHT")
	hl:SetAllPoints(self)
	hl:SetTexture(G.media.barhightlight)
	hl:SetVertexColor(1, 1, 1, .5)
	hl:SetTexCoord(0, 1, 1, 0)
	hl:SetBlendMode("ADD")
	self.Highlight = hl
	
	-- [[ 血量條 ]] --

	-- 創建一個條
	local Health = CreateFrame('StatusBar', nil, self)
	Health:SetAllPoints(self)
	Health:SetFrameLevel(self:GetFrameLevel())
	Health:SetStatusBarTexture(G.media.raidbar)
	--Health:SetStatusBarColor(0, 0, 0, .4)	-- 材質本身就透明
	-- 選項
	Health.colorClass = true
	-- 背景
	Health.bg = Health:CreateTexture(nil, "BACKGROUND")
	Health.bg:SetTexture(G.media.blank)
	-- 背景的位置：在反轉血量條中，血條是透明的，背景才是表示血量的實體，因此將長度依附於血量條本體，尺寸隨血量而變化
	Health.bg:SetPoint("TOPLEFT", Health:GetStatusBarTexture(), "TOPRIGHT", 0, 0)
	Health.bg:SetPoint("BOTTOMRIGHT", Health, "BOTTOMRIGHT", 0, 0)
	-- 邊框：透明背景和1px邊框
	Health.border = F.CreateBD(Health, Health, 1, 0, 0, 0, 0, 1)
	-- 陰影
	Health.shadow = F.CreateSD(Health, Health.border, 4)
	-- 註冊到OUF
	self.Health = Health
	self.Health.PostUpdate = T.PostUpdateHealth	-- 更新機制：顯示損血量，使血量漸變色和透明度隨損血量改變

	-- 目標高亮，陰影變色
	self:RegisterEvent("PLAYER_TARGET_CHANGED", UpdateGroupBorder, true)
	self:RegisterEvent("GROUP_ROSTER_UPDATE", UpdateGroupBorder, true)
	-- 仇恨高亮，陰影變色
	local threat = CreateFrame("Frame", nil, self)
	self.ThreatIndicator = threat
	self.ThreatIndicator.Override = UpdateGroupBorder
	
	-- [[ 能量條 ]] --

	local Power = F.CreateStatusbar(self, G.addon..unit.."_PowerBar", "ARTWORK", nil, nil, 0, 0, 0, 1)
	Power:SetHeight(powerHeight)
	Power:SetPoint("BOTTOMLEFT", self.Health, 0, 0)	-- 與血量條等寬
	Power:SetPoint("BOTTOMRIGHT", self.Health, 0, 0)
	Power:SetFrameLevel(self:GetFrameLevel() + 2)
	-- 選項
	Power.frequentUpdates = frequentPowerUpdates
	Power.colorPower = true
	Power.colorDisconnected = true
	-- 背景
	Power.bg = Power:CreateTexture(nil, "BACKGROUND")
	Power.bg:SetAllPoints()
	Power.bg:SetTexture(G.media.blank)
	Power.bg:SetVertexColor(.05, .05, .05, 1)
	-- 邊框：能量條做在主框體內，所以只需要上方一條1px的線
	Power.border = Power:CreateTexture(nil, "ARTWORK")
	Power.border:SetHeight(1)
	Power.border:SetPoint("TOPLEFT", Power, 0, 1)	-- 與能量條等寬
	Power.border:SetPoint("TOPRIGHT", Power, 0, 1)
	Power.border:SetTexture(G.media.blank)
	Power.border:SetVertexColor(.05, .05, .05, 1)	-- 和背景同色
	-- 註冊到OUF
	self.Power = Power
	
	-- [[ 圖示 ]] --
	
	-- 建立一個提供給圖示依附的父級框體，框體層級高，避免被蓋住
	local StringParent = CreateFrame("Frame", nil, self)
	StringParent:SetFrameLevel(self:GetFrameLevel() + 8)
	self.StringParent = StringParent

	-- 團隊標記
	local RaidTarget = StringParent:CreateTexture(nil, "OVERLAY")
	RaidTarget:SetSize(28, 28)
	RaidTarget:SetTexture(G.media.raidicon)
	self.RaidTargetIndicator = RaidTarget
	-- 助手
	local Assistant = StringParent:CreateTexture(nil, "OVERLAY")
	Assistant:SetSize(14, 14)
	self.AssistantIndicator = Assistant
	-- 領隊
	local Leader = StringParent:CreateTexture(nil, "OVERLAY")
	Leader:SetSize(14, 14)
	self.LeaderIndicator = Leader
	-- 團隊確認
	local RDCheck = StringParent:CreateTexture(nil, "OVERLAY")
	RDCheck:SetSize(20, 20)
	RDCheck:SetPoint("CENTER", self.Health, 0, -3)
	self.ReadyCheckIndicator = RDCheck
	-- 異位面
	local phase = StringParent:CreateTexture(nil, "OVERLAY")
	phase:SetSize(20, 20)
	phase:SetPoint("CENTER", self.Health, 0, -3)
	phase.PostUpdate = PostUpdateGroupPhase
	self.PhaseIndicator = phase
	-- 召喚
	local Summon = StringParent:CreateTexture(nil, "OVERLAY")
    Summon:SetSize(28, 28)
    Summon:SetPoint("CENTER", self.Health, 0, -3)
    self.SummonIndicator = Summon
	-- 復活
    local Res = StringParent:CreateTexture(nil, "OVERLAY")
    Res:SetSize(20, 20)
    Res:SetPoint("CENTER", self.Health, 0, -3)
    self.ResurrectIndicator = Res
	-- 職責
    local Role = StringParent:CreateTexture(nil, "OVERLAY")
    Role:SetSize(16, 16)
    Role:SetPoint("TOPLEFT", self.Health, 3, 6)
    Role:SetDesaturated(true)
    self.GroupRoleIndicator = Role
	self.GroupRoleIndicator.PostUpdate = PostUpdateGroupRole
	
	-- [[ 文本/TAGS ]] --
	
	-- 名字與狀態
	self.Name = F.CreateText(StringParent, "OVERLAY", G.Font, G.NameFS, G.FontFlag, "RIGHT")
	self.Name:SetPoint("TOPRIGHT", self.Health, -2, -3)
	self.Name.frequentUpdates = 5
	self:Tag(self.Name, "[namecolor][name][afkdnd]")
	
	-- 死亡背景
	self.DeadSkull = F.CreateText(self.Health, "OVERLAY", G.Font, height, G.FontFlag, "CENTER")
	self.DeadSkull:SetAlpha(.4)
	self:Tag(self.DeadSkull, "[deadskull]")
end

local function CreateParty(self, unit)
	self.mystyle = "R"
	self.Range = { insideAlpha = 1, outsideAlpha = .5, }

	-- 小隊人數少，保留 UNIT_POWER_FREQUENT 的即時能量更新。
	CreateGroupShared(self, unit, C.PartyWidth, C.PartyHeight, C.PartyPHeight, true)
	-- 吸收盾
	T.CreateHealthPrediction(self, true)
	-- 文本
	self.Name:SetWidth(C.PartyWidth - 4)
	-- 死亡背景
	self.DeadSkull:SetWidth(C.PartyWidth - 4)
	self.DeadSkull:SetPoint("CENTER", -10, 0)
	-- 光環
	if F.GetRuriOption("PartyDebuffs") then T.CreateRaidDebuffs(self) end
	if F.GetRuriOption("PartyBuffs") then T.CreateRaidBuffs(self) end
	-- 圖示和標記
	self.RaidTargetIndicator:SetPoint("TOPRIGHT", self.Health, -12, 12)
	self.AssistantIndicator:SetPoint("TOPRIGHT", self.Health, 3, 10)
	self.LeaderIndicator:SetPoint("TOPRIGHT", self.Health, 3, 8)
end

local function CreateRaid(self, unit)
	self.mystyle = "R"
	self.Range = { insideAlpha = 1, outsideAlpha = .4, }

	-- 團隊改用 UNIT_POWER_UPDATE，降低多人框架的能量事件頻率。
	CreateGroupShared(self, unit, C.RWidth, C.RHeight, C.RPHeight, false)
	-- 吸收盾
	T.CreateHealthPrediction(self, true)
	-- 文本
	self.Name:SetWidth(C.RWidth - 4)
	-- 死亡背景
	self.DeadSkull:SetWidth(C.RWidth - 4)
	self.DeadSkull:SetPoint("CENTER", -5, 0)
	-- 光環
	if F.GetRuriOption("RaidDebuffs") then T.CreateRaidDebuffs(self) end
	if F.GetRuriOption("RaidBuffs") then T.CreateRaidBuffs(self) end
	-- 圖示和標記
	self.RaidTargetIndicator:SetPoint("TOPRIGHT", self.Health, -12, 12)
	self.AssistantIndicator:SetPoint("TOPRIGHT", self.Health, 3, 10)
	self.LeaderIndicator:SetPoint("TOPRIGHT", self.Health, 3, 8)
end

--===================================================--
-----------------    [[ Spawn ]]     ------------------
--===================================================--

oUF:Factory(function(self)
	if not GroupFramesEnabled() then return end

	local partyFrames = F.GetRuriOption("PartyFrames")
	local raidFrames = F.GetRuriOption("RaidFrames")

	if raidFrames then
		self:RegisterStyle("Raid", CreateRaid)
	end

	if partyFrames then
		self:RegisterStyle("Party", CreateParty)
	end

	if partyFrames then
		local partyAnchor = CreateFrame("Frame", nil, UIParent)
		partyAnchor:SetSize(20, 20)
		partyAnchor:ClearAllPoints()
		partyAnchor:SetPoint(unpack(C.Position.Party))
		
		self:SetActiveStyle("Party")
		local party = self:SpawnHeader("oUF_Party", nil,
			"showSolo",			false,
			"showParty",		true,
			"showRaid",			false,
			"showPlayer",		true,

			"point",			"TOP",
			"columnAnchorPoint","LEFT",

			"sortMethod",		"INDEX", -- or "NAME"
			"startingIndex",	1,
			
			"unitsPerColumn",	5,
			"columnSpacing",	C.PartySpace,
			"xOffset",			C.PartySpace,
			"yOffset",			-C.PartySpace,
			
			"oUF-initialConfigFunction", ([[
				self:SetWidth(%d)
				self:SetHeight(%d)
			]]):format(C.PartyWidth, C.PartyHeight)
		)
		party:SetVisibility("party")

		party:SetPoint("TOPLEFT", partyAnchor, "BOTTOMRIGHT", -20, 4)

		--[[
		-- as same as default partyframe, it dont have self unitframe
		self:SetActiveStyle("Party")
		local party = {}
		for i = 1, 4 do
			local unit = self:Spawn("party"..i, "oUF_Party"..i)
			if i == 1 then
				unit:SetPoint(unpack(C.Position.Party))
			else
				unit:SetPoint("TOP", party[i-1], "BOTTOM", 0, -(C.PartySpace+C.PartyPHeight+2))
			end
			party[i] = unit
		end]]--
	end

	if raidFrames then
        local raidAnchor = CreateFrame("Frame", nil, UIParent)
        raidAnchor:SetSize(20, 20)
        raidAnchor:ClearAllPoints()
        raidAnchor:SetPoint(unpack(C.Position.Raid))
        
        self:SetActiveStyle("Raid")
        local raid = {}
        
        for i = 1, 8 do
            raid[i] = self:SpawnHeader("oUF_Raid"..i, nil,
                "showSolo",         false,
                "showParty",        false,
                "showRaid",         true,
                "showPlayer",       true,
                
                "groupFilter",		tostring(i),
				"groupingOrder",	tostring(i),
                "groupBy",          "GROUP",
                "sortMethod",       "INDEX",
                "startingIndex",    1,
                
                "maxColumns",       1,
                "unitsPerColumn",   5,
                
                "point",            "TOP",
                "columnAnchorPoint","LEFT",
                "columnSpacing",    C.RSpace,
                "xOffset",          C.RSpace,
                "yOffset",          -C.RSpace,
                
                "oUF-initialConfigFunction", ([[
                    self:SetWidth(%d)
                    self:SetHeight(%d)
                ]]):format(C.RWidth, C.RHeight)
            )
            raid[i]:SetVisibility("raid")
            
            if i == 1 then
                raid[i]:SetPoint("TOPLEFT", raidAnchor, "BOTTOMRIGHT", -20, 4)
            elseif i == 5 then
                raid[i]:SetPoint("TOPLEFT", raidAnchor, "BOTTOMRIGHT", -20, -(C.RHeight*5+C.RSpace*6+30))
            else
                raid[i]:SetPoint("TOPLEFT", raid[i-1], "TOPRIGHT", C.RSpace, 0)
            end
        end
    end
end)
