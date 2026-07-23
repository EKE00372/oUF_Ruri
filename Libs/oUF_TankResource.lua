--[[
	## 元件 / Widget
	TankResource - 一組 `StatusBar`，用來顯示坦克職業的資源充能。
	TankResource - A table of `StatusBar`s used to display tank resource charges.

	## 子元件 / Sub-Widgets
	.bg - 背景材質，跟隨 StatusBar 的顏色並套用 multiplier。
	.bg - Background texture. It inherits StatusBar color with multiplier.

	## 子元件選項 / Sub-Widget Options
	.multiplier - 背景顏色乘數，預設 1，範圍 0-1。
	.multiplier - Background color multiplier. Defaults to 1, range 0-1.

	## 選項 / Options
	.colors - 職業顏色 。
	.colors - Class colors.

	.costColor - 資源不足時是否改用 noPowerCostColor，預設 true。
	.costColor - Whether to use noPowerCostColor when the spell lacks resource. Defaults to true.

	.noPowerCostColor - 資源不足顏色，預設 {.9, .1, .1, 1}。
	.noPowerCostColor - Color used when the spell lacks resource. Defaults to {.9, .1, .1, 1}.

	.overrideSpellOptions - 依 spell override 套用顏色，格式為 {[PlayerClass] = {[spellID] = {r, g, b, a}}}
	.overrideSpellOptions - Per-override spell colors, formatted as {[PlayerClass] = {[spellID] = {r, g, b, a}}}

	.MaxChangeUpdate - 最大充能數改變時呼叫更新
	.MaxChangeUpdate - Called when max charges change

	## 支援職業 / Supported Classes
	- PALADIN
	- WARRIOR
	- DEMONHUNTER
	- MONK
	- DRUID
	- DEATHKNIGHT

	## 範例 / Example
	local TankResource = {}
	local maxLength = 4
	for index = 1, maxLength do
		local bar = CreateFrame('StatusBar', nil, self)

		-- 位置與尺寸。/ Position and size.
		bar:SetSize(120 / maxLength, 20)
		bar:SetPoint('TOPLEFT', self, 'BOTTOMLEFT', (index - 1) * bar:GetWidth(), 0)

		TankResource[index] = bar
	end

	-- 註冊到 oUF。/ Register with oUF.
	self.TankResource = TankResource

	## 備註 / Notes
	自訂顏色：/ Custom colors:
	TankResource.colors = {
		["WARRIOR"] = {.2, .5, .7},
		["PALADIN"] = {1, 1, 0},
		["DEMONHUNTER"] = {.7, .6, .4},
		["MONK"] = {.7, .6, .4},
	}
	TankResource.noPowerCostColor = {.9, .1, .1, 1}

	最大充能數改變時，可覆寫 MaxChangeUpdate 來調整尺寸或位置：
	When max charges change, override MaxChangeUpdate to adjust size or position:
	TankResource.MaxChangeUpdate = function(self, maxCharge)
		for i = 1, maxCharge do
			local bar = self[i]

			bar:SetSize(120 / maxCharge, 20)
			bar:SetPoint('TOPLEFT', self, 'BOTTOMLEFT', (i - 1) * bar:GetWidth(), 0)
		end
	end

	secret value 時無法顯示充能進度。
]] --

----------------------
-- 原始作者：HopeASD --
----------------------

local addon, ns = ...
local C, F, G, T = unpack(ns)
local oUF = ns.oUF or oUF

if not C.TankResource then return end

local _, PlayerClass = UnitClass('player')
local SPEC_MONK_BREWMASTER = SPEC_MONK_BREWMASTER or 1
local SPEC_DEATHKNIGHT_BLOOD = SPEC_DEATHKNIGHT_BLOOD or 1
local SPEC_DEMONHUNTER_VENGEANCE = SPEC_DEMONHUNTER_VENGEANCE or 2
local SPEC_WARRIOR_PROTECTION = SPEC_WARRIOR_PROTECTION or 3
local SPEC_PALADIN_PROTECTION = SPEC_PALADIN_PROTECTION or 2
local SPEC_DRUID_GUARDIAN = SPEC_DRUID_GUARDIAN or 3

local UnitHasVehicleUI = UnitHasVehicleUI
local C_Spell_GetSpellCharges = C_Spell.GetSpellCharges
local C_Spell_GetSpellCastCount = C_Spell.GetSpellCastCount
local C_Spell_GetOverrideSpell = C_Spell.GetOverrideSpell
local C_Spell_IsSpellUsable = C_Spell.IsSpellUsable
local C_SpellBook_IsSpellKnownOrInSpellBook = C_SpellBook.IsSpellKnownOrInSpellBook
local C_SpecializationInfo_GetSpecialization = C_SpecializationInfo.GetSpecialization

-------------
-- 啟用判斷 --
-------------

local TankResourceEnable, TankResourceDisable
-- 目前啟用狀態：{enable, spell, spec, overrideSpellOptions}
local enableState = {}

--[[
	enableClassAndSpec:
		[classFileName] = {specIndex, spellID}

	classFileName - UnitClass("player") 的第二回傳值。
	specIndex - C_SpecializationInfo.GetSpecialization() 的回傳值。
	spellID - 需要存在於玩家法術書中的坦克資源技能。
]]
local enableClassAndSpec = {
    ['MONK'] = { SPEC_MONK_BREWMASTER, 119582 },
    ['PALADIN'] = { SPEC_PALADIN_PROTECTION, 432459 },
    ['DEMONHUNTER'] = { SPEC_DEMONHUNTER_VENGEANCE, 203720 },
    ['WARRIOR'] = { SPEC_WARRIOR_PROTECTION, 2565 },
    ['DRUID'] = { SPEC_DRUID_GUARDIAN, 22842 },
    ['DEATHKNIGHT'] = { SPEC_DEATHKNIGHT_BLOOD, 194679 }
}

-- 判斷目前的職業專精是否需要啟用模組，以及對應的坦克法術
local function GetEnableStateAndSpell()
    if enableClassAndSpec[PlayerClass] then
        local spec, spell = unpack(enableClassAndSpec[PlayerClass])
        if spec == C_SpecializationInfo_GetSpecialization() and C_SpellBook_IsSpellKnownOrInSpellBook(spell) then
            return true, spell
        end
    end
    return false, nil
end

-----------------
-- 獲取法術狀態 --
-----------------

-- 獲取目前充能數： currentCharges 為密秘值時不可運算
local function GetResourceCooldown(element, spell)
    local chargesInfo = C_Spell_GetSpellCharges(spell)
    local maxCharges = element.__max or #element

    if chargesInfo then
        return chargesInfo.currentCharges, maxCharges
    end

    return C_Spell_GetSpellCastCount(spell), maxCharges
end

local function GetOverrideSpell(spell)
    return C_Spell_GetOverrideSpell(spell) or spell
end

-- 套用顏色
local function SetBarColor(bar, r, g, b)
    bar:SetStatusBarColor(r, g, b)

    local bg = bar.bg
    if bg then
        local mu = bg.multiplier or 1
        bg:SetVertexColor(r * mu, g * mu, b * mu)
    end
end

local function SetBarValue(bar, value)
    bar:SetValue(value)
end

local function UpdateColor(element)
    local spec = enableState.enable and enableState.spec or 0
    local color = element.__owner.colors.power[4]

    if (spec ~= 0 and element.colors and element.colors[PlayerClass]) then
        color = element.colors[PlayerClass]
    end

    if enableState.overrideSpellOptions then
        local overrideSpell = GetOverrideSpell(enableState.spell)
        local overrideSpellOptions = enableState.overrideSpellOptions
        local overrideSpellColor = overrideSpellOptions[overrideSpell]
        if overrideSpellColor then
            color = overrideSpellColor

        end
    end

    local r, g, b = color[1], color[2], color[3]

    for i = 1, #element do
        SetBarColor(element[i], r, g, b)
    end
end

local UsableUpdateEvents = {
    ["PLAYER_TARGET_CHANGED"] = true,
    ["UNIT_POWER_FREQUENT"] = true,
}

local function UpdateUsableColor(element)
    if not enableState.enable then return end
    if not element.costColor then return end
    local spec = enableState.spec or 0
    local costColor = element.noPowerCostColor
    local color = element.__owner.colors.power[4]
    if (spec ~= 0 and element.colors and element.colors[PlayerClass]) then
        color = element.colors[PlayerClass]
    end

    if enableState.overrideSpellOptions then
        local overrideSpell = GetOverrideSpell(enableState.spell)
        local overrideSpellOptions = enableState.overrideSpellOptions
        local overrideSpellColor = overrideSpellOptions[overrideSpell]
        if overrideSpellColor then
            color = overrideSpellColor

        end
    end

    local usable, noMana = C_Spell_IsSpellUsable(enableState.spell)

    local r, g, b = costColor[1], costColor[2], costColor[3]

    if (not usable) and noMana then
        for i = 1, #element do
            SetBarColor(element[i], r, g, b)
        end
    elseif usable then
        r, g, b = color[1], color[2], color[3]

        for i = 1, #element do
            SetBarColor(element[i], r, g, b)
        end
    end
end

----------
-- 更新 --
----------

-- 更新坦克資源顯示。
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

    local cur, maxCharges, oldMax

    cur, maxCharges = GetResourceCooldown(element, enableState.spell)
    for i = 1, maxCharges do
        SetBarValue(element[i], cur)

        if not element[i]:IsShown() and element.init then
            element[i]:Show()
        end
    end
    oldMax = element.__max

    if element.init then
        if maxCharges + 1 >= oldMax then
            for i = maxCharges + 1, oldMax do
                element[i]:Hide()
                SetBarValue(element[i], 0)
            end
        end
        element.init = false
    end

    if (maxCharges ~= oldMax) then
        if (maxCharges < oldMax) then
            for i = maxCharges + 1, oldMax do
                element[i]:Hide()
                SetBarValue(element[i], 0)
            end
        else
            for i = oldMax, maxCharges do element[i]:Show() end
        end
        -- 預留最大充能數變化
        if element.MaxChangeUpdate then
            element:MaxChangeUpdate(maxCharges)
        end
        element.__max = maxCharges
    end
    -- 預留 PostUpdate
    if element.PostUpdate then
        return element:PostUpdate(cur, maxCharges, oldMax ~= maxCharges)
    end
end

local function EnableEvent(self, spell) end

local function DisableEvent(self) enableState = {} end

-- 真正更新的轉接方法：預留 Override/OverrideEnableEvent/OverrideDisableEvent
local function Path(self, event, ...)
    if event == "TankResourceEnable" then
        (self.TankResource.OverrideEnableEvent or EnableEvent)(self, ...)
    elseif event == "TankResourceDisable" then
        return (self.TankResource.OverrideDisableEvent or DisableEvent)(self, ...)
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
        element.__max = #element
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

                bar:SetMinMaxValues(i - 1, i)
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
