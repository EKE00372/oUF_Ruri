--[[
    ## Widget
    TankResource - An `table` holding `StatusBar`s.
    
    ## Sub-Widgets
    .bg - A `Texture` used as a background. It will inherit the color of the main StatusBar.
    
    ## Sub-Widget Options
    .multiplier - Used to tint the background based on the widget's R, G and B values. Defaults to 1 (number)[0-1]
    
    ## Examples
    local TankResource = {}
    local maxLength = 4
    for index = 1, maxLength do
        local Bar = CreateFrame('StatusBar', nil, self)

        -- Position and size.
        Bar:SetSize(120 / maxLength, 20)
        Bar:SetPoint('TOPLEFT', self, 'BOTTOMLEFT', (index - 1) * Bar:GetWidth(), 0)

        TankResource[index] = Bar
    end

    -- Register with oUF
    self.TankResource = TankResource
]] 
local addon, ns = ...
local C, F, G, T = unpack(ns)
local oUF = ns.oUF or oUF

local _, PlayerClass = UnitClass('player')

local spec = GetSpecialization() or 0

local SPEC_MONK_BREWMASTER = SPEC_MONK_BREWMASTER or 1
local SPEC_DEATHKNIGHT_BLOOD = SPEC_DEATHKNIGHT_BLOOD or 1
local SPEC_DEMONHUNTER_VENGEANCE = SPEC_DEMONHUNTER_VENGEANCE or 2
local SPEC_WARRIOR_PROTECTION = SPEC_WARRIOR_PROTECTION or 3
local SPEC_PALADIN_PROTECTION = SPEC_PALADIN_PROTECTION or 2
local SPEC_DRUID_GUARDIAN = SPEC_DRUID_GUARDIAN or 3

local TankResourceEnable, TankResourceDisable
local RequireSpec, RequireSpell

-- 自制的获取时间方法
local function GetResourceCooldown(spell)
    local start, dur, enable = GetSpellCooldown(spell)
    local charges, maxCharges, startCharges, durCharges = GetSpellCharges(spell);
    local stack = charges or GetSpellCount(spell)
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

-- 把Aura API 返回的方法转换成进度比 取值[0,1]
local function GetProgress(startTime, duration)
    local value = GetTime()
    local min = startTime
    local max = startTime + value
	
    value = math.max(min, value)
    value = math.min(max + value, value)
	
    local progress = (value - min) / (duration)
	
    return progress
end

-- 颜色更改
-- 需要在oUF.colors中声明tankresource 目前弃置
-- 返回能量的颜色
local function UpdateColor(element)
    spec = GetSpecialization() or 0
    local color = element.__owner.colors.power[4]

    if (spec ~= 0 and element.colorSpec) then
        -- color = element.__owner.colors.tankresource[spec]
    else
        color = element.__owner.colors.power[4]
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

-- 真实更新
local function Update(self, unit, spellID)
	if not (unit and UnitIsUnit(unit, 'player')) then return end
	
    local element = self.TankResource
    -- 预留 PreUpdate
    if element.PreUpdate then
		element:PreUpdate()
	end

    local cur, max, mod, oldMax
    if event ~= 'TankResourceDisable' then

        cur, max, start, duration = GetResourceCooldown(spellID)

        local numActive = cur + 0.9
        for i = 1, max do
            if (i > numActive) then
                element[i]:Hide()
                element[i]:SetValue(0)
            else
                element[i]:Show()
                element[i]:SetValue(GetProgress())
            end
        end

        oldMax = element.__max
        if (max ~= oldMax) then
            if (max < oldMax) then
                for i = max + 1, oldMax do
                    element[i]:Hide()
                    element[i]:SetValue(0)
                end
            end

            element.__max = max
        end
        -- 预留 PostUpdate
        if element.PostUpdate then
            return element:PostUpdate(cur, max, start, duration, spellID)
        end
    end
end

-- 真实更新的转接方法 预留覆盖API
local function Path(self, ...)
    return (self.tankresource.Override or Update) (self, ...)
end

-- 判断是否让元素显示
local function Visibility(self, event)
	if unit ~="player" then return end
	
    local element = self.TankResource
    local shouleEnable

    -- 当有载具UI时 不显示
    if UnitHasVehicleUI('player') then
		unit = 'vehicle'
        shouleEnable = false
    elseif spec then
        if RequireSpec and RequireSpec == GetSpecialization() then
            if RequireSpell and IsPlayerSpell(RequireSpell) then
                shouleEnable = true
				unit = 'player'
            end
        end
    end

    local isEnabled = element.isEnabled
    local spell = RequireSpell

    -- 如果当前状态可以开启模块显示 则提前设置颜色
    if shouleEnable then
		(element.UpdateColor or UpdateColor) (element)
	end
	
    if shouleEnable and not isEnabled then
        TankResourceEnable(self)
    elseif not shouleEnable and (isEnabled or isEnabled == nil) then
        TankResourceDisable(self)
    elseif shouleEnable and isEnabled then
        Path(self, event, spell)
    end
end

-- 这里是判断是否让元素显示的转接方法 预留了覆盖的方法
local function VisibilityPath(self, ...)
    return (self.TankResource.OverrideVisibility or Visibility) (self, ...)
end

-- 预留的API 当Visibility的更新被预留的API覆盖时 可以使用的预留API
local function ForceUpdate(element)
    return VisibilityPath(element.__owner, 'ForceUpdate')
end

do
    -- 当资源真正开启时
    function TankResourceEnable(self)
        -- 这里注册监视事件
        -- todo:这里注册监视事件
		self:RegisterEvent('SPELL_UPDATE_COOLDOWN', Path)
		self:RegisterEvent('SPELL_UPDATE_CHARGES', Path)
		self:RegisterEvent('UNIT_SPELLCAST_SENT', Path)
		self:RegisterEvent('ACTIONBAR_UPDATE_COOLDOWN', Path)

        self.TankResource.isEnabled = true
        -- 进行初始化
        Path(self, 'TankResourceEnable', RequireSpell)
    end

    function TankResourceDisable(self)
        -- 这里取消注册事件
        -- todo: 取消注册事件
		self:UnregisterEvent('SPELL_UPDATE_COOLDOWN', Path)
		self:UnregisterEvent('SPELL_UPDATE_CHARGES', Path)
		self:UnregisterEvent('UNIT_SPELLCAST_SENT', Path)
		self:UnregisterEvent('ACTIONBAR_UPDATE_COOLDOWN', Path)

        -- 隐藏
        local element = self.TankResource
        for i = 1, #element do
			element:Hide()
		end

        self.TankResource.isEnabled = false
        -- 进行关闭
        Path(self, 'TankResourceDisable', RequireSpell)
    end

    --[[ 
        {RequireSpec} 需要显示的天赋
        {RequireSpell} 需要监视的坦克防御技能
    ]]
    if PlayerClass == 'MONK' then
        RequireSpec = SPEC_MONK_BREWMASTER
        RequireSpell = 115308
    elseif PlayerClass == 'DEATHKNIGHT' then
        RequireSpec = SPEC_DEATHKNIGHT_BLOOD
        RequireSpell = 321
    elseif PlayerClass == 'DEMONHUNTER' then
        RequireSpec = SPEC_DEMONHUNTER_VENGEANCE
        RequireSpell = 321
    elseif PlayerClass == 'WARRIOR' then
        RequireSpec = SPEC_WARRIOR_PROTECTION
        RequireSpell = 321
    elseif PlayerClass == 'PALADIN' then
        RequireSpec = SPEC_PALADIN_PROTECTION
        RequireSpell = 53600
    elseif PlayerClass == 'DRUID' then
        RequireSpec = SPEC_DRUID_GUARDIAN
        RequireSpell = 321
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
        element.ForceUpdate = ForceUpdate

        -- 这里注册用于判断是否显示的事件 用于更新是否显隐
        self:RegisterEvent('PLAYER_TALENT_UPDATE', VisibilityPath, true)
        self:RegisterEvent('SPELLS_CHANGED', VisibilityPath, true)

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

                bar:SetMinMaxValues(0, 1)
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
    end
end

oUF:AddElement('TankResource', VisibilityPath, Enable, Disable)
