local addon, ns = ...
local C, F, G, T, L = unpack(ns)

local GetLocale = GetLocale

--===================================================--
-----------------    [[ Locales ]]    -----------------
--===================================================--

if GetLocale() == "zhTW" then

	L.Overview = "總覽"
	L.UnitFrames = "單位框架"
	L.RaidFrames = "團隊框架"
	L.PartyFrames = "隊伍框架"
	L.Nameplates = "名條"

	L.UnitFramesDesc = "包含玩家、寵物、目標、目標的目標、專注目標、專注目標的目標、競技場、首領。"
	L.RaidFramesDesc = "簡單的團隊框架，只顯示團隊，不顯示隊友寵物、主坦克和主助攻的單獨框架。"
	L.PartyFramesDesc = "簡單的隊伍框架，不顯示隊友寵物。"
	L.NameplatesDesc = "簡單的名條。"

	L.StyleSwitch = "樣式"
	L.DisplayFrames = "框架"
	L.DisplayElements = "元素"
	L.PlayerResource = "個人資源"

	L.VerticalPlayer = "直式玩家框架"
	L.VerticalTarget = "直式目標框架"
	L.SimpleFocus = "簡易專注目標"
	L.BossFrames = "首領框架"
	L.ArenaFrames = "競技場框架"
	L.PlayerDebuffs = "玩家減益"
	L.Totems = "玩家圖騰"
	L.TankResource = "坦克資源"
	L.Fade = "閒置淡出"
	L.StandaloneCastbar = "獨立施法條"

	L.SimpleFocusTip = "數字模式的簡易專注目標，只顯示血量百分比和必要資訊，不顯示完整框架。\n\n停用此選項則顯示與目標相同外觀的標準專注目標框架。"
	L.TotemsTip = "顯示簡易的玩家圖騰列，適用於|cff0070dd薩滿|r以外的職業。\n\n|cfff48cba聖騎士|r：奉獻\n|cffff7c0a德魯伊|r：林地守護者\n|cff00ff98武僧|r：雕像\n|cff8788ee術士|r：狂野小鬼\n|cffc41e3a死亡騎士|r：食屍鬼"
	L.TankResourceTip = "以個人資源形式顯示坦克的二層充能技能。\n\n|cfff48cba聖騎士|r：光鑄師\n|cffa330c9惡魔獵人|r：惡魔尖刺\n|cffff7c0a德魯伊|r：狂暴恢復\n|cff00ff98武僧|r：清心絕釀\n|cffc69b6d戰士|r：盾牌格擋"
	L.FadeTip = "當你不在戰鬥中或施法狀態，滿生命值且沒有目標時，隱藏玩家框架。"
	L.StandaloneCastbarTip = "玩家、目標和非簡易模式專注目標的獨立施法條。"

	L.NumberStyle = "數字模式"
	L.ShowAuras = "顯示光環"
	L.FriendlyClassColor = "友方職業染色"
	L.EnemyClassColor = "敵方職業染色"
	L.HighlightTargetFocus = "高亮目標和專注目標"
	L.HighlightMouseover = "高亮滑鼠指向"
	L.Crosshairs = "目標準星"
	L.CrosshairsTip = "以準星標記你的當前目標。"
	L.PlayerPlate = "玩家個人資源"
	L.PlayerBuffs = "顯示增益"

	L.ReloadUI = "重載 UI"
	L.StatusChanged = "設定已變更，重載後生效。"
	L.WIP = "開發中"

elseif GetLocale() == "zhCN" then

	L.Overview = "总览"
	L.UnitFrames = "单位框架"
	L.RaidFrames = "团队框架"
	L.PartyFrames = "队伍框架"
	L.Nameplates = "姓名板"
	L.UnitFramesDesc = "包含玩家、宠物、目标、目标的目标、焦点目标、焦点目标的目标、竞技场、首领。"
	L.RaidFramesDesc = "简单的团队框架，只显示团队，不显示队友宠物、主坦克和主助攻的独立框架。"
	L.PartyFramesDesc = "简单的队伍框架，不显示队友宠物。"
	L.NameplatesDesc = "简单的姓名板。"
	
	L.StyleSwitch = "样式"
	L.DisplayFrames = "框架"
	L.DisplayElements = "元素"
	L.PlayerResource = "个人资源"

	L.VerticalPlayer = "直式玩家框架"
	L.VerticalTarget = "直式目标框架"
	L.SimpleFocus = "简易焦点框架"
	L.BossFrames = "首领框架"
	L.ArenaFrames = "竞技场框架"
	L.PlayerDebuffs = "玩家减益"
	L.Totems = "玩家图腾"
	L.TankResource = "坦克资源"
	L.Fade = "闲置淡出"
	L.StandaloneCastbar = "独立施法条"

	L.SimpleFocusTip = "数字模式的简易焦点目标，只显示血量百分比和必要信息，不显示完整框架。"
	L.TotemsTip = "显示简易的玩家图腾列，适用于|cff0070dd萨满|r以外的职业。\n\n|cfff48cba圣骑士|r：奉献\n|cffff7c0a德鲁伊|r：林地守护者\n|cff00ff98武僧|r：雕像\n|cff8788ee术士|r：狂野小鬼\n|cffc41e3a死亡骑士|r：食尸鬼"
	L.TankResourceTip = "以个人资源形式显示坦克的二层充能技能。\n\n|cfff48cba圣骑士|r：铸光者\n|cffa330c9恶魔猎手|r：恶魔尖刺\n|cffff7c0a德鲁伊|r：狂暴回复\n|cff00ff98武僧|r：清心酒\n|cffc69b6d战士|r：盾牌格挡"
	L.FadeTip = "当你不在战斗中或施法状态，满生命值且没有目标时，隐藏玩家框架。"
	L.StandaloneCastbarTip = "玩家、目标和非简易模式焦点目标的独立施法条。"

	L.NumberStyle = "数字模式"
	L.ShowAuras = "显示光环"
	L.FriendlyClassColor = "友方职业染色"
	L.EnemyClassColor = "敌方职业染色"
	L.HighlightTargetFocus = "高亮目标和焦点"
	L.HighlightMouseover = "高亮鼠标指向"
	L.Crosshairs = "目标准星"
	L.CrosshairsTip = "以准星标记你的当前目标。"
	L.PlayerPlate = "玩家个人资源"
	L.PlayerBuffs = "显示增益"

	L.ReloadUI = "重载 UI"
	L.StatusChanged = "设置已变更，重载后生效。"
	L.WIP = "开发中"

else

	L.Overview = "Overview"
	L.UnitFrames = "Unit Frames"
	L.RaidFrames = "Raid Frames"
	L.PartyFrames = "Party Frames"
	L.Nameplates = "Nameplates"
	L.UnitFramesDesc = "Includes Player, Pet, Target, Target of target, Focus, Focus target, Arena, and Boss frames."
	L.RaidFramesDesc = "Simple raid frames; only the raid is shown. Party-member pets, main tanks, and main assists are not shown."
	L.PartyFramesDesc = "Simple party frames; party-member pets are not shown."
	L.NameplatesDesc = "Simple nameplates."

	L.StyleSwitch = "Style"
	L.DisplayFrames = "Frames"
	L.DisplayElements = "Elements"
	L.PlayerResource = "Player Resource"

	L.VerticalPlayer = "Vertical Player Frame"
	L.VerticalTarget = "Vertical Target Frame"
	L.SimpleFocus = "Simple Focus Frame"
	L.BossFrames = "Boss Frames"
	L.ArenaFrames = "Arena Frames"
	L.PlayerDebuffs = "Player Debuffs"
	L.Totems = "Player Totems"
	L.TankResource = "Tank Resource"
	L.Fade = "Idle Fade"
	L.StandaloneCastbar = "Standalone Castbar"

	L.SimpleFocusTip = "Numeric-style simple focus target. \n\nShows only health percentage and essential info, not the full frame."
	L.TotemsTip = "Show a simple player totem bar for non-|cff0070ddShaman|r classes.\n\n|cfff48cbaPaladin|r: Consecration\n|cffff7c0aDruid|r: Grove Guardians\n|cff00ff98Monk|r: Statue\n|cff8788eeWarlock|r: Wild Imps\n|cffc41e3aDeath Knight|r: Ghoul"
	L.TankResourceTip = "Show two-charge tank skills as player resources.\n\n|cfff48cbaPaladin|r: Lightsmith\n|cffa330c9Demon Hunter|r: Demon Spikes\n|cffff7c0aDruid|r: Frenzied Regeneration\n|cff00ff98Monk|r: Purifying Brew\n|cffc69b6dWarrior|r: Shield Block"
	L.FadeTip = "Hide the player frame while:\n\nOut of combat or not casting, at full health, and with no target."
	L.StandaloneCastbarTip = "Standalone castbars for:\n\nPlayer, Target, and non-simple-mode Focus target."

	L.NumberStyle = "Number Style"
	L.ShowAuras = "Show Auras"
	L.FriendlyClassColor = "Friendly Class Color"
	L.EnemyClassColor = "Enemy Class Color"
	L.HighlightTargetFocus = "Highlight Target/Focus"
	L.HighlightMouseover = "Highlight Mouseover"
	L.Crosshairs = "Target Crosshairs"
	L.CrosshairsTip = "Mark your currently selected target with crosshairs."
	L.PlayerPlate = "Player Plate"
	L.PlayerBuffs = "Show Buffs"

	L.ReloadUI = "Reload UI"
	L.StatusChanged = "Reload UI to apply settings."
	L.WIP = "WIP"

end
