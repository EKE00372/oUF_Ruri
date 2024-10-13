--[[
	## Widget
	TankResource - An `table` holding `StatusBar`s.
	
	## Sub-Widgets
	.bg - A `Texture` used as a background. It will inherit the color of the main StatusBar.
	
	## Sub-Widget Options
	.multiplier - Used to tint the background based on the widget's R, G and B values. Defaults to 1 (number)[0-1]
	
	## Options
	.colors the RGB values for the widget.
	.updateDealy the delay for the bar update values. Defaults to .1 (number)[0-1]
    .costColor the resource noPowerCostColor flag Defaults to true (boolean)
    .noPowerCostColor the RGB values for noPowerCost Defaults to {.9,.1,.1}
    .overrideSpellOptions the overrideSpellOptions, Defaults to {[PlayerClass] = {[spell] = {colorR,colorG,colorB,colorA}}}
	## Support Class
	- PALDAIN
	- WARRIOR
	- DEMON HUNTER
	- MONK

	## Examples
	local TankResource = {}
	local maxLength = 4
	for index = 1, maxLength do
		local bar = CreateFrame('StatusBar', nil, self)

		-- Position and size.
		bar:SetSize(120 / maxLength, 20)
		bar:SetPoint('TOPLEFT', self, 'BOTTOMLEFT', (index - 1) * Bar:GetWidth(), 0)

		TankResource[index] = bar
	end

	-- Register with oUF
	self.TankResource = TankResource

	## Notes
	####if you use custom color bar then

	-- SetCustomColor
	TankResource.colors = {
		["WARRIOR"] = {.2,.5,.7},
		["PALDAIN"] = {.6,.4,.5},
		["DEMONHUNTER"] = {.7,.6,.4},
		["MONK"] = {.7,.6,.4},
	}
    TankResouce.noPowerCostColor = {
        .9,
        .1,
        .1,
    }

	#### if resourceStack is changed  you can override MaxChangeUpdate function to changed size.
	TankResource.MaxChangeUpdate = function(self,maxCharge)
		for i = 1, maxCharge do
			local bar = self[i]
			
			bar:SetSize(120/maxCharge,20)
			bar:SetPoint('TOPLEFT', self, 'BOTTOMLEFT', (i - 1) * Bar:GetWidth(), 0)
		end
	end
]] --
-----------------------------
-- all credits to HopeASD. --
-----------------------------
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

local GetSpellCharges, UnitSpellHaste, GetTime, UnitIsUnit, GetSpecialization, UnitHasVehicleUI,
IsPlayerSpell, CreateFrame = GetSpellCharges, UnitSpellHaste, GetTime,
    UnitIsUnit, GetSpecialization, UnitHasVehicleUI, IsPlayerSpell, CreateFrame
local C_Spell_GetSpellCharges = C_Spell.GetSpellCharges
local C_Spell_GetSpellCastCount = C_Spell.GetSpellCastCount
local C_Spell_GetSpellCooldown = C_Spell.GetSpellCooldown


local TankResourceEnable, TankResourceDisable
-- {enable,spell,spec,overrideSpellOptions}
local enableState = {}

--[[
	TODO:
		1 Paladin tankResource
		2 StatusBar update Type(ChargesCooldown,AuraDuration,AuraStacks)
]]
--[[
	[PlayerClassName] = {SPECNUMBER,SPELL,SPECIALSEVENTS,UPDATETYPE}
		PlayerClassName - string
		SPECNUMBER - number
		SPECIALSEVENTS - table(string)
		UPDATETYPE - number
			1. ChargesCooldown
			2. AuraDuration
			3. AuraStacks (like Druid_Guardian 铁鬃)
]]
local enableClassAndSpec = {
    ['MONK'] = { SPEC_MONK_BREWMASTER, 119582 },
    ['PALADIN'] = { SPEC_PALADIN_PROTECTION, 432459 },
    ['DEMONHUNTER'] = { SPEC_DEMONHUNTER_VENGEANCE, 203720 },
    ['WARRIOR'] = { SPEC_WARRIOR_PROTECTION, 2565 },
    ['DRUID'] = { SPEC_DRUID_GUARDIAN, 22842 },
    ['DEATHKNIGHT'] = { SPEC_DEATHKNIGHT_BLOOD, 194679 }
}
--[[
	return 是否能开启模块的状态
]]
local function GetEnableStateAndSpell()
    if enableClassAndSpec[PlayerClass] then
        local spec, spell = unpack(enableClassAndSpec[PlayerClass])
        if spec == GetSpecialization() and IsPlayerSpell(spell) then
            return true, spell
        end
    end
    return false, nil
end

-- 自制的获取时间方法
local function GetResourceCooldown(spell)
    local cooldownInfo = C_Spell_GetSpellCooldown(spell)
    local start, dur, enable = cooldownInfo.startTime, cooldownInfo.duration, cooldownInfo.isEnable

    local chargesInfo = C_Spell_GetSpellCharges(spell)
    local charges, maxCharges, startCharges, durCharges = chargesInfo.currentCharges, chargesInfo.maxCharges,
        chargesInfo.cooldownStartTime, chargesInfo.cooldownDuration

    local stack = charges or C_Spell_GetSpellCastCount(spell)
    local gcd = math.max((1.5 / (1 + (UnitSpellHaste("player") / 100))), 0.75)

    start = start or 0
    dur = dur or 0

    startCharges = startCharges or 0
    durCharges = durCharges or 0

    if enable == 0 then start, dur = 0, 0 end

    local startTime, duration = start, dur

    if charges == maxCharges then
        start, dur = 0, 0
        startCharges, durCharges = 0, 0
    elseif charges > 0 then
        startTime, duration = startCharges, durCharges
    end

    if gcd == duration then startTime, duration = 0, 0 end

    return stack, maxCharges, startTime, duration
end

-- 把Aura API 返回的方法转换成进度比 取值[0,100]
local function GetProgress(startTime, duration)
    if startTime == 0 and duration == 0 then return 100 end
    local nowTime = GetTime()   -- nowTime
    local startTime = startTime -- startTime

    local progress = (nowTime - startTime) / (duration)

    return progress * 100
end

local function IsOverrideSpell(spell)
    local overrideSpell = C_Spell.GetOverrideSpell(spell)
    return overrideSpell == spell, overrideSpell
end


-- 颜色更改
-- 需要在element.colors中声明
-- 返回能量的颜色
local function UpdateColor(element)
    local spec = enableState.enable and enableState.spec or 0
    local color = element.__owner.colors.power[4]

    if (spec ~= 0 and element.colors) then
        color = element.colors[PlayerClass]
    end

    if enableState.overrideSpellOptions then
        local _, overrideSpell = IsOverrideSpell(enableState.spell)
        local overrideSpellOptions = enableState.overrideSpellOptions
        local overrideSpellColor = overrideSpellOptions[overrideSpell]
        if overrideSpellColor then
            color = overrideSpellColor

        end
    end

    local r, g, b = color[1], color[2], color[3]

    for i = 1, #element do
        local bar = element[i]
        bar:SetStatusBarColor(r, g, b)

        local bg = bar.bg
        if bg then
            local mu = bg.multiplier or 1
            bg:SetVertexColor(r * mu, g * mu, b * mu)
        end
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
    if (spec ~= 0 and element.colors) then
        color = element.colors[PlayerClass]
    end

    if enableState.overrideSpellOptions then
        local _, overrideSpell = IsOverrideSpell(enableState.spell)
        local overrideSpellOptions = enableState.overrideSpellOptions
        local overrideSpellColor = overrideSpellOptions[overrideSpell]
        if overrideSpellColor then
            color = overrideSpellColor

        end
    end

    local usable, noMana = C_Spell.IsSpellUsable(enableState.spell)

    local r, g, b = costColor[1], costColor[2], costColor[3]

    if (not usable) and noMana then
        for i = 1, #element do
            local bar = element[i]
            bar:SetStatusBarColor(r, g, b)
        end
    elseif usable then
        r, g, b = color[1], color[2], color[3]

        for i = 1, #element do
            local bar = element[i]
            bar:SetStatusBarColor(r, g, b)
        end
    end
end


-- 更新计时条的进度
-- 仅在需要更新时进行
local function onUpdate(self, elapsed)
    if not enableState.enable then return end
    local element = self.__owner.TankResource

    -- self.elapsed = (self.elapsed or 0) + elapsed

    -- if self.elapsed > element.updateDelay then
    local cur, maxCharges, start, duration

    if element.CooldownUpdate then
        cur, maxCharges, start, duration =
            GetResourceCooldown(enableState.spell)

        if cur == maxCharges then element.CooldownUpdate = false end

        for i = maxCharges, 1, -1 do
            if element[i].needUpdate then
                if cur + 1 == i then
                    element[i]:SetValue(GetProgress(start, duration))
                end
            end
        end
    end
    -- end
end

-- 更新
local function Update(self, event, unit)
    if (unit and unit ~= self.unit) then return end
    if not enableState.enable then return end

    -- 预留 PreUpdate
    local element = self.TankResource
    if element.PreUpdate then element:PreUpdate(event) end
    if UsableUpdateEvents[event] then return UpdateUsableColor(element) else UpdateUsableColor(element) end

    local cur, maxCharges, oldMax, start, duration

    cur, maxCharges, start, duration = GetResourceCooldown(enableState.spell)
    for i = 1, maxCharges do
        if cur + 1 == i then
            element[i].needUpdate = true
        elseif cur < i then
            element[i]:SetValue(0)
            element[i].needUpdate = false
        else
            element[i]:SetValue(100)
        end
        if not element[i]:IsShown() and element.init then
            element[i]:Show()
        end
    end
    if cur ~= maxCharges then element.CooldownUpdate = true end

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
            for i = oldMax, maxCharges do element[i]:Show() end
        end
        -- 预留最大层数变化接口
        if element.MaxChangeUpdate then
            element:MaxChangeUpdate(maxCharges)
        end
        element.__max = maxCharges
    end
    -- 预留 PostUpdate
    if element.PostUpdate then
        -- return element:PostUpdate(cur, maxCharges, start, duration)
        return element:PostUpdate(cur, maxCharges, oldMax ~= max, start, duration)
    end
end

local function EnableEvent(self, spell) end

local function DisableEvent(self) enableState = {} end

-- 真实更新的转接方法 预留覆盖API
local function Path(self, event, ...)
    if event == "TankResourceEnable" then
        (self.TankResource.OverrideEnableEvent or EnableEvent)(self, ...)
    elseif event == "TankResourceDisable" then
        return (self.TankResource.OverrideDisableEvent or DisableEvent)(self, ...)
    end

    return (self.TankResource.Override or Update)(self, event, ...)
end

-- 判断是否让元素显示
local function Visibility(self, event, unit)
    local element = self.TankResource
    local shouleEnable = false

    -- 当有载具UI时 不显示
    if UnitHasVehicleUI('player') then
        unit = 'vehicle'
        shouleEnable = false
    else
        local enable, spell = GetEnableStateAndSpell()
        if enable and spell then
            shouleEnable = enable
            unit = 'player'
            if not enableState.spec or enableState.spec ~= GetSpecialization() then
                enableState.spell = spell
                enableState.spec = GetSpecialization()
            end
            local overrideSpellOptions = element.overrideSpellOptions
            if overrideSpellOptions[PlayerClass] then
                enableState.overrideSpellOptions = overrideSpellOptions[PlayerClass]
            end
        end
    end
    local isEnabled = element.isEnabled
    local spell = enableState.spell

    -- 如果当前状态可以开启模块显示 则提前设置颜色
    if shouleEnable then (element.UpdateColor or UpdateColor)(element) end

    if shouleEnable and not isEnabled then
        TankResourceEnable(self)
    elseif not shouleEnable and (isEnabled or isEnabled == nil) then
        TankResourceDisable(self)
    elseif shouleEnable and isEnabled then
        Path(self, event, spell, unit)
    end
end

-- 这里是判断是否让元素显示的转接方法 预留了覆盖的方法
local function VisibilityPath(self, ...)
    return (self.TankResource.OverrideVisibility or Visibility)(self, ...)
end

-- 预留的API 当Visibility的更新被预留的API覆盖时 可以使用的预留API
local function ForceUpdate(element)
    return VisibilityPath(element.__owner, 'ForceUpdate')
end

do
    -- 当资源真正开启时
    function TankResourceEnable(self)
        -- 这里注册监视事件
        self:RegisterEvent('SPELL_UPDATE_COOLDOWN', Path, true)
        self:RegisterEvent('PLAYER_TALENT_UPDATE', Path, true)
        -- self:RegisterEvent('SPELL_UPDATE_CHARGES', Path, true)
        if self.TankResource.costColor then
            for k in pairs(UsableUpdateEvents) do
                if  not self:IsEventRegistered(k) then
                    self:RegisterEvent(k, Path, true)
                end
            end
        end

        -- 创建用于更新进度的框架
        local _timeHandler = CreateFrame("Frame")
        _timeHandler.__owner = self
        -- _timeHandler:SetScript('OnUpdate', onUpdate)
        _timeHandler:SetScript("OnUpdate", function(_, elapsed)
            _timeHandler.elapsed = (_timeHandler.elapsed or 0) + elapsed
            if _timeHandler.elapsed > self.TankResource.updateDelay then
                onUpdate(_timeHandler)
                _timeHandler.elapsed = 0
            end
        end)
        self._timeHandler = _timeHandler
        self.TankResource.isEnabled = true
        self.TankResource.init = true
        enableState.enable = true

        -- 进行初始化
        Path(self, 'TankResourceEnable', enableState.spell)
    end

    function TankResourceDisable(self)
        -- 这里取消注册事件
        self:UnregisterEvent('SPELL_UPDATE_COOLDOWN', Path)
        self:UnregisterEvent('PLAYER_TALENT_UPDATE', Path)
        -- self:UnregisterEvent('SPELL_UPDATE_CHARGES', Path)
        if self.TankResource.costColor then
            for k in pairs(UsableUpdateEvents) do
                self:UnregisterEvent(k, Path)
            end
        end

        if self._timeHandler then
            self._timeHandler:SetScript('OnUpdate', nil)
        end

        -- 隐藏
        local element = self.TankResource
        for i = 1, #element do element[i]:Hide() end

        self.TankResource.isEnabled = false
        self.TankResource.CooldownUpdate = false
        enableState.enable = false

        -- 进行关闭
        Path(self, 'TankResourceDisable', enableState.spell)
    end
end

-- 模块开启
local function Enable(self, unit)
    -- 不是玩家自己就退出
    if unit ~= "player" then return end

    local element = self.TankResource

    -- 初始化
    if element then
        element.__owner = self
        element.__max = #element
        element.updateDelay = .2
        element.noPowerCostColor = { .9, .1, .1, 1 }
        element.costColor = true
        element.ForceUpdate = ForceUpdate

        -- 这里注册用于判断是否显示的事件 用于更新是否显隐
        self:RegisterEvent('PLAYER_TALENT_UPDATE', VisibilityPath, true)
        self:RegisterEvent('SPELLS_CHANGED', VisibilityPath, true)
        self:RegisterEvent('PLAYER_SPECIALIZATION_CHANGED', VisibilityPath)
        self:RegisterEvent('PLAYER_ENTERING_WORLD', VisibilityPath)
        --self:RegisterEvent('TRAIT_SUB_TREE_CHANGED', VisibilityPath, true)

        element.TankResourceEnable = TankResourceEnable
        element.TankResourceDisable = TankResourceDisable

        -- 对没有预置材质的进度条进行 材质设置
        -- 对进度条的进度条取值进行设置
        for i = 1, #element do
            local bar = element[i]
            if (bar:IsObjectType('StatusBar')) then
                if (not bar:GetStatusBarTexture()) then
                    bar:SetStatusBarTexture(
                        [[Interface\TargetingFrame\UI-StatusBar]])
                end

                bar:SetMinMaxValues(0, 100)
            end
        end

        return true
    end
end

local function Disable(self)
    if self.TankResource then
        TankResourceDisable(self)

        -- 这里解除注册用于判断是否显示的事件
        self:UnregisterEvent('PLAYER_TALENT_UPDATE', VisibilityPath)
        self:UnregisterEvent('SPELLS_CHANGED', VisibilityPath)
        self:UnregisterEvent('PLAYER_SPECIALIZATION_CHANGED', VisibilityPath)
        self:UnregisterEvent('PLAYER_ENTERING_WORLD', VisibilityPath)
        --self:UnregisterEvent('TRAIT_SUB_TREE_CHANGED', VisibilityPath)
    end
end

oUF:AddElement('TankResource', VisibilityPath, Enable, Disable)
