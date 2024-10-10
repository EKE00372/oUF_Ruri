local addon, ns = ...
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
	-- [[ Class ]] --
    -- [[ 補足暴雪白名單裡缺少的控場法術 / Show auras not in blizzard default list ]] --

    -- Buffs
	--[1459] = true,	-- 秘法智力，測試用
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
	
	-- [[ Dungeons ]] --
	
	-- 詞綴
	--[[
    [228318] = true,	-- 狂怒
	[226510] = true,	-- 膿血
	[343502] = true,	-- 鼓舞
	[343553] = true,	-- 盡噬忿恨
	[373724] = true,	-- 鲜血屏障
	[373011] = true,	-- 伪装
	[373785] = true,	-- 大魔王伪装
    ]]--
    
    -- CATA
	[451040] = true,	-- 格瑞姆巴托，怒氣飆升/暴怒
    --[[
    -- MOP
	[113315] = true,	-- 青龙寺，强烈
	[113309] = true,	-- 青龙寺，至高能量
    -- WOD
    [164504] = true,	-- 钢铁码头，威吓
	[163689] = true,	-- 钢铁码头，血红之球
    -- Legion
    [227548] = true,	-- 卡上，烧蚀护盾
    -- BFA
    [260805] = true,	-- 庄园，聚焦之虹
	[264027] = true,	-- 庄园，结界蜡烛
    [257899] = true,	-- 自由镇，痛苦激励
	[268008] = true,	-- 神庙，毒蛇诱惑
	[260792] = true,	-- 神庙，尘土云
	[260416] = true,	-- 孢林，蜕变
    [258653] = true,	-- 阿塔达萨，魂能壁垒
	[255960] = true,	-- 阿塔达萨，强效巫毒
	[255967] = true,	-- 阿塔达萨，强效巫毒
	[255968] = true,	-- 阿塔达萨，强效巫毒
	[255970] = true,	-- 阿塔达萨，强效巫毒
	[255972] = true,	-- 阿塔达萨，强效巫毒
	[267981] = true,	-- 风暴神殿，防护光环
	[274631] = true,	-- 风暴神殿，次级铁墙祝福
	[267901] = true,	-- 风暴神殿，铁墙祝福
	[276767] = true,	-- 风暴神殿，吞噬虚空
	[268212] = true,	-- 风暴神殿，小型强化结界
	[268186] = true,	-- 风暴神殿，强化结界
	[263246] = true,	-- 风暴神殿，闪电之盾
	[257597] = true,	-- 矿区，艾泽里特的灌注
    [269302] = true,    -- 矿区，淬毒之刃
    -- SL
    [327416] = true,	-- 晋升高塔，心能回灌
	[317936] = true,	-- 晋升高塔，弃誓信条
	[327812] = true,	-- 晋升高塔，振奋英气
	[339917] = true,	-- 晋升高塔，命运之矛
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
	[326450] = true,	-- 贖罪之殿，忠實野獸]]--
	[343558] = true,	-- 死靈戰地，病态凝视
	[343470] = true,	-- 死靈戰地，碎骨之盾
	[328351] = true,	-- 死靈戰地，染血长枪
	--[[[322433] = true,	-- 血紅深淵，石肤术
	[321402] = true,	-- 血紅深淵，饱餐]]--
    [323149] = true,	-- 仙林，黑暗之拥
	[322569] = true,	-- 仙林，兹洛斯之手
    --[[[355147] = true,	-- 集市，鱼群鼓舞
	[355057] = true,	-- 集市，鱼人战吼
	[351088] = true,	-- 集市，圣物联结
	[355640] = true,	-- 集市，重装方阵
	[355783] = true,	-- 集市，力量增幅
	[347840] = true,	-- 集市，野性
	[347015] = true,	-- 集市，强化防御
	[355934] = true,	-- 集市，强光屏障
	[349933] = true,	-- 集市，狂热鞭笞协议
	[350931] = true,	-- 爬塔，软泥免疫
    -- DF
    [384148] = true,	-- 蕨皮，诱捕陷阱
	[200672] = true,	-- 巢穴，水晶迸裂
	[377724] = true,	-- 提尔，小怪易伤
	[413027] = true,	-- 永恒黎明，泰坦之壁
    [372824] = true,	-- 奈萨鲁斯，燃烧锁链
    -- TWW
    ]]--
	
	-- [[ Raids ]] --
}

C.BlackList = {
	--[116189] = true,	-- 嘲心嘯，測試
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
    -- [[ Class ]] --
    
    -- DH Condemned Demon
    --[169430]
	--[169428]
	--[168932]
	--[169425]
	--[169429]
	--[169421]
	--[169426]   

    -- [[ Dungeons ]] --

    -- 詞綴
	--[204560] = {.7, .95, 1}, 	-- 詞綴，無形生命
	--[174773] = {.7, .95, 1}, 	-- 詞綴，懷恨幽影
	[229537] = {.7, .95, 1}, 	-- 詞綴，虛無特使
	--[120651] = {.7, .95, 1}, 	-- 詞綴，易爆
	--[190128] = {.7, .95, 1}, 	-- 詞綴，隱蔽的祖爾佳穆克斯

    --[[
    -- CATA
    [52019]  = {.8, 1, .1},     -- 坠天新星，旋云之巅
    -- MOP
    -- WOD
    [84400]  = {.8, 1, .1},		-- 繁盛古树，永茂林地
    -- Legion
    [92538]  = {.8, 1, .1},		-- 喷油蛆虫，巢穴
    [101008] = {.8, 1, .1},		-- 黑鸦堡垒，针刺虫群
	[190174] = {.8, 1, .1}, 	-- 眾星之庭，催眠蝙蝠
    [104251] = {.8, 1, .1},		-- 眾星之庭，哨兵
    -- BFA
    [137103] = {.8, 1, .1},		-- 血面兽，地渊
    [135764] = {.8, 1, .1},		-- 諸王之眠，爆裂圖騰
	[137591] = {.8, 1, .1},		-- 諸王之眠，療癒之潮圖騰
	[130896] = {.8, 1, .1},		-- 自由港，昏厥酒桶
    -- SL
    [169498] = {.8, 1, .1},		-- 瘟疫之臨，瘟疫彈
	[170851] = {.8, 1, .1},		-- 瘟疫之臨，爆燃瘟疫彈
	[165556] = {.8, 1, .1},		-- 血紅深淵，瞬息具象]]--
	[165251] = {.8, 1, .1},		-- 仙林，幻影仙狐
	--[[[170234] = {.8, 1, .1},		-- 伤逝剧场，压制战旗
	[164464] = {.8, 1, .1},		-- 伤逝剧场，卑劣的席拉
	[171341] = {.8, 1, .1},		-- 彼界，幼鹤
	[175576] = {.8, 1, .1},		-- 集市，监禁
	[179733] = {.8, 1, .1},     -- 集市，鱼串
	[180433] = {.8, 1, .1},		-- 集市，流浪的脉冲星
    -- DF
    [199368] = {.8, 1, .1},     -- 硬化的水晶，碧蓝魔馆
    [196548] = {.8, 1, .1},     -- 學院，古樹樹枝
    [190426] = {.8, 1, .1},		-- 腐朽图腾，蕨皮
	[190381] = {.8, 1, .1},		-- 腐爆图腾，蕨皮
	[186696] = {.8, 1, .1},		-- 撼地图腾，提尔
    -- TWW
    ]]--
	
	-- [[ Raids ]] --
	--[175992] = {.8, 1, .1},		-- 猩红议会，忠实的侍从
	--[165762] = {.8, 1, .1},		-- 凯子，灵能灌注者
}

-- [[ Show fixed target: NPC IDs ]] --
C.UnitTarget = {
	[165251] = true,	-- 迷霧，追人狐狸
	[174773] = true,	-- 惡意詞綴，憎恨幽影
	[40357]  = true,    -- 格瑞姆巴托，被喚來的暗焰靈魂
	--[190174] = true,	-- 眾星之庭，催眠蝙蝠
}

-- [[ Show Spell target: NPC IDs ]] --
C.UnitSpellTarget = {
    [128967] = true,    -- 圍攻，狙擊手
    [166301] = true,    -- 迷霧，潛獵者
    [214350] = true,    -- 石庫，變異代言者

}

-- [[ show power: NPC IDs ]] --
C.ShowPower = {
    -- [[ Dungeons ]] --

    -- MOP
	--[56792] = true,	-- 青龙寺，怀疑臆象
    -- Legion
    --[114247] = true,	-- 卡上，馆长
    -- BFA
	--[133944] = true,	-- 神廟，艾斯匹
	--[133379] = true,	-- 神廟，阿德利斯
	--[165556] = true,	-- 血紅深淵，瞬息具象
	
	--[163746] = true,	-- 垃圾场，步行震击者X1型

    -- [[ Raids ]] --

    --[171557] = true,	-- 猎手阿尔迪莫，巴加斯特之影
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
	[206151] = true,    -- 挑戰者的重擔
	--[25163] = true,   -- 軟泥怪
	[271544] = true,    -- 消蝕防護
	[296847] = true,    -- 压迫光环
	[338906] = true,    -- 典狱长之链
}

C.RaidBuffList = {
    -- list taked from BuffOverlay
	-- Death Knight
    [48707]  = true, -- 反魔法護罩 / Anti-Magic Shell
    [48792]  = true, -- 冰錮堅韌 / Icebound Fortitude
    [49039]  = true, -- 巫妖之軀 / Lichborne
    [55233]  = true, -- 血族之裔 / Vampiric Blood
    [194679] = true, -- 符文轉化 / Rune Tap
    [145629] = true, -- 反魔法力場 / Anti-Magic Zone
    [81256]  = true, -- 符文武器幻舞 / Dancing Rune Weapon
    --[410305] = true, -- PVP 血鑄護甲 / Bloodforged Armor
    --[48265] = true, -- 死神逼近 / 
    --[3714] = true, -- 冰霜之徑 / 

    -- Demon Hunter
    [196555] = true, -- 虛空穿越 / Netherwalk
    [209426] = true, -- 黑暗 / Darkness
    --[206804] = true, -- PVP 從天而降 / Rain from Above
    [187827] = true, -- 復仇惡魔化身 / Metamorphosis (Vengeance)
    [212800] = true, -- 殘影 / Blur
    [263648] = true, -- 靈魂屏障 / Soul Barrier

    -- Druid
    --[203554] = true, -- PVP 集中生長 / Focused Growth
    --[362486] = true, -- PVP 保護自然 / Tranquility (Druid PVP)
    [22842]  = true, -- 狂暴恢復 / Frenzied Regeneration
    [102342] = true, -- 鐵樹皮術 / Ironbark
    [22812]  = true, -- 樹皮術 / Barkskin
    [61336]  = true, -- 求生本能 / Survival Instincts
    [5215]   = true, -- 潛行 / Prowl
    --[106898]  = true, -- 熊奔竄咆哮
    --[77764]  = true, -- 貓奔竄咆哮
    [1850]    = true, -- 突進
    [252216]  = true, -- 虎豹突進
    --[102560]  = true, -- 鳥化身
    [102558]  = true, -- 熊化身
    --[102543]  = true, -- 貓化身
    [117679]  = true, -- 樹化身
    --[157982]  = true, -- 寧靜

    -- Evoker
    --[378441] = true, -- PVP 時間停止 / Time Stop
    [363916] = true, -- 黑曜鱗片 / Obsidian Scales
    [357170] = true, -- 時間擴張 / Time Dilation
    --[383005] = true, -- PVP 時光迴圈 / Chrono Loop
    [374348] = true, -- 再生烈焰 / Renewing Blaze
    [370960] = true, -- 翡翠共融 / Emerald Communion
    [363534] = true, -- 時光倒轉 / Rewind
    [404381] = true, -- 抗拒命運 / Defy Fate
    [375234] = true, -- 時間螺旋
    [406732] = true, -- 時空悖論
    [374227] = true, -- 輕風

    -- Hunter
    [186265] = true, -- 巨龜守護 / Aspect of the Turtle
    [202748] = true, -- 求生戰術 / Survival Tactics
    [53480]  = true, -- 犧牲咆哮 / Roar of Sacrifice
    [264735] = true, -- 適者生存(帶寵) / Survival of the Fittest (Pet Ability)
    [281195] = true, -- 適者生存(孤狼) / Survival of the Fittest (Lone Wolf)
    [388035] = true, -- 熊之堅韌 / Fortitude of the Bear
    [199483] = true, -- 偽裝 / Camouflage

    -- Mage
    [45438]  = true, -- 寒冰屏障 / Ice Block
    [41425]  = true, -- 體溫過低 / Hypothermia
    [414658] = true, -- 冰脈鎮體 / Ice Cold
    [66]     = true, -- 隱形術(前搖) / Invisibility
    [32612]  = true, -- 隱形術(隱形) / Invisibility
    [414664] = true, -- 群體隱形術 / Mass Invisibility
    --[198111] = true, -- PVP 時光護盾 / Temporal Shield
    [113862] = true, -- 強效隱形 / Greater Invisibility
    [342246] = true, -- 時光倒轉 / Alter Time

    -- Monk
    --[353319] = true, -- PVP 和平編織者 / Peaceweaver
    [125174] = true, -- 乾坤挪移 / Touch of Karma
    --[202577] = true, -- PVP 迷霧護體 / Dome of Mist
    [120954] = true, -- 酒石形絕釀 / Fortifying Brew (Brewmaster)
    [115176] = true, -- 冥思禪功 / Zen Meditation
    [116849] = true, -- 氣繭護體 / Life Cocoon
    [122278] = true, -- 卸勁訣 / Dampen Harm
    [122783] = true, -- 祛魔訣 / Diffuse Magic
    [116841] = true, -- 猛虎出匣

    -- Paladin
    [204018] = true, -- 抗咒 / Blessing of Spellwarding
    [642]    = true, -- 聖盾術 / Divine Shield
    --[228050] = true, -- PVP 女王 / Divine Shield (Protection)
    [1022]   = true, -- 保護 / Blessing of Protection
    [25771]  = true, -- 自律 / Forbearance
    [6940]   = true, -- 犧牲 / Blessing of Sacrifice
    [199448] = true, -- 犧牲 / Blessing of Ultimate Sacrifice
    [498]    = true, -- 聖佑術(神聖) / Divine Protection
    [403876] = true, -- 聖佑術(懲戒) / Divine Protection
    [31850]  = true, -- 忠誠防衛者 / Ardent Defender
    [86659]  = true, -- 諸王 / Guardian of Ancient Kings
    [205191] = true, -- 以眼還眼 / Eye for an Eye
    [184662] = true, -- 復仇聖盾 / Shield of Vengeance
    [31821]  = true, -- 精通光環 / Aura Mastery
    [327193] = true, -- 榮耀時刻 / Moment of Glory
    [1044]   =   true, -- 自由

    -- Priest
    --[197268]  = true, -- PVP 希望曙光 / Ray of Hope
    [47788]  = true, -- 守護聖靈 / Guardian Spirit
    [27827]  = true, -- 救贖之靈(死) / Spirit of Redemption
    [215769] = true, -- 救贖之靈(活) / Spirit of the Redeemer
    [586]    = true, -- 漸隱術 / Fade
    [47585]  = true, -- 影散 / Dispersion
    [33206]  = true, -- 痛苦鎮壓 / Pain Suppression
    [81782]  = true, -- 真言術壁 / Power Word: Barrier
    [271466] = true, -- 光輝屏障 / Luminous Barrier
    [19236]  = true, -- 絕望禱言 / Desperate Prayer
    [64844]  = true, -- 神聖禮頌 / Divine Hymn

    -- Rogue
    [31224]  = true, -- 暗影披風 / Cloak of Shadows
    [45182]  = true, -- 死亡謊言 / Cheating Death
    [5277]   = true, -- 閃避 / Evasion
    [1966]   = true, -- 佯攻 / Feint
    [1784]   = true, -- 潛行 / Stealth
    [11327]  = true, -- 消失 / Vanish
    [114018] = true, -- 隱蔽護罩(自己) / Shroud of Concealment
    [115834] = true, -- 隱蔽護罩(隊友) / Shroud of Concealment

    -- Shaman
    -- [409293]  = true, -- PVP 鑽地 / Burrow
    [108271] = true, -- 星界轉移 / Astral Shift
    [118337] = true, -- 硬化外皮 / Harden Skin
    [201633] = true, -- 大地盾牆圖騰 / Earthen Wall Totem
    [325174] = true, -- 靈魂連結圖騰 / Spirit Link Totem
    [207498] = true, -- 先祖保護圖騰 / Ancestral Protection Totem
    --[8178] = true, -- PVP 根基圖騰 / Grounding Totem
    --[462844/114893] = true, -- 石之壁壘圖騰

    -- Warlock
    [212295] = true, -- 虛空結界 / Nether Ward
    [104773] = true, -- 心志堅定 / Unending Resolve
    [108416] = true, -- 黑暗契約 / Dark Pact

    -- Warrior
    [871]    = true, -- 盾牆 / Shield Wall
    [118038] = true, -- 劍下亡魂 / Die by the Sword
    [147833] = true, -- 阻擾 / Intervene
    --[213915] = true, -- PVP 法術反彈 / Mass Spell Reflection
    [23920]  = true, -- 法術反射 / Spell Reflection (Prot)
    [184364] = true, -- 狂怒恢復 / Enraged Regeneration
    [97463]  = true, -- 振奮咆哮 / Rallying Cry
    [12975]  = true, -- 破釜沉舟 / Last Stand
    --[190456] = true, -- 無視苦痛 / Ignore Pain
    --[213871] = true, -- PVP 保鏢 / Bodyguard
    --[424655] = true, -- PVP 安全守護 / Safeguard


    -- Misc
    [58984]  = true,  -- 影遁 / Shadowmeld
}