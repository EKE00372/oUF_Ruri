local addon, ns = ...
local oUF = ns.oUF
local C, F, G, T = unpack(ns)

local UnitAffectingCombat, UnitClass, UnitExists, UnitGUID, GetUnitName = UnitAffectingCombat, UnitClass, UnitExists, UnitGUID, GetUnitName
local UnitGetTotalAbsorbs, UnitReaction, UnitThreatSituation = UnitGetTotalAbsorbs, UnitReaction, UnitThreatSituation
local UnitHealth, UnitHealthMax, UnitPower, UnitPowerMax, UnitPowerType = UnitHealth, UnitHealthMax, UnitPower, UnitPowerMax, UnitPowerType
local UnitIsAFK, UnitIsConnected, UnitIsDND, UnitIsDead, UnitIsGhost = UnitIsAFK, UnitIsConnected, UnitIsDND, UnitIsDead, UnitIsGhost
local UnitIsPlayer, UnitIsQuestBoss, UnitIsTapDenied, UnitIsUnit, UnitName = UnitIsPlayer, UnitIsQuestBoss, UnitIsTapDenied, UnitIsUnit, UnitName

--==================================================--
-----------------    [[ Colors ]]    -----------------
--==================================================--

oUF.colors.health:SetCurve({
	[ 0] = CreateColor(1, 0, 0),
	[.5] = CreateColor(1, .8, .1),
	[ 1] = CreateColor(1, .8, .1),
})

-- [[ 職業 ]] --

oUF.colors.class["SHAMAN"] = oUF:CreateColor(0, .6, 1)
oUF.colors.class["MAGE"] = oUF:CreateColor(.48, .84, .94)
oUF.colors.class["DEATHKNIGHT"] = oUF:CreateColor(1, .23, .23)
oUF.colors.class["DEMONHUNTER"] = oUF:CreateColor(.74, .35, .95)
oUF.colors.class["EVOKER"] = oUF:CreateColor(.33, .68, .68)

-- [[ 威脅 ]] --

oUF.colors.threat[0] = oUF:CreateColor(.1, .7, .9) -- 非當前仇恨，低威脅值
oUF.colors.threat[1] = oUF:CreateColor(.4, .1, .9) -- 非當前仇恨，但已OT即將獲得仇恨，或坦克正在獲得仇恨
oUF.colors.threat[2] = oUF:CreateColor(.9, .1, .9) -- 當前仇恨，但不穩，已被OT或坦克正在丟失仇恨 (over threat 遠程130/近戰110)
oUF.colors.threat[3] = oUF:CreateColor(.9, .1, .4) -- 當前仇恨，威脅值穩定

-- [[ 光環 ]] --

oUF.colors.dispel[oUF.Enum.DispelType.None] = oUF:CreateColor(.9, .05, .05)

-- [[ 能量 ]] --

local function ReplacePowerColor(name, index, r, g, b)
	oUF.colors.power[name] = oUF:CreateColor(r, g, b)
	oUF.colors.power[index] = oUF.colors.power[name]
end

ReplacePowerColor("MANA", 0, 0, .8, 1)						-- 0 法力
ReplacePowerColor("RAGE", 1, .9, .1, .1)					-- 1 戰士熊德 怒氣
ReplacePowerColor("FOCUS", 2, .9, .5, .1)					-- 2 獵人 集中值
ReplacePowerColor("ENERGY", 3, .9, .9, .1)					-- 3 盜賊武僧貓德 能量
ReplacePowerColor("RUNIC_POWER", 6, .1, .9, .9)				-- 6 死騎 符能
ReplacePowerColor("LUNAR_POWER", 8, 0, .6, 1)				-- 8 鳥德 月能
ReplacePowerColor("MAELSTROM", 11, 0, .6, 1)				-- 11 薩滿旋渦值
ReplacePowerColor("INSANITY", 13, .74, .35, .95)            -- 13 暗牧 瘋狂值(共用dh職業色)
ReplacePowerColor("ARCANE_CHARGES", 16, 0, .8, 1)			-- 16 秘法 充能
ReplacePowerColor("ARCANE_CHARGES", 19, .02, .9, .9)		-- 19 喚能師 龍能
-- 載具類型
oUF.colors.power["FUEL"] = oUF:CreateColor(0, .75, .7)		-- 同時用於npc無屬能量
oUF.colors.power["AMMOSLOT"] = oUF:CreateColor(.8, .6, 0)

-- [[ 陣營 ]] --

oUF.colors.reaction[1] = oUF:CreateColor(1, .12, .25)
oUF.colors.reaction[2] = oUF:CreateColor(1, .12, .25)
oUF.colors.reaction[3] = oUF:CreateColor(1, .5, .25)
oUF.colors.reaction[4] = oUF:CreateColor(1, 1, 0)
oUF.colors.reaction[5] = oUF:CreateColor(.26, 1, .22)
oUF.colors.reaction[6] = oUF:CreateColor(.26, 1, .22)
oUF.colors.reaction[7] = oUF:CreateColor(.26, 1, .22)
oUF.colors.reaction[8] = oUF:CreateColor(.26, 1, .22)

--[[
	["HUNTER"] = { r = 0.58, g = 0.86, b = 0.49 },
	["WARLOCK"] = { r = 0.6, g = 0.47, b = 0.85 },
	["PALADIN"] = { r = 1, g = 0.22, b = 0.52 },
	["PRIEST"] = { r = 0.8, g = 0.87, b = .9 },
	["MAGE"] = { r = 0, g = 0.76, b = 1 },
	["MONK"] = {r = 0.0, g = 1.00 , b = 0.59},
	["ROGUE"] = { r = 1, g = 0.91, b = 0.2 },
	["DRUID"] = { r = 1, g = 0.49, b = 0.04 },
	["SHAMAN"] = { r = 0, g = 0.6, b = 0.6 };
	["WARRIOR"] = { r = 0.9, g = 0.65, b = 0.45 },
	["DEATHKNIGHT"] = { r = 0.77, g = 0.12 , b = 0.23 },
]]--

--==================================================--
-----------------    [[ Status ]]    -----------------
--==================================================--

-- [[ 任務目標 ]] --

oUF.Tags.Methods["quest"] = function(unit)
	local quest = UnitIsQuestBoss(unit)
	if quest then
		return "|cff8AFF30!|r"
	else
		return ""
	end
end
oUF.Tags.Events["quest"] = "UNIT_CLASSIFICATION_CHANGED"

-- [[ 死亡 ]] --
oUF.Tags.Methods["deadskull"] = function(unit)
	local dead = UnitIsDead(unit) or UnitIsGhost(unit)
	if dead then
		--return "|T"..G.media.skull..":64:64:0:0:64:64:0:64:8:56|t"
		return "|T"..G.media.skull..":12:16:0:0:64:64:8:56:9:52|t"
	else
		return ""
	end
end
oUF.Tags.Events["deadskull"] = "UNIT_HEALTH"

-- [[ 狀態 ]] --

oUF.Tags.Methods["afkdnd"] = function(unitnit)
	if not unit then return end
	
	if UnitIsAFK(unitnit) then					-- 暫離
		return "|T"..FRIENDS_TEXTURE_AFK..":14:14:0:0:16:16:1:15:1:15|t"
	elseif UnitIsDND(unitnit) then				-- 忙錄
		return "|T"..FRIENDS_TEXTURE_DND..":14:14:0:0:16:16:1:15:1:15|t"
	elseif (not UnitIsConnected(unitnit)) then	-- 離線
		return "|T"..FRIENDS_TEXTURE_OFFLINE..":14:14:0:0:16:16:1:15:1:15|t"
	end
end
oUF.Tags.Events["afkdnd"] = "PLAYER_FLAGS_CHANGED UNIT_CONNECTION"

--==================================================--
-----------------    [[ Values ]]    -----------------
--==================================================--

-- [[ Unitframes ]] --

-- health: cur-per
oUF.Tags.Methods["unit:hp"] = function(unit)
	local max = F.NumberAbbrValue(UnitHealthMax(unit))
	local cur = F.NumberAbbrValue(UnitHealth(unit))
	local per = format("%d", UnitHealthPercent(unit, true, CurveConstants.ScaleTo100))

	if UnitIsDead(unit) then				-- 死亡
		return "|cff559655RIP|r"			-- or DEAD
	elseif UnitIsGhost(unit) then			-- 鬼魂
		return "|cff559655GHO|r"
	elseif not UnitIsConnected(unit) then	-- 離線
		return "|cff559655OFF|r"			-- or PLAYER_OFFLINE
	else -- 血量
		if C.verticalTarget and unit == "target" then
			return F.Hex(1, 1, 0)..per.."|r "..F.Hex(1, 1, 1)..cur.."|r"
		else
			return F.Hex(1, 1, 1)..cur.." "..F.Hex(1, 1, 0)..per.."|r"
		end
	end
end
oUF.Tags.Events["unit:hp"] = "UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED PARTY_MEMBER_ENABLE PARTY_MEMBER_DISABLE"

-- power: cur
oUF.Tags.Methods["unit:pp"]  = function(unit)
	local cur, max = UnitPower(unit), UnitPowerMax(unit)
	local _, class = UnitClass(unit)
	local _, type = UnitPowerType(unit)
	local color = oUF.colors.power[type] or oUF.colors.power.FUEL

	if type == "MANA" then -- 法力
		return F.Hex(unpack(color))..F.NumberAbbrValue(cur).."|r"
	else
		return F.Hex(unpack(color))..cur.."|r"
	end
end
oUF.Tags.Events["unit:pp"] = "UNIT_POWER_FREQUENT UNIT_MAXPOWER UNIT_DISPLAYPOWER"


-- [[ Nameplates ]] --






-- bar style nameplates
oUF.Tags.Methods["bp:hp"] = function(unit)
	local per = oUF.Tags.Methods["perhp"](unit)
	
	if UnitIsDead(unit) then
		-- 死亡
		return ""
	elseif not UnitIsConnected(unit) then
		-- 離線
		return ""
	elseif per == 100 then
		-- 滿血不顯示血量
		return ""
	else
		return per
	end
end
oUF.Tags.Events["bp:hp"] = "UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION"

-- number style nameplates
oUF.Tags.Methods["np:hp"] = function(unit)
	local per = oUF.Tags.Methods["perhp"](unit)
	--local player = UnitIsPlayer(unit)
	local reaction = UnitReaction(unit, "player")
	local absorb = UnitGetTotalAbsorbs(unit) or 0
	local color
	
	if per < 25 then
		color = F.Hex(.8, .05, 0)
	elseif per < 30 then
		color = F.Hex(.95, .7, .25)
	else
		color = F.Hex(1, 1, 1)
	end
	
	if reaction and reaction >= 5 then
		return ""
	else
		if UnitIsDead(unit) then
			-- 死亡
			return ""
		elseif not UnitIsConnected(unit) then
			-- 離線
			return ""
		elseif per == 100 then
			-- 滿血不顯示血量
			--return UnitAffectingCombat("player") and "100" or ""
			return (absorb > 0 and "+") or ""
		elseif per ~= 100 then
			return color..per.."|r"
		else
			return ""
		end
	end
end
oUF.Tags.Events["np:hp"] = "UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION"

-- [[ 能量 ]] --

-- unitframes


-- nameplates
oUF.Tags.Methods["np:pp"] = function(unitnit)
	-- 只監控白名單的能量
	local npcID = F.GetNPCID(unitnitGUID(unitnit))
	if not C.ShowPower[npcID] then return end
	
	local per = oUF.Tags.Methods["perpp"](unitnit)
	local color
	
	if per < 25 then
		color = F.Hex(.2, .2, 1)
	elseif per < 30 then
		color = F.Hex(.4, .4, 1)
	else
		color = F.Hex(.8, .8, 1)
	end
	
	per = color..per.."|r"

	return per
end
oUF.Tags.Events["np:pp"] = "UNIT_POWER_FREQUENT UNIT_MAXPOWER"

-- [[ 吸收量 ]] --

-- nameplates
oUF.Tags.Methods["np:ab"] = function(unit)
	local max = UnitHealthMax(unit)
	local absorb = UnitGetTotalAbsorbs(unit) or 0
	
	if absorb ~= 0 then
		return F.Hex(1, .9, .4).."+"..math.floor((absorb / max * 100) + .5)
	else
		return ""
	end
end
oUF.Tags.Events["np:ab"] = "UNIT_ABSORB_AMOUNT_CHANGED"

-- [[ 名字顏色 ]] --

oUF.Tags.Methods["namecolor"] = function(unit, r)
	local reaction = UnitReaction(unit, "player")
	
	if UnitIsTapDenied(unit) then
		return F.Hex(oUF.colors.tapped)
	elseif UnitIsPlayer(unit) then
		local _, class = UnitClass(unit)
		return F.Hex(oUF.colors.class[class])
	elseif reaction then
		return F.Hex(oUF.colors.reaction[reaction])
	else
		return F.Hex(1, 1, 1)
	end
end
oUF.Tags.Events["namecolor"] = "UNIT_NAME_UPDATE UNIT_FACTION"

-- [[ 單位的目標 ]] --

oUF.Tags.Methods["np:tar"] = function(unitnit)
	local targetUnit = unit.."target"

	if UnitExists(targetUnit) then
		local targetClass = select(2, UnitClass(targetUnit))
		return F.Hex(oUF.colors.class[targetClass])..UnitName(targetUnit)
	else
		return ""
	end
end
oUF.Tags.Events["np:tar"] = "UNIT_NAME_UPDATE UNIT_THREAT_SITUATION_UPDATE UNIT_HEALTH"


--[[
oUF.Tags.Methods["npcast"] = function(unitnit)
	local unitTarget = unit.."target"
	
	if UnitExists(unitnitTarget) and UnitIsPlayer(unitnitTarget) then
		local nameString
		--if UnitIsUnit(unitnitTarget, "player") then
			nameString = format("|cffff0000%s|r", ">"..strupper(YOU).."<")
		--else
			local _, class = UnitClass(unitnitTarget)
			nameString = F.Hex(oUF.colors.class[class])..">>"..UnitName(unitnitTarget)
		--end
		
		return nameString
	end
end
oUF.Tags.Events["npcast"] = "UNIT_SPELLCAST_START UNIT_SPELLCAST_CHANNEL_START"
]]--

--[[
oUF.Tags.Methods["np:name"] = function(unit)
	local name = GetUnitName(unit) or UNKNOWN
	local status = UnitThreatSituation("player", u) or false
	local reaction = UnitReaction(unit, "player")
	
	if UnitIsTapDenied(unit) then
		return F.Hex(oUF.colors.tapped)
	elseif UnitIsPlayer(unit) then
		local _, class = UnitClass(unit)
		return F.Hex(oUF.colors.class[class])
	elseif reaction and reaction >= 5 then
		return F.Hex(oUF.colors.reaction[reaction])
	elseif status then
		if status == 0 then
			return F.Hex(.1, .7, .9)
		elseif status == 1 then
			return F.Hex(.4, .1, .9)
		elseif status == 2 then
			return F.Hex(.9, .1, .9)
		elseif status == 3 then
			return F.Hex(.9, .1, .4)
		end
	else
		return F.Hex(1, 0, 0)
	end
end
oUF.Tags.Events["np:name"] = "UNIT_NAME_UPDATE UNIT_FACTION UNIT_THREAT_SITUATION_UPDATE"
]]--