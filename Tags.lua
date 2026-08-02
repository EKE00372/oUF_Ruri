local _, ns = ...
local oUF = ns.oUF
local _, F, G = unpack(ns)

local UnitClass = UnitClass
local UnitReaction = UnitReaction
local UnitHealth, UnitPower, UnitPowerType = UnitHealth, UnitPower, UnitPowerType
local UnitIsAFK, UnitIsConnected, UnitIsDND, UnitIsDead, UnitIsGhost = UnitIsAFK, UnitIsConnected, UnitIsDND, UnitIsDead, UnitIsGhost
local UnitIsPlayer, UnitIsQuestBoss, UnitIsTapDenied = UnitIsPlayer, UnitIsQuestBoss, UnitIsTapDenied
local canaccessvalue, issecretvalue = canaccessvalue, issecretvalue

--==================================================--
-----------------    [[ Colors ]]    -----------------
--==================================================--

-- [[ Health color gardient ]] --

oUF.colors.health:SetCurve({
	[ 0] = CreateColor(1, 0, 0),
	[.5] = CreateColor(1, .8, .1),
	[ 1] = CreateColor(1, .8, .1),
})

-- [[ Class color ]] --

oUF.colors.class["SHAMAN"] = oUF:CreateColor(0, .6, 1)
oUF.colors.class["MAGE"] = oUF:CreateColor(.48, .84, .94)
oUF.colors.class["DEATHKNIGHT"] = oUF:CreateColor(1, .23, .23)
oUF.colors.class["DEMONHUNTER"] = oUF:CreateColor(.74, .35, .95)
oUF.colors.class["EVOKER"] = oUF:CreateColor(.33, .68, .68)

-- [[ Threat color ]] --

oUF.colors.threat[0] = oUF:CreateColor(.1, .7, .9) -- 非當前仇恨，低威脅值
oUF.colors.threat[1] = oUF:CreateColor(.4, .1, .9) -- 非當前仇恨，但已OT即將獲得仇恨，或坦克正在獲得仇恨
oUF.colors.threat[2] = oUF:CreateColor(.9, .1, .9) -- 當前仇恨，但不穩，已被OT或坦克正在丟失仇恨 (over threat 遠程130/近戰110)
oUF.colors.threat[3] = oUF:CreateColor(.9, .1, .4) -- 當前仇恨，威脅值穩定

-- [[ Aura type color ]] --

oUF.colors.dispel.None = oUF:CreateColor(.9, .05, .05)
oUF.colors.dispel.Disease = oUF:CreateColor(.8, .5, .2)

-- [[ Power type color ]] --

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
ReplacePowerColor("ESSENCE", 19, .02, .9, .9)				-- 19 喚能師 龍能
-- 載具類型
oUF.colors.power["FUEL"] = oUF:CreateColor(0, .75, .7)		-- 同時用於npc無屬能量
oUF.colors.power["AMMOSLOT"] = oUF:CreateColor(.8, .6, 0)

-- [[ Faction color ]] --

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

-- [[ Name colored by Player class and NPC faction ]] --

oUF.Tags.Methods["namecolor"] = function(unit)
	local reaction = UnitReaction(unit, "player")

	if UnitIsTapDenied(unit) then
		return F.Hex(oUF.colors.tapped)
	--elseif UnitIsPlayer(unit) or UnitPlayerControlled(unit) then
	elseif UnitIsPlayer(unit) then
		local _, class = UnitClass(unit)
		local color

		if issecretvalue(class) then
			-- 受限時不能用 secret class 索引自訂顏色表，改用暴雪職業色。
			color = C_ClassColor.GetClassColor(class)
		else
			color = oUF.colors.class[class]
		end

		return color and color:GenerateHexColorMarkup() or F.Hex(1, 1, 1)
	elseif reaction then
		return F.Hex(oUF.colors.reaction[reaction])
	else
		return F.Hex(1, 1, 1)
	end
end
oUF.Tags.Events["namecolor"] = "UNIT_NAME_UPDATE UNIT_FACTION"


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

oUF.Tags.Methods["afkdnd"] = function(unit)
	if not (unit and UnitIsPlayer(unit)) then return end
	
	local isAFK = UnitIsAFK(unit)
	local isDND = UnitIsDND(unit)
	local isConnected = UnitIsConnected(unit)
	
	if canaccessvalue(isAFK) and isAFK then				-- 暫離
		return "|T"..FRIENDS_TEXTURE_AFK..":14:14:0:0:16:16:1:15:1:15|t"
	elseif canaccessvalue(isDND) and isDND then			-- 忙錄
		return "|T"..FRIENDS_TEXTURE_DND..":14:14:0:0:16:16:1:15:1:15|t"
	elseif canaccessvalue(isConnected) and not isConnected then	-- 離線
		return "|T"..FRIENDS_TEXTURE_OFFLINE..":14:14:0:0:16:16:1:15:1:15|t"
	end
end
oUF.Tags.Events["afkdnd"] = "PLAYER_FLAGS_CHANGED UNIT_CONNECTION"

--==================================================--
-----------------    [[ Values ]]    -----------------
--==================================================--

-- [[ Unitframes ]] --

-- health: cur per
oUF.Tags.Methods["unit:hp"] = function(unit)
	if UnitIsDead(unit) then				-- 死亡
		return "|cff559655RIP|r"			-- or DEAD
	elseif UnitIsGhost(unit) then			-- 鬼魂
		return "|cff559655GHO|r"
	elseif not UnitIsConnected(unit) then	-- 離線
		return "|cff559655OFF|r"			-- or PLAYER_OFFLINE
	end

	local cur = F.NumberAbbrValue(UnitHealth(unit))
	local per = format("%d", UnitHealthPercent(unit, true, CurveConstants.ScaleTo100))
	return F.Hex(1, 1, 1)..cur.." "..F.Hex(1, 1, 0)..per.."|r"
end
oUF.Tags.Events["unit:hp"] = "UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED PARTY_MEMBER_ENABLE PARTY_MEMBER_DISABLE"

-- power: cur
oUF.Tags.Methods["unit:pp"]  = function(unit)
	local cur = UnitPower(unit)
	local _, type = UnitPowerType(unit)
	local color = oUF.colors.power[type] or oUF.colors.power.FUEL

	if type == "MANA" then -- 法力
		return F.Hex(color)..F.NumberAbbrValue(cur).."|r"
	else
		return F.Hex(color)..cur.."|r"
	end
end
oUF.Tags.Events["unit:pp"] = "UNIT_POWER_FREQUENT UNIT_MAXPOWER UNIT_DISPLAYPOWER"
