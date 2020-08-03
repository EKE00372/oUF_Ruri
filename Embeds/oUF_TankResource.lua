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

	#### if resourceStack is changed  you can override MaxChangeUpdate function to changed size.
		TankResource.MaxChangeUpdate = function(self,maxCharge)
			for i = 1, maxCharge do
				local bar = self[i]
				
				bar:SetSize(120/maxCharge,20)
				bar:SetPoint('TOPLEFT', self, 'BOTTOMLEFT', (i - 1) * Bar:GetWidth(), 0)
			end

		end

]]--
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
--local SPEC_PALADIN_PROTECTION = SPEC_PALADIN_PROTECTION or 2
local SPEC_DRUID_GUARDIAN = SPEC_DRUID_GUARDIAN or 3

local GetSpellCooldown, GetSpellCharges, GetSpellCount, UnitSpellHaste, GetTime,
	  UnitIsUnit, GetSpecialization, UnitHasVehicleUI, IsPlayerSpell,
	  CreateFrame = GetSpellCooldown, GetSpellCharges, GetSpellCount,
					UnitSpellHaste, GetTime, UnitIsUnit, GetSpecialization,
					UnitHasVehicleUI, IsPlayerSpell, CreateFrame

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

-- 把Aura API 返回的方法转换成进度比 取值[0,100]
local function GetProgress(startTime, duration)
	if startTime == 0 and duration == 0 then return 100 end
	local nowTime = GetTime() -- nowTime
	local startTime = startTime -- startTime
	local expirTime = startTime + nowTime -- expirTime

	local progress = (nowTime - startTime) / (duration)

	return progress * 100
end

-- 颜色更改
-- 需要在element.colors中声明
-- 返回能量的颜色
local function UpdateColor(element)
	local color = element.__owner.colors.power[4]

	if (spec ~= 0 and element.colors) then
		color = element.colors[PlayerClass]
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

-- 更新计时条的进度
-- 仅在需要更新时进行
local function onUpdate(self, elapsed)
	local element = self.__owner.TankResource
	
	--self.elapsed = (self.elapsed or 0) + elapsed
	
	--if self.elapsed > element.updateDelay then
		local cur, maxCharges, start, duration
		
		if element.CooldownUpdate then
			cur, maxCharges, start, duration = GetResourceCooldown(RequireSpell)
			
			if cur == maxCharges then
				element.CooldownUpdate = false
			end
			
			for i = maxCharges, 1, -1 do
				if element[i].needUpdate then
					if cur + 1 == i then
						element[i]:SetValue(GetProgress(start, duration))
					end
				end
			end

		end
	--end
end

-- 更新
local function Update(self, event, unit)
	if (unit and unit ~= self.unit) then return end
	if not RequireSpell then return end
	
	-- 预留 PreUpdate
	local element = self.TankResource
	if element.PreUpdate then element:PreUpdate() end
	
	local cur, maxCharges, oldMax, start, duration
	if event ~= 'TankResourceDisable' then

		cur, maxCharges, start, duration = GetResourceCooldown(RequireSpell)
		for i = 1, maxCharges do
			if cur +1 == i then 
				element[i].needUpdate = true 
			elseif cur<i then
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
				for i = oldMax, maxCharges do
					element[i]:Show()
				end
			end
			-- 预留最大层数变化接口
			if element.MaxChangeUpdate then
				element:MaxChangeUpdate(maxCharges)
			end
			element.__max = maxCharges
		end
		-- 预留 PostUpdate
		if element.PostUpdate then
			--return element:PostUpdate(cur, maxCharges, start, duration)
			return element:PostUpdate(cur, maxCharges, oldMax ~= max, start, duration)
		end
	end
end

-- 真实更新的转接方法 预留覆盖API
local function Path(self, ...)
	--local event = ...
	return (self.TankResource.Override or Update)(self, ...)
end

-- 判断是否让元素显示
local function Visibility(self, event, unit)
	local element = self.TankResource
	local shouleEnable = false

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
		--self:RegisterEvent('SPELL_UPDATE_CHARGES', Path, true)
		
		-- 创建用于更新进度的框架
		local _timeHandler = CreateFrame("Frame")
		_timeHandler.__owner = self
		--_timeHandler:SetScript('OnUpdate', onUpdate)
		_timeHandler:SetScript("OnUpdate", function(_, elapsed)
		_timeHandler.elapsed = (_timeHandler.elapsed or 0) + elapsed
			if _timeHandler.elapsed > .1 then
				onUpdate(_timeHandler)
				_timeHandler.elapsed = 0
			end
		end)
		self._timeHandler = _timeHandler

		self.TankResource.isEnabled = true
		self.TankResource.init = true  

		-- 进行初始化
		Path(self, 'TankResourceEnable', RequireSpell)
	end

	function TankResourceDisable(self)
		-- 这里取消注册事件
		self:UnregisterEvent('SPELL_UPDATE_COOLDOWN', Path)
		self:UnregisterEvent('PLAYER_TALENT_UPDATE', Path)
		--self:UnregisterEvent('SPELL_UPDATE_CHARGES', Path)

		if self._timeHandler then
			self._timeHandler:SetScript('OnUpdate', nil)
		end

		-- 隐藏
		local element = self.TankResource
		for i = 1, #element do element[i]:Hide() end

		self.TankResource.isEnabled = false
		self.TankResource.CooldownUpdate = false

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
	elseif PlayerClass == 'DEMONHUNTER' then
		RequireSpec = SPEC_DEMONHUNTER_VENGEANCE
		RequireSpell = 203720
	elseif PlayerClass == 'WARRIOR' then
		RequireSpec = SPEC_WARRIOR_PROTECTION
		RequireSpell = 2565
	--[[elseif PlayerClass == 'DEATHKNIGHT' then
		RequireSpec = SPEC_DEATHKNIGHT_BLOOD
		RequireSpell = 321
	elseif PlayerClass == 'DRUID' then
		RequireSpec = SPEC_DRUID_GUARDIAN
		RequireSpell = 273048]]--
	else
		RequireSpec = nil
		RequireSpell = nil
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
		element.ForceUpdate = ForceUpdate
		
		-- 这里注册用于判断是否显示的事件 用于更新是否显隐
		self:RegisterEvent('PLAYER_TALENT_UPDATE', VisibilityPath, true)
		--self:RegisterEvent('SPELLS_CHANGED', VisibilityPath, true)
		self:RegisterEvent('PLAYER_SPECIALIZATION_CHANGED', VisibilityPath)
		self:RegisterEvent('PLAYER_ENTERING_WORLD', Path)

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
		--self:UnregisterEvent('SPELLS_CHANGED', VisibilityPath)
		self:UnregisterEvent('PLAYER_SPECIALIZATION_CHANGED', VisibilityPath)
		self:UnregisterEvent('PLAYER_ENTERING_WORLD', Path)
	end
end

oUF:AddElement('TankResource', VisibilityPath, Enable, Disable)
