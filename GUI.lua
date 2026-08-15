local addon, ns = ...
local F, G, L = ns[2], ns[3], ns[5]

local type, ipairs = type, ipairs
local tinsert, wipe, floor = table.insert, wipe, math.floor
local MainFrame

-- 外觀常數
local THEME_R, THEME_G, THEME_B = 0, .85, .85
local DISABLED_TEXT_R, DISABLED_TEXT_G, DISABLED_TEXT_B = .45, .5, .5
local DISABLED_DESC_R, DISABLED_DESC_G, DISABLED_DESC_B = .36, .44, .44

local PANEL_ALPHA, BUTTON_ALPHA = .82, .35
local BREATH_MIN_ALPHA, BREATH_MAX_ALPHA = .25, .75
local BREATH_IN_DURATION, BREATH_OUT_DURATION = 5, 7
local BREATH_MAIN_SIZE, BREATH_TAB_SIZE = 12, 10

local MAIN_WIDTH, MAIN_HEIGHT = 480, 340
local PAGE_HORIZONTAL_INSET, PAGE_TOP_INSET = 26, 32
local COLUMN_WIDTH, COLUMN_GAP = 205, 18
local SECTION_HEIGHT, SECTION_GAP = 24, 8
local OPTION_HEIGHT, OPTION_GAP = 26, 2
local OVERVIEW_ROW_HEIGHT, OVERVIEW_ROW_GAP = 52, 4
local TAB_WIDTH, TAB_HEIGHT, TAB_GAP = 150, 32, 10
local TITLE_Y_OFFSET = 14

-----------
-- Reset --
-----------

-- Reset clears the whole RuriDB table / 重置整個 RuriDB
local function ResetDB()
	if type(RuriDB) == "table" then
		wipe(RuriDB)
	else
		RuriDB = {}
	end
end

--------------
-- Template --
--------------

-- Text template / 文字模板
local function CreateText(parent, text, size, justify)
	local fontString = F.CreateText(parent, "OVERLAY", G.Font, size or G.NameFS, G.FontFlag, justify)
	fontString:SetText(text)
	return fontString
end

-- Panel template / 框體模板
local function SetPanelBackdrop(frame, alpha)
	frame:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8x8",
		edgeFile = "Interface\\Buttons\\WHITE8x8",
		edgeSize = 1,
		tile = false,
		insets = {left = 1, right = 1, top = 1, bottom = 1},
	})
	frame:SetBackdropColor(0, 0, 0, alpha or .75)
	frame:SetBackdropBorderColor(THEME_R, THEME_G, THEME_B, 1)
end

-- Glow animation template / 呼吸光
local function CreateBreathGlow(parent, size)
	local glow = F.CreateSD(parent, parent, size, THEME_R, THEME_G, THEME_B, .65)
	glow:SetAlpha(BREATH_MIN_ALPHA)

	local animation = glow:CreateAnimationGroup()
	animation:SetLooping("REPEAT")

	local fadeIn = animation:CreateAnimation("Alpha")
	fadeIn:SetFromAlpha(BREATH_MIN_ALPHA)
	fadeIn:SetToAlpha(BREATH_MAX_ALPHA)
	fadeIn:SetDuration(BREATH_IN_DURATION)
	fadeIn:SetSmoothing("IN_OUT")
	fadeIn:SetOrder(1)

	local fadeOut = animation:CreateAnimation("Alpha")
	fadeOut:SetFromAlpha(BREATH_MAX_ALPHA)
	fadeOut:SetToAlpha(BREATH_MIN_ALPHA)
	fadeOut:SetDuration(BREATH_OUT_DURATION)
	fadeOut:SetSmoothing("IN_OUT")
	fadeOut:SetOrder(2)

	animation:Play()
end

-- Button template / 按鈕模板
local function CreateButton(parent, width, height, text)
	local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
	button:SetSize(width, height)
	SetPanelBackdrop(button, BUTTON_ALPHA)

	button.Text = CreateText(button, text, G.NameFS, "CENTER")
	button.Text:SetPoint("CENTER")

	button:SetScript("OnEnter", function(self)
		self:SetBackdropColor(0, .45, .45, .65)
	end)
	button:SetScript("OnLeave", function(self)
		self:SetBackdropColor(0, 0, 0, BUTTON_ALPHA)
	end)

	return button
end

-- WIP
local function GetOptionLabel(option)
	local labelText = L[option.label] or option.label
	if option.wip then
		labelText = labelText.." ("..(L.WIP or "WIP")..")"
	end
	return labelText
end

-- Title template / 標題模板
local function CreateSectionTitle(parent, text, yOffset)
	local title = CreateText(parent, "|cff00ffff"..(L[text] or text).."|r", G.NameFS + 2, "LEFT")
	title:SetPoint("TOPLEFT", 0, yOffset)
end

-- Tooltip template / 說明模板
local function CreateInfoTooltip(parent, text)
	local icon = CreateFrame("Button", nil, parent)
	icon:SetSize(G.NameFS + 2, G.NameFS + 2)

	local texture = icon:CreateTexture(nil, "ARTWORK")
	texture:SetAllPoints()
	texture:SetTexture(G.media.info)
	icon:SetHighlightTexture(G.media.info)

	icon:SetScript("OnEnter", function(self)
		local tooltip = L[text] or text
		if type(tooltip) == "function" then
			tooltip = tooltip()
		end

		GameTooltip:ClearLines()
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 0, 0)
		GameTooltip:AddLine(tooltip, 1, 1, 1, true)
		GameTooltip:Show()
	end)
	icon:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	return icon
end

---------------
-- Functions --
---------------

-- 檢查選項本身及各層依賴，判斷是否允許編輯
local function CanEditOption(option, group, section)
	-- 檢查選項本身是否被禁用
	if option.disabled then return false end

	-- 依序檢查頁面、子分類與選項本身的依賴條件
	for _, setting in ipairs({group, section, option}) do
		local requiredAny = setting.requiresAny
		if requiredAny then
			local matched
			for _, key in ipairs(requiredAny) do
				if F.GetRuriOption(key) == true then
					matched = true
					break
				end
			end
			if not matched then return false end
		end
	end

	return true
end

-- 同步選項狀態
local function RefreshOptionControls()
	if not MainFrame or not MainFrame.OptionRows then return end

	for _, row in ipairs(MainFrame.OptionRows) do
		row:RefreshState()
	end
end

-- 寫入設定值
local function SetOptionValue(option, value)
	-- 禁用選項不寫入設定值
	if option.disabled then return end
	-- 寫入設定值
	F.SetRuriOption(option.key, value)
	-- 提示重載
	if MainFrame and MainFrame.StatusText then
		MainFrame.StatusText:SetText("|cffffd100"..(L.StatusChanged or "StatusChanged").."|r")
	end
	-- 更新
	RefreshOptionControls()
end

-- 將選項綁定至設定值，並處理點擊與更新
local function SetupOptionRow(row, check, label, desc, option, group, section)
	-- 開關
	local function ToggleValue()
		if not CanEditOption(option, group, section) then
			check:SetChecked(F.GetRuriOption(option.key) == true)
			return
		end

		SetOptionValue(option, check:GetChecked() == true)
	end
	-- 選項方塊=開關
	check:SetScript("OnClick", ToggleValue)
	-- 選項詞條=開關
	row:SetScript("OnClick", function()
		check:SetChecked(not check:GetChecked())
		ToggleValue()
	end)

	-- 同步選項狀態
	row.RefreshState = function(self)
		local available = CanEditOption(option, group, section)
		check:SetChecked(F.GetRuriOption(option.key) == true)
		if available then
			self:Enable()
			check:Enable()
			label:SetTextColor(1, 1, 1, 1)
			if desc then desc:SetTextColor(.72, .86, .86, 1) end
		else
			self:Disable()
			check:Disable()
			label:SetTextColor(DISABLED_TEXT_R, DISABLED_TEXT_G, DISABLED_TEXT_B, 1)
			if desc then desc:SetTextColor(DISABLED_DESC_R, DISABLED_DESC_G, DISABLED_DESC_B, 1) end
		end
	end

	tinsert(MainFrame.OptionRows, row)
end

-- 總覽選項：整行說明
-- Overview：rows use full-width
local function CreateOverviewOption(parent, option, index, yBase, group, section)
	local yOffset = yBase - (index - 1) * (OVERVIEW_ROW_HEIGHT + OVERVIEW_ROW_GAP)
	local row = CreateFrame("Button", nil, parent)
	row:SetSize(COLUMN_WIDTH * 2 + COLUMN_GAP, OVERVIEW_ROW_HEIGHT)
	row:SetPoint("TOPLEFT", 0, yOffset)

	local check = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
	check:SetPoint("TOPLEFT", -4, 2)

	local label = CreateText(row, GetOptionLabel(option), G.NameFS, "LEFT")
	label:SetPoint("TOPLEFT", check, "TOPRIGHT", 2, -5)
	label:SetPoint("RIGHT", row, "RIGHT", 0, 0)

	local desc
	if option.desc then
		desc = CreateText(row, L[option.desc] or option.desc, G.NameFS, "LEFT")
		desc:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -2)
		desc:SetPoint("RIGHT", row, "RIGHT", 0, 0)
		desc:SetWordWrap(true)
	end

	SetupOptionRow(row, check, label, desc, option, group, section)
	return desc or label
end

-- 一般選項：兩欄選項並支援 [i] tooltip
-- Regular option: two-column layout and support [i] tooltips
local function CreateCheckOption(parent, option, index, yBase, group, section)
	local column = (index - 1) % 2
	local rowIndex = floor((index - 1) / 2)
	local xOffset = column * (COLUMN_WIDTH + COLUMN_GAP)
	local yOffset = yBase - rowIndex * (OPTION_HEIGHT + OPTION_GAP)

	local row = CreateFrame("Button", nil, parent)
	row:SetSize(COLUMN_WIDTH, OPTION_HEIGHT)
	row:SetPoint("TOPLEFT", xOffset, yOffset)

	local check = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
	check:SetPoint("LEFT", -4, 0)

	local label = CreateText(row, GetOptionLabel(option), G.NameFS, "LEFT")
	label:SetPoint("LEFT", check, "RIGHT", 2, 0)
	if option.tooltip then
		local tip = CreateInfoTooltip(row, option.tooltip)
		tip:SetPoint("LEFT", label, "RIGHT", 4, 2)
	else
		label:SetPoint("RIGHT", row, "RIGHT", 0, 0)
	end

	SetupOptionRow(row, check, label, nil, option, group, section)
end

-- Create category page / 創建設定頁面
local function CreatePage(parent, group)
	local page = CreateFrame("Frame", nil, parent)
	page:SetPoint("TOPLEFT", PAGE_HORIZONTAL_INSET, -PAGE_TOP_INSET)
	page:SetPoint("BOTTOMRIGHT", -PAGE_HORIZONTAL_INSET, 54)
	page:Hide()

	local yOffset = 0
	local lastOverviewOptionText

	local function AddSection(section)
		local optionIndex = 0
		local hasDescription = false

		if section.name then
			CreateSectionTitle(page, section.name, yOffset)
			yOffset = yOffset - SECTION_HEIGHT
		end

		for _, option in ipairs(section.options or {}) do
			if option.desc then
				hasDescription = true
				break
			end
		end

		for _, option in ipairs(section.options or {}) do
			if option.type == "toggle" then
				optionIndex = optionIndex + 1
				if hasDescription then
					lastOverviewOptionText = CreateOverviewOption(page, option, optionIndex, yOffset, group, section)
				else
					CreateCheckOption(page, option, optionIndex, yOffset, group, section)
				end
			end
		end

		if optionIndex > 0 then
			if hasDescription then
				yOffset = yOffset - optionIndex * (OVERVIEW_ROW_HEIGHT + OVERVIEW_ROW_GAP) - SECTION_GAP
			else
				local rows = floor((optionIndex + 1) / 2)
				yOffset = yOffset - rows * (OPTION_HEIGHT + OPTION_GAP) - SECTION_GAP
			end
		end
	end

	-- 有子分類的按 sections 分段建立，沒有的直接建立
	if group.sections then
		for _, section in ipairs(group.sections) do
			AddSection(section)
		end
	else
		AddSection({ options = group.options })
	end

	if group.name == "Overview" then
		local credits = CreateText(page, L.Credits, G.NameFS - 2, "LEFT")
		credits:SetPoint("TOPRIGHT", lastOverviewOptionText, "BOTTOMRIGHT", 0, -SECTION_GAP)
		credits:SetSize(COLUMN_WIDTH * 2 + COLUMN_GAP - 4, (G.NameFS - 2) * 3)
		credits:SetWordWrap(true)
		credits:SetTextColor(.72, .86, .86, 1)
	end

	return page
end

-- 左側分頁按鈕只負責切換頁面顯示
-- Left tab buttons only switch page visibility
local function SelectTab(frame, index)
	for tabIndex, tab in ipairs(frame.Tabs) do
		tab.Selected = tabIndex == index
		if tab.Selected then
			tab:SetBackdropColor(0, .35, .35, PANEL_ALPHA)
			frame.Pages[tabIndex]:Show()
		else
			tab:SetBackdropColor(0, 0, 0, PANEL_ALPHA)
			frame.Pages[tabIndex]:Hide()
		end
	end
end

-- Create left tab button / 創建分頁按鈕
local function CreateTab(parent, index, text)
	local tab = CreateButton(parent, TAB_WIDTH, TAB_HEIGHT, L[text] or text)
	tab:SetPoint("TOPRIGHT", parent, "TOPLEFT", -10, -48 - (index - 1) * (TAB_HEIGHT + TAB_GAP))
	tab.Text:SetFont(G.Font, G.NameFS, G.FontFlag)
	tab:SetBackdropColor(0, 0, 0, PANEL_ALPHA)
	CreateBreathGlow(tab, BREATH_TAB_SIZE)

	tab:SetScript("OnEnter", function(self)
		self:SetBackdropColor(0, .45, .45, PANEL_ALPHA)
	end)
	tab:SetScript("OnLeave", function(self)
		if self.Selected then
			self:SetBackdropColor(0, .35, .35, PANEL_ALPHA)
		else
			self:SetBackdropColor(0, 0, 0, PANEL_ALPHA)
		end
	end)
	tab:SetScript("OnClick", function()
		SelectTab(parent, index)
	end)
	return tab
end

-----------
-- Build --
-----------

-- Build GUI
local function BuildGUI()
	local version = C_AddOns.GetAddOnMetadata(addon, "Version") or ""

	MainFrame = CreateFrame("Frame", "oUFRuriGUI", UIParent, "BackdropTemplate")
	tinsert(UISpecialFrames, MainFrame:GetName())
	MainFrame:SetFrameStrata("DIALOG")
	MainFrame:SetSize(MAIN_WIDTH, MAIN_HEIGHT)
	MainFrame:SetPoint("CENTER")
	MainFrame:SetMovable(true)
	MainFrame:EnableMouse(true)
	MainFrame:RegisterForDrag("LeftButton")
	MainFrame:SetClampedToScreen(true)
	MainFrame:SetScript("OnDragStart", MainFrame.StartMoving)
	MainFrame:SetScript("OnDragStop", MainFrame.StopMovingOrSizing)
	SetPanelBackdrop(MainFrame, PANEL_ALPHA)
	CreateBreathGlow(MainFrame, BREATH_MAIN_SIZE)

	local titleSize = G.NameFS + 4
	local title = CreateText(MainFrame, "|cff00ffffoUF_Ruri|r "..version, titleSize, "CENTER")
	title:SetPoint("TOP", MainFrame, "TOP", 0, TITLE_Y_OFFSET)

	MainFrame.StatusText = CreateText(MainFrame, "", G.NameFS, "LEFT")
	MainFrame.StatusText:SetPoint("BOTTOMLEFT", 20, 22)

	MainFrame.Tabs = {}
	MainFrame.Pages = {}
	MainFrame.OptionRows = {}

	for index, group in ipairs(F.GUIOptionGroups) do
		MainFrame.Tabs[index] = CreateTab(MainFrame, index, group.name)
		MainFrame.Pages[index] = CreatePage(MainFrame, group)
	end

	local closeButton = CreateButton(MainFrame, 24, 24, "X")
	closeButton:SetPoint("TOPRIGHT", -12, -12)
	closeButton:SetScript("OnClick", function()
		MainFrame:Hide()
	end)

	local reloadButton = CreateButton(MainFrame, 88, 28, L.ReloadUI or "ReloadUI")
	reloadButton:SetPoint("BOTTOMRIGHT", -24, 18)
	reloadButton:SetScript("OnClick", ReloadUI)

	local resetButton = CreateButton(MainFrame, 88, 28, RESET)
	resetButton:SetPoint("RIGHT", reloadButton, "LEFT", -10, 0)
	resetButton:SetScript("OnClick", function()
		ResetDB()
		ReloadUI()
	end)

	SelectTab(MainFrame, 1)
	MainFrame:Hide()
end

-- slash CMD
F.CreateRuriGUI = function()
	if not MainFrame then
		BuildGUI()
	end
	RefreshOptionControls()

	if MainFrame:IsShown() then
		MainFrame:Hide()
	else
		MainFrame:Show()
	end
end

SlashCmdList["OUFRURI"] = F.CreateRuriGUI
SLASH_OUFRURI1 = "/ruri"
