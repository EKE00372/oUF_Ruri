local _, ns = ...
local C = ns[1]

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
	--[451040] = true,	-- 格瑞姆巴托，怒氣飆升/暴怒
    
    -- MOP
	--[113315] = true,	-- 青龙寺，强烈
	--[113309] = true,	-- 青龙寺，至高能量
    -- WOD
    --[164504] = true,	-- 钢铁码头，威吓
	--[163689] = true,	-- 钢铁码头，血红之球
    -- Legion
    --[227548] = true,	-- 卡上，烧蚀护盾
    -- BFA
    --[[[260805] = true,	-- 庄园，聚焦之虹
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
    [293724] = true,	-- 车间，护盾发生器]]--
    -- SL
    --[[[327416] = true,	-- 晋升高塔，心能回灌
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
	[333227] = true,	-- 彼界，不死之怒]]--
	[326771] = true,	-- 贖罪之殿，石之看守者
	[326450] = true,	-- 贖罪之殿，忠實野獸
	--[[[343558] = true,	-- 死靈戰地，病态凝视
	[343470] = true,	-- 死靈戰地，碎骨之盾
	[328351] = true,	-- 死靈戰地，染血长枪
	[322433] = true,	-- 血紅深淵，石肤术
	[321402] = true,	-- 血紅深淵，饱餐
    [323149] = true,	-- 仙林，黑暗之拥
	[322569] = true,	-- 仙林，兹洛斯之手]]--
    [355147] = true,	-- 集市，鱼群鼓舞
	[355057] = true,	-- 集市，鱼人战吼
	[351088] = true,	-- 集市，圣物联结
	[355640] = true,	-- 集市，重装方阵
	[355783] = true,	-- 集市，力量增幅
	[347840] = true,	-- 集市，野性
	[347015] = true,	-- 集市，强化防御
	[355934] = true,	-- 集市，强光屏障
	[349933] = true,	-- 集市，狂热鞭笞协议
	--[[[350931] = true,	-- 爬塔，软泥免疫]]--
    -- DF
    --[[[384148] = true,	-- 蕨皮，诱捕陷阱
	[200672] = true,	-- 巢穴，水晶迸裂
	[377724] = true,	-- 提尔，小怪易伤
	[413027] = true,	-- 永恒黎明，泰坦之壁
    [372824] = true,	-- 奈萨鲁斯，燃烧锁链]]--
    -- TWW
    
	
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
	[469882] = true,	-- 淬練之火
	[370794] = true,	-- 滯留冰霜火花
    [204301] = true,	-- 祝福之錘
	[452229] = true,	-- 回音之城，飾品紅蛋
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
	[57723] = true,   -- 精疲力竭 / Exhaustion
	[57724] = true,   -- 精神亢奮 / Sated
	[80354] = true,   -- 時光位移 / Temporal Displacement
	[95809] = true,   -- 瘋狂 / Insanity
	[160455] = true,  -- 疲倦 / Fatigued
	[264689] = true,  -- 疲倦 / Fatigued
	[390435] = true,  -- 精疲力竭 / Exhaustion
	[26013] = true,   -- 逃亡者 / Deserter
	[71041] = true,   -- 地城逃亡者 / Dungeon Deserter
	[1313593] = true, -- 逃亡者 / Deserter
	[206151] = true,  -- 挑戰者的重擔 / Challenger's Burden
	[308312] = true,  -- 限時試煉練習 / Time Trial Practice
	[1254550] = true, -- 秘法活化 / Arcane Empowerment
}

C.RaidWhiteList = {

    [58984] = true,      -- [輔助] 影遁 / Shadowmeld

    -- Death Knight

    [48707] = true,      -- [個人] 反魔法護罩 / Anti-Magic Shell
    [444741] = true,     -- [個人] 反魔法護罩 / Anti-Magic Shell
    [48792] = true,      -- [個人] 冰錮堅韌 / Icebound Fortitude
    -- [49039] = true,   -- [個人] 巫妖之軀 / Lichborne
    [55233] = true,      -- [個人] 血族之裔 / Vampiric Blood
    -- [101568] = true,  -- [個人] 黑暗救贖 / Dark Succor
    [145629] = true,     -- [團隊] 反魔法力場 / Anti-Magic Zone
    [48265] = true,      -- [輔助] 死神逼近 / Death's Advance
    [212552] = true,     -- [輔助] 闇境靈行 / Wraith Walk
    [444347] = true,     -- [輔助] 死亡戰騎 / Death Charge
    [3714] = true,       -- [輔助] 冰霜之徑 / Path of Frost

    -- Demon Hunter

    -- [442715] = true,  -- [個人] 刃禦 / Blade Ward
    [212800] = true,     -- [個人] 殘影 / Blur
    -- [1266616] = true, -- [個人] 惡魔靜默 / Demon Muzzle
    -- [427912] = true,  -- [個人] 獻祭光環 / Immolation Aura
    -- [258920] = true,  -- [個人] 獻祭光環 / Immolation Aura
    [187827] = true,     -- [個人] 惡魔化身 / Metamorphosis
    [207771] = true,     -- [個人] 熾炎烙印 / Fiery Brand
    [209426] = true,     -- [團隊] 黑暗 / Darkness

    -- Druid

    [22812] = true,      -- [個人] 樹皮術 / Barkskin
    [22842] = true,      -- [個人] 狂暴恢復 / Frenzied Regeneration
    -- [192081] = true,  -- [個人] 鋼鐵毛皮 / Ironfur
    [61336] = true,      -- [個人] 求生本能 / Survival Instincts
    [393903] = true,     -- [個人] 熊之活力 / Ursine Vigor
    [1261872] = true,    -- [個人] 野性之心 / Heart of the Wild
    [102558] = true,     -- [個人] 化身：厄索克守護者 / Incarnation: Guardian of Ursoc
    [740] = true,        -- [團隊] 寧靜 / Tranquility
    [117679] = true,     -- [團隊] 化身：生命之樹 / Incarnation: Tree of Life
    [102342] = true,     -- [輔助] 鐵樹皮術 / Ironbark
    [1850] = true,       -- [輔助] 突進 / Dash
    [106898] = true,     -- [輔助] 奔竄咆哮 / Stampeding Roar
    [77761] = true,      -- [輔助] 奔竄咆哮 / Stampeding Roar
    [77764] = true,      -- [輔助] 奔竄咆哮 / Stampeding Roar
    [252216] = true,     -- [輔助] 虎豹突進 / Tiger Dash
    [5215] = true,       -- [輔助] 潛行 / Prowl
    -- [340546] = true,  -- [輔助] 堅定追擊 / Tireless Pursuit
    -- [400126] = true,  -- [輔助] 森林漫步 / Forestwalk
    [29166] = true,      -- [輔助] 啟動 / Innervate

    -- Evoker

    [404381] = true,     -- [個人] 抗拒命運 / Defy Fate
    [363916] = true,     -- [個人] 黑曜鱗片 / Obsidian Scales
    [374349] = true,     -- [個人] 再生烈焰 / Renewing Blaze
    -- [359816] = true,  -- [團隊] 夢境飛翔 / Dream Flight
    [363534] = true,     -- [團隊] 時光倒轉 / Rewind
    [374227] = true,     -- [團隊] 輕風 / Zephyr
    [357170] = true,     -- [輔助] 時間擴張 / Time Dilation
    -- [373267] = true,  -- [輔助] 生命守縛 / Lifebind
    [358267] = true,     -- [輔助] 盤旋 / Hover
    [358733] = true,     -- [輔助] 滑翔 / Glide
    [370889] = true,     -- [輔助] 雙生守護者 / Twin Guardian
    [375234] = true,     -- [輔助] 時間螺旋 / Time Spiral
    [375226] = true,     -- [輔助] 時間螺旋 / Time Spiral
    [375229] = true,     -- [輔助] 時間螺旋 / Time Spiral
    [375230] = true,     -- [輔助] 時間螺旋 / Time Spiral
    [375238] = true,     -- [輔助] 時間螺旋 / Time Spiral
    [375240] = true,     -- [輔助] 時間螺旋 / Time Spiral
    [375252] = true,     -- [輔助] 時間螺旋 / Time Spiral
    [375253] = true,     -- [輔助] 時間螺旋 / Time Spiral
    [375254] = true,     -- [輔助] 時間螺旋 / Time Spiral
    [375255] = true,     -- [輔助] 時間螺旋 / Time Spiral
    [375256] = true,     -- [輔助] 時間螺旋 / Time Spiral
    [375257] = true,     -- [輔助] 時間螺旋 / Time Spiral
    [375258] = true,     -- [輔助] 時間螺旋 / Time Spiral
    [406732] = true,     -- [輔助] 空間悖論 / Spatial Paradox
    [406789] = true,     -- [輔助] 空間悖論 / Spatial Paradox

    -- Hunter

    [186265] = true,     -- [個人] 巨龜守護 / Aspect of the Turtle
    [202748] = true,     -- [個人][PvP] 求生戰術 / Survival Tactics
    [472708] = true,     -- [個人] 龜殼掩護 / Shell Cover
    [264735] = true,     -- [個人] 適者生存 / Survival of the Fittest
    [53480] = true,      -- [輔助] 犧牲咆哮 / Roar of Sacrifice
    [186257] = true,     -- [輔助] 獵豹守護 / Aspect of the Cheetah
    [186258] = true,     -- [輔助] 獵豹守護 / Aspect of the Cheetah
    [118922] = true,     -- [輔助] 疾影術 / Posthaste
    [5384] = true,       -- [輔助] 假死 / Feign Death
    [199483] = true,     -- [輔助] 偽裝 / Camouflage
    [1267208] = true,    -- [輔助] 把握良機 / Moment of Opportunity
    [1224810] = true,    -- [輔助] 主人的呼喚 / Master's Call
    [54216] = true,      -- [輔助] 主人的呼喚 / Master's Call
    [62305] = true,      -- [輔助] 主人的呼喚 / Master's Call

    -- Mage

    [342246] = true,     -- [個人] 時光倒轉 / Alter Time
    -- [235313] = true,  -- [個人] 熾炎屏障 / Blazing Barrier
    -- [11426] = true,   -- [個人] 寒冰護體 / Ice Barrier
    [45438] = true,      -- [個人] 寒冰屏障 / Ice Block
    [414658] = true,     -- [個人] 冰脈鎮體 / Ice Cold
    -- [235450] = true,  -- [個人] 稜彩屏障 / Prismatic Barrier
    [449336] = true,     -- [個人] 愈挫愈勇 / Merely a Setback
    [1309793] = true,    -- [個人] 增幅折射 / Amplified Refraction
    [444754] = true,     -- [輔助] 滑溜拋法 / Slippery Slinging
    [130] = true,        -- [輔助] 緩落術 / Slow Fall
    [55342] = true,      -- [輔助] 鏡像 / Mirror Image
    [108843] = true,     -- [輔助] 熾烈迅捷 / Blazing Speed
    [66] = true,         -- [輔助] 隱形術（漸隱）/ Invisibility
    [32612] = true,      -- [輔助] 隱形術（完全隱形）/ Invisibility
    [110960] = true,     -- [輔助] 強效隱形 / Greater Invisibility
    [382294] = true,     -- [輔助] 迅捷咒術 / Incantation of Swiftness

    -- Monk

    [122783] = true,     -- [個人] 祛魔訣 / Diffuse Magic
    [120954] = true,     -- [個人] 石形絕釀 / Fortifying Brew
    [125174] = true,     -- [個人] 乾坤挪移 / Touch of Karma
    [132578] = true,     -- [個人] 召喚玄牛怒兆 / Invoke Niuzao, the Black Ox
    [322507] = true,     -- [個人] 天尊絕釀 / Celestial Brew
    [1241059] = true,    -- [個人] 星界灌注 / Celestial Infusion
    -- [432180] = true,  -- [個人] 風之舞 / Dance of the Wind
    [116849] = true,     -- [輔助] 氣繭護體 / Life Cocoon
    -- [119085] = true,  -- [輔助] 真氣飛龍穿 / Chi Torpedo
    -- [443569] = true,  -- [輔助] 赤吉迅捷 / Chi-Ji's Swiftness
    [116841] = true,     -- [輔助] 猛虎出閘 / Tiger's Lust
    -- [394112] = true,  -- [輔助] 逃離現實 / Escape from Reality
    -- [449609] = true,  -- [輔助] 身輕如燕 / Lighter Than Air

    -- Paladin

    [498] = true,        -- [個人] 聖佑術 / Divine Protection
    [403876] = true,     -- [個人] 聖佑術 / Divine Protection
    [642] = true,        -- [個人] 聖盾術 / Divine Shield
    -- [184662] = true,  -- [個人] 復仇聖盾 / Shield of Vengeance
    [31850] = true,      -- [個人] 忠誠防衛者 / Ardent Defender
    [86659] = true,      -- [個人] 遠古諸王守護者 / Guardian of Ancient Kings
    [212641] = true,     -- [個人] 遠古諸王守護者 / Guardian of Ancient Kings
    [31821] = true,      -- [團隊] 精通光環 / Aura Mastery
    [317929] = true,     -- [團隊] 精通光環 / Aura Mastery
    [1022] = true,       -- [輔助] 保護祝福 / Blessing of Protection
    [6940] = true,       -- [輔助] 犧牲祝福 / Blessing of Sacrifice
    [204018] = true,     -- [輔助] 抗咒祝福 / Blessing of Spellwarding
    [387804] = true,     -- [輔助] 保護迴響 / Echoing Protection
    -- [276111] = true,  -- [輔助] 神性戰馬 / Divine Steed
    -- [221886] = true,  -- [輔助] 神性戰馬 / Divine Steed
    -- [221883] = true,  -- [輔助] 神性戰馬 / Divine Steed
    -- [276112] = true,  -- [輔助] 神性戰馬 / Divine Steed
    -- [254474] = true,  -- [輔助] 神性戰馬 / Divine Steed
    -- [254472] = true,  -- [輔助] 神性戰馬 / Divine Steed
    -- [254471] = true,  -- [輔助] 神性戰馬 / Divine Steed
    -- [221885] = true,  -- [輔助] 神性戰馬 / Divine Steed
    -- [254473] = true,  -- [輔助] 神性戰馬 / Divine Steed
    -- [363608] = true,  -- [輔助] 神性戰馬 / Divine Steed
    -- [294133] = true,  -- [輔助] 神性戰馬 / Divine Steed
    -- [221887] = true,  -- [輔助] 神性戰馬 / Divine Steed
    -- [453804] = true,  -- [輔助] 神性戰馬 / Divine Steed
    [1044] = true,       -- [輔助] 自由祝福 / Blessing of Freedom

    -- Priest

    -- [114214] = true,  -- [個人] 天使之壁 / Angelic Bulwark
    [19236] = true,      -- [個人] 絕望禱言 / Desperate Prayer
    [47585] = true,      -- [個人] 影散 / Dispersion
    [586] = true,        -- [個人] 漸隱術 / Fade
    [45242] = true,      -- [個人] 意志專注 / Focused Will
    [426401] = true,     -- [個人] 意志專注 / Focused Will
    [193065] = true,     -- [個人] 保護之光 / Protective Light
    [27827] = true,      -- [個人] 救贖之靈（死亡）/ Spirit of Redemption
    [215769] = true,     -- [個人][PvP] 救贖之靈（主動）/ Spirit of Redemption
    [64843] = true,      -- [團隊] 神聖禮頌 / Divine Hymn
    [64844] = true,      -- [團隊] 神聖禮頌 / Divine Hymn
    [81782] = true,      -- [團隊] 真言術：壁 / Power Word: Barrier
    [47788] = true,      -- [輔助] 守護聖靈 / Guardian Spirit
    [33206] = true,      -- [輔助] 痛苦鎮壓 / Pain Suppression
    [10060] = true,      -- [輔助] 注入能量 / Power Infusion
    [121557] = true,     -- [輔助] 天使之羽 / Angelic Feather
    [65081] = true,      -- [輔助] 身心合一 / Body and Soul
    [111759] = true,     -- [輔助] 漂浮術 / Levitate

    -- Rogue

    [31224] = true,      -- [個人] 暗影披風 / Cloak of Shadows
    [5277] = true,       -- [個人] 閃避 / Evasion
    [1966] = true,       -- [個人] 佯攻 / Feint
    -- [185311] = true,  -- [個人] 赤紅藥瓶 / Crimson Vial
    [45182] = true,      -- [個人] 死亡謊言（觸發減傷）/ Cheating Death
    [2983] = true,       -- [輔助] 疾跑 / Sprint
    [1784] = true,       -- [輔助] 潛行 / Stealth
    [36554] = true,      -- [輔助] 暗影閃現 / Shadowstep
    [11327] = true,      -- [輔助] 消失 / Vanish
    [114018] = true,     -- [輔助] 隱蔽護罩 / Shroud of Concealment
    [115834] = true,     -- [輔助] 隱蔽護罩 / Shroud of Concealment

    -- Shaman

    [108271] = true,     -- [個人] 星界轉移 / Astral Shift
    [260881] = true,     -- [個人] 幽靈狼 / Spirit Wolf
    [325174] = true,     -- [團隊] 靈魂連結圖騰 / Spirit Link Totem
    [192082] = true,     -- [輔助] 疾風突進 / Wind Rush
    [79206] = true,      -- [輔助] 靈行者之賜 / Spiritwalker's Grace
    [58875] = true,      -- [輔助] 幽魂步伐 / Spirit Walk
    [2645] = true,       -- [輔助] 鬼魂之狼 / Ghost Wolf

    -- Warlock

    [108416] = true,     -- [個人] 黑暗契約 / Dark Pact
    [104773] = true,     -- [個人] 心志堅定 / Unending Resolve
    [132413] = true,     -- [個人] 暗影壁壘 / Shadow Bulwark
    [387636] = true,     -- [個人] 靈魂炙燃：治療石 / Soulburn: Healthstone
    [389614] = true,     -- [個人] 深淵行者 / Abyss Walker
    [212295] = true,     -- [個人][PvP] 虛空結界 / Nether Ward
    [111400] = true,     -- [輔助] 燃燒狂奔 / Burning Rush
    --[333889] = true,   -- [輔助] 惡魔支配 / Fel Domination
    --[387626] = true,   -- [輔助] 靈魂炙燃 / Soulburn
    [387633] = true,     -- [輔助] 靈魂炙燃：惡魔法陣 / Soulburn: Demonic Circle

    -- Warrior

    [118038] = true,     -- [個人] 劍下亡魂 / Die by the Sword
    [184364] = true,     -- [個人] 狂怒恢復 / Enraged Regeneration
    [190456] = true,     -- [個人] 無視苦痛 / Ignore Pain
    [1277297] = true,    -- [個人] 無視苦痛 / Ignore Pain
    [147833] = true,     -- [個人] 阻擾 / Intervene
    [23920] = true,      -- [個人] 法術反射（反射效果）/ Spell Reflection (Reflect)
    --[385391] = true,     -- [個人] 法術反射（魔法減傷）/ Spell Reflection (Magic DR)
    [871] = true,        -- [個人] 盾牆 / Shield Wall
    -- [202147] = true,  -- [個人] 重新振作 / Second Wind
    [12975] = true,      -- [個人] 破釜沉舟 / Last Stand
    [97463] = true,      -- [團隊] 振奮咆哮 / Rallying Cry
    [202164] = true,     -- [輔助] 昂首闊步 / Bounding Stride
    [1244157] = true,    -- [輔助] 刺耳怒吼 / Piercing Howl

}
