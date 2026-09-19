--[[
	## Element

	TankResource - 用於顯示坦克二層減傷技能充能的三個 StatusBar。
	前兩條直接接收 currentCharges；第三條使用 DurationObject 顯示下一層充能進度。

	## Sub-Widgets

	[1], [2] - 充能顯示。currentCharges 可能是 secret value，只能直接交給 StatusBar:SetValue()。
	[3] / .rechargeBar - 下一層充能進度條，使用 C_Spell.GetSpellChargeDuration()。
	.Time - 可選的充能倒數 FontString，.binding 由 layout 配置為 DurationTextBinding。
	.bg - 跟隨 StatusBar 顏色的背景材質，可設定 .multiplier，預設為 1。

	## Options

	.colorBase - 基礎配色，預設為 {.95, .72, .28}。
	.colorOverride - lib 指定替換法術的配色，預設為 {1, .92, .55}。
	兩種配色接受 {r, g, b} 或 ColorMixin，RGB 必須為公開值；切換規則由 lib 管理。
	.rechargeBar - 下一層充能進度使用的 StatusBar，預設為 element[3]。
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

	TankResource.rechargeBar = TankResource[3]
	self.TankResource = TankResource
]]

----------------------
-- 原始作者：HopeASD --
----------------------

local _, ns = ...
local oUF = ns.oUF or oUF

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
local C_SpellBook_IsSpellKnownOrInSpellBook = C_SpellBook.IsSpellKnownOrInSpellBook
local C_SpecializationInfo_GetSpecialization = C_SpecializationInfo.GetSpecialization

local STATE = {}
local TankResourceEnable, TankResourceDisable

-- 追蹤法術、天賦門檻與切色規則由 element 維護。
local classSpells = {
	['MONK'] = { spec = SPEC_MONK_BREWMASTER, spell = 119582 },
	['PALADIN'] = { spec = SPEC_PALADIN_PROTECTION, spell = 432459, overrideSpell = 432472 }, -- 光鑄者
	['DEMONHUNTER'] = { spec = SPEC_DEMONHUNTER_VENGEANCE, spell = 203720, requiredTalent = 1266307 }, -- 惡魔韌性
	['WARRIOR'] = { spec = SPEC_WARRIOR_PROTECTION, spell = 2565 },
	['DRUID'] = { spec = SPEC_DRUID_GUARDIAN, spell = 22842, requiredTalent = 377811 }, -- 固有決心
}

local function GetEnableStateAndSpell()
	local options = classSpells[PlayerClass]
	if options then
		if options.spec == C_SpecializationInfo_GetSpecialization() and C_SpellBook_IsSpellKnownOrInSpellBook(options.spell) then
			if options.requiredTalent and not C_SpellBook_IsSpellKnownOrInSpellBook(options.requiredTalent) then
				return false
			end

			return true, options.spell, options.overrideSpell
		end
	end

	return false
end

local function GetActiveColor(element, state)
	if state.overrideSpell and C_Spell_GetOverrideSpell(state.spell) == state.overrideSpell then
		return element.colorOverride
	end

	return element.colorBase
end

local function UpdateColor(self, event, unit)
	local element = self.TankResource
	local state = STATE[element]
	if not state or not state.enabled then return end

	local color = GetActiveColor(element, state)
	if state.color == color then return end
	state.color = color

	local r, g, b
	if color.GetRGB then
		r, g, b = color:GetRGB()
	else
		r, g, b = color[1], color[2], color[3]
	end

	for i = 1, #element do
		local bar = element[i]
		bar:SetStatusBarColor(r, g, b)

		local bg = bar.bg
		if bg then
			local multiplier = bg.multiplier or 1
			bg:SetVertexColor(r * multiplier, g * multiplier, b * multiplier)
		end
	end

	if element.PostUpdateColor then
		element:PostUpdateColor(color)
	end
end

local function ColorPath(self, ...)
	return (self.TankResource.UpdateColor or UpdateColor)(self, ...)
end

-- 使用 DurationObject 將充能進度交給原生 StatusBar 計算
local function UpdateRechargeBar(element, spell)
	local bar = element.__rechargeBar
	if not bar then return end

	bar:Show()

	local duration = C_Spell_GetSpellChargeDuration(spell)
	local time = element.Time
	if duration then
		bar:SetTimerDuration(duration)
		if time then
			time.binding:SetDuration(duration)
			time.binding:SetEnabled(true)
			time.binding:UpdateFontString()
		end
	else
		bar:SetValue(1)
		if time then
			time.binding:SetEnabled(false)
			time:SetText("")
		end
	end
end

local function Update(self, event, unit)
	local element = self.TankResource
	local state = STATE[element]
	if not state or not state.enabled then return end

	if not unit or unit ~= self.__unit then return end

	if element.PreUpdate then
		element:PreUpdate(unit)
	end

	ColorPath(self, event, unit)

	local chargesInfo = C_Spell_GetSpellCharges(state.spell)
	if not chargesInfo then
		UpdateRechargeBar(element, state.spell)
		return
	end

	-- currentCharges 可能是 secret value，maxCharges 在 12.1 是公開的
	local secretCurrentCharges = chargesInfo.currentCharges
	local maxCharges = chargesInfo.maxCharges
	local oldMax = state.max

	for i = 1, 2 do
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

	local hasMaxChanged = (maxCharges ~= oldMax)
	if hasMaxChanged then
		state.max = maxCharges

		if element.MaxChangeUpdate then
			element:MaxChangeUpdate(maxCharges)
		end
	end

	if element.PostUpdate then
		return element:PostUpdate(maxCharges, hasMaxChanged)
	end
end

-- Override 一律接收標準 event、unit，再附上目前資源法術
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

-- SPELL_UPDATE_* 是 unitless event，不要把其 payload 誤當成 unit
local function SpellUpdatePath(self, event, ...)
	local state = STATE[self.TankResource]
	if not state or not state.enabled then return end

	return Path(self, event, self.__unit, ...)
end

local function Visibility(self, event)
	local element = self.TankResource
	local state = STATE[element]
	if not state then return end

	local shouldEnable, spell, overrideSpell
	if not UnitHasVehicleUI('player') then
		shouldEnable, spell, overrideSpell = GetEnableStateAndSpell()
	end

	local wasEnabled = state.enabled
	if shouldEnable then
		state.spell = spell
		state.overrideSpell = overrideSpell
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

		state.enabled = true

		Path(self, 'TankResourceEnable', self.__unit)
	end

	function TankResourceDisable(self)
		local element = self.TankResource
		local state = STATE[element]
		if not state then return end

		self:UnregisterEvent('SPELL_UPDATE_COOLDOWN', SpellUpdatePath)
		self:UnregisterEvent('SPELL_UPDATE_CHARGES', SpellUpdatePath)

		if element.Time then
			element.Time.binding:SetEnabled(false)
			element.Time:SetText("")
		end

		for i = 1, #element do
			element[i]:Hide()
		end

		state.enabled = false

		Path(self, 'TankResourceDisable', self.__unit)

		state.spell = nil
		state.overrideSpell = nil
		state.color = nil
	end
end

local function Enable(self, unit)
	local element = self.TankResource
	if not element or unit ~= 'player' then return end

	element.__owner = self
	element.__rechargeBar = element.rechargeBar or element[3]
	element.colorBase = element.colorBase or { .95, .72, .28 }
	element.colorOverride = element.colorOverride or { 1, .92, .55 }
	element.ForceUpdate = ForceUpdate

	STATE[element] = {
		enabled = false,
		max = 2,
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

			if i <= 2 then
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
