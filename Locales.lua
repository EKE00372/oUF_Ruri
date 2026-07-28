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

	L.UnitFramesDesc = "包含玩家、寵物、目標、目標的目標、焦點目標、焦點目標的目標、競技場、首領。"
	L.RaidFramesDesc = "功能簡單的團隊框架，不顯示隊友寵物。"
	L.PartyFramesDesc = "功能簡單的隊伍框架，不顯示隊友寵物。"
	L.NameplatesDesc = "功能簡單的名條。"

	L.StyleSwitch = "樣式"
	L.DisplayFrames = "框架"
	L.DisplayElements = "元素"
	L.PlayerResource = "個人資源"

	L.VerticalPlayer = "直式玩家框架"
	L.VerticalTarget = "直式目標框架"
	L.SimpleFocus = "簡易焦點框架"
	L.BossFrames = "首領框架"
	L.ArenaFrames = "競技場框架"
	L.PlayerDebuffs = "玩家減益"
	L.TankResource = "坦克資源"
	L.Fade = "閒置淡出"
	L.StandaloneCastbar = "獨立施法條"

	L.SimpleFocusTip = "數字模式的簡易焦點目標，只顯示血量百分比和必要資訊，不顯示完整框架。\n\n停用此選項則顯示與目標相同外觀的標準焦點目標框架。"
	L.TankResourceTip = "以個人資源形式顯示坦克的二層充能技能。\n\n聖騎士：鑄光者\n惡魔獵人：惡魔尖刺\n德魯伊：狂暴恢復\n武僧：清心絕釀\n戰士：盾牌格擋"
	L.FadeTip = "當你不在戰鬥中或施法狀態，滿生命值且沒有目標時，隱藏玩家框架。"
	L.StandaloneCastbarTip = "玩家、目標和非簡易模式焦點目標的獨立施法條。"

	L.NumberStyle = "數字模式"
	L.ShowAuras = "顯示光環"
	L.FriendlyClassColor = "友方職業染色"
	L.EnemyClassColor = "敵方職業染色"
	L.HighlightTargetFocus = "高亮目標和焦點"
	L.HighlightMouseover = "高亮滑鼠指向"
	L.Crosshairs = "目標準星"
	L.CrosshairsTip = "以準星標記你的當前目標。"
	L.PlayerPlate = "玩家個人資源"
	L.PlayerBuffs = "顯示增益"

	L.ReloadUI = "重載 UI"
	L.StatusApply = "設定保存後需重載 UI 套用。"
	L.StatusChanged = "設定已保存，重載 UI 後生效。"
	L.ResetOptionsConfirm = "重置 oUF_Ruri 所有設定並重載 UI？"
	L.WIP = "開發中"

elseif GetLocale() == "zhCN" then

	L.Overview = "总览"
	L.UnitFrames = "单位框架"
	L.RaidFrames = "团队框架"
	L.PartyFrames = "队伍框架"
	L.Nameplates = "姓名板"
	L.UnitFramesDesc = "包含玩家、宠物、目标、目标的目标、焦点目标、焦点目标的目标、竞技场、首领。"
	L.RaidFramesDesc = "功能简单的团队框架，不显示队友宠物。"
	L.PartyFramesDesc = "功能简单的队伍框架，不显示队友宠物。"
	L.NameplatesDesc = "功能简单的姓名板。"
	
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
	L.TankResource = "坦克资源"
	L.Fade = "闲置淡出"
	L.StandaloneCastbar = "独立施法条"
	L.SimpleFocusTip = "数字模式的简易焦点目标，只显示血量百分比和必要信息，不显示完整框架。"
	L.TankResourceTip = "以个人资源形式显示坦克的二层充能技能。\n\n圣骑士：铸光者\n恶魔猎人：恶魔尖刺\n德鲁伊：狂暴回复\n武僧：清心酒\n战士：盾牌格挡"
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
	L.StatusApply = "设置保存后需重载 UI 套用。"
	L.StatusChanged = "设置已保存，重载 UI 后生效。"
	L.ResetOptionsConfirm = "重置 oUF_Ruri 所有设置并重载 UI？"
	L.WIP = "开发中"

else

	L.Overview = "Overview"
	L.UnitFrames = "Unit Frames"
	L.RaidFrames = "Raid Frames"
	L.PartyFrames = "Party Frames"
	L.Nameplates = "Nameplates"
	L.UnitFramesDesc = "Includes Player, Pet, Target, Target of target, Focus, Focus target, Arena, and Boss frames."
	L.RaidFramesDesc = "Simple raid frames; party-member pets are not shown."
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
	L.TankResource = "Tank Resource"
	L.Fade = "Idle Fade"
	L.StandaloneCastbar = "Standalone Castbar"
	L.SimpleFocusTip = "Numeric-style simple focus target. \n\nShows only health percentage and essential info, not the full frame."
	L.TankResourceTip = "Show two-charge tank skills as player resources.\n\nPaladin: Lightsmith\nDemon Hunter: Demon Spikes\nDruid: Frenzied Regeneration\nMonk: Purifying Brew\nWarrior: Shield Block"
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
	L.StatusApply = "Reload UI to apply settings."
	L.StatusChanged = "Settings saved. Reload UI to apply."
	L.ResetOptionsConfirm = "Reset all oUF_Ruri settings and reload UI?"
	L.WIP = "WIP"

end
