﻿local addon, ns = ...
local oUF = ns.oUF
local C, F, G, T = unpack(ns)

-- 抄他喵的
-- https://github.com/siweia/NDui/blob/master/Interface/AddOns/NDui/Config/Nameplate.lua

--======================================================--
-----------------    [[ Nameplates ]]    -----------------
--======================================================--
--[[
C.StackList = {
	-- we dont need this because only bolster at now
	}
]]--
C.WhiteList = {
	-- [[ 補足暴雪的白名單裡缺少的控場法術 / Show auras not in blizzard default list ]] --
	
	-- Buffs
	--[1459] = true,	-- 秘法智力test
	[642]	 = true,	-- 聖盾術
	[1022]	 = true,	-- 保護祝福
	[23920]	 = true,	-- 法術反射
	[45438]	 = true,	-- 寒冰屏障
	[186265] = true,	-- 灵龟守护
	-- Debuffs
	[2094]	 = true,	-- 致盲
	[10326]	 = true,	-- 超度邪恶
	[117405] = true,	-- 束缚射击
	[127797] = true,	-- 厄索爾之旋
	[20549]  = true,	-- 戰爭踐踏
	[107079] = true,	-- 震山掌
	[272295] = true,	-- 悬赏
	
	-- [[ 副本 ]] --
	
	-- 詞綴
	[228318] = true,	-- 狂怒
	[226510] = true,	-- 膿血
	--[343502] = true,	-- 鼓舞
	--[343553] = true,	-- 盡噬忿恨
	--[373724] = true,	-- 鲜血屏障
	--[373011] = true,	-- 伪装
	--[373785] = true,	-- 大魔王伪装
	
	-- Dungeons
	[113315] = true,	-- 青龙寺，强烈
	[113309] = true,	-- 青龙寺，至高能量
	[384148] = true,	-- 诱捕陷阱，蕨皮
	[200672] = true,	-- 水晶迸裂，巢穴
	[377724] = true,	-- 小怪易伤，提尔
	[413027] = true,	-- 泰坦之壁，永恒黎明
	[258653] = true,	-- 魂能壁垒，阿塔达萨
	[255960] = true,	-- 强效巫毒，阿塔达萨
	[255967] = true,	-- 强效巫毒，阿塔达萨
	[255968] = true,	-- 强效巫毒，阿塔达萨
	[255970] = true,	-- 强效巫毒，阿塔达萨
	[255972] = true,	-- 强效巫毒，阿塔达萨
	[260805] = true,	-- 聚焦之虹，庄园
	[264027] = true,	-- 结界蜡烛，庄园
	
	-- Raids
}

C.BlackList = {
	--[116189] = true,	-- 嘲心嘯
	[15407]	 = true,	-- 精神鞭笞
	[51714]	 = true,	-- 锋锐之霜
	[199721] = true,	-- 腐烂光环
	[214968] = true,	-- 死灵光环
	[214975] = true,	-- 抑心光环
	[273977] = true,	-- 亡者之握
	[276919] = true,	-- 承受压力
	[206930] = true,	-- 心脏打击
	[385723] = true,	-- 十字軍聖印
	[370794] = true,	-- 滯留冰霜火花
}

C.CustomUnits = {
	[204560] = {.7, .95, 1}, 	-- 詞綴，無形生命
	[174773] = {.7, .95, 1}, 	-- 詞綴，懷恨幽影
	[120651] = {.7, .95, 1}, 	-- 詞綴，易爆
	--[190128] = {.7, .95, 1}, 	-- 詞綴，隱蔽的祖爾佳穆克斯
	
	-- Dungeons	
	[104251] = {.8, 1, .1},		-- 眾星之庭，哨兵
	[101008] = {.8, 1, .1},		-- 黑鸦堡垒，针刺虫群
	[190174] = {.8, 1, .1}, 	-- 眾星之庭，催眠蝙蝠
	[196548] = {.8, 1, .1}, 	-- 學院，古樹樹枝
	[137103] = {.8, 1, .1},		-- 血面兽，地渊
	[92538]  = {.8, 1, .1},		-- 喷油蛆虫，巢穴
	[190426] = {.8, 1, .1},		-- 腐朽图腾，蕨皮
	[190381] = {.8, 1, .1},		-- 腐爆图腾，蕨皮
	[186696] = {.8, 1, .1},		-- 撼地图腾，提尔
	
	-- Raids
}

C.UnitTarget = {
	-- Show fixed target: NPC IDs
	[165251] = true,	-- 迷霧的追人狐狸
	[174773] = true,	-- 惡意詞綴，憎恨幽影
	[190174] = true,	-- 眾星之庭，催眠蝙蝠
}

C.UnitSpellTarget = {
	-- Show Spell target: NPC IDs
}

C.ShowPower = {
	-- show power: NPC IDs
	[56792] = true,		-- 青龙寺，怀疑臆象
	[133944] = true,	-- 神廟，艾斯匹
	[133379] = true,	-- 神廟，阿德利斯
	[165556] = true,	-- 血紅深淵，瞬息具象
	[171557] = true,	-- 猎手阿尔迪莫，巴加斯特之影
	[163746] = true,	-- 垃圾场，步行震击者X1型
	[114247] = true,	-- 卡上，馆长
}

--======================================================--
-----------------    [[ UnitFrames ]]    -----------------
--======================================================--

C.PlayerWhiteList = {
	[315496] = true,	-- 盜賊，切割
}

C.PlayerBlackList = {
	[2479]	 = true,	-- 無榮譽目標
	[269279] = true,	-- 迴響防護
	[273298] = true,	-- 翔陽寸勁
}

--======================================================--
-----------------    [[ RaidFrames ]]    -----------------
--======================================================--

C.RaidBlackList = {
	[206151] = true,		-- 挑戰者的重擔
	--[25163] = true,
	[271544] = true,		-- 消蝕防護
	[296847] = true,		-- 压迫光环
	[338906] = true,		-- 典狱长之链
}

C.RaidBuffList = {
	-- Death Knight
    [48707]  = true, -- Anti-Magic Shell
    [48792]  = true, -- Icebound Fortitude
    [287081] = true, --Lichborne
    [55233]  = true, --Vampiric Blood
    [194679] = true, --Rune Tap
    [145629] = true, --Anti-Magic Zone
    [81256]  = true, --Dancing Rune Weapon

    -- Demon Hunter
    [196555] = true, --Netherwalk
    [206804] = true, --Rain from Above
    [187827] = true, --Metamorphosis (Vengeance)
    [212800] = true, --Blur
    [263648] = true, --Soul Barrier

    -- Druid
    [203554] = true, --Focused Growth
    [362486] = true, --Tranquility (Druid PVP)
    [102342] = true, --Ironbark
    [22812]  = true, --Barkskin
    [61336]  = true, --Survival Instincts
    [5215]   = true, --Prowl

    -- Hunter
    [186265] = true, --Aspect of the Turtle
    [53480] = true, --Roar of Sacrifice
    [264735] = true, --Survival of the Fittest (Pet Ability)
    [281195] = true, --Survival of the Fittest (Lone Wolf)
    [199483] = true, --Camouflage

    -- Mage
    [45438]  = true, --Ice Block
    [66]     = true, --Invisibility
    [198111] = true, --Temporal Shield
    [113862] = true, --Greater Invisibility
    [342246] = true, --Alter Time
    [110909] = true,
    [108978] = true,

    -- Monk
    [125174] = true, -- 乾坤挪移 / Touch of Karma
    [120954] = true, --Fortifying Brew (Brewmaster)
    [243435] = true, --Fortifying Brew (Mistweaver)
    [201318] = true, --Fortifying Brew (Windwalker)
    [115176] = true, -- 禪定歸宗 / Zen Meditation
    [116849] = true, --Life Cocoon
    [122278] = true, --Dampen Harm
    [122783] = true, -- Diffuse Magic

    -- Paladin
    [204018] = true, --Blessing of Spellwarding
    [642]    = true, --聖盾術 / Divine Shield
    [228050] = true, --Divine Shield (Protection)
    [1022]   = true, --保護 / Blessing of Protection
    [6940]   = true, --Blessing of Sacrifice
    [199448] = true, --Blessing of Ultimate Sacrifice
    [498]    = true, --Divine Protection
    [31850]  = true, --Ardent Defender
    [86659]  = true, --Guardian of Ancient Kings
    [205191] = true, --Eye for an Eye

    -- Priest
    [47788]  = true, --Guardian Spirit
    [47585]  = true, --Dispersion
    [33206]  = true, --Pain Suppression
    [213602] = true, --Greater Fade
    [81782]  = true, --Power Word: Barrier
    [271466] = true, --Luminous Barrier
    [20711]  = true, --Spirit of Redemption

    -- Rogue
    [31224]  = true, --Cloak of Shadows
    [45182]  = true, --Cheating Death
    [5277]   = true, --Evasion
    [199754] = true, --Riposte
    [1966]   = true, --Feint
    [1784]   = true, --Stealth

    -- Shaman
    [210918] = true, --Ethereal Form
    [108271] = true, --Astral Shift
    [118337] = true, --Harden Skin
    [201633] = true, --Earthen Wall Totem

    -- Warlock
    [212295] = true, --Nether Ward
    [104773] = true, --Unending Resolve
    [108416] = true, --Dark Pact

    -- Warrior
    [871]    = true, --Shield Wall
    [118038] = true, --Die by the Sword
    [147833] = true, --Intervene
    [213915] = true, --Mass Spell Reflection
    [23920]  = true, --Spell Reflection (Prot)
    [216890] = true, --Spell Reflection (Arms/Fury)
    [184364] = true, --Enraged Regeneration
    [97463]  = true, --Rallying Cry
    [12975]  = true, --Last Stand
    [190456] = true, --Ignore Pain

    -- Misc
    --[[["Eating/Drinking"] = true, -- Food umbrella
	["Food & Drink"] = true, --Food & Drink
    ["Food"] = true, --Food
    ["Drink"] = true, --Drink
    ["Refreshment"] = true, --Refreshment
    [185710] = true, --Sugar-Crusted Fish Feast
    [320224] = true, -- Podtender
    [363522] = true, -- Gladiator's Eternal Aegis
    [345231] = true, -- Gladiator's Emblem]]--
}