local _, ns = ...
local L = ns[5]

local GetLocale = GetLocale
local GetBindingKey, GetBindingText = GetBindingKey, GetBindingText

-- 綁定需在 tooltip 顯示時讀取；插件載入階段可能尚未建立使用者按鍵設定。
local function CreateBindingTooltip(text, action)
	return function()
		local key = GetBindingKey(action)
		return text:format(GetBindingText(key))
	end
end

--===================================================--
-----------------    [[ Locales ]]    -----------------
--===================================================--

if GetLocale() == "zhTW" then

	-- Tab
	L.Overview = "總覽"
	L.UnitFrames = "單位框架"
	L.GroupFrames = "組隊框架"
	L.RaidFrames = "團隊框架"
	L.PartyFrames = "小隊框架"
	L.Nameplates = "名條"
	L.Credits = "鳴謝：\nDawn, HopeASD, ls-, p3lim, Paopao001, Peterdox, Qulight, Ray, Rhythm, Rubgrsch, Siweia, zork，排名不分先後。"

	-- Overview
	L.UnitFramesDesc = "包含玩家、寵物、目標、目標的目標、專注目標、專注目標的目標、競技場、首領。"
	L.RaidFramesDesc = "簡單的團隊框架，只顯示團隊成員，不顯示隊友寵物、主坦克和主助攻的單獨框架。"
	L.PartyFramesDesc = "簡單的小隊框架，不顯示隊友寵物。"
	L.NameplatesDesc = "簡單的名條。"

	-- subTitle
	L.StyleSwitch = "樣式"
	L.DisplayFrames = "框架"
	L.DisplayElements = "元素"
	L.Extensions = "擴充"

	-- Unitframes
	L.VerticalPlayer = "直式玩家框架"
	L.VerticalTarget = "直式目標框架"
	L.SimpleFocus = "簡易專注目標"
	L.BossFrames = "首領框架"
	L.ArenaFrames = "競技場框架"
	--L.BlizzardAuras = "原生光環美化"
	L.PlayerDebuffs = "玩家減益"
	L.Totems = "玩家圖騰"
	L.TankResource = "坦克資源"
	L.Fade = "閒置淡出"
	L.StandaloneCastbar = "獨立施法條"

	--L.BlizzardAurasTip = "美化暴雪預設的右上角光環框架。"
	L.SimpleFocusTip = "數字模式的簡易專注目標，只顯示血量百分比和必要資訊，不顯示完整框架。\n\n停用此選項則顯示與目標相同外觀的標準專注目標框架。"
	L.TotemsTip = "顯示簡易的玩家圖騰列，適用於|cff0070dd薩滿|r以外的職業。\n\n|cfff48cba聖騎士|r：奉獻\n|cffff7c0a德魯伊|r：林地守護者\n|cff00ff98武僧|r：雕像\n|cff8788ee術士|r：狂野小鬼\n|cffc41e3a死亡騎士|r：食屍鬼"
	L.TankResourceTip = "以個人資源形式顯示坦克的二層充能技能。\n\n|cfff48cba聖騎士|r：光鑄師\n|cffa330c9惡魔獵人|r：惡魔尖刺\n|cffff7c0a德魯伊|r：狂暴恢復\n|cff00ff98武僧|r：清心絕釀\n|cffc69b6d戰士|r：盾牌格擋"
	L.FadeTip = "當你不在戰鬥中、沒有施法且沒有目標時，淡出玩家與寵物框架。"
	L.StandaloneCastbarTip = "玩家、目標和非簡易模式專注目標的獨立施法條。"

	-- Raidframes
	L.HideBlizzardRaidFrames = "隱藏原生組隊框架"
	L.HideCompactRaidManager = "淡出團隊管理介面"
	L.ShowBuffAuras = "顯示增益光環"
	L.ShowDebuffAuras = "顯示減益光環"
	L.HealerManaOnly = "只顯示治療者能量"

	L.ShowBuffAurasTip = "只顯示防禦法術。"
	L.HealerManaOnlyTip = "只顯示治療者的能量條。"
	L.HideBlizzardRaidFramesTip = "只隱藏已啟用的 Ruri 組隊框架所取代的原生框架，不隱藏畫面左上角的團隊管理介面。"
	L.HideCompactRaidManagerTip = "淡出畫面左上角的團隊管理介面，滑鼠指向時顯示。"

	-- Nameplates
	L.NumberStyle = "數字模式"
	L.ShowAuras = "顯示光環"
	L.HighlightTargetFocus = "高亮目標和專注目標"
	L.HighlightMouseover = "高亮滑鼠指向"
	L.Crosshairs = "目標準星"
	L.CVars = "調整 CVar"
	L.CVarsTip = "調整一些名條的 CVar。\n\n可以在 Embeds\\CVars.lua 查看改動的 CVar 清單。"
	L.FriendlyNameSize = "調整友方名字"
	L.FriendlyNameSizeTip = CreateBindingTooltip("啟用友方名字模式，進入副本會自動開啟友方名條，隱藏血量條並使用描邊與較大字型。\n\n你可以按 %s 切換友方名條顯隱。\n\n這項功能受暴雪限制，啟用後會更改原生名條外觀。", "FRIENDNAMEPLATES")
	L.PlayerPlate = "玩家個人資源"
	L.PlayerPlateTip = "顯示血量、能量與職業資源的簡易資源條。\n\n啟用後會停用暴雪原生的玩家個人資源條。"

	-- Other
	L.ReloadUI = "重載 UI"
	L.StatusChanged = "設定已變更，重載後生效。"
	L.WIP = "開發中"

elseif GetLocale() == "zhCN" then

	-- Tab
	L.Overview = "总览"
	L.UnitFrames = "单位框架"
	L.GroupFrames = "组队框架"
	L.RaidFrames = "团队框架"
	L.PartyFrames = "小队框架"
	L.Nameplates = "姓名板"
	L.Credits = "鸣谢：\nDawn, HopeASD, ls-, p3lim, Paopao001, Peterdox, Qulight, Ray, Rhythm, Rubgrsch, Siweia, zork，排名不分先后。"

	-- Overview
	L.UnitFramesDesc = "包含玩家、宠物、目标、目标的目标、焦点目标、焦点目标的目标、竞技场、首领。"
	L.RaidFramesDesc = "简单的团队框架，只显示团队，不显示队友宠物、主坦克和主助攻的独立框架。"
	L.PartyFramesDesc = "简单的小队框架，不显示队友宠物。"
	L.NameplatesDesc = "简单的姓名板。"

	-- subTitle
	L.StyleSwitch = "样式"
	L.DisplayFrames = "框架"
	L.DisplayElements = "元素"
	L.Extensions = "扩展"

	-- Unitframes
	L.VerticalPlayer = "直式玩家框架"
	L.VerticalTarget = "直式目标框架"
	L.SimpleFocus = "简易焦点框架"
	L.BossFrames = "首领框架"
	L.ArenaFrames = "竞技场框架"
	--L.BlizzardAuras = "原生光环美化"
	L.PlayerDebuffs = "玩家减益"
	L.Totems = "玩家图腾"
	L.TankResource = "坦克资源"
	L.Fade = "闲置淡出"
	L.StandaloneCastbar = "独立施法条"

	--L.BlizzardAurasTip = "美化暴雪默认的右上角光环框架。"
	L.SimpleFocusTip = "数字模式的简易焦点目标，只显示血量百分比和必要信息，不显示完整框架。"
	L.TotemsTip = "显示简易的玩家图腾列，适用于|cff0070dd萨满|r以外的职业。\n\n|cfff48cba圣骑士|r：奉献\n|cffff7c0a德鲁伊|r：林地守护者\n|cff00ff98武僧|r：雕像\n|cff8788ee术士|r：狂野小鬼\n|cffc41e3a死亡骑士|r：食尸鬼"
	L.TankResourceTip = "以个人资源形式显示坦克的二层充能技能。\n\n|cfff48cba圣骑士|r：铸光者\n|cffa330c9恶魔猎手|r：恶魔尖刺\n|cffff7c0a德鲁伊|r：狂暴回复\n|cff00ff98武僧|r：清心酒\n|cffc69b6d战士|r：盾牌格挡"
	L.FadeTip = "当你不在战斗中、没有施法且没有目标时，淡出玩家与宠物框架。"
	L.StandaloneCastbarTip = "玩家、目标和非简易模式焦点目标的独立施法条。"

	-- Raidframes
	L.HideBlizzardRaidFrames = "隐藏原生组队框架"
	L.HideCompactRaidManager = "淡出团队管理界面"
	L.ShowBuffAuras = "显示增益光环"
	L.ShowDebuffAuras = "显示减益光环"
	L.HealerManaOnly = "只显示治疗者能量"

	L.ShowBuffAurasTip = "只显示防御法术。"
	L.HealerManaOnlyTip = "只显示治疗者的能量条。"
	L.HideBlizzardRaidFramesTip = "只隐藏已启用的 Ruri 组队框架所取代的原生框架，不隐藏画面左上角的团队管理界面。"
	L.HideCompactRaidManagerTip = "淡出画面左上角的团队管理界面，鼠标指向时显示。"

	-- Nameplates
	L.NumberStyle = "数字模式"
	L.ShowAuras = "显示光环"
	L.HighlightTargetFocus = "高亮目标和焦点"
	L.HighlightMouseover = "高亮鼠标指向"
	L.Crosshairs = "目标准星"
	L.CVars = "调整 CVar"
	L.CVarsTip = "调整一些姓名板的 CVar。\n\n可以在 Embeds\\CVars.lua 中查看改动的 CVar 列表。"
	L.FriendlyNameSize = "调整友方名字"
	L.FriendlyNameSizeTip = CreateBindingTooltip("启用友方名字模式，进入副本会自动开启友方姓名板，隐藏血量条并使用描边和较大字体。\n\n你可以按 %s 切换友方姓名板的显示与隐藏。\n\n此功能受暴雪限制，启用后会更改原生姓名板外观。", "FRIENDNAMEPLATES")
	L.PlayerPlate = "玩家个人资源"
	L.PlayerPlateTip = "显示血量、能量与职业资源的简易资源条。启用后会停用暴雪原生的玩家个人资源条。"

	-- Other
	L.ReloadUI = "重载 UI"
	L.StatusChanged = "设置已变更，重载后生效。"
	L.WIP = "开发中"

else

	-- Tab
	L.Overview = "Overview"
	L.UnitFrames = "Unit Frames"
	L.GroupFrames = "Group Frame"
	L.RaidFrames = "Raid Frames"
	L.PartyFrames = "Party Frames"
	L.Nameplates = "Nameplates"
	L.Credits = "Credits (in no particular order): \nDawn, HopeASD, ls-, p3lim, Paopao001, Peterdox, Qulight, Ray, Rhythm, Rubgrsch, Siweia, zork."

	-- Overview
	L.UnitFramesDesc = "Includes Player, Pet, Target, Target of target, Focus, Focus target, Arena, and Boss frames."
	L.RaidFramesDesc = "Simple raid frames; only the raid is shown. Party-member pets, main tanks, and main assists are not shown."
	L.PartyFramesDesc = "Simple party frames; party-member pets are not shown."
	L.NameplatesDesc = "Simple nameplates."

	-- subTitle
	L.StyleSwitch = "Style"
	L.DisplayFrames = "Frames"
	L.DisplayElements = "Elements"
	L.Extensions = "Extensions"

	-- Unitframes
	L.VerticalPlayer = "Vertical Player Frame"
	L.VerticalTarget = "Vertical Target Frame"
	L.SimpleFocus = "Simple Focus Frame"
	L.BossFrames = "Boss Frames"
	L.ArenaFrames = "Arena Frames"
	--L.BlizzardAuras = "Blizzard Aura Styling"
	L.PlayerDebuffs = "Player Debuffs"
	L.Totems = "Player Totems"
	L.TankResource = "Tank Resource"
	L.Fade = "Idle Fade"
	L.StandaloneCastbar = "Standalone Castbar"

	--L.BlizzardAurasTip = "Styles Blizzard's default aura frames in the upper-right corner."
	L.SimpleFocusTip = "Numeric-style simple focus target. \n\nShows only health percentage and essential info, not the full frame."
	L.TotemsTip = "Show a simple player totem bar for non-|cff0070ddShaman|r classes.\n\n|cfff48cbaPaladin|r: Consecration\n|cffff7c0aDruid|r: Grove Guardians\n|cff00ff98Monk|r: Statue\n|cff8788eeWarlock|r: Wild Imps\n|cffc41e3aDeath Knight|r: Ghoul"
	L.TankResourceTip = "Show two-charge tank skills as player resources.\n\n|cfff48cbaPaladin|r: Lightsmith\n|cffa330c9Demon Hunter|r: Demon Spikes\n|cffff7c0aDruid|r: Frenzied Regeneration\n|cff00ff98Monk|r: Purifying Brew\n|cffc69b6dWarrior|r: Shield Block"
	L.FadeTip = "Fade the player and pet frames while out of combat, not casting, and with no target."
	L.StandaloneCastbarTip = "Standalone castbars for:\n\nPlayer, Target, and non-simple-mode Focus target."

	-- Raidframes
	L.HideBlizzardRaidFrames = "Hide Blizzard Group Frames"
	L.HideCompactRaidManager = "Fade RaidManager"
	L.ShowBuffAuras = "Show Buff Auras"
	L.ShowDebuffAuras = "Show Debuff Auras"
	L.HealerManaOnly = "Healer Mana Only"

	L.ShowBuffAurasTip = "Only defensive spells are shown."
	L.HealerManaOnlyTip = "Only show power bars for healers."
	L.HideBlizzardRaidFramesTip = "Hide Blizzard group frames only when the corresponding Ruri group frames are enabled. The raid manager in the upper-left corner remains available."
	L.HideCompactRaidManagerTip = "Fade the raid manager in the upper-left corner. It is shown on mouseover."

	-- Nameplates
	L.NumberStyle = "Number Style"
	L.ShowAuras = "Show Auras"
	L.HighlightTargetFocus = "Highlight Target/Focus"
	L.HighlightMouseover = "Highlight Mouseover"
	L.Crosshairs = "Target Crosshairs"
	L.CVars = "Adjust CVars"
	L.CVarsTip = "Adjust some nameplate CVars.\n\nSee Embeds\\CVars.lua for the list of changed CVars."
	L.FriendlyNameSize = "Adjust Friendly Names"
	L.FriendlyNameSizeTip = CreateBindingTooltip("Enable friendly player name-only mode. Friendly nameplates are enabled automatically when entering an instance; health bars are hidden and names use larger outlined text.\n\nPress %s to toggle friendly nameplates.\n\nBecause of Blizzard restrictions, enabling this changes the appearance of Blizzard nameplates.", "FRIENDNAMEPLATES")
	L.PlayerPlate = "Player Plate"
	L.PlayerPlateTip = "Show a simple resource bar for health, power, and class resources. Enabling it disables Blizzard's default Personal Resource Display."

	-- Other
	L.ReloadUI = "Reload UI"
	L.StatusChanged = "Reload UI to apply settings."
	L.WIP = "WIP"

end
