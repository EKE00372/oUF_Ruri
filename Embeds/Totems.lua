local _, ns = ...
local C, F, G, T = unpack(ns)

-- https://github.com/FireSiku/LUI/blob/master/modules/unitframes/layout/layout.lua
-- https://github.com/siweia/NDui/blob/master/Interface/AddOns/NDui/Modules/Auras/Totems.lua

local _G, CreateFrame, hooksecurefunc = _G, CreateFrame, hooksecurefunc
local C_DurationUtil_CreateDurationTextBinding = C_DurationUtil.CreateDurationTextBinding
local C_StringUtil_CreateNumericRuleFormatter = C_StringUtil.CreateNumericRuleFormatter
local GetTotemDuration = GetTotemDuration
local sort = table.sort
local wipe = wipe

local MAX_TOTEMS = _G.MAX_TOTEMS or 4
local totemBarHooked

-------------
-- 緊湊顯示 --
-------------

-- 1 = 單圖騰，秒數在圖示中
-- 4 = 多圖騰只顯示一個圖示，秒數在圖示兩側
local compactClasses = {
	PALADIN = 1,
	MONK = 1,
	DEATHKNIGHT = 1,
	DRUID = 4,
	WARLOCK = 4,
}

-- 多圖騰緊湊模式的秒數位置
local compactTextPoints = {
	[1] = {
		{ "RIGHT", "LEFT", -2, 0 },
	},
	[2] = {
		{ "RIGHT", "LEFT", -2, 0 },
		{ "LEFT", "RIGHT", 2, 0 },
	},
	[3] = {
		{ "RIGHT", "LEFT", -2, 6 },
		{ "RIGHT", "LEFT", -2, -6 },
		{ "LEFT", "RIGHT", 2, 0 },
	},
	[4] = {
		{ "RIGHT", "LEFT", -2, 6 },
		{ "RIGHT", "LEFT", -2, -6 },
		{ "LEFT", "RIGHT", 2, 6 },
		{ "LEFT", "RIGHT", 2, -6 },
	},
}

-------------
-- 普通顯示 --
-------------

-- 普通四格圖騰條：保留給薩滿的圖騰使用
local normalClasses = {}

--------------
-- Function --
--------------

-- 秒數文字格式
local durationFormatter = C_StringUtil_CreateNumericRuleFormatter()
durationFormatter:AddBreakpoint({
	threshold = 0,
	step = 1,
	rounding = Enum.NumericRuleFormatRounding.Up,
	min = 0,
	format = "%d",
})

-- 設定文字外觀
local function ConfigureCooldown(cooldown)
	-- 關掉所有動畫
	cooldown:SetDrawSwipe(false)
	cooldown:SetDrawEdge(false)
	cooldown:SetDrawBling(false)
	cooldown:SetReverse(true)
	cooldown:SetHideCountdownNumbers(false)

	local cooldownText = cooldown:GetRegions()
	if cooldownText and cooldownText.SetFont then
		cooldownText:SetFont(G.NFont or G.Font, G.NumberFS, G.FontFlag)
		cooldownText:ClearAllPoints()
		cooldownText:SetPoint("TOP", cooldown, 0, 3)
	end
end

-- 設定圖騰格子外觀：外框與 castbar icon 相同
local function StyleTotemButton(totem)
	totem.Shadow = F.CreateSD(totem, totem, 5)

	totem.Icon = totem:CreateTexture(nil, "OVERLAY")
	totem.Icon:SetAllPoints(totem)
	totem.Icon:SetTexCoord(.08, .92, .08, .92)
	totem.Icon:SetTexture(nil)

	totem.CD = CreateFrame("Cooldown", nil, totem, "CooldownFrameTemplate")
	totem.CD:SetAllPoints(totem)
	ConfigureCooldown(totem.CD)

	totem:SetAlpha(0)
	totem:EnableMouse(true)
end

-- 創建秒數文字
local function CreateDurationText(element, index)
	local text = F.CreateText(element[1] or element, "OVERLAY", G.NFont or G.Font, G.NumberFS, G.FontFlag, "CENTER")
	text:SetDrawLayer("OVERLAY", 7)
	text:SetText("")
	text:Hide()

	text.DurationBinding = C_DurationUtil_CreateDurationTextBinding()
	text.DurationBinding:SetFontString(text)
	text.DurationBinding:SetFormatter(durationFormatter)
	text.DurationBinding:SetUpdateInterval(.1)

	element.DurationTexts[index] = text
	return text
end

-- 類 oUF element 的子框結構：element[index] 保存每個自製圖騰格
local function CreateTotemButton(element, index)
	local totem = CreateFrame("Frame", nil, element)
	StyleTotemButton(totem)

	element[index] = totem
	return totem
end

-- 樣式布局：普通圖騰條保留原本四格一字排列；緊湊模式則是單圖示
local function LayoutTotemBar(element, compactLimit)
	local owner = element.__owner or _G.oUF_Player
	if not owner then return end

	local vertical = F.GetRuriOption("vertPlayer")
	local spacing = C.PPOffset
	local sideOffset = C.PPHeight + C.PPOffset
	local iconSize = C.AuraSize + 4
	local castIconSize = C.PHeight + C.PPHeight*2

	element:ClearAllPoints()

	if compactLimit then
		element:SetSize(castIconSize, castIconSize)
		if vertical then
			element:SetPoint("BOTTOM", owner.Health, "TOP", -(C.PPHeight + 1), C.PPOffset)
		else
			element:SetPoint("TOPRIGHT", owner.Health, "TOPLEFT", -C.PPOffset, -1)
		end

		for i = 1, MAX_TOTEMS do
			local totem = element[i]
			if not totem then break end

			totem:SetSize(castIconSize, castIconSize)
			totem:ClearAllPoints()

			if i == 1 then
				totem:SetPoint("CENTER", element, "CENTER", 0, 0)
			else
				totem.Icon:SetTexture(nil)
				totem.CD:Hide()
				totem:SetAlpha(0)
				totem:Hide()
			end
		end

		for i = 1, MAX_TOTEMS do
			local text = element.DurationTexts[i]
			if text then text:ClearAllPoints() end
		end

		return
	end

	if vertical then
		element:SetSize(iconSize + spacing*2, iconSize*MAX_TOTEMS + spacing*(MAX_TOTEMS + 1))
		element:SetPoint("TOPRIGHT", owner, "TOPLEFT", -sideOffset, 0)
	else
		element:SetSize(iconSize*MAX_TOTEMS + spacing*(MAX_TOTEMS + 1), iconSize + spacing*2)
		element:SetPoint("TOPRIGHT", owner, "BOTTOMRIGHT", -sideOffset, -spacing)
	end

	for i = 1, MAX_TOTEMS do
		local totem = element[i]
		if not totem then break end

		totem:SetSize(iconSize, iconSize)
		totem:ClearAllPoints()
		totem:Show()

		if vertical then
			if i == 1 then
				totem:SetPoint("TOP", element, "TOP", 0, 0)
			else
				totem:SetPoint("TOP", element[i - 1], "BOTTOM", 0, -spacing)
			end
		else
			if i == 1 then
				totem:SetPoint("BOTTOMRIGHT", element, "BOTTOMRIGHT", spacing, spacing)
			else
				totem:SetPoint("RIGHT", element[i - 1], "LEFT", -spacing, 0)
			end
		end
	end

	for i = 1, MAX_TOTEMS do
		local text = element.DurationTexts[i]
		if text then text:ClearAllPoints() end
	end
end

-- 建立類 oUF element 的圖騰列容器
local function CreateTotemElement(owner)
	local element = _G.Ruri_TotemBar
	if not element then
		element = CreateFrame("Frame", "Ruri_TotemBar", owner)
	end

	element:SetParent(owner)
	element.__owner = owner
	element.ForceUpdate = T.UpdateTotemBar
	element.activeButtons = element.activeButtons or {}
	element.DurationTexts = element.DurationTexts or {}

	for i = 1, MAX_TOTEMS do
		if not element[i] then
			CreateTotemButton(element, i)
		end
		if not element.DurationTexts[i] then
			CreateDurationText(element, i)
		end
	end

	LayoutTotemBar(element, compactClasses[G.myClass])
	element:Hide()
	owner.RuriTotems = element

	return element
end

-- 圖示沿用原生材質
local function GetTotemIcon(button)
	return button.Icon.Texture:GetTexture()
end

-- 顯示冷卻計時
local function SetTotemCooldown(totem, slot, showNumbers)
	local cooldown = totem.CD

	cooldown:SetHideCountdownNumbers(showNumbers == false)

	-- Secret value 不可計算
	cooldown:SetCooldownFromDurationObject(GetTotemDuration(slot))
	cooldown:Show()
end

-- 清空圖騰消失剩下的空格子
local function ClearTotem(totem)
	if not totem then return end

	totem.Icon:SetTexture(nil)
	totem.CD:Hide()
	totem:SetAlpha(0)
	totem:Hide()
end

-- 保留暴雪原生圖騰按鈕，用於點擊
local function AttachBlizzardButton(button, totem)
	button:ClearAllPoints()
	button:SetParent(totem)
	button:SetAllPoints(totem)
	button:SetAlpha(0)
	button:SetFrameLevel(totem:GetFrameLevel() + 3)
	button:EnableMouse(true)
end

-- 將圖騰的狀態同步到插件創建的圖騰格子
local function UpdateTotemButton(totem, button, showNumbers)
	totem.Icon:SetTexture(GetTotemIcon(button))
	SetTotemCooldown(totem, button.slot, showNumbers)
	totem:SetAlpha(1)
	totem:Show()

	-- 保留暴雪原生圖騰按鈕，才能右鍵取消
	AttachBlizzardButton(button, totem)
end

-- 更新緊湊模式
local function UpdateCompactTotemBar(element, activeButtons, compactLimit)
	local count = #activeButtons
	if count == 0 then
		ClearTotem(element[1])
		for i = 1, MAX_TOTEMS do
			local text = element.DurationTexts[i]
			text.DurationBinding:SetEnabled(false)
			text:SetText("")
			text:Hide()
		end
		element:SetShown(false)
		return
	end

	UpdateTotemButton(element[1], activeButtons[1], compactLimit == 1)

	for i = 2, MAX_TOTEMS do
		ClearTotem(element[i])
	end

	local displayCount = count > compactLimit and compactLimit or count
	local textPoints = compactLimit > 1 and compactTextPoints[displayCount]
	for i = 1, MAX_TOTEMS do
		local text = element.DurationTexts[i]
		local button = activeButtons[i]
		if textPoints and textPoints[i] and button and i <= compactLimit then
			local point = textPoints[i]
			text:ClearAllPoints()
			text:SetPoint(point[1], element[1], point[2], point[3], point[4])
			text.DurationBinding:SetDuration(GetTotemDuration(button.slot))
			text.DurationBinding:SetEnabled(true)
			text:Show()
		else
			text.DurationBinding:SetEnabled(false)
			text:SetText("")
			text:Hide()
		end
	end

	for i = 2, count do
		local button = activeButtons[i]
		button:ClearAllPoints()
		button:SetParent(element)
		button:SetSize(1, 1)
		button:SetPoint("CENTER", element, "CENTER", 0, 0)
		button:SetAlpha(0)
		button:SetFrameLevel(element:GetFrameLevel())
		button:EnableMouse(false)
	end

	element:SetShown(true)
end

-- 更新普通圖騰條：格子固定
local function UpdateNormalTotemBar(element, activeButtons)
	for i = 1, MAX_TOTEMS do
		local text = element.DurationTexts[i]
		text.DurationBinding:SetEnabled(false)
		text:SetText("")
		text:Hide()
	end

	for i = 1, #activeButtons do
		UpdateTotemButton(element[i], activeButtons[i], true)
	end

	for i = #activeButtons + 1, MAX_TOTEMS do
		ClearTotem(element[i])
	end

	element:SetShown(#activeButtons > 0)
end

-- 使用暴雪公開的圖騰顯示順位
local function SortTotemButtons(buttonA, buttonB)
	return buttonA.layoutIndex < buttonB.layoutIndex
end

-- hook 原生的狀態更新，Ruri 只同步外觀
function T.UpdateTotemBar()
	local element = _G.Ruri_TotemBar
	local totemFrame = _G.TotemFrame
	if not element or not totemFrame or not totemFrame.totemPool then return end

	local compactLimit = compactClasses[G.myClass]
	local useNormal = normalClasses[G.myClass]
	if not compactLimit and not useNormal then
		element:SetShown(false)
		return
	end

	local activeButtons = element.activeButtons
	wipe(activeButtons)

	for button in totemFrame.totemPool:EnumerateActive() do
		if button:IsShown() and button.slot and #activeButtons < MAX_TOTEMS then
			activeButtons[#activeButtons + 1] = button
		end
	end
	sort(activeButtons, SortTotemButtons)

	LayoutTotemBar(element, compactLimit)

	if compactLimit then
		UpdateCompactTotemBar(element, activeButtons, compactLimit)
	else
		UpdateNormalTotemBar(element, activeButtons)
	end
end

-- 註冊圖騰條
T.CreateTotemBar = function(self)
	if not compactClasses[G.myClass] and not normalClasses[G.myClass] then return end
	if not _G.TotemFrame or not _G.TotemFrame.totemPool then return end

	CreateTotemElement(self)

	if not totemBarHooked then
		hooksecurefunc(_G.TotemFrame, "Update", T.UpdateTotemBar)
		totemBarHooked = true
	end

	T.UpdateTotemBar()
end
