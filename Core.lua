local addon, ns = ...
local oUF = ns.oUF
local C, F, G, T = unpack(ns)

local UnitGetIncomingHeals, UnitGetTotalAbsorbs, UnitClass, UnitAffectingCombat = UnitGetIncomingHeals, UnitGetTotalAbsorbs, UnitClass, UnitAffectingCombat
local UnitHealth, UnitHealthMax, UnitPowerType, GetRuneCooldown = UnitHealth, UnitHealthMax, UnitPowerType, GetRuneCooldown
local UnitIsConnected, UnitIsDead, UnitIsGhost, UnitGUID, UnitIsPlayer = UnitIsConnected, UnitIsDead, UnitIsGhost, UnitGUID, UnitIsPlayer
local GetTime, format = GetTime, format

-- 在 CreateCastbar 等創建元素的的 function 裡，self.Castbar 中的 self 指的是頭像本身
-- 而在施法條、光環、副資源等元素的 PostUpdate 中，self 指的是 self.Castbar，即施法條元素自身
-- 為了防止搞混，這裡的 function(self, unit) 寫為 function (element, unit)

--=================================================--
-----------------    [[ Power ]]    -----------------
--=================================================--



-- [[ 更新預估治療 ]] --
--[[
T.PostUpdateHealthPrediction = function(self, unit, myIncomingHeal, otherIncomingHeal, absorb, healAbsorb, hasOverAbsorb, hasOverHealAbsorb)
	local health = self.__owner.Health
	local style = self.__owner.mystyle
	local cur, max = UnitHealth(unit), UnitHealthMax(unit)
	local ab, income = UnitGetTotalAbsorbs(unit) or 0, UnitGetIncomingHeals(unit) or 0
	
	-- 合併預估治療和吸收盾
	-- 不要這麼做，會誤判血量
	--self.absorbBar:SetValue(ab + income)
	
	if self.overAbsorb and hasOverAbsorb then
	--if self.overAbsorb and (cur + ab > max) then
		local totalAbsorb = (ab + income)
		local lostHealth = (max - cur) -- 目標當前缺口
		local curHealth = cur/max -- 目標當前血量百分比
		local perAbsorb = (totalAbsorb > lostHealth) and (totalAbsorb - lostHealth)/max or 0 -- 盾吸收值轉換血量百分比
		
		-- 轉換計量條的相乘係數
		local value
		if totalAbsorb >= max then
			-- 盾大於總血量：長度等於當前血量
			value = curHealth
		else
			-- 盾小於總血量：長度等於百分比
			value = perAbsorb
		end

		if perAbsorb == 0 then
			-- value 偶爾會無法運算，hasOverAbsorb成立但不滿足perAbsorb條件？
			self.overAbsorb:Hide()
		else
			self.overAbsorb:Show()
			
			if F.IsAny(style, "VL", "VR") then
				self.overAbsorb:SetHeight(value * health:GetHeight())
			elseif F.IsAny(style, "H", "BP", "BPP", "R") then
				self.overAbsorb:SetWidth(value * health:GetWidth())
			end
		end
	end
end
]]--