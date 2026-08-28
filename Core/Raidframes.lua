local _, ns = ...
local oUF = ns.oUF
local C, F, G, T, L = unpack(ns)

local raidTooltipAnchor
local function RaidFrameOnEnter(self)
	local point, relativePoint, x, y = raidTooltipAnchor:GetTooltipPosition()
	GameTooltip:SetOwner(self, "ANCHOR_NONE")
	GameTooltip:ClearAllPoints()
	GameTooltip:SetPoint(point, raidTooltipAnchor, relativePoint, x, y)
	F.UpdateUnitFrameTooltip(self, RaidFrameOnEnter)
end

--=================================================--
-----------------    [[ Color ]]    -----------------
--=================================================--

-- 高亮陰影：選中白框，仇恨依狀態變色
local function UpdateGroupBorder(self, event, unit)
	if unit and unit ~= self.__unit then return end

	local highlight = self.Health.highlightShadow
	local shadow = self.Health.shadow
	local status = UnitThreatSituation(self.__unit)
	local r, g, b
	if status and status > 1 then
		local color = oUF.colors.threat[status]
		r, g, b = color:GetRGB()
	elseif UnitIsUnit("target", self.__unit) then
		r, g, b = .9, .9, .9
	end

	if r ~= nil then
		shadow:SetAlpha(0)
		highlight:SetBackdropBorderColor(r, g, b)
		highlight:SetAlpha(1)
	else
		highlight:SetAlpha(0)
		shadow:SetAlpha(1)
	end
end

--================================================--
-----------------    [[ Role ]]    -----------------
--================================================--

-- 職責圖示
local groupRoleTextures = {
	[Enum.LFGRole.Tank] = G.media.role_tank,
	[Enum.LFGRole.Healer] = G.media.role_healer,
	[Enum.LFGRole.Damage] = G.media.role_dps,
}

-- 職責未確認或等待停用時，保持 power 隱藏
local function PostUpdateGroupPower(element)
	element:SetShown(element.shouldEnable)
end

-- 將 power 的 enable/disable 掛在 GroupRoleIndicator 上，利用 ouf 的職責更新節省資源
local function PostUpdateGroupRole(element, role)
	-- 職責圖示
	local texture = groupRoleTextures[role]
	if texture then
		element:SetTexture(texture)
		element:SetTexCoord(0, 1, 0, 1)
	end

	-- 判斷是否顯示能量
	local owner = element.__owner
	local Power = owner.Power
	if not Power.healerOnly then return end

	local isHealer = (role == Enum.LFGRole.Healer)
	local isEnabled = (owner:IsElementEnabled("Power") == true)
	Power.shouldEnable = isHealer -- 取得職責，取代初始化的 false

	-- 先判斷是否顯示 power
	if isHealer then
		Power.PostUpdate = nil -- 是治療者，停止 PostUpdate 檢查顯隱狀態
	else
		Power.PostUpdate = PostUpdateGroupPower	-- 不是治療者，保持隱藏
	end
	Power:SetShown(isHealer and isEnabled) -- 決定顯隱狀態
	-- 治療已啟用或等待排程時停止
	if isEnabled == isHealer or Power.roleUpdatePending then return end

	-- 再判斷是否停用 power
	Power.roleUpdatePending = true -- 排程至 UpdateAllElements 之後，避免重複
	C_Timer.After(0, function()
		Power.roleUpdatePending = nil

		if Power.shouldEnable then
			owner:EnableElement("Power")
			Power:ForceUpdate()
		else
			owner:DisableElement("Power")
		end
	end)
end

--====================================================--
-----------------    [[ Function ]]    -----------------
--====================================================--

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

local function UpdateGroupAura(self)
	self.PhaseIndicator:ForceUpdate()
end

--=========================================================--
-----------------    [[ Create Frames ]]    -----------------
--=========================================================--

local function CreateGroupShared(self, unit, width, height, powerHeight, frequentPowerUpdates, healerOnly)

	-- [[ 前置作業 ]] --
	self.mystyle = "R"
	self.Range = { insideAlpha = 1, outsideAlpha = .5, }
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
	-- self.Highlight = hl -- 沒有外部調用不需要這行
	
	-- [[ 血量條 ]] --

	-- 創建一個條
	local Health = CreateFrame('StatusBar', nil, self)
	Health:SetAllPoints(self)
	Health:SetFrameLevel(self:GetFrameLevel())
	Health:SetStatusBarTexture(G.media.raidbar)
	-- 選項
	Health.colorDisconnected = true
	Health.colorClass = true
	-- 背景
	Health.bg = Health:CreateTexture(nil, "BACKGROUND")
	Health.bg:SetTexture(G.media.blank)
	-- 背景的位置：在反轉血量條中，血條是透明的，背景才是表示血量的實體，因此將長度依附於血量條本體，尺寸隨血量而變化
	Health.bg:SetPoint("TOPLEFT", Health:GetStatusBarTexture(), "TOPRIGHT", 0, 0)
	Health.bg:SetPoint("BOTTOMRIGHT", Health, "BOTTOMRIGHT", 0, 0)
	-- 固定1px邊框，透明背景配合反轉血量條
	Health.border = F.CreateBD(Health, Health, 1, .05, .05, .05, 0, 1)
	-- 普通陰影
	Health.shadow = F.CreateSD(Health, Health, 4)
	-- 選中與仇恨的加厚陰影，平時保持透明
	Health.highlightShadow = F.CreateSD(Health, Health.border, 5)
	Health.highlightShadow:SetAlpha(0)
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
	-- 根據職責顯示能量
	Power.healerOnly = healerOnly
	if Power.healerOnly then
		Power.shouldEnable = false	-- 初始化：先預設隱藏能量條
		Power.PostUpdate = PostUpdateGroupPower	-- 更新 Power 顯示
	end
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
	RaidTarget:SetPoint("TOPRIGHT", self.Health, -12, 12)
	RaidTarget:SetTexture(G.media.raidicon)
	self.RaidTargetIndicator = RaidTarget
	-- 領隊
	local Leader = StringParent:CreateTexture(nil, "OVERLAY")
	Leader:SetSize(14, 14)
	Leader:SetPoint("TOPLEFT", self.Health, 3, 8)
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
	
	-- [[ 文本/TAGS ]] --
	
	-- 名字與狀態
	self.Name = F.CreateText(StringParent, "OVERLAY", G.Font, G.NameFS, G.FontFlag, "RIGHT")
	self.Name:SetPoint("TOPRIGHT", self.Health, -8, -3)
	self.Name.frequentUpdates = 5
	self:Tag(self.Name, "[afkdnd][namecolor][name]")
	
	-- 死亡背景
	self.DeadSkull = F.CreateText(self.Health, "OVERLAY", G.Font, height, G.FontFlag, "CENTER")
	self.DeadSkull:SetAlpha(.4)
	self:Tag(self.DeadSkull, "[deadskull]")

	-- 職責
    local Role = StringParent:CreateTexture(nil, "OVERLAY")
    Role:SetSize(28, 28)
    Role:SetPoint("LEFT", self.Name, "RIGHT", -6, 1)
    Role:SetDesaturated(true)
    self.GroupRoleIndicator = Role
	self.GroupRoleIndicator.PostUpdate = PostUpdateGroupRole -- 利用 ouf 的職責更新來更新 power 啟用停用，節省資源
end

local function CreateParty(self, unit)
	-- 小隊用 UNIT_POWER_FREQUENT
	CreateGroupShared(self, unit, C.Party.Width, C.Party.Height, C.Party.PHeight, true, F.GetRuriOption("PartyHealerManaOnly"))
	self:SetScript("OnEnter", F.UnitFrameOnEnter)

	-- 吸收盾
	T.CreateHealthPrediction(self, true)
	-- 文本
	self.Name:SetWidth(C.Party.Width - 4)
	-- 死亡背景
	self.DeadSkull:SetWidth(C.Party.Width - 4)
	self.DeadSkull:SetPoint("CENTER", -10, 0)
	-- 光環
	if F.GetRuriOption("PartyDebuffs") then T.CreateRaidDebuffs(self) end
	if F.GetRuriOption("PartyBuffs") then T.CreateRaidBuffs(self) end
	if self.Debuffs or self.Buffs then
		self:RegisterEvent("ENCOUNTER_STATE_CHANGED", UpdateGroupAura, true)
	end
end

local function CreateRaid(self, unit)
	local height = self:GetParent().raidFrameHeight or C.Raid.Height -- 根據header紀錄的團框高度變化

	-- 團隊用 UNIT_POWER_UPDATE
	CreateGroupShared(self, unit, C.Raid.Width, height, C.Raid.PHeight, false, F.GetRuriOption("RaidHealerManaOnly"))
	self:SetScript("OnEnter", RaidFrameOnEnter)

	-- 吸收盾
	T.CreateHealthPrediction(self, true)
	-- 文本
	self.Name:SetWidth(C.Raid.Width - 4)
	-- 死亡背景
	self.DeadSkull:SetWidth(C.Raid.Width - 4)
	self.DeadSkull:SetPoint("CENTER", -5, 0)
	-- 光環
	if F.GetRuriOption("RaidDebuffs") then T.CreateRaidDebuffs(self) end
	if F.GetRuriOption("RaidBuffs") then T.CreateRaidBuffs(self) end
	if self.Debuffs or self.Buffs then
		self:RegisterEvent("ENCOUNTER_STATE_CHANGED", UpdateGroupAura, true)
	end
	-- 助手
	local Assistant = self.StringParent:CreateTexture(nil, "OVERLAY")
	Assistant:SetSize(14, 14)
	Assistant:SetPoint("TOPLEFT", self.Health, 3, 10)
	self.AssistantIndicator = Assistant
end

--=========================================================--
-----------------    [[ Raid Layout ]]    -----------------
--=========================================================--

local function CreateRaidLayoutController(raid, raidAnchor, tooltipAnchor, layoutButtonEnabled)
	-- 布局列表
	local raidLayouts = {
		-- 布局名稱，顯示幾個小隊，每行幾個小隊，座標，高度縮放
		{ label = "5x4", capacity = 4, groupsPerRow = 4, position = C.Position.Raid54 },
		{ label = "5x5", capacity = 5, groupsPerRow = 5, position = C.Position.Raid55 },
		{ label = "5x6", capacity = 6, groupsPerRow = 6, position = C.Position.Raid55 },
		{ label = "5x6 (3+3)", capacity = 6, groupsPerRow = 3, position = C.Position.Raid5633 },
		{ label = "5x8", capacity = 8, groupsPerRow = 8, position = C.Position.Raid54 },
		{ label = "5x8 (4+4)", capacity = 8, groupsPerRow = 4, position = C.Position.Raid54 },
		{ label = "5x8 (" .. L.HalfHeight .. ")", capacity = 8, groupsPerRow = 4, position = C.Position.Raid54, heightScale = .6 },
	}
	-- 預設使用完整八隊的 5x8 (4+4) 布局
	local currentLayoutIndex = 6
	local enabledGroups = {true, true, true, true, true, true, true, true}
	-- 宣告按鈕創建
	local groupButtons = {}	-- 小隊顯隱按鈕
	local layoutButtons = {}-- 布局切換按鈕
	local layoutButton, layoutPanel, saveButton	-- 布局按鈕，布局面板，保存按鈕

	-- 讀取保存在設定檔中的布局、小隊與位置
	local function LoadSavedRaidLayout()
		local saved = RuriDB.RaidLayout
		if type(saved) ~= "table" then return end

		local position = saved.position
		if not raidLayouts[saved.layoutIndex]
			or type(saved.enabledGroups) ~= "table"
			or type(position) ~= "table"
			or type(position.point) ~= "string"
			or type(position.relativePoint) ~= "string"
			or type(position.x) ~= "number"
			or type(position.y) ~= "number"
		then
			RuriDB.RaidLayout = nil
			return
		end

		currentLayoutIndex = saved.layoutIndex
		for i = 1, 8 do
			enabledGroups[i] = saved.enabledGroups[i] == true
		end

		return {position.point, UIParent, position.relativePoint, position.x, position.y}
	end

	local savedPosition = layoutButtonEnabled and LoadSavedRaidLayout()

	-- 團框靠近畫面上緣時，tooltip 改放兩側，其餘位置固定放在右上
	function tooltipAnchor:GetTooltipPosition()
		local gap = C.Raid.Space * 2
		local inTopQuarter = raidAnchor:GetTop() > UIParent:GetHeight() * .75
		if inTopQuarter then
			local layoutOnRight = self:GetCenter() > UIParent:GetWidth() * .5
			if layoutOnRight then
				return "TOPRIGHT", "TOPLEFT", -gap, 0
			end
			return "TOPLEFT", "TOPRIGHT", gap, 0
		end
		return "BOTTOMRIGHT", "TOPRIGHT", 0, gap
	end

	-- 布局面板按鈕高亮
	local function UpdateControlButton(button, selected)
		button.selected = selected
		if selected then
			button:SetBackdropColor(0, .35, .35, .82)
		elseif button.hovered then
			button:SetBackdropColor(0, .45, .45, .65)
		else
			button:SetBackdropColor(0, 0, 0, .35)
		end
	end

	-- 設定保存按鈕高亮
	local function UpdateSaveButton()
		local saved = RuriDB.RaidLayout ~= nil
		UpdateControlButton(saveButton, saved)
		if saved then
			saveButton.Text:SetTextColor(0, 1, 1)
		else
			saveButton.Text:SetTextColor(1, 1, 1)
		end
	end

	-- 更新布局面板
	local function UpdateLayoutControls(groupMemberCounts)
		if not layoutButton then return end

		-- 在布局按鈕上顯示當前布局
		layoutButton.Text:SetText(raidLayouts[currentLayoutIndex].label)
		-- 獲取當前啟用顯示的小隊數量
		local enabledCount = 0
		for i = 1, 8 do
			if enabledGroups[i] then
				enabledCount = enabledCount + 1
			end
		end
		-- 布局面板的小隊按鈕
		local capacity = raidLayouts[currentLayoutIndex].capacity
		for i = 1, 8 do
			local button = groupButtons[i]
			local available = enabledGroups[i] or enabledCount < capacity -- 停用超出布局容量的小隊，不可點擊
			button:SetEnabled(available)
			button:SetAlpha(available and 1 or .35)
			-- 青色有人，灰色空隊
			if groupMemberCounts[i] then
				button.Text:SetTextColor(0, 1, 1)
			else
				button.Text:SetTextColor(.5, .5, .5)
			end
			UpdateControlButton(button, enabledGroups[i])
		end
		-- 布局面板的布局按鈕
		for i = 1, #raidLayouts do
			UpdateControlButton(layoutButtons[i], i == currentLayoutIndex)
		end
		-- 布局面板的保存按鈕
		UpdateSaveButton()
	end

	-- 布局按鈕指向高亮
	local function UpdateLayoutButtonHighlight()
		if layoutButton.dragging or layoutPanel:IsShown() or layoutButton:IsMouseOver() then
			layoutButton:SetAlpha(1)
			layoutButton:SetBackdropColor(0, .45, .45, .82)
		else
			layoutButton:SetAlpha(.1)
			layoutButton:SetBackdropColor(0, 0, 0, .82)
		end
	end

	-- 布局按鈕與面板在戰鬥中隱藏
	local function UpdateLayoutControlShown(forceHidden)
		if not layoutButton then return end

		if IsInRaid() and not forceHidden and not InCombatLockdown() then
			layoutButton:Show()
			UpdateLayoutButtonHighlight()
		else
			if layoutButton.dragging then
				raidAnchor:StopMovingOrSizing()
				layoutButton.dragging = nil
			end
			layoutPanel:Hide()
			layoutButton:Hide()
		end
	end

	-- 套用布局
	local function ApplyRaidLayout(resetPosition, positionOverride)
		if InCombatLockdown() then return false end

		local groupMemberCounts = {} -- 各小隊的實際人數，初始化為空表
		local occupiedGroupCount = 0 -- 有人小隊的數量，初始化為0
		local firstFourGroupsOnly = false -- 是否只顯示前四小隊，初始化為停用
		if IsInRaid() then
			-- 空小隊縮排
			for i = 1, GetNumGroupMembers() do
				local _, _, subgroup = GetRaidRosterInfo(i)
				local memberCount = groupMemberCounts[subgroup] or 0
				groupMemberCounts[subgroup] = memberCount + 1
				if memberCount == 0 then
					occupiedGroupCount = occupiedGroupCount + 1
				end
			end

			-- 自動模式：傳奇團隊編組完整自動隱藏替補
			if not layoutButtonEnabled then
				local _, _, difficultyID = GetInstanceInfo()
				if difficultyID == DifficultyUtil.ID.PrimaryRaidMythic
					and groupMemberCounts[1] == 5
					and groupMemberCounts[2] == 5
					and groupMemberCounts[3] == 5
					and groupMemberCounts[4] == 5
				then
					occupiedGroupCount = 4
					firstFourGroupsOnly = true
				end
			end
		end

		-- 手動模式沿用目前布局；自動模式根據有人小隊的數量選擇布局
		local layoutIndex = currentLayoutIndex
		if not layoutButtonEnabled then
			layoutIndex = 6
			if occupiedGroupCount > 0 and occupiedGroupCount <= 4 then
				layoutIndex = 1
			elseif occupiedGroupCount == 5 then
				layoutIndex = 2
			elseif occupiedGroupCount == 6 then
				layoutIndex = 4
			elseif occupiedGroupCount >= 7 then
				layoutIndex = 7
			end
		end

		local layout = raidLayouts[layoutIndex]
		local raidFrameHeight = C.Raid.Height * (layout.heightScale or 1) -- heightScale = 半高設定值

		local orderedHeaders = {} -- 按順序排好，等布局座標套用的小隊(table)
		local emptyHeaders = {} -- 空小隊(table)
		local rowOffset = raidFrameHeight * 5 + C.Raid.Space * 7 -- 雙排間距

		for i = 1, 8 do
			local header = raid[i]
			local groupEnabled
			if layoutButtonEnabled then
				-- 手動布局：根據玩家設定顯示對應小隊
				groupEnabled = enabledGroups[i]
			else
				-- 自動布局：顯示全部小隊或前四小隊
				groupEnabled = not firstFourGroupsOnly or i <= 4
			end
			-- 更新顯隱狀態
			if header.layoutEnabled ~= groupEnabled then
				header.layoutEnabled = groupEnabled
				header:SetVisibility(groupEnabled and "raid" or "custom hide")
			end

			-- 半高布局切換
			if header.raidFrameHeight ~= raidFrameHeight then
				header.raidFrameHeight = raidFrameHeight
				for childIndex = 1, 5 do
					local frame = header:GetAttribute("child" .. childIndex)
					if not frame then break end
					frame:SetHeight(raidFrameHeight)
					frame.DeadSkull:SetFont(G.Font, raidFrameHeight, G.FontFlag)
				end
			end

			-- 清除小隊的舊錨點
			header:ClearAllPoints()

			-- 判斷啟用顯示的小隊是否有人，然後分類 orderedHeaders 或 emptyHeaders
			if groupEnabled then
				local headers = groupMemberCounts[i] and orderedHeaders or emptyHeaders
				headers[#headers + 1] = header
			end
		end

		-- 將空小隊排到有人小隊後面以保留 header
		for i = 1, #emptyHeaders do
			orderedHeaders[#orderedHeaders + 1] = emptyHeaders[i]
		end

		local previousHeader -- 前一個定位完的小隊
		for positionIndex, header in ipairs(orderedHeaders) do
			local column = (positionIndex - 1) % layout.groupsPerRow + 1 -- 雙排布局取餘數計算換行
			local row = math.floor((positionIndex - 1) / layout.groupsPerRow)

			if column == 1 then
				header:SetPoint("TOPLEFT", raidAnchor, "BOTTOMRIGHT", -20, -rowOffset * row)
			else
				header:SetPoint("TOPLEFT", previousHeader, "TOPRIGHT", C.Raid.Space, 0)
			end
			previousHeader = header
		end

		local headerCount = #orderedHeaders
		if headerCount > 0 then
			local rightHeader = orderedHeaders[math.min(headerCount, layout.groupsPerRow)]
			tooltipAnchor:ClearAllPoints()
			tooltipAnchor:SetPoint("TOPLEFT", orderedHeaders[1], "TOPLEFT")
			tooltipAnchor:SetPoint("TOPRIGHT", rightHeader, "TOPRIGHT")
		end

		-- 載入布局時套用預設座標
		if (not layoutButtonEnabled) or resetPosition then
			raidAnchor:ClearAllPoints()
			raidAnchor:SetPoint(unpack(positionOverride or layout.position))
		end

		UpdateLayoutControls(groupMemberCounts)
		return true
	end

	-- 建立布局面板
	if layoutButtonEnabled then
		raidAnchor:SetMovable(true)
		local controlBackdrop = {
			bgFile = "Interface\\Buttons\\WHITE8x8",
			edgeFile = "Interface\\Buttons\\WHITE8x8",
			edgeSize = 1,
			insets = {left = 1, right = 1, top = 1, bottom = 1},
		}

		layoutButton = CreateFrame("Button", nil, raidAnchor, "BackdropTemplate")
		layoutButton:SetSize(C.Raid.Width, 20)
		layoutButton:SetPoint("BOTTOMLEFT", raidAnchor, "BOTTOMRIGHT", -20, C.Raid.Space + 4)
		layoutButton:SetClampedToScreen(true)
		layoutButton:SetClampRectInsets(-10, 10, 10, -10)
		layoutButton:SetFrameStrata("DIALOG")
		layoutButton:SetBackdrop(controlBackdrop)
		layoutButton:SetBackdropBorderColor(0, .85, .85, 1)
		layoutButton:RegisterForClicks("LeftButtonUp")
		layoutButton:RegisterForDrag("RightButton")
		layoutButton.Text = F.CreateText(layoutButton, "OVERLAY", G.Font, G.NameFS, G.FontFlag, "CENTER")
		layoutButton.Text:SetPoint("CENTER")

		layoutPanel = CreateFrame("Frame", nil, raidAnchor, "BackdropTemplate")
		layoutPanel:SetSize(276, 202)
		layoutPanel:SetClampedToScreen(true)
		layoutPanel:SetClampRectInsets(-10, 10, 10, -10)
		layoutPanel:SetFrameStrata("DIALOG")
		layoutPanel:SetBackdrop(controlBackdrop)
		layoutPanel:SetBackdropColor(0, 0, 0, .82)
		layoutPanel:SetBackdropBorderColor(0, .85, .85, 1)
		layoutPanel:EnableMouse(true)
		layoutPanel:Hide()

		local function CreatePanelButton(width, text)
			local button = CreateFrame("Button", nil, layoutPanel, "BackdropTemplate")
			button:SetSize(width, 22)
			button:SetBackdrop(controlBackdrop)
			button:SetBackdropBorderColor(0, .85, .85, 1)
			button.Text = F.CreateText(button, "OVERLAY", G.Font, G.NameFS, G.FontFlag, "CENTER")
			button.Text:SetPoint("CENTER")
			button.Text:SetText(text)
			button:SetScript("OnEnter", function(self)
				self.hovered = true
				UpdateControlButton(self, self.selected)
			end)
			button:SetScript("OnLeave", function(self)
				self.hovered = nil
				UpdateControlButton(self, self.selected)
			end)
			return button
		end

		local groupTitle = F.CreateText(layoutPanel, "OVERLAY", G.Font, G.NameFS, G.FontFlag, "LEFT")
		groupTitle:SetPoint("TOPLEFT", 12, -10)
		groupTitle:SetText(L.RaidGroupVisibility)

		local layoutTitle = F.CreateText(layoutPanel, "OVERLAY", G.Font, G.NameFS, G.FontFlag, "LEFT")
		layoutTitle:SetPoint("TOPLEFT", 12, -66)
		layoutTitle:SetText(L.RaidLayouts)

		for i = 1, 8 do
			local groupIndex = i
			local button = CreatePanelButton(28, groupIndex)
			button:SetPoint("TOPLEFT", 12 + (i - 1) * 32, -30)
			button:SetScript("OnClick", function()
				if InCombatLockdown() then return end

				enabledGroups[groupIndex] = not enabledGroups[groupIndex]
				ApplyRaidLayout(false)
			end)
			groupButtons[groupIndex] = button
		end

		for i, layout in ipairs(raidLayouts) do
			local layoutIndex = i
			local layoutData = layout
			local column = (layoutIndex - 1) % 2
			local row = math.floor((layoutIndex - 1) / 2)
			local button = CreatePanelButton(123, layoutData.label)
			button:SetPoint("TOPLEFT", 12 + column * 129, -86 - row * 28)
			button:SetScript("OnClick", function()
				if InCombatLockdown() then return end

				currentLayoutIndex = layoutIndex
				for groupIndex = 1, 8 do
					enabledGroups[groupIndex] = groupIndex <= layoutData.capacity
				end
				ApplyRaidLayout(true)
			end)
			layoutButtons[layoutIndex] = button
		end

		saveButton = CreatePanelButton(123, L.SaveRaidLayout)
		saveButton:SetPoint("TOPLEFT", 141, -170)
		saveButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
		saveButton:SetScript("OnClick", function(_, mouseButton)
			if InCombatLockdown() then return end

			if mouseButton == "RightButton" then
				RuriDB.RaidLayout = nil
			else
				local point, _, relativePoint, x, y = raidAnchor:GetPoint()
				local groups = {}
				for i = 1, 8 do
					groups[i] = enabledGroups[i]
				end
				RuriDB.RaidLayout = {
					layoutIndex = currentLayoutIndex,
					enabledGroups = groups,
					position = {
						point = point,
						relativePoint = relativePoint,
						x = x,
						y = y,
					},
				}
			end

			UpdateSaveButton()
		end)
		saveButton:HookScript("OnEnter", function(self)
			local x = self:GetCenter()
			GameTooltip:SetOwner(self, x > UIParent:GetWidth() / 2 and "ANCHOR_LEFT" or "ANCHOR_RIGHT")
			GameTooltip:SetText(L.SaveRaidLayout)
			GameTooltip:AddLine(L.SaveRaidLayoutTip, 1, 1, 1, true)
			GameTooltip:Show()
		end)
		saveButton:HookScript("OnLeave", function()
			GameTooltip:Hide()
		end)

		layoutButton:SetScript("OnClick", function()
			if InCombatLockdown() then return end
			layoutPanel:SetShown(not layoutPanel:IsShown())
		end)
		layoutButton:SetScript("OnEnter", UpdateLayoutButtonHighlight)
		layoutButton:SetScript("OnLeave", UpdateLayoutButtonHighlight)
		layoutButton:SetScript("OnDragStart", function(self)
			if InCombatLockdown() or not IsAltKeyDown() then return end
			layoutPanel:Hide()
			self.dragging = true
			UpdateLayoutButtonHighlight()
			raidAnchor:StartMoving()
		end)
		layoutButton:SetScript("OnDragStop", function(self)
			if not self.dragging then return end
			raidAnchor:StopMovingOrSizing()
			self.dragging = nil
			UpdateLayoutButtonHighlight()
		end)
		layoutPanel:SetScript("OnShow", function(self)
			-- 展開面板：上方高度不足以顯示面板時，朝下展開
			local availableHeightAbove = UIParent:GetHeight() - layoutButton:GetTop() - 10
			local openDown = availableHeightAbove < self:GetHeight() + C.Raid.Space
			local point = openDown and "TOPLEFT" or "BOTTOMLEFT"
			local relativePoint = openDown and "BOTTOMLEFT" or "TOPLEFT"

			self:ClearAllPoints()
			self:SetPoint(point, layoutButton, relativePoint, 0, openDown and -C.Raid.Space or C.Raid.Space)
			UpdateLayoutButtonHighlight()
		end)
		layoutPanel:SetScript("OnHide", UpdateLayoutButtonHighlight)
	end

	local wasInRaid = false
	-- 初始化：先建立預設；若遇戰鬥鎖定，脫戰後再套用
	if ApplyRaidLayout(true, savedPosition) then
		wasInRaid = IsInRaid()
	end
	UpdateLayoutControlShown() -- 初始化布局按鈕的顯隱狀態

	-- 受保護布局只在戰鬥外切換
	raidAnchor:RegisterEvent("PLAYER_ENTERING_WORLD")
	raidAnchor:RegisterEvent("GROUP_ROSTER_UPDATE")
	raidAnchor:RegisterEvent("PLAYER_REGEN_ENABLED")
	if layoutButtonEnabled then
		raidAnchor:RegisterEvent("PLAYER_REGEN_DISABLED")
	end
	raidAnchor:SetScript("OnEvent", function(_, event)
		if event == "PLAYER_REGEN_DISABLED" then
			UpdateLayoutControlShown(true)
			return
		end
		-- 戰鬥中由 secure header 沿用預留位置更新成員，離戰後再重排布局
		if InCombatLockdown() then return end

		local inRaid = IsInRaid()
		local raidStateChanged = inRaid ~= wasInRaid

		local positionOverride
		if layoutButtonEnabled and raidStateChanged then
			positionOverride = LoadSavedRaidLayout()
			if not positionOverride then
				currentLayoutIndex = 6
				for i = 1, 8 do
					enabledGroups[i] = true
				end
			end
		end

		ApplyRaidLayout(layoutButtonEnabled and raidStateChanged, positionOverride)
		wasInRaid = inRaid
		UpdateLayoutControlShown()
	end)
end

--===================================================--
-----------------    [[ Spawn ]]     ------------------
--===================================================--

local function SpawnGroupFrames(self)
	if F.GetRuriOption("PartyFrames") then
		self:RegisterStyle("Party", CreateParty)
		self:SetActiveStyle("Party")

		if F.GetRuriOption("PartyShowPlayer") then
			local partyAnchor = CreateFrame("Frame", nil, UIParent)
			partyAnchor:SetSize(20, 20)
			partyAnchor:SetPoint(unpack(C.Position.Party5))

			local party = self:SpawnHeader("oUF_Party", nil,
				"showParty",		true,
				"showPlayer",		true,
				"yOffset",			-C.Party.Space,

				"oUF-initialConfigFunction", ([[
					self:SetWidth(%d)
					self:SetHeight(%d)
				]]):format(C.Party.Width, C.Party.Height)
			)
			party:SetVisibility("party")
			party:SetPoint("TOPLEFT", partyAnchor, "BOTTOMRIGHT", -20, 4)
		else
			local party = {}
			for i = 1, 4 do
				local unit = self:Spawn("party"..i, "oUF_Party"..i)
				if i == 1 then
					unit:SetPoint(unpack(C.Position.Party4))
				else
					unit:SetPoint("TOP", party[i-1], "BOTTOM", 0, -(C.Party.Space+C.Party.PHeight+2))
				end
				party[i] = unit
			end
		end
	end

	if F.GetRuriOption("RaidFrames") then
		local layoutButtonEnabled = F.GetRuriOption("RaidLayoutButton")
		self:RegisterStyle("Raid", CreateRaid)

		local raidAnchor = CreateFrame("Frame", nil, UIParent)
		raidAnchor:SetSize(20, 20)
		raidAnchor:SetClampedToScreen(true)
		raidAnchor:SetClampRectInsets(-10, 10, 10, -10)

		raidTooltipAnchor = CreateFrame("Frame", nil, UIParent)
		raidTooltipAnchor:SetSize(1, 1)
		raidTooltipAnchor:SetPoint("TOPLEFT", raidAnchor, "BOTTOMLEFT")

		self:SetActiveStyle("Raid")
		local raid = {}

		for i = 1, 8 do
			raid[i] = self:SpawnHeader("oUF_Raid"..i, nil,
				"showRaid",         true,

				"groupFilter",		tostring(i),
				"yOffset",          -C.Raid.Space,

				"oUF-initialConfigFunction", ([[
					self:SetWidth(%d)
					self:SetHeight(%d)
				]]):format(C.Raid.Width, C.Raid.Height)
			)
			raid[i].raidFrameHeight = C.Raid.Height
			raid[i].layoutEnabled = true
			raid[i]:SetVisibility("raid")
		end

		CreateRaidLayoutController(raid, raidAnchor, raidTooltipAnchor, layoutButtonEnabled)
	end
end

oUF:Factory(SpawnGroupFrames)
