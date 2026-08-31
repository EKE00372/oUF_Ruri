--[[
	## Element

	TankResource - 用於顯示坦克減傷技能充能的 StatusBar table。
	前兩條直接接收 currentCharges；第三條使用 DurationObject 顯示下一層充能進度。

	## Sub-Widgets

	[1], [2] - 充能顯示。currentCharges 可能是 secret value，只能直接交給 StatusBar:SetValue()。
	[3] / .rechargeBar - 下一層充能進度條，使用 C_Spell.GetSpellChargeDuration()。
	.bg - 跟隨 StatusBar 顏色的背景材質，可設定 .multiplier，預設為 1。

	## Options

	.colors - 依職業指定顏色，格式為 {[classFileName] = color}。
	.costColor - 資源不足時是否改用 noPowerCostColor，預設為 true。
	.noPowerCostColor - 資源不足時的顏色，預設為 {.9, .1, .1, 1}。
	.overrideSpellOptions - 變形法術顏色，格式為 {[classFileName] = {[spellID] = color}}。
	.chargeBarCount - 充能 StatusBar 數量，預設為 element 數量減一。
	.rechargeBar - 下一層充能進度使用的 StatusBar，預設為 chargeBarCount 後一條。
	.MaxChangeUpdate(maxCharges) - 最大充能數改變後調整 layout。

	## Callbacks and Overrides

	.PreUpdate(unit)
	.PostUpdate(maxCharges, hasMaxChanged)
	.PostUpdateColor(color)
	.PostVisibility(isVisible)
	.Override(self, event, unit, spell, ...)
	.OverrideVisibility(self, event, ...)
	.OverrideEnableEvent(self, spell)
	.OverrideDisableEvent(self, spell)
	.UpdateColor(self, event, unit)

	## Example

	local TankResource = {}
	local maxLength = 3
	for index = 1, maxLength do
		local bar = CreateFrame('StatusBar', nil, self)
		bar:SetSize(120 / maxLength, 20)
		bar:SetPoint('TOPLEFT', self, 'BOTTOMLEFT', (index - 1) * bar:GetWidth(), 0)
		TankResource[index] = bar
	end

	TankResource.chargeBarCount = 2
	TankResource.rechargeBar = TankResource[3]
	self.TankResource = TankResource
]]

----------------------
-- 原始作者：HopeASD --
----------------------

local _, ns = ...
local T = ns[4]
local oUF = ns.oUF or oUF
local pcall = pcall

local _, PlayerClass = UnitClass('player')
local SPEC_MONK_BREWMASTER = SPEC_MONK_BREWMASTER or 1
local SPEC_DEMONHUNTER_VENGEANCE = SPEC_DEMONHUNTER_VENGEANCE or 2
local SPEC_WARRIOR_PROTECTION = SPEC_WARRIOR_PROTECTION or 3
local SPEC_PALADIN_PROTECTION = SPEC_PALADIN_PROTECTION or 2
local SPEC_DRUID_GUARDIAN = SPEC_DRUID_GUARDIAN or 3

local UnitHasVehicleUI = UnitHasVehicleUI
local C_Spell_GetSpellCharges = C_Spell.GetSpellCharges
local C_Spell_GetSpellChargeDuration = C_Spell.GetSpellChargeDuration
local C_Spell_GetOverrideSpell = C_Spell.GetOverrideSpell
local C_Spell_IsSpellUsable = C_Spell.IsSpellUsable
local C_SpellBook_IsSpellKnownOrInSpellBook = C_SpellBook.IsSpellKnownOrInSpellBook
local C_SpecializationInfo_GetSpecialization = C_SpecializationInfo.GetSpecialization
local StatusBarInterpolationImmediate = Enum.StatusBarInterpolation and Enum.StatusBarInterpolation.Immediate
local StatusBarTimerDirectionElapsedTime = Enum.StatusBarTimerDirection and Enum.StatusBarTimerDirection.ElapsedTime
local DEFAULT_COLOR = { .95, .72, .28 }

local STATE = {}
local TankResourceEnable, TankResourceDisable

-- [classFileName] = {specIndex, spellID, requiredTalentSpellID}
local enableClassAndSpec = {
	['MONK'] = { SPEC_MONK_BREWMASTER, 119582 },
	['PALADIN'] = { SPEC_PALADIN_PROTECTION, 432459, 432459 }, -- 光鑄者
	['DEMONHUNTER'] = { SPEC_DEMONHUNTER_VENGEANCE, 203720, 1266307 }, -- 惡魔韌性
	['WARRIOR'] = { SPEC_WARRIOR_PROTECTION, 2565 },
	['DRUID'] = { SPEC_DRUID_GUARDIAN, 22842, 377811 }, -- 固有決心
}

local function GetEnableStateAndSpell()
	local options = enableClassAndSpec[PlayerClass]
	if options then
		local spec, spell, requiredTalentSpell = unpack(options)
		if spec == C_SpecializationInfo_GetSpecialization() and C_SpellBook_IsSpellKnownOrInSpellBook(spell) then
			if requiredTalentSpell and not C_SpellBook_IsSpellKnownOrInSpellBook(requiredTalentSpell) then
				return false
			end

			return true, spell
		end
	end

	return false
end

-- 供其他模組查詢玩家目前是否擁有坦克資源；只回傳 boolean，不外洩 spell。
T.PlayerHasTankResource = function()
	return (GetEnableStateAndSpell())
end

-- currentCharges 可能是 secret value；maxCharges 在 12.1 API 契約中是公開值。
local function GetResourceChargesInfo(element, state)
	local chargesInfo = C_Spell_GetSpellCharges(state.spell)
	local maxCharges = state.max or element.__chargeBarCount or #element

	if chargesInfo then
		return chargesInfo, chargesInfo.maxCharges or maxCharges
	end

	return nil, maxCharges
end

local function SetBarColor(bar, color)
	local r, g, b

	if color and color.GetRGB then
		r, g, b = color:GetRGB()
	elseif color then
		r, g, b = color[1], color[2], color[3]
	end

	if not r or not g or not b then
		r, g, b = DEFAULT_COLOR[1], DEFAULT_COLOR[2], DEFAULT_COLOR[3]
	end

	bar:SetStatusBarColor(r, g, b)

	local bg = bar.bg
	if bg then
		local multiplier = bg.multiplier or 1
		bg:SetVertexColor(r * multiplier, g * multiplier, b * multiplier)
	end
end

local function GetActiveColor(element, state)
	local color = (element.colors and element.colors[PlayerClass]) or DEFAULT_COLOR
	local overrideSpellOptions = state.overrideSpellOptions

	if overrideSpellOptions then
		local overrideSpell = C_Spell_GetOverrideSpell(state.spell) or state.spell
		color = overrideSpellOptions[overrideSpell] or color
	end

	return color
end

local function UpdateColor(self, event, unit)
	local element = self.TankResource
	local state = STATE[element]
	if not state or not state.enabled then return end

	local color = GetActiveColor(element, state)
	if element.costColor then
		local usable, insufficientPower = C_Spell_IsSpellUsable(state.spell)
		if not usable and insufficientPower then
			color = element.noPowerCostColor
		end
	end

	if state.color == color then return end
	state.color = color

	for i = 1, #element do
		SetBarColor(element[i], color)
	end

	if element.PostUpdateColor then
		element:PostUpdateColor(color)
	end
end

local function ColorPath(self, ...)
	return (self.TankResource.UpdateColor or UpdateColor)(self, ...)
end

-- 使用 DurationObject 交給原生 StatusBar 計算，不在 Lua 端讀取或運算冷卻時間。
local function UpdateRechargeBar(element, spell)
	local bar = element.__rechargeBar
	if not bar then return end

	bar:Show()

	if not C_Spell_GetSpellChargeDuration or not bar.SetTimerDuration then
		bar:SetValue(0)
		return
	end

	local duration = C_Spell_GetSpellChargeDuration(spell)
	if duration then
		local success
		if StatusBarInterpolationImmediate and StatusBarTimerDirectionElapsedTime then
			success = pcall(bar.SetTimerDuration, bar, duration, StatusBarInterpolationImmediate, StatusBarTimerDirectionElapsedTime)
		else
			success = pcall(bar.SetTimerDuration, bar, duration)
		end

		if not success then
			bar:SetValue(0)
		end
	else
		bar:SetValue(1)
	end
end

local function Update(self, event, unit)
	local element = self.TankResource
	local state = STATE[element]
	if not state or not state.enabled then return end

	-- 法術可用狀態只影響資源不足顏色，不需要重讀充能資料。
	if event == 'SPELL_UPDATE_USABLE' then
		if unit and unit ~= self.__unit then return end
		return ColorPath(self, event, self.__unit)
	end

	if not unit or unit ~= self.__unit then return end

	if element.PreUpdate then
		element:PreUpdate(unit)
	end

	ColorPath(self, event, unit)

	local chargesInfo, maxCharges = GetResourceChargesInfo(element, state)
	if not chargesInfo then
		UpdateRechargeBar(element, state.spell)
		return
	end

	local secretCurrentCharges = chargesInfo.currentCharges
	local chargeBarCount = element.__chargeBarCount
	local oldMax = state.max

	for i = 1, chargeBarCount do
		local bar = element[i]
		if i <= maxCharges then
			bar:Show()
			bar:SetValue(secretCurrentCharges)
		else
			bar:Hide()
			bar:SetValue(0)
		end
	end

	UpdateRechargeBar(element, state.spell)

	local hasMaxChanged = maxCharges ~= oldMax
	if hasMaxChanged then
		state.max = maxCharges
		element.__max = maxCharges

		if element.MaxChangeUpdate then
			element:MaxChangeUpdate(maxCharges)
		end
	end

	if element.PostUpdate then
		return element:PostUpdate(maxCharges, hasMaxChanged)
	end
end

-- Override 一律接收標準 event、unit，再附上目前資源法術。
local function Path(self, event, unit, ...)
	local element = self.TankResource
	local state = STATE[element]

	if event == 'TankResourceEnable' then
		if element.OverrideEnableEvent then
			element.OverrideEnableEvent(self, state and state.spell)
		end
	elseif event == 'TankResourceDisable' then
		if element.OverrideDisableEvent then
			element.OverrideDisableEvent(self, state and state.spell)
		end
		return
	end

	return (element.Override or Update)(self, event, unit, state and state.spell, ...)
end

-- SPELL_UPDATE_* 是 unitless event；不要把其 payload 誤當成 unit。
local function SpellUpdatePath(self, event, ...)
	local state = STATE[self.TankResource]
	if not state or not state.enabled then return end

	return Path(self, event, self.__unit, ...)
end

local function Visibility(self, event)
	local element = self.TankResource
	local state = STATE[element]
	if not state then return end

	local shouldEnable, spell
	if not UnitHasVehicleUI('player') then
		shouldEnable, spell = GetEnableStateAndSpell()
	end

	local wasEnabled = state.enabled
	if shouldEnable then
		state.spell = spell

		local overrideSpellOptions = element.overrideSpellOptions
		state.overrideSpellOptions = overrideSpellOptions and overrideSpellOptions[PlayerClass]
	end

	if shouldEnable and not wasEnabled then
		TankResourceEnable(self)
		if element.PostVisibility then
			element:PostVisibility(true)
		end
	elseif not shouldEnable and wasEnabled then
		TankResourceDisable(self)
		if element.PostVisibility then
			element:PostVisibility(false)
		end
	elseif shouldEnable then
		Path(self, event, self.__unit)
	end
end

local function VisibilityPath(self, ...)
	return (self.TankResource.OverrideVisibility or Visibility)(self, ...)
end

local function ForceUpdate(element)
	return VisibilityPath(element.__owner, 'ForceUpdate', element.__owner.__unit)
end

do
	function TankResourceEnable(self)
		local element = self.TankResource
		local state = STATE[element]
		if not state then return end

		self:RegisterEvent('SPELL_UPDATE_COOLDOWN', SpellUpdatePath, true)
		self:RegisterEvent('SPELL_UPDATE_CHARGES', SpellUpdatePath, true)

		if element.costColor then
			self:RegisterEvent('SPELL_UPDATE_USABLE', SpellUpdatePath, true)
		end

		state.enabled = true
		element.isEnabled = true

		Path(self, 'TankResourceEnable', self.__unit)
	end

	function TankResourceDisable(self)
		local element = self.TankResource
		local state = STATE[element]
		if not state then return end

		self:UnregisterEvent('SPELL_UPDATE_COOLDOWN', SpellUpdatePath)
		self:UnregisterEvent('SPELL_UPDATE_CHARGES', SpellUpdatePath)
		self:UnregisterEvent('SPELL_UPDATE_USABLE', SpellUpdatePath)

		for i = 1, #element do
			element[i]:Hide()
		end

		state.enabled = false
		element.isEnabled = false

		Path(self, 'TankResourceDisable', self.__unit)

		state.spell = nil
		state.overrideSpellOptions = nil
		state.color = nil
	end
end

local function Enable(self, unit)
	local element = self.TankResource
	if not element or unit ~= 'player' then return end

	element.__owner = self
	element.__chargeBarCount = element.chargeBarCount or element.__chargeBarCount or (#element - 1)
	element.__rechargeBar = element.rechargeBar or element[element.__chargeBarCount + 1]
	element.__max = element.__chargeBarCount
	element.isEnabled = false
	element.noPowerCostColor = element.noPowerCostColor or { .9, .1, .1, 1 }
	if element.costColor == nil then element.costColor = true end
	element.ForceUpdate = ForceUpdate
	element.TankResourceEnable = TankResourceEnable
	element.TankResourceDisable = TankResourceDisable

	STATE[element] = {
		enabled = false,
		max = element.__max,
	}

	self:RegisterEvent('PLAYER_TALENT_UPDATE', VisibilityPath, true)
	self:RegisterEvent('SPELLS_CHANGED', VisibilityPath, true)
	self:RegisterEvent('PLAYER_SPECIALIZATION_CHANGED', VisibilityPath)

	for i = 1, #element do
		local bar = element[i]
		if bar:IsObjectType('StatusBar') then
			if not bar:GetStatusBarTexture() then
				bar:SetStatusBarTexture([[Interface\TargetingFrame\UI-StatusBar]])
			end

			if i <= element.__chargeBarCount then
				bar:SetMinMaxValues(i - 1, i)
			else
				bar:SetMinMaxValues(0, 1)
			end
		end

		bar:Hide()
	end

	return true
end

local function Disable(self)
	local element = self.TankResource
	if not element then return end

	TankResourceDisable(self)

	self:UnregisterEvent('PLAYER_TALENT_UPDATE', VisibilityPath)
	self:UnregisterEvent('SPELLS_CHANGED', VisibilityPath)
	self:UnregisterEvent('PLAYER_SPECIALIZATION_CHANGED', VisibilityPath)

	STATE[element] = nil
end

oUF:AddElement('TankResource', VisibilityPath, Enable, Disable)
