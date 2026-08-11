--[[
# Element: Evoker Essence

Try layout as same as classpower/rune.

## Sub-Widgets

.bg - A `Texture` used as a background. It will inherit the color of the main StatusBar.

## Options

.color
.updateInterval - number, seconds between Charging_OnUpdate ticks (default 0.05)
.PostUpdate(self, cur, max) - callback after every refresh, If you want more custom
.PostVisibility(self, isVisible) - callback after vehicle visibility changes

## Sub-Widget Options

.multiplier - Used to tint the background based on the main widgets R, G and B values. Defaults to 1 (number)[0-1]

## Examples

    if select(2, UnitClass('player')) == 'EVOKER' then
        local Essence = {}
        for i = 1, 5 do                                  -- build the bars
            local bar = CreateFrame('StatusBar', nil, self)
            bar:SetSize(16, 16)
            bar:SetPoint(i == 1 and 'LEFT' or 'RIGHT',
                i == 1 and self or Essence[i-1], i == 1 and nil or 'RIGHT', 2, 0)
            
                Essence[i] = bar
        end

        -- Register with oUF
        self.Essence = Essence   
    end
---]]

local _, ns  = ...
local oUF    = ns.oUF or oUF
local UnitPower, UnitPowerMax, UnitPartialPower = UnitPower, UnitPowerMax, UnitPartialPower
local UnitHasVehicleUI = UnitHasVehicleUI
local PTYPE  = Enum.PowerType.Essence
local STATE = {}
local EssenceEnable, EssenceDisable

local function Charging_OnUpdate(bar, elapsed)
    local interval = bar.updateInterval or 0.05
    bar.t = (bar.t or 0) + elapsed
    if bar.t < interval then return end
    bar.t = 0

    local pct = (UnitPartialPower('player', PTYPE) or 0) / 1000
    bar:SetValue(pct)
end

local function Update(self, _, unit, ptype)
    local element = self.Essence
    local state = STATE[element]
    if not state or not state.enabled then return end
    if unit ~= 'player' or self.__unit ~= unit or (ptype and ptype ~= 'ESSENCE') then return end

    local cur     = UnitPower('player', PTYPE) or 0
    local max     = UnitPowerMax('player', PTYPE) or 0
    local created = #element

    -- 龍能基礎 5 顆，天賦可提高到 6 顆；API 未就緒時退回已建立數量。
    max = (max > 0 and max <= created) and max or created

    if element.__max ~= max then
        element.__max = max

        if element.MaxChangeUpdate then
            element:MaxChangeUpdate(max)
        end
    end

    for i = 1, created do
        local bar = element[i]
        if not bar then break end

        if i > max then
            bar:Hide()
            bar:SetValue(0)
            bar:SetScript('OnUpdate', nil)
        elseif i <= cur then
            bar:Show()
            bar:SetValue(1)
            bar:SetScript('OnUpdate', nil)
        elseif i == cur + 1 then
            bar:Show()
            bar:SetScript('OnUpdate', Charging_OnUpdate)
            Charging_OnUpdate(bar, 0)
        else
            bar:Show()
            bar:SetValue(0)
            bar:SetScript('OnUpdate', nil)
        end

        local r, g, b = bar:GetStatusBarColor()
        if bar.bg then
            local mu = bar.bg.multiplier or .3
            bar.bg:SetVertexColor(r * mu, g * mu, b * mu)
        end
    end

    if element.PostUpdate then
        element:PostUpdate(cur, max)
    end
end

local function Path(self, ...)
    return (self.Essence.Override or Update)(self, ...)
end

local function Visibility(self, event)
    local element = self.Essence
    local state = STATE[element]
    if not state then return end

    -- Essence 只顯示玩家自身資源；進入載具時依 oUF 職業資源慣例停用。
    local shouldEnable = self.__unit == 'player' and not UnitHasVehicleUI('player')
    if shouldEnable ~= state.enabled then
        if shouldEnable then
            EssenceEnable(self)
        else
            EssenceDisable(self)
        end

        if element.PostVisibility then
            element:PostVisibility(shouldEnable)
        end
    elseif shouldEnable then
        Path(self, event, 'player', 'ESSENCE')
    end
end

local function VisibilityPath(self, ...)
    return (self.Essence.OverrideVisibility or Visibility)(self, ...)
end

local function ForceUpdate(element)
    return VisibilityPath(element.__owner, 'ForceUpdate', element.__owner.__unit)
end

do
    function EssenceEnable(self)
        local element = self.Essence
        local state = STATE[element]
        if not state then return end

        self:RegisterEvent('UNIT_POWER_FREQUENT', Path)
        self:RegisterEvent('UNIT_MAXPOWER', Path)
        state.enabled = true

        Path(self, 'EssenceEnable', 'player', 'ESSENCE')
    end

    function EssenceDisable(self)
        local element = self.Essence
        local state = STATE[element]
        if not state then return end

        self:UnregisterEvent('UNIT_POWER_FREQUENT', Path)
        self:UnregisterEvent('UNIT_MAXPOWER', Path)

        for i = 1, #element do
            local bar = element[i]
            bar:SetScript('OnUpdate', nil)
            bar.t = nil
            bar:Hide()
        end

        element.__max = nil
        state.enabled = false
    end
end

local function Enable(self, unit)
    local element = self.Essence
    if not element or unit ~= 'player' then return end

    local interval = element.updateInterval or 0.05
    local color = element.color or {0.1, 0.8, 1}
    local r, g, b = color[1], color[2], color[3]

    -- bar int
    for i = 1, #element do
        local bar = element[i]
        if not bar:GetStatusBarTexture() then
            bar:SetStatusBarTexture([[Interface\TargetingFrame\UI-StatusBar]])
        end
        bar:SetMinMaxValues(0, 1)
        bar:SetStatusBarColor(unpack(color))

        bar.updateInterval = interval

        local bg= bar.bg
        if(bg) then
            local mu = bg.multiplier or 1
            bg:SetVertexColor(r * mu, g * mu, b * mu)
        end
    end

    element.__owner = self
    element.ForceUpdate = ForceUpdate
    STATE[element] = {}
    return true
end

local function Disable(self)
    local element = self.Essence
    if element then
        EssenceDisable(self)
        STATE[element] = nil
    end
end

oUF:AddElement('Essence', VisibilityPath, Enable, Disable)
