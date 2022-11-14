local addon, ns = ...
local C, F, G, T = unpack(ns)

if not (C.RaidFrames or C.PartyFrames) then return end

-- Hide Default RaidFrame
do
	local HiddenFrame = CreateFrame("Frame")
	HiddenFrame:Hide()
	
	if CompactRaidFrameManager_SetSetting then
		CompactRaidFrameManager_SetSetting("IsShown", "0")
		UIParent:UnregisterEvent("GROUP_ROSTER_UPDATE")
		CompactRaidFrameManager:UnregisterAllEvents()
		CompactRaidFrameManager:SetParent(HiddenFrame)
	end
end

--[[
local function DisableBlizzard()
    local hider = CreateFrame("Frame")
    hider:Hide()

    if _G.CompactUnitFrameProfiles then
        _G.CompactUnitFrameProfiles:UnregisterAllEvents()
    end

    if _G.CompactRaidFrameManager and (_G.CompactRaidFrameManager:GetParent() ~= hider) then
        _G.CompactRaidFrameManager:SetParent(hider)
    end

    InterfaceOptionsFrameCategoriesButton10:SetScale(0.00001)
    InterfaceOptionsFrameCategoriesButton10:SetAlpha(0)
end
]]--
--====================================================--
-----------------    [[ Function ]]    -----------------
--====================================================--

-- 離線等同超距
local function UpdateOffline(self, parent, inRange, checkedRange, isConnected)
	if not isConnected then
		parent:SetAlpha(self.outsideAlpha)
	end
end

-- 職業顏色映射至背景
local function PostUpdateColor(self, unit, r, g, b)
	local r, g, b, t
	
	if UnitIsPlayer(unit) then
		local class = select(2, UnitClass(unit))
		t = oUF.colors.class[class]
	else		
		r, g, b = .2, .9, .1
	end

	if(t) then
		r, g, b = t[1], t[2], t[3]
	end

	if(b) then
		self.bg:SetVertexColor(r, g, b, 1)
	end
end

-- 目標高亮
local function UpdateTargetBorder(self, event, unit)
	-- 使優先級低於仇恨高亮
	local status = UnitThreatSituation(self.unit)
	if status and status ~= 0 then return end
	
	if UnitIsUnit("target", self.unit) then
		self.Health.border:SetBackdropBorderColor(.9, .9, .9)
	else
		self.Health.border:SetBackdropBorderColor(0, 0, 0)
	end
end

-- 仇恨高亮
local function UpdateThreatBorder(self, event, unit)
	if unit ~= self.unit then return end
	
	local status = UnitThreatSituation(unit)
	if status and status > 1 then
		local r, g, b = unpack(oUF.colors.threat[status])
		self.Health.border:SetBackdropBorderColor(r, g, b)
	else
		self.Health.border:SetBackdropBorderColor(0, 0, 0)
	end
end

--===========================================================--
-----------------    [[ Create Elements ]]    -----------------
--===========================================================--

-- 專用的光環
local function CreateAuras(self)
	local Auras = CreateFrame("Frame", nil, self)
	Auras.size = C.sAuSize
	Auras.spacing = 4
	
	Auras:SetFrameLevel(self:GetFrameLevel() + 2)
	Auras.numBuffs = 0
	Auras.numDebuffs = 4
	Auras.numTotal = 4

	Auras:SetPoint("BOTTOMLEFT", self, 4, 6)
	Auras:SetWidth(C.sAuSize*4 + Auras.spacing * 3)
	Auras:SetHeight(C.sAuSize+Auras.spacing*2)
	
	-- 選項
	Auras.disableCooldown = true
	Auras.showDebuffType = true
	Auras.disableMouse = true
	-- 註冊到ouf
	self.Auras = Auras
	self.Auras.PostCreateButton = T.PostCreateIcon
	self.Auras.PostUpdateButton = T.PostUpdateIcon
	self.Auras.FilterAura = T.CustomFilter				-- 光環過濾
end

--=========================================================--
-----------------    [[ Create Frames ]]    -----------------
--=========================================================--

local function CreateRaid(self, unit)

	-- [[ 前置作業 ]] --
	
	-- Make mouse active
	self:SetScript("OnEnter", UnitFrame_OnEnter)	-- mouseover
	self:SetScript("OnLeave", UnitFrame_OnLeave)
	self:RegisterForClicks("AnyUp")
	
	-- Highlight
	local hl = self:CreateTexture(nil, "HIGHLIGHT")
	hl:SetAllPoints(self)
	hl:SetTexture(G.media.barhightlight)
	hl:SetVertexColor(1, 1, 1, .5)
	hl:SetTexCoord(0, 1, 1, 0)
	hl:SetBlendMode("ADD")
	self.Highlight = hl
	
	-- 創建一個條
	local Health = F.CreateStatusbar(self, G.addon..unit.."_HealthBar", "ARTWORK", nil, nil, 1, 0, 0, 1)
	Health:SetAllPoints(self)
	Health:SetFrameLevel(self:GetFrameLevel())
	Health:SetReverseFill(true)
	-- 選項
	Health.colorDisconnected = true
	Health.colorSmooth = true			-- 血量漸變色
	Health.smoothGradient = {1, 0, 0, 1, .8, .1, 1, .8, .1}
	-- 背景
	Health.bg = Health:CreateTexture(nil, "BACKGROUND")
	Health.bg:SetAllPoints()
	Health.bg:SetTexture(G.media.raidbar)
	-- 陰影和邊框
	Health.border = F.CreateSD(Health, Health, 3)
	-- 註冊到OUF
	self.Health = Health
	self.Health.PreUpdate = T.OverrideHealthbar		-- 更新機制：損血量
	self.Health.PostUpdate = T.PostUpdateHealth		-- 更新機制：顯示損血量，使血量漸變色和透明度隨損血量改變
	self.Health.PostUpdateColor = PostUpdateColor	-- 職業顏色映射至背景
	-- 目標高亮
	self:RegisterEvent("PLAYER_TARGET_CHANGED", UpdateTargetBorder, true)
	self:RegisterEvent("GROUP_ROSTER_UPDATE", UpdateTargetBorder, true)
	-- 仇恨高亮
	local threat = CreateFrame("Frame", nil, self)
	self.ThreatIndicator = threat
	self.ThreatIndicator.Override = UpdateThreatBorder
	
	local Power = F.CreateStatusbar(self, G.addon..unit.."_PowerBar", "ARTWORK", nil, nil, 1, 1, 1, 1)
	Power:SetHeight(C.RPHeight)
	Power:SetPoint("BOTTOMLEFT", self.Health, 0, 0)	-- 與血量條等寬
	Power:SetPoint("BOTTOMRIGHT", self.Health, 0, 0)
	Power:SetFrameLevel(self:GetFrameLevel()+3)
	-- 選項
	Power.frequentUpdates = true
	Power.colorPower = true
	-- 背景
	Power.bg = Power:CreateTexture(nil, "BACKGROUND")
	Power.bg:SetAllPoints()
	Power.bg:SetTexture(G.media.blank)
	Power.bg.multiplier = .3
	-- 邊框，只需要上方一條1px，CreateBD會創建四面的
	Power.border = Power:CreateTexture(nil, "BACKGROUND")
	Power.border:SetHeight(1)	-- 與血量條等寬
	Power.border:SetPoint("TOPLEFT", Power, 0, 1)	-- 與血量條等寬
	Power.border:SetPoint("TOPRIGHT", Power, 0, 2)	-- 1px高度
	Power.border:SetTexture(G.media.blank)
	Power.border:SetVertexColor(0, 0, 0, 1)
	-- 註冊到OUF
	self.Power = Power
	
	-- [[ 圖示 ]] --
	
	-- 建立一個提供給圖示依附的父級框體，框體層級高，避免被蓋住
	local StringParent = CreateFrame("Frame", nil, self)
	StringParent:SetFrameLevel(self:GetFrameLevel() + 8)
	self.StringParent = StringParent
	
	-- 團隊標記
	local RaidIcon = StringParent:CreateTexture(nil, "OVERLAY")
	RaidIcon:SetSize(20, 20)
	RaidIcon:SetTexture(G.media.raidicon)
	self.RaidTargetIndicator = RaidIcon
	-- 助手
	local Assistant = StringParent:CreateTexture(nil, "OVERLAY")
	Assistant:SetSize(14, 14)
	self.AssistantIndicator = Assistant
	-- 領隊
	local Leader = StringParent:CreateTexture(nil, "OVERLAY")
	Leader:SetSize(14, 14)
	self.LeaderIndicator = Leader
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
    Role:SetSize(20, 20)
    Role:SetPoint("TOPLEFT", self.Health, 3, 6)
    Role:SetTexture(G.media.role)
    --Role:SetDesaturation(true)
    self.GroupRoleIndicator = Role
end

--[[
local function CreatePartyStyle(self, unit)
	self.mystyle = "R"
	self.Range = {
		insideAlpha = 1, outsideAlpha = .5,
	}

	-- 框體
	CreateRaid(self, unit)				-- 繼承通用樣式	
	self:SetSize(C.RWidth, C.RHeight)	-- 主框體尺寸
	-- 文本
	self.Name = F.CreateText(self.Health, "OVERLAY", G.Font, G.NameFS, G.FontFlag, nil)
	self.Name:SetPoint("TOPRIGHT", -2, -2)
	self.Name:SetJustifyH("RIGHT")
	self.Name:SetWidth(self:GetWidth() * 0.9)
	self:Tag(self.Name, "[namecolor][name]")
	-- 減益
	CreateAuras(self)
	
	-- 狀態：暫離/忙錄/等級
	self.StatusR = F.CreateText(self.Health, "OVERLAY", G.Font, G.NameFS, G.FontFlag, nil)
	self:Tag(self.StatusR, "[afkdnd] ")
	self.StatusR:SetPoint("TOPRIGHT", 0, 0)
	
	self.RaidTargetIndicator:SetPoint("TOP", self.Health, 0, 12)
	self.AssistantIndicator:SetPoint("TOPLEFT", self.Health, 0, 8)
	self.LeaderIndicator:SetPoint("TOPLEFT", self.Health, 0, 8)
end
]]--
local function CreateRaidStyle(self, unit)
	self.mystyle = "R"
	self.Range = {
		insideAlpha = 1, outsideAlpha = .4,
	}
	self.Range.PostUpdate = UpdateOffline

	-- 框體
	CreateRaid(self, unit)				-- 繼承通用樣式	
	self:SetSize(C.RWidth, C.RHeight)	-- 主框體尺寸
	-- 文本
	self.Name = F.CreateText(self.Health, "OVERLAY", G.Font, G.NameFS, G.FontFlag, nil)
	self.Name:SetPoint("TOPRIGHT", -2, -3)
	self.Name:SetJustifyH("RIGHT")
	self.Name:SetWidth(self:GetWidth()-4)
	self.Name.frequentUpdates = 60
	self:Tag(self.Name, "[namecolor][name][afkdnd]")
	-- 減益
	CreateAuras(self)

	self.RaidTargetIndicator:SetPoint("TOPRIGHT", self.Health, -12, 12)
	self.AssistantIndicator:SetPoint("BOTTOMRIGHT", self.Health, 0, 0)
	self.LeaderIndicator:SetPoint("BOTTOMRIGHT", self.Health, 0, 0)
end

--===================================================--
--------------    [[ RegisterStyle ]]     -------------
--===================================================--
-- 註冊樣式
if C.RaidFrames then
	oUF:RegisterStyle("Raid", CreateRaidStyle)
end
--[[
if C.PartyFrames then
	oUF:RegisterStyle("Party", CreatePartyStyle)
end
]]--
--===================================================--
-----------------    [[ Spawn ]]     ------------------
--===================================================--
-- 生成

oUF:Factory(function(self)
	self:SetActiveStyle("Raid")
	
	local raidAnchor = CreateFrame("Frame", nil, UIParent)
	raidAnchor:SetSize(20, 20)
	raidAnchor:ClearAllPoints()
	raidAnchor:SetPoint("CENTER", UIParent, 570, 120)
	
	--[[
	local party = {}
	for i = 1, 5 do
		local unit = self:Spawn("party"..i, "oUF_Party"..i)
		if i == 1 then
			unit:SetPoint("TOPLEFT", raidAnchor, "BOTTOMRIGHT", -20, 4)
		else
			unit:SetPoint("TOP", party[i-1], "BOTTOM", 0, -4)
		end
		party[i] = unit
	end
	]]--
	
	local raid = {}
	for i = 1, 8 do
		raid[i] = self:SpawnHeader("oUF_Raid"..i, nil, "party,raid,solo",
			"showSolo",			false,
			"showParty",		C.PartyFrames,
			"showRaid",			C.RaidFrames,
			"showPlayer",		true,

			"point",			"TOP",
			"columnAnchorPoint","LEFT",

			"groupFilter",		tostring(i),
			"groupingOrder",	tostring(i),
			"groupBy",			"GROUP",
			"sortMethod",		"INDEX", -- or "NAME"
			"startingIndex",	1,
			
			"maxColumns",		8,
			"unitsPerColumn",	5,
			"columnSpacing",	C.RSpace,
			"xoffset",			C.RSpace,
			"yOffset",			-C.RSpace,
			
			"templateType", "Button",
			"oUF-initialConfigFunction", ([[
				self:SetWidth(%d)
				self:SetHeight(%d)
			]]):format(C.RWidth, C.RHeight)
		)
		
		if i == 1 then
			raid[i]:SetPoint("TOPLEFT", raidAnchor, "BOTTOMRIGHT", -20, 4)
		elseif i >= 2 and i <= 4 then
			raid[i]:SetPoint("TOPLEFT", raid[i-1], "TOPRIGHT", C.RSpace, 0)
		elseif i == 5 then
			--raid[i]:SetPoint("TOP", raid[i-4], "BOTTOM", 0, -C.RSpace)
			raid[i]:SetPoint("TOPLEFT", raidAnchor, "BOTTOMRIGHT", -20, -(C.RHeight+C.RSpace)*5)
		elseif i >= 6 then
			raid[i]:SetPoint("TOPLEFT", raid[i-1], "TOPRIGHT", C.RSpace, 0)
		end
	end
end)