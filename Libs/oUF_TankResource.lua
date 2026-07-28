--[[
	## 元件 / Widget

	TankResource - A table of `StatusBar`s used to display tank resource charges.
	The first two bars only show available charges; the third bar uses a DurationObject for next-charge recharge progress.

	## 子元件 / Sub-Widgets

	[1], [2] - 充能顯示，直接吃 `currentCharges`，避免 Lua 端運算 secret value。
	[1], [2] - Charge indicators. They receive `currentCharges` directly to avoid Lua-side secret value math.

	[3] / .rechargeBar - 下一層充能進度條，使用 `C_Spell.GetSpellChargeDuration()`。
	[3] / .rechargeBar - Recharge progress bar for the next charge, using `C_Spell.GetSpellChargeDuration()`.

	.bg - 背景材質，跟隨 StatusBar 的顏色並套用 multiplier。
	.bg - Background texture. It inherits StatusBar color with multiplier.

	## Sub-Widget Options

	.multiplier - Background color multiplier. Defaults to 1, range 0-1.

	## Options

	.colors - Class colors.
	.costColor - Whether to use `noPowerCostColor` when the spell lacks resource. Defaults to true.
	.noPowerCostColor - Color used when the spell lacks resource. Defaults to {.9, .1, .1, 1}.
	.overrideSpellOptions - Per-override spell colors, formatted as {[PlayerClass] = {[spellID] = {r, g, b, a}}}

	.chargeBarCount - Number of StatusBars used for charge indicators. Defaults to 2.
	.rechargeBar - StatusBar used to display the next charge recharge progress.
	.MaxChangeUpdate - Called when max charges change

	## Supported Classes
    
	- PALADIN
	- WARRIOR
	- DEMONHUNTER
	- MONK
	- DRUID

	## Example

	local TankResource = {}
	local maxLength = 4
	for index = 1, maxLength do
		local bar = CreateFrame('StatusBar', nil, self)

		bar:SetSize(120 / maxLength, 20)
		bar:SetPoint('TOPLEFT', self, 'BOTTOMLEFT', (index - 1) * bar:GetWidth(), 0)

		TankResource[index] = bar
	end

	-- Register with oUF.
	self.TankResource = TankResource

	## Notes

	- Custom colors:
	TankResource.colors = { ["PALADIN"] = {.95, .72, .28} }
	TankResource.noPowerCostColor = {.9, .1, .1, 1}

	- When max charges change, override MaxChangeUpdate to adjust size or position:
	TankResource.MaxChangeUpdate = function(self, maxCharge)
		for i = 1, maxCharge do
			local bar = self[i]

			bar:SetSize(120 / maxCharge, 20)
			bar:SetPoint('TOPLEFT', self, 'BOTTOMLEFT', (i - 1) * bar:GetWidth(), 0)
		end
	end
]] --

----------------------
-- 原始作者：HopeASD --
----------------------

local addon, ns = ...
local C, F, G, T = unpack(ns)
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

-------------
-- 啟用判斷 --
-------------

local TankResourceEnable, TankResourceDisable
-- 目前啟用狀態：{enable, spell, spec, overrideSpellOptions}
local enableState = {}

--[[
	enableClassAndSpec:
		[classFileName] = {specIndex, spellID, requiredTalentSpellID}

	classFileName - UnitClass("player") 的第二回傳值。
	specIndex - C_SpecializationInfo.GetSpecialization() 的回傳值。
	spellID - 需要存在於玩家法術書中的坦克資源技能。
	requiredTalentSpellID - 可選，需要存在於玩家法術書中的天賦技能。
]]
local enableClassAndSpec = {
    ['MONK'] = { SPEC_MONK_BREWMASTER, 119582 },
    ['PALADIN'] = { SPEC_PALADIN_PROTECTION, 432459, 432459 }, -- 光鑄者
    ['DEMONHUNTER'] = { SPEC_DEMONHUNTER_VENGEANCE, 203720, 1266307 }, -- 惡魔韌性
    ['WARRIOR'] = { SPEC_WARRIOR_PROTECTION, 2565 },
    ['DRUID'] = { SPEC_DRUID_GUARDIAN, 22842, 377811 } -- 固有決心
}

-- 判斷目前的職業專精是否需要啟用模組，以及對應的坦克法術
local function GetEnableStateAndSpell()
    if enableClassAndSpec[PlayerClass] then
        local spec, spell, requiredTalentSpell = unpack(enableClassAndSpec[PlayerClass])
        if spec == C_SpecializationInfo_GetSpecialization() and C_SpellBook_IsSpellKnownOrInSpellBook(spell) then
            if requiredTalentSpell and not C_SpellBook_IsSpellKnownOrInSpellBook(requiredTalentSpell) then
                return false, nil
            end
            return true, spell
        end
    end
    return false, nil
end

-- 給 API.lua 計算資源布局用；只回傳 boolean，不外洩 spell。
T.PlayerHasTankResource = function()
    return (GetEnableStateAndSpell())
end

-----------------
-- 獲取法術狀態 --
-----------------

-- 獲取充能資料：currentCharges 是 secret value，只能直接交給支援的 widget
local function GetResourceChargesInfo(element, spell)
    local chargesInfo = C_Spell_GetSpellCharges(spell)
    local maxCharges = element.__max or element.__chargeBarCount or #element

    if chargesInfo then
        return chargesInfo, chargesInfo.maxCharges or maxCharges
    end

    return nil, maxCharges
end

-- 套用顏色，支援 RGB table 與 oUF ColorMixin
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
        local mu = bg.multiplier or 1
        bg:SetVertexColor(r * mu, g * mu, b * mu)
    end
end

local function GetActiveColor(element)
    local color = (element.colors and element.colors[PlayerClass]) or DEFAULT_COLOR

    if enableState.overrideSpellOptions then
        local overrideSpell = C_Spell_GetOverrideSpell(enableState.spell) or enableState.spell
        local overrideSpellColor = enableState.overrideSpellOptions[overrideSpell]
        if overrideSpellColor then
            color = overrideSpellColor
        end
    end

    return color
end

-- 更新充能進度條，就是技能CD
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

local function UpdateColor(element)
    local color = GetActiveColor(element)

    for i = 1, #element do
        SetBarColor(element[i], color)
    end
end

local UsableUpdateEvents = {
    ["PLAYER_TARGET_CHANGED"] = true,
    ["UNIT_POWER_FREQUENT"] = true,
}

local function UpdateUsableColor(element)
    if not enableState.enable then return end
    if not element.costColor then return end
    local costColor = element.noPowerCostColor
    local color = GetActiveColor(element)

    local usable, noMana = C_Spell_IsSpellUsable(enableState.spell)

    if (not usable) and noMana then
        for i = 1, #element do
            SetBarColor(element[i], costColor)
        end
    elseif usable then
        for i = 1, #element do
            SetBarColor(element[i], color)
        end
    end
end

----------
-- 更新 --
----------

local function Update(self, event, unit)
    if not enableState.enable then return end

    -- 預留 PreUpdate
    local element = self.TankResource
    if element.PreUpdate then element:PreUpdate(event) end
    if UsableUpdateEvents[event] then
        return UpdateUsableColor(element)
    elseif (unit and unit ~= self.unit) then
        UpdateUsableColor(element)
    else
        (element.UpdateColor or UpdateColor)(element)
    end

    local chargesInfo, maxCharges, oldMax

    chargesInfo, maxCharges = GetResourceChargesInfo(element, enableState.spell)
    if not chargesInfo then
        UpdateRechargeBar(element, enableState.spell)
        return
    end

    local secretCurrentCharges = chargesInfo.currentCharges
    local chargeBarCount = element.__chargeBarCount or maxCharges
    for i = 1, chargeBarCount do
        local bar = element[i]

        if i <= maxCharges then
            bar:SetValue(secretCurrentCharges)

            if not bar:IsShown() and element.init then
                bar:Show()
            end
        else
            bar:Hide()
            bar:SetValue(0)
        end
    end
    UpdateRechargeBar(element, enableState.spell)
    oldMax = element.__max

    if element.init then
        if maxCharges + 1 >= oldMax then
            for i = maxCharges + 1, oldMax do
                element[i]:Hide()
                element[i]:SetValue(0)
            end
        end
        element.init = false
    end

    if (maxCharges ~= oldMax) then
        if (maxCharges < oldMax) then
            for i = maxCharges + 1, oldMax do
                element[i]:Hide()
                element[i]:SetValue(0)
            end
        else
            for i = oldMax, maxCharges do
                if i <= chargeBarCount then element[i]:Show() end
            end
        end
        -- 預留最大充能數變化
        if element.MaxChangeUpdate then
            element:MaxChangeUpdate(maxCharges)
        end
        element.__max = maxCharges
    end

    -- 預留 PostUpdate
    if element.PostUpdate then
        return element:PostUpdate(maxCharges, oldMax ~= maxCharges)
    end
end

-- 更新轉接：預留 Override/OverrideEnableEvent/OverrideDisableEvent
local function Path(self, event, ...)
    if event == "TankResourceEnable" then
        if self.TankResource.OverrideEnableEvent then
            self.TankResource.OverrideEnableEvent(self, ...)
        end
    elseif event == "TankResourceDisable" then
        if self.TankResource.OverrideDisableEvent then
            self.TankResource.OverrideDisableEvent(self, ...)
        end
        enableState = {}
        return
    end

    return (self.TankResource.Override or Update)(self, event, ...)
end

-- 判斷是否顯示
local function Visibility(self, event, unit)
    local element = self.TankResource
    local shouleEnable = false

    -- 有載具時不顯示
    if UnitHasVehicleUI('player') then
        unit = 'vehicle'
        shouleEnable = false
    else
        local enable, spell = GetEnableStateAndSpell()
        if enable and spell then
            shouleEnable = enable
            unit = 'player'
            if not enableState.spec or enableState.spec ~= C_SpecializationInfo_GetSpecialization() then
                enableState.spell = spell
                enableState.spec = C_SpecializationInfo_GetSpecialization()
            end
            local overrideSpellOptions = element.overrideSpellOptions
            if overrideSpellOptions and overrideSpellOptions[PlayerClass] then
                enableState.overrideSpellOptions = overrideSpellOptions[PlayerClass]
            end
        end
    end
    local isEnabled = element.isEnabled
    local spell = enableState.spell

    -- 啟用時先更新顏色
    if shouleEnable then (element.UpdateColor or UpdateColor)(element) end

    if shouleEnable and not isEnabled then
        TankResourceEnable(self)
    elseif not shouleEnable and (isEnabled or isEnabled == nil) then
        TankResourceDisable(self)
    elseif shouleEnable and isEnabled then
        Path(self, event, spell, unit)
    end
end

-- 顯示判斷的轉接方法：預留 OverrideVisibility
local function VisibilityPath(self, ...)
    return (self.TankResource.OverrideVisibility or Visibility)(self, ...)
end

-- 預留 API：Visibility 被覆寫時仍可呼叫 ForceUpdate
local function ForceUpdate(element)
    return VisibilityPath(element.__owner, 'ForceUpdate')
end

do
    function TankResourceEnable(self)
        self:RegisterEvent('SPELL_UPDATE_COOLDOWN', Path, true)
        self:RegisterEvent('PLAYER_TALENT_UPDATE', Path, true)
        self:RegisterEvent('SPELL_UPDATE_CHARGES', Path, true)
        if self.TankResource.costColor then
            for k in pairs(UsableUpdateEvents) do
                if  not self:IsEventRegistered(k) then
                    self:RegisterEvent(k, Path, true)
                end
            end
        end
        self.TankResource.isEnabled = true
        self.TankResource.init = true
        enableState.enable = true

        -- 初始化
        Path(self, 'TankResourceEnable', enableState.spell)
    end

    function TankResourceDisable(self)
        self:UnregisterEvent('SPELL_UPDATE_COOLDOWN', Path)
        self:UnregisterEvent('PLAYER_TALENT_UPDATE', Path)
        self:UnregisterEvent('SPELL_UPDATE_CHARGES', Path)
        if self.TankResource.costColor then
            for k in pairs(UsableUpdateEvents) do
                self:UnregisterEvent(k, Path)
            end
        end

        -- 隱藏
        local element = self.TankResource
        for i = 1, #element do element[i]:Hide() end

        self.TankResource.isEnabled = false
        enableState.enable = false

        -- 關閉模組
        Path(self, 'TankResourceDisable', enableState.spell)
    end
end

-- 模組啟用
local function Enable(self, unit)
    -- 只處理玩家自身
    if unit ~= "player" then return end

    local element = self.TankResource

    -- 初始化
    if element then
        element.__owner = self
        element.__chargeBarCount = element.chargeBarCount or element.__chargeBarCount or (#element - 1)
        element.__rechargeBar = element.rechargeBar or element[element.__chargeBarCount + 1]
        element.__max = element.__chargeBarCount
        element.noPowerCostColor = element.noPowerCostColor or { .9, .1, .1, 1 }
        if element.costColor == nil then element.costColor = true end
        element.ForceUpdate = ForceUpdate

        self:RegisterEvent('PLAYER_TALENT_UPDATE', VisibilityPath, true)
        self:RegisterEvent('SPELLS_CHANGED', VisibilityPath, true)
        self:RegisterEvent('PLAYER_SPECIALIZATION_CHANGED', VisibilityPath)
        self:RegisterEvent('PLAYER_ENTERING_WORLD', VisibilityPath)
        --self:RegisterEvent('TRAIT_SUB_TREE_CHANGED', VisibilityPath, true)

        element.TankResourceEnable = TankResourceEnable
        element.TankResourceDisable = TankResourceDisable

        -- 設定預設材質和每個分段的取值範圍
        for i = 1, #element do
            local bar = element[i]
            if (bar:IsObjectType('StatusBar')) then
                if (not bar:GetStatusBarTexture()) then
                    bar:SetStatusBarTexture(
                        [[Interface\TargetingFrame\UI-StatusBar]])
                end

                if i <= element.__chargeBarCount then
                    bar:SetMinMaxValues(i - 1, i)
                else
                    bar:SetMinMaxValues(0, 1)
                end
            end
        end

        return true
    end
end

local function Disable(self)
    if self.TankResource then
        TankResourceDisable(self)

        self:UnregisterEvent('PLAYER_TALENT_UPDATE', VisibilityPath)
        self:UnregisterEvent('SPELLS_CHANGED', VisibilityPath)
        self:UnregisterEvent('PLAYER_SPECIALIZATION_CHANGED', VisibilityPath)
        self:UnregisterEvent('PLAYER_ENTERING_WORLD', VisibilityPath)
        --self:UnregisterEvent('TRAIT_SUB_TREE_CHANGED', VisibilityPath)
    end
end

oUF:AddElement('TankResource', VisibilityPath, Enable, Disable)
