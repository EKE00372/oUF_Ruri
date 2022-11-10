local addon, ns = ...
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
	[343502] = true,	-- 鼓舞
	--[343553] = true,	-- 盡噬忿恨
	--[373724] = true,	-- 鲜血屏障
	[373011] = true,	-- 伪装
	[373785] = true,	-- 大魔王伪装
	
	-- Dungeons
	[320293] = true,	-- 伤逝剧场，融入死亡
	[331510] = true,	-- 伤逝剧场，死亡之愿
	[333241] = true,	-- 伤逝剧场，暴脾气
	[336449] = true,	-- 凋魂之殇，玛卓克萨斯之墓
	[336451] = true,	-- 凋魂之殇，玛卓克萨斯之壁
	[333737] = true,	-- 凋魂之殇，凝结之疾
	[328175] = true,	-- 凋魂之殇，凝结之疾
	[340357] = true,	-- 凋魂之殇，急速感染
	[228626] = true,	-- 彼界，怨灵之瓮
	[344739] = true,	-- 彼界，幽灵
	[333227] = true,	-- 彼界，不死之怒
	[326771] = true,	-- 贖罪之殿，石之看守者
	[326450] = true,	-- 贖罪之殿，忠實野獸
	[343558] = true,	-- 死靈戰地，病态凝视
	[343470] = true,	-- 死靈戰地，碎骨之盾
	[328351] = true,	-- 死靈戰地，染血长枪
	[322433] = true,	-- 血紅深淵，石肤术
	[321402] = true,	-- 血紅深淵，饱餐
	[327416] = true,	-- 晋升高塔，心能回灌
	[317936] = true,	-- 晋升高塔，弃誓信条
	[327812] = true,	-- 晋升高塔，振奋英气
	[339917] = true,	-- 晋升高塔，命运之矛
	[323149] = true,	-- 仙林，黑暗之拥
	[322569] = true,	-- 仙林，兹洛斯之手
	[355147] = true,	-- 集市，鱼群鼓舞
	[355057] = true,	-- 集市，鱼人战吼
	[351088] = true,	-- 集市，圣物联结
	[355640] = true,	-- 集市，重装方阵
	[355783] = true,	-- 集市，力量增幅
	[347840] = true,	-- 集市，野性
	[347015] = true,	-- 集市，强化防御
	[355934] = true,	-- 集市，强光屏障
	[349933] = true,	-- 集市，狂热鞭笞协议
	[350931] = true,	-- 爬塔软泥免疫
	[164504] = true,	-- 钢铁码头，威吓
	[163689] = true,	-- 钢铁码头，血红之球
	[227548] = true,	-- 卡上，烧蚀护盾
	
	-- Raids
	[334695] = true,	-- 动荡能量，猎手
	[345902] = true,	-- 破裂的联结，猎手
	[346792] = true,	-- 罪触之刃，猩红议会
}

C.BlackList = {
	[15407]	 = true,	-- 精神鞭笞
	[51714]	 = true,	-- 锋锐之霜
	[199721] = true,	-- 腐烂光环
	[214968] = true,	-- 死灵光环
	[214975] = true,	-- 抑心光环
	[273977] = true,	-- 亡者之握
	[276919] = true,	-- 承受压力
	[206930] = true,	-- 心脏打击
	[385723] = true,	-- 十字軍聖印
}

C.CustomUnits = {
	[120651] = {.7, .95, 1}, 	-- 火爆詞綴，炸藥
	[174773] = {.7, .95, 1}, 	-- 怨毒詞綴，Spiteful Shade
	--[190128] = {.7, .95, 1}, 	-- 隱蔽詞綴，祖爾佳穆克斯
	[190174] = {.7, .95, 1}, 	-- 隱蔽詞綴，催眠
	
	-- Shadowlands Dungeons	
	[169498] = {.8, 1, .1},		-- 瘟疫之臨，瘟疫彈
	[170851] = {.8, 1, .1},		-- 瘟疫之臨，爆燃瘟疫彈
	[165556] = {.8, 1, .1},		-- 血紅深淵，瞬息具象
	[165251] = {.8, 1, .1},		-- 仙林，幻影仙狐
	[170234] = {.8, 1, .1},		-- 伤逝剧场，压制战旗
	[164464] = {.8, 1, .1},		-- 伤逝剧场，卑劣的席拉
	[171341] = {.8, 1, .1},		-- 彼界，幼鹤
	[175576] = {.8, 1, .1},		-- 集市，监禁
	[179733] = {.8, 1, .1},		-- 集市，鱼串
	[180433] = {.8, 1, .1},		-- 集市，流浪的脉冲星
	[104251] = {.8, 1, .1},		-- 群星庭院，哨兵
	[101008] = {.8, 1, .1},		-- 黑鸦堡垒，针刺虫群
	
	-- Raids
	[175992] = {.8, 1, .1},		-- 猩红议会，忠实的侍从
	[165762] = {.8, 1, .1},		-- 凯子，灵能灌注者
}

C.UnitTarget = {
	-- Show fixed target: NPC IDs
	[165251] = true,	-- 迷霧的追人狐狸
	[174773] = true,	-- 惡意詞綴，憎恨幽影
	[190174] = true,	-- 惡意詞綴，憎恨幽影
	[190174] = true,	-- 隱蔽詞綴，催眠蝙蝠
}

C.UnitSpellTarget = {
	-- Show Spell target: NPC IDs
	[61672] = true,	-- 隱蔽詞綴，催眠蝙蝠
}

C.ShowPower = {
	-- show power: NPC IDs
	[133944] = true,	-- 神廟，艾斯匹
	[133379] = true,	-- 神廟，阿德利斯
	[165556] = true,	-- 血紅深淵，瞬息具象
	[171557] = true,	-- 猎手阿尔迪莫，巴加斯特之影
	[165556] = true,	-- 血紅深淵，瞬息具象
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
	[296847] = true,
	[338906] = true,
}

C.RaidAuraList = {
-- Death Knight
    [48707] = true, --Anti-Magic Shell
    [48792] = true, --Icebound Fortitude
    [287081] = true, --Lichborne
    [55233] = true, --Vampiric Blood
    [194679] = true, --Rune Tap
    [145629] = true, --Anti-Magic Zone
    [81256] = true, --Dancing Rune Weapon

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
    [22812] = true, --Barkskin
    [61336] = true, --Survival Instincts
    [5215] = true, --Prowl

    -- Hunter
    [186265] = true, --Aspect of the Turtle
    [53480] = true, --Roar of Sacrifice
    [264735] = true, --Survival of the Fittest (Pet Ability)
    [281195] = true, --Survival of the Fittest (Lone Wolf)
    [199483] = true, --Camouflage

    -- Mage
    [45438] = true, --Ice Block
    [66] = true, --Invisibility
    [198111] = true, --Temporal Shield
    [113862] = true, --Greater Invisibility
    [342246] = true, --Alter Time
    [110909] = true,
    [108978] = true,

    -- Monk
    [125174] = true, --Touch of Karma
    [120954] = true, --Fortifying Brew (Brewmaster)
    [243435] = true, --Fortifying Brew (Mistweaver)
    [201318] = true, --Fortifying Brew (Windwalker)
    [115176] = true, --Zen Meditation
    [116849] = true, --Life Cocoon
    [122278] = true, --Dampen Harm
    [122783] = true, --Diffuse Magic

    -- Paladin
    [204018] = true, --Blessing of Spellwarding
    [642] = true, --Divine Shield
    [228050] = true, --Divine Shield (Protection)
    [1022] = true, --Blessing of Protection
    [6940] = true, --Blessing of Sacrifice
    [199448] = true, --Blessing of Ultimate Sacrifice
    [498] = true, --Divine Protection
    [31850] = true, --Ardent Defender
    [86659] = true, --Guardian of Ancient Kings
    [205191] = true, --Eye for an Eye

    -- Priest
    [47788] = true, --Guardian Spirit
    [47585] = true, --Dispersion
    [33206] = true, --Pain Suppression
    [213602] = true, --Greater Fade
    [81782] = true, --Power Word: Barrier
    [271466] = true, --Luminous Barrier
    [20711] = true, --Spirit of Redemption

    -- Rogue
    [31224] = true, --Cloak of Shadows
    [45182] = true, --Cheating Death
    [5277] = true, --Evasion
    [199754] = true, --Riposte
    [1966] = true, --Feint
    [1784] = true, --Stealth

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
    [871] = true, --Shield Wall
    [118038] = true, --Die by the Sword
    [147833] = true, --Intervene
    [213915] = true, --Mass Spell Reflection
    [23920] = true, --Spell Reflection (Prot)
    [216890] = true, --Spell Reflection (Arms/Fury)
    [184364] = true, --Enraged Regeneration
    [97463] = true, --Rallying Cry
    [12975] = true, --Last Stand
    [190456] = true, --Ignore Pain

    -- Misc
    ["Eating/Drinking"] = true, -- Food umbrella
    ["Food & Drink"] = true, --Food & Drink
    ["Food"] = true, --Food
    ["Drink"] = true, --Drink
    ["Refreshment"] = true, --Refreshment
    [185710] = true, --Sugar-Crusted Fish Feast
    [320224] = true, -- Podtender
    [363522] = true, -- Gladiator's Eternal Aegis
    [345231] = true, -- Gladiator's Emblem
}