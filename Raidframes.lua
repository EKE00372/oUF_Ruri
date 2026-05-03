local addon, ns = ...
local oUF = ns.oUF
local C, F, G, T = unpack(ns)

if not (C.RaidFrames or C.PartyFrames) then return end

-- Hide Default CompactRaidFrame and keep CompactRaidFrameManager
do
    local function HideRaid()
        if CompactRaidFrameContainer then
            CompactRaidFrameContainer:UnregisterAllEvents()
            CompactRaidFrameContainer:Hide()
        end
        if CompactPartyFrame then
            CompactPartyFrame:UnregisterAllEvents()
        end
    end

	hooksecurefunc("CompactRaidFrameManager_UpdateShown",function() HideRaid() end)
end

-- Manager fader code frome Deja PRFader
do
	local function WaitForMouseToGoAway(self)
		if not self:IsMouseOver() then
			self:SetScript("OnUpdate", nil)
			self:SetAlpha(0)
		end
	end

	CompactRaidFrameManager:HookScript("OnEnter", function(self)
		self:SetScript("OnUpdate", nil)
		self:SetAlpha(1)
	end)

	CompactRaidFrameManager:HookScript("OnLeave", function(self)
		if self.collapsed then
			self:SetScript("OnUpdate", WaitForMouseToGoAway)
		end
	end)

	local function CheckMouseOver(self)
		if self:IsMouseOver() and not self.collapsed then
			self:GetScript("OnEnter")(self)
		else
			self:GetScript("OnLeave")(self)
		end
	end

	hooksecurefunc("CompactRaidFrameManager_Collapse", function(self) CheckMouseOver(CompactRaidFrameManager) end)
	hooksecurefunc("CompactRaidFrameManager_Expand", function(self) CheckMouseOver(CompactRaidFrameManager) end)

	CompactRaidFrameManager:HookScript("OnShow", function(self) CheckMouseOver(CompactRaidFrameManager) end)

	local function CRFCUpdate(self)
		if InCombatLockdown() then 
			CompactRaidFrameContainer:UnregisterAllEvents();
		elseif not InCombatLockdown() then
			CompactRaidFrameContainer:RegisterEvent("DISPLAY_SIZE_CHANGED");
			CompactRaidFrameContainer:RegisterEvent("UI_SCALE_CHANGED");
			CompactRaidFrameContainer:RegisterEvent("GROUP_ROSTER_UPDATE");
			CompactRaidFrameContainer:RegisterEvent("UNIT_FLAGS");
			CompactRaidFrameContainer:RegisterEvent("PLAYER_FLAGS_CHANGED");
			CompactRaidFrameContainer:RegisterEvent("PLAYER_ENTERING_WORLD");
			CompactRaidFrameContainer:RegisterEvent("PARTY_LEADER_CHANGED");
			CompactRaidFrameContainer:RegisterEvent("RAID_TARGET_UPDATE");
			CompactRaidFrameContainer:RegisterEvent("PLAYER_TARGET_CHANGED");
			CompactRaidFrameContainer:SetParent(UIParent)
		end
	end

	hooksecurefunc("CompactUnitFrame_UpdateVisible", CRFCUpdate)
	hooksecurefunc("CompactUnitFrame_UpdateAll", CRFCUpdate)
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

-- 目標高亮
local function UpdateTargetBorder(self, event, unit)
	-- 使優先級低於仇恨高亮
	local status = UnitThreatSituation(self.unit)
	if status and status ~= 0 then return end
	
	if UnitIsUnit("target", self.unit) then
		self.Health.shadow:SetBackdropBorderColor(.9, .9, .9)
	else
		self.Health.shadow:SetBackdropBorderColor(.05, .05, .05)
	end
end

-- 仇恨高亮
local function UpdateThreatBorder(self, event, unit)
	if unit ~= self.unit then return end
	
	local status = UnitThreatSituation(unit)
	if status and status > 1 then
		local color = oUF.colors.threat[status]
		self.Health.shadow:SetBackdropBorderColor(color:GetRGB())
	else
		self.Health.shadow:SetBackdropBorderColor(.05, .05, .05)
	end
end

-- 職責圖示
local function UpdateGroupRole(self)
	local element = self.GroupRoleIndicator
	local role = UnitGroupRolesAssigned(self.unit)

	if role == "TANK" then
		element:SetTexture(G.media.role_tank)
		element:Show()
	elseif role == "HEALER" then
		element:SetTexture(G.media.role_healer)
		element:Show()
	elseif role == "DAMAGER" then
		element:SetTexture(G.media.role_dps)
		element:Show()
	end
	
	element:SetDesaturated(true)
end

--===========================================================--
-----------------    [[ Create Elements ]]    -----------------
--===========================================================--

-- 隊伍增益光環
local function CreatePartyBuffs(self)
	local Buffs = CreateFrame("Frame", nil, self)
	Buffs.size = C.PartyBuffSize
	Buffs.spacing = 4
	
	Buffs:SetFrameLevel(self:GetFrameLevel() + 2)
	Buffs.num = 2

	Buffs:SetPoint("BOTTOMRIGHT", self, -4, 6)
	Buffs:SetWidth(C.PartyBuffSize*2 + Buffs.spacing)
	Buffs:SetHeight(C.PartyBuffSize + Buffs.spacing*2)
	
	-- 選項
	Buffs["growth-x"] = "LEFT"
	Buffs.initialAnchor = "BOTTOMRIGHT"
	Buffs.showDebuffType = false
	Buffs.disableCooldown = true
	Buffs.disableMouse = true
	-- 註冊到ouf
	self.Buffs = Buffs
	self.Buffs.PostCreateButton = T.PostCreateIcon
	self.Buffs.PostUpdateButton = T.PostUpdateIcon
	--self.Buffs.FilterAura = ClassAuraFilter				-- 光環過濾
end

--=========================================================--
-----------------    [[ Create Frames ]]    -----------------
--=========================================================--

local function CreateRaid(self, unit)

	-- [[ 前置作業 ]] --
	self:SetScript("OnEnter", UnitFrame_OnEnter)	-- mouseover tooltip
	self:SetScript("OnLeave", UnitFrame_OnLeave)
	self:RegisterForClicks("AnyUp")
	
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
	self:RegisterEvent("PLAYER_TARGET_CHANGED", UpdateTargetBorder, true)
	self:RegisterEvent("GROUP_ROSTER_UPDATE", UpdateTargetBorder, true)
	-- 仇恨高亮，陰影變色
	local threat = CreateFrame("Frame", nil, self)
	self.ThreatIndicator = threat
	self.ThreatIndicator.Override = UpdateThreatBorder
	
	-- [[ 能量條 ]] --

	local Power = F.CreateStatusbar(self, G.addon..unit.."_PowerBar", "ARTWORK", nil, nil, 0, 0, 0, 1)
	Power:SetHeight(C.RPHeight)
	Power:SetPoint("BOTTOMLEFT", self.Health, 0, 0)	-- 與血量條等寬
	Power:SetPoint("BOTTOMRIGHT", self.Health, 0, 0)
	Power:SetFrameLevel(self:GetFrameLevel() + 2)
	-- 選項
	Power.frequentUpdates = true
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
    --Role:SetTexture(G.media.role)
    --Role:SetDesaturated(true)
    self.GroupRoleIndicator = Role
	self.GroupRoleIndicator.Override = UpdateGroupRole
	
	-- [[ 文本/TAGS ]] --
	
	-- 名字與狀態
	self.Name = F.CreateText(StringParent, "OVERLAY", G.Font, G.NameFS, G.FontFlag, "RIGHT")
	self.Name:SetPoint("TOPRIGHT", self.Health, -2, -3)
	self.Name.frequentUpdates = 5
	self:Tag(self.Name, "[namecolor][name][afkdnd]")
	
	-- 死亡背景
	self.DeadSkull = F.CreateText(self.Health, "OVERLAY", G.Font, C.PartyHeight, G.FontFlag, "CENTER")
	self.DeadSkull:SetAlpha(.4)
	self:Tag(self.DeadSkull, "[deadskull]")
end

local function CreatePartyStyle(self, unit)
	self.mystyle = "R"
	self.Range = { insideAlpha = 1, outsideAlpha = .5, }

	-- 框體
	CreateRaid(self, unit)						-- 繼承通用樣式	
	self:SetSize(C.PartyWidth, C.PartyHeight)	-- 主框體尺寸
	-- 文本
	self.Name:SetWidth(C.PartyWidth - 4)
	-- 死亡背景
	self.DeadSkull:SetWidth(C.PartyWidth - 4)
	self.DeadSkull:SetPoint("CENTER", -10, 0)
	-- 減益
	T.CreateDebuffs(self)
	self.Debuffs:SetPoint("BOTTOMLEFT", self, 4, 6)
	-- 增益
	--CreatePartyBuffs(self)
	-- 圖示和標記
	self.RaidTargetIndicator:SetPoint("TOPRIGHT", self.Health, -12, 12)
	self.AssistantIndicator:SetPoint("TOPRIGHT", self.Health, 3, 10)
	self.LeaderIndicator:SetPoint("TOPRIGHT", self.Health, 3, 8)
end

local function CreateRaidStyle(self, unit)
	self.mystyle = "R"
	self.Range = { insideAlpha = 1, outsideAlpha = .4, }

	-- 框體
	CreateRaid(self, unit)				-- 繼承通用樣式	
	self:SetSize(C.RWidth, C.RHeight)	-- 主框體尺寸
	-- 文本
	self.Name:SetWidth(C.RWidth - 4)
	-- 死亡背景
	self.DeadSkull:SetWidth(C.RWidth - 4)
	self.DeadSkull:SetPoint("CENTER", -5, 0)
	-- 減益
	T.CreateDebuffs(self)
	self.Debuffs:SetPoint("BOTTOMLEFT", self, 4, 6)
	-- 圖示和標記
	self.RaidTargetIndicator:SetPoint("TOPRIGHT", self.Health, -12, 12)
	self.AssistantIndicator:SetPoint("TOPRIGHT", self.Health, 3, 10)
	self.LeaderIndicator:SetPoint("TOPRIGHT", self.Health, 3, 8)
end

--===================================================--
--------------    [[ RegisterStyle ]]     -------------
--===================================================--
-- 註冊樣式
if C.RaidFrames then
	oUF:RegisterStyle("Raid", CreateRaidStyle)
end

if C.PartyFrames then
	oUF:RegisterStyle("Party", CreatePartyStyle)
end

--===================================================--
-----------------    [[ Spawn ]]     ------------------
--===================================================--

oUF:Factory(function(self)
	if C.PartyFrames then
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
			"columnSpacing",	C.RSpace,
			"xoffset",			C.RSpace,
			"yOffset",			-C.RSpace,	-- power hight and 2px border
			
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
				unit:SetPoint("TOP", party[i-1], "BOTTOM", 0, -(C.RSpace+C.RPHeight+2))
			end
			party[i] = unit
		end]]--
	end

	if C.RaidFrames then
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
                raid[i]:SetPoint("TOPLEFT", raidAnchor, "BOTTOMRIGHT", -20, -(C.RHeight*5+C.RPHeight*5+C.RSpace*6))
            else
                raid[i]:SetPoint("TOPLEFT", raid[i-1], "TOPRIGHT", C.RSpace, 0)
            end
        end
    end
end)