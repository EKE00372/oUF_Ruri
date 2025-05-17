----------------------
-- Dont touch this! --
----------------------

local addon, ns = ...
	ns[1] = {} -- C, config
	ns[2] = {} -- F, functions, constants, variables
	ns[3] = {} -- G, globals (Optionnal)
	ns[4] = {} -- T, ouf custom
	
local C, F, G, T = unpack(ns)

	G.addon = "oUF_Ruri_"
	G.myClass = select(2, UnitClass("player"))
	
local MediaFolder = "Interface\\AddOns\\oUF_Ruri\\Media\\"

------------
-- Global --
------------

	-- NOTE: ture = enable, false = disable / enable = 啟用，disable = 停用
	C.UnitFrames = true		-- Enable Unitframes,  / 啟用單位框架
	C.RaidFrames = false	-- Enable Raidframes / 啟用團隊框架
	C.PartyFrames = false	-- Enable Partyframes / 啟用隊伍框架
	C.Nameplates = true		-- Enable Nameplates/ 啟用名條

-------------
-- Texture --
-------------

	G.media = {
		blank = MediaFolder.."dM3",		-- "Interface\\Buttons\\WHITE8x8",
		raidbar = MediaFolder.."Inner-Shadow.blp",
		glow = MediaFolder.."glow.tga",
		barhightlight = MediaFolder.."highlight.tga",
		
		spark = MediaFolder.."spark.tga",	-- "Interface\\UnitPowerBarAlt\\Generic1Player_Pill_Flash"
		border = MediaFolder.."border.tga",
		
		resting = MediaFolder.."resting.blp",
		combat = MediaFolder.."combat.blp",
		raidicon = MediaFolder.."raidicons.blp",
		skull = MediaFolder.."RaidFrameDeathIcon.blp",
		
		circle = MediaFolder.."crosshair_circle.blp",
		arrows = MediaFolder.."crosshair_arrows.blp",
		
		role = MediaFolder.."UI-LFG-ICON-PORTRAITROLES.blp", -- from matty's texture
	}

-----------
-- Fonts --
-----------

	G.Font = STANDARD_TEXT_FONT						-- General font / 字型
	G.NameFS = 14									-- General font size / 字型大小
	G.FontFlag = "OUTLINE"							-- General font flag / 描邊 "OUTLINE" or none
	
	G.NFont = MediaFolder.."myriadHW.ttf"			-- Number font for auras / 光環數字字型
	G.NumberFS = 14
	
	G.NPNameFS = 12									-- Nameplate font size / 名條的字型
	G.NPFont = MediaFolder.."Infinity Gears.ttf"	-- Number style nameplate health text font / 數字模式名條的血量字型
	G.NPFS = 16										-- Number style nameplate health text font size / 數字模式名條的血量字型大小

------------------------
-- UnitFrame settings --
------------------------

	-- [[ UnitFrames / 單位框架 ]] --
	
	C.vertPlayer = true			-- Vertical Player and Pet frame / 直式玩家
	C.vertTarget = true			-- Vertical Target and ToT frame / 直式目標頭
	C.SimpleFocus = true		-- Simply show fucos as simple number style / 簡易模式：數字形式的焦點目標
	
	C.Boss = true				-- Enable Boss frame / 首領
	C.Arena = true				-- Enable Brena frame / 競技場
	
	-- Size / 大小
	C.PWidth = 220				-- Player/Target/Focus frame width / 主框體寬度：玩家/目標/焦點
	C.TOTWidth = 120			-- Targettarget/Focusetarget/Pet frame width / 副框體寬度：寵物/目標的目標/焦點目標
	C.BWidth = 160				-- Arena/Boss frame width / 首領和競技場寬度
	
	C.PHeight = 26				-- Frame height /  通用的框體高度
	C.PPHeight = 4				-- Power bar height / 能量條高度
	C.PPOffset = 6				-- Power bar offset / 能量條向下偏移

	C.buSize = 26				-- Aura icon size for all frames, except player debuff / 光環圖示大小
	C.maxAura = 14				-- How many auras show / 顯示光環數量
	
	-- Options / 選項
	C.PlayerDebuffs = true		-- Show debuffs on the player frame / 顯示自身減益
	C.Totems = false			-- Show player totems / 顯示玩家圖騰
	C.TankResource = true		-- Show player main tank resource as class power / 以職業資源形式顯示坦克核心技能

	C.Fade = true				-- Hide UFs when out of combat or not casting (Include Player/Target/Focus) / 戰鬥外閒置狀態淡出，作用於玩家/目標/焦點
	C.FadeOutAlpha = 0			-- Fade out value / 淡出值
	
	--[[ Castbar / 施法條 ]] --
	
	-- Options / 選項
	-- NOTICE: when Vertical style and StandaloneCastbar both enable, castbar size will match vert frame height.
	C.StandaloneCastbar = false	-- Independent castbar for player and target / 玩家與目標的獨立施法條
	C.CastbarWidth = 200		-- Castbar width, only can be config when not vertical unitframe / 橫式頭像時，獨立施法條的寬度
	
	-- Colors / 顏色
	-- NOTICE: This effect on BOTH unitframe standalone castbar and nameplates castbar.
	C.CastNormal = {.6, .6, .6}	-- Normal castbar / 普通施法條
	C.CastFailed = {.5, .2, .2}	-- Cast failed / 施法失敗
	C.CastShield = {.9, 0, 1}	-- Non-InterruptibleColor castbar / 不可打斷的施法條

------------------------
-- GroupFrame settings --
------------------------
	
	C.RWidth = 128				-- Raid frame width / 團隊寬度
	C.RHeight = 44				-- Raid frame height / 團隊高度
	
	C.RPHeight = 2				-- Raid frame power height / 團隊能量條高度
	C.RSpace = 6				-- Raid frame space / 團隊間距
	C.sAuSize = 18				-- Raid corner small aura size / 團隊邊角光環大小
	--C.bAuSize = 20				-- Middle big aura size
	C.RangeAlpha = 0.4			-- Alpha for out of range units / 超距離淡出透明度
	
	C.PartyWidth = 162			-- Party frame width / 隊伍寬度
	C.PartyHeight = 44			-- Party frame height / 隊伍高度
	
	C.PartyPHeight = 2			-- Party frame power height / 隊伍能量條高度
	C.PartySpace = 6			-- Party frame space / 隊伍間距
	C.PartyBuffSize = 22		-- Party corner small aura size / 隊伍邊角光環大小
	
------------------------
-- Nameplate settings --
------------------------

	-- NOTICE: Will do some change since version 5.2, because the layout of number style is not good for mythic+.
	-- maybe change size.
	C.NumberStyle = true	-- Number style nameplates / 數字模式的名條
	
	-- Number style nameplate config
	C.NPCastIcon = 28		-- Nmber style nameplate cast icon size /  數字模式的施法圖示大小
	
	-- Bar style nameplate config
	C.NPWidth = 110			-- Nameplate frame width / 名條寬度
	C.NPHeight = 8			-- Nameplate frame height / 名條高度
	
	-- Auras / 光環
	C.ShowAuras = true		-- Show auras / 顯示光環
	C.Auranum = 5			-- How many aura show / 顯示光環數量
	C.AuraSize = 16			-- Aura icon size / 光環大小

	-- Colors / 顏色
	C.friendlyCR = true		-- Friendly unit class color / 友方職業染色
	C.enemyCR = true		-- Enemy unit class color / 敵方職業染色
	
	C.HLTarget = true		-- Highlight target and focus / 高亮目標和焦點
	C.HLMouseover = true	-- Highlight mouseover / 高亮滑鼠指向
	
	-- Options / 選項
	C.Crosshairs = true		-- Show crosshairs red line on target / 在目標名條上顯示準星
	
	-- [[ Player plate ]] --
	
	C.PlayerPlate = false	-- Enable player plate / 玩家自身名條，即個人資源
	C.NumberstylePP = false	-- Number style player plate / 數字模式的玩家名條
	C.PlayerBuffs = true	-- Show player buff on player plate / 顯示自身增益
	C.PlayerNPWidth = 180	-- Player plate width

	--[[ Nameplates CVar ]] --
	
	C.Inset = true			-- Let Nameplates don't go off screen / 名條貼齊畫面邊緣
	C.MaxDistance = 45		-- Max distance for nameplate show on / 名條顯示的最大距離
	C.SelectedScale = 1		-- Scale select target nameplate / 縮放當前目標的名條大小
	C.MinAlpha = 1			-- Set fadeout for out of range and non-target / 非當前目標與遠距離名條的透明度
	
-----------------------
-- Position settings --
-----------------------

	C.Position = {	-- 各元素座標 / Elements positions
	
		-- [[ 直式 / vertical ]] --
		
		-- Player / 玩家
		VPlayer	= {"CENTER", -340, 0},
		VPet	= {"TOPRIGHT", "oUF_Player", "TOPLEFT", -C.PHeight, 0},
		-- Target / 目標
		VTarget	= {"CENTER", 340, 0},
		VTOT	= {"TOPLEFT", "oUF_Target", "TOPRIGHT", C.PHeight, 0},
		
		-- [[ 橫式 / horizontal ]] --

		-- Player / 玩家
		Player	= {"CENTER", -360, -180},
		Pet		= {"TOPLEFT", "oUF_Player", "BOTTOMLEFT", 0, -(C.PHeight + C.PPOffset * 2)},
		-- Target / 目標
		Target	= {"CENTER", 360, -180},
		TOT		= {"TOPRIGHT", "oUF_Target", "BOTTOMRIGHT", 0, -(C.PHeight + C.PPOffset * 2)},
		
		-- [[ 焦點 / focus ]] --
		
		-- 橫式目標時，焦點與焦點目標座標 / Focus and FoT position when horizontal target frame.
		Focus	= {"CENTER", 360, 0},
		FOT		= {"TOPRIGHT", "oUF_Focus", "BOTTOMRIGHT", 0, -(C.PHeight + C.PPOffset * 2)},

		-- 直式目標時，焦點與焦點目標座標 / Focus and FoT position when vertical target frame.
		VFocus	= {"CENTER", 0, -250},
		VFOT	= {"LEFT", "oUF_Focus", "RIGHT", C.PPOffset * 2, 0},
		
		-- 橫式的簡易焦點目標 / Simple style focus postion
		SFOT	= {"TOPLEFT", "oUF_Focus", "BOTTOMLEFT", 0, -C.PPOffset},

		-- [[ Other / 其他 ]] --
		
		Boss	= {"LEFT", 10, 80},
		Arena	= {"LEFT", 10, 80},
		
		-- [[ Groups / 團隊 ]] --
		Party	= {"CENTER", UIParent, 570, 120},
		Raid	= {"CENTER", UIParent, 570, 120},
		
		-- [[ Player plate / 玩家個人資源 ]] --
		
		PlayerPlate	= {"CENTER", 0, -200},
		
		-- [[ Standalone castbar / 獨立施法條 ]] --
		
		PlayerCastbar = {"LEFT", "oUF_Player", "RIGHT", C.PPOffset, 0},
		TargetCastbar = {"RIGHT", "oUF_Target", "LEFT", -C.PPOffset, 0},
		FocusCastbar = {"RIGHT", "oUF_Focus", "LEFT", -C.PPOffset, 0},
		
		VPlayerCastbar = {"BOTTOMLEFT", "oUF_Player", "BOTTOMRIGHT", C.buSize + C.PPOffset + C.PHeight, 0},
		VTargetCastbar = {"BOTTOMRIGHT", "oUF_Target", "BOTTOMLEFT", -(C.buSize*2 + C.PPOffset*2 + C.PHeight), 0},
		VFocusCastbar = {"TOPLEFT", "oUF_Focus", "BOTTOMLEFT", 0, -C.PPOffset * 3}
	}


-------------
-- Credits --
-------------

	-- NDui by Siweia
	-- unitframes
	-- https://github.com/siweia/NDui/tree/master/Interface/AddOns/NDui/Modules/UFs
	-- spell list
	-- https://github.com/siweia/NDui/blob/master/Interface/AddOns/NDui/Config/Nameplate.lua
	
	-- AltzUI by Paopao
	-- unitframes
	-- https://github.com/Paojy/Altz-UI/tree/master/Interface/AddOns/AltzUI/mods/unitframes
	
	-- oUF Mlight
	-- https://www.wowinterface.com/downloads/info21095-oUF_Mlight.html
	
	-- oUF Farva
	-- https://github.com/scrable/oUF_Farva

	-- oUF Slim
	-- https://www.wowinterface.com/downloads/info12972-oUF_Slim.html
	
	-- oUF Skaarj
	-- https://www.wowinterface.com/downloads/info20211-oUFSkaarj.html
	
	-- Infinity Plates by Dawn
	-- https://www.wowinterface.com/downloads/info19881-InfinityPlates.html

	-- SpecialTotemBar and oUF_TankResource by HopeASD
	
	-- [oUF] 1.5版 oUF系插件 通用说明 (FD)
	-- https://nga.178.com/read.php?tid=4107042

	-- [oUF][最基础扫盲][初稿完工！]以Ouf_viv5为例，不完全不专业注释
	-- https://nga.178.com/read.php?tid=4184224

	-- [未完成]oUF系列头像编写教程
	-- https://bbs.nga.cn/read.php?tid=7212677