local addon, ns = ...
local C, F, G, T = unpack(ns)

if C.RaidFrames ~= true then return end
	
-- 專用的顏色
local function UpdateHealthColor(self, unit)
	local r, g, b, t
	local bg = self.bg
	
	local colors = setmetatable({
		power = setmetatable({
			['MANA'] = {.31,.45,.63},
		}, {__index = oUF.colors.power}),
		}, {__index = oUF.colors})

	if UnitIsPlayer(unit) then
		local _, class = UnitClass(unit)
		t = colors.class[class]
	else		
		r, g, b = .2, .9, .1
	end

	if(t) then
		r, g, b = t[1], t[2], t[3]
	end

	if(b) then
		self:SetStatusBarColor(r*.2, g*.2, b*.2, 1)
		self.bg:SetVertexColor(r, g, b, 1)
	end
end

-- 邊框變化

local function UpdateTarget(self, event, unit)
	if UnitIsUnit("target", self.unit) then
		self.Target:Show()
	else
		self.Target:Hide()
	end
end
--[[
local function UpdateThreat(_, unit)
	if unit ~= self.unit then return end

	local element = self.ThreatIndicator
	local status = UnitThreatSituation(unit)

	if status and status > 1 then
		local r, g, b = GetThreatStatusColor(status)
		element:SetBackdropBorderColor(r, g, b)
		element:Show()
	else
		element:Hide()
	end
end
]]--
-- 專用的光環
local function CreateAuras(self)
	local Auras = CreateFrame("Frame", nil, self)
	Auras.size = C.sAuSize
	Auras.spacing = 4
	
	Auras:SetFrameLevel(self:GetFrameLevel() + 2)
	Auras.numBuffs = 1
	Auras.numDebuffs = 3
	Auras.numTotal = 3

	Auras:SetPoint("BOTTOMLEFT", self, 4, 6)
	Auras:SetWidth(C.sAuSize*3 + Auras.spacing * 2)
	Auras:SetHeight(self:GetHeight())
	
	-- 選項
	Auras.disableCooldown = true
	Auras.showDebuffType = true
	-- 註冊到ouf
	self.Auras = Auras
	self.Auras.PostCreateIcon = T.PostCreateIcon
	self.Auras.PostUpdateIcon = T.PostUpdateIcon
	self.Auras.CustomFilter = T.CustomFilter				-- 光環過濾	
end

local function CreateRaid(self, unit)

	-- [[ 前置作業 ]] --
	
	-- Make mouse active
	self:SetScript("OnEnter", UnitFrame_OnEnter)	-- mouseover
    self:SetScript("OnLeave", UnitFrame_OnLeave)
	self:RegisterForClicks("AnyUp")
	
	-- Highlight
	self.hl = self:CreateTexture(nil, "HIGHLIGHT")
    self.hl:SetAllPoints(self)
    self.hl:SetTexture(G.media.barhightlight)
    self.hl:SetVertexColor(1, 1, 1, 0.3)
    self.hl:SetTexCoord(0, 1, 1, 0)
    self.hl:SetBlendMode("ADD")
	self.Mouseover = hl
	
	--self.Target = F.CreateBD(self, self, 2, 1, 1, 0, 1)
	--self.Target:SetOutside(self, 3, 3)
	--self.Target:RegisterEvent("PLAYER_TARGET_CHANGED", UpdateTarget, true)
	
	-- 創建一個條
	local Health = F.CreateStatusbar(self, G.addon..unit.."_HealthBar", "ARTWORK", nil, nil, 0, 0, 0, 1)
	Health:SetAllPoints(self)
	Health:SetFrameLevel(self:GetFrameLevel())
	
	Health.colorDisconnected = true
	Health.frequentUpdates = .1
	
	Health.bg = Health:CreateTexture(nil, "BACKGROUND")
	Health.bg:SetAllPoints()
	Health.bg:SetTexture(G.media.blank)
	
	Health.border = F.CreateSD(Health, Health, 3)

	self.Health = Health
	self.Health.UpdateColor = UpdateHealthColor
	--self.Health.PostUpdate = UpdateTarget
	--self.Health:RegisterEvent("PLAYER_TARGET_CHANGED", UpdateTarget, true)
	
	local Power = F.CreateStatusbar(self, G.addon..unit.."_PowerBar", "ARTWORK", nil, nil, 1, 1, 1, 1)
	Power:SetHeight(C.RPHeight)
	Power:SetPoint("BOTTOMLEFT", self.Health, 0, 0)	-- 與血量條等寬
	Power:SetPoint("BOTTOMRIGHT", self.Health, 0, 0)
	Power:SetFrameLevel(self:GetFrameLevel() + 2)
	
	Power.frequentUpdates = true
	Power.colorPower = true
	
	Power.bg = Power:CreateTexture(nil, "BACKGROUND")
	Power.bg:SetAllPoints()
	Power.bg:SetTexture(G.media.blank)
	Power.bg.multiplier = .3
	
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
	phase:SetPoint("CENTER", self.Health, 0, 0)
	self.PhaseIndicator = phase
	-- 召喚
	-- 復活
end


-- 右下 ICON ROLE等等

local function CreateRaidStyle(self, unit)
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
	--[[self.StatusR = F.CreateText(self.Health, "OVERLAY", G.Font, G.NameFS, G.FontFlag, nil)
	self:Tag(self.StatusR, "[afkdnd] ")
	self.StatusR:SetPoint("TOPRIGHT", 0, 0)]]--
	
	self.RaidTargetIndicator:SetPoint("TOP", self.Health, 0, 12)
	self.AssistantIndicator:SetPoint("TOPLEFT", self.Health, 0, 8)
	self.LeaderIndicator:SetPoint("TOPLEFT", self.Health, 0, 8)
end


oUF:RegisterStyle("Raid", CreateRaidStyle)
oUF:Factory(function(self)
	self:SetActiveStyle("Raid")
	local raid = {}
		for i = 1, 6 do
			local header = oUF:SpawnHeader(
				"Ruri_Raid"..i,
				nil,
				"solo, party, raid",
				
				"showPlayer",		true,
				"showSolo",			false,
				"showParty",		true,
				"showRaid",         true,
				
				"xoffset",			5,
				"yOffset",			-(C.PPHeight*2+5),
				
				"groupFilter",		tostring(i),
				"groupingOrder",	"1,2,3,4,5,6,7,8",
				"groupBy",			"GROUP",
				"sortMethod",		"INDEX", -- or "NAME"
				"startingIndex",	1,
				
				"unitsPerColumn",	5,
				"maxColumns",		8,
				"columnSpacing",	5,
				
				"point",              RIGHT,
				"columnAnchorPoint",  "RIGHT",
				
				"oUF-initialConfigFunction", ([[
					self:SetWidth(%d)
					self:SetHeight(%d)
					]]):format(C.RaidWidth, C.RaidHeight)
			)
			if i == 1 then
				header:SetAttribute("showSolo", true)
				header:SetAttribute("showPlayer", true)
				header:SetAttribute("showParty", true)

				header:SetPoint("CENTER", UIParent, 580, 0)
			else
				header:SetPoint("TOPLEFT",raid[i-1],"TOPRIGHT", 4, 0)
			end
			raid[i] = header
		end
end)