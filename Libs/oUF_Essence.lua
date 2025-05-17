--[[
# Element: Evoker Essence

Try layout as same as classpower/rune.

## Sub-Widgets

.bg - A `Texture` used as a background. It will inherit the color of the main StatusBar.

## Options

.color
.spacing - respacing
.updateInterval - number, seconds between Charging_OnUpdate ticks (default 0.05)
.PostUpdate(self, cur, max) - callback after every refresh, If you want more custom

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
local UnitPartialPower = UnitPartialPower
local PTYPE  = Enum.PowerType.Essence

local function Charging_OnUpdate(bar, elapsed)
    local interval = bar.updateInterval or 0.05
    bar.t = (bar.t or 0) + elapsed
    if bar.t < interval then return end
    bar.t = 0

    local pct = (UnitPartialPower('player', PTYPE) or 0) / 1000
    bar:SetValue(pct)
end

local function Update(self, _, unit, ptype)
    if self.unit ~= unit or (ptype and ptype ~= 'ESSENCE') then return end

    local element = self.Essence
    local cur     = UnitPower(unit, PTYPE)
    local max     = #element

    for i = 1, max do
        local bar = element[i]
        if not bar then break end
        if i <= cur then
            bar:SetValue(1)
            bar:SetScript('OnUpdate', nil)
        elseif i == cur + 1 then
            bar:SetScript('OnUpdate', Charging_OnUpdate)
            Charging_OnUpdate(bar, 0)
        else
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

-- ------------------------------------------------------------------- --
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

    self:RegisterEvent('UNIT_POWER_FREQUENT', Path)
    self:RegisterEvent('UNIT_MAXPOWER',       Path)

    element.__owner     = self
    element.ForceUpdate = function()
        return Path(self, 'ForceUpdate', self.unit, 'ESSENCE')
    end
    return true
end

local function Disable(self)
    if self.Essence then
        self:UnregisterEvent('UNIT_POWER_FREQUENT', Path)
        self:UnregisterEvent('UNIT_MAXPOWER',       Path)
        for i = 1, #self.Essence do
            self.Essence[i]:SetScript('OnUpdate', nil)
        end
    end
end

oUF:AddElement('Essence', Path, Enable, Disable)
