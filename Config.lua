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

	C.UnitFrames = true		-- enable Unitframes, ture = enable, false = disable / 啟用頭像，enable = 啟用，disable = 停用
	--C.RaidFrames = false	-- enable Raidframes / 啟用團隊框架
	C.Nameplates = true		-- enable Nameplates/ 啟用名條

-------------
-- Texture --
-------------

	G.media = {
		blank = MediaFolder.."dM3",		-- "Interface\\Buttons\\WHITE8x8",
		glow = MediaFolder.."glow.tga",
		barhightlight = MediaFolder.."highlight.tga",
		
		spark = MediaFolder.."spark.tga",	-- "Interface\\UnitPowerBarAlt\\Generic1Player_Pill_Flash"
		border = MediaFolder.."border.tga",
		
		resting = MediaFolder.."resting.blp",
		combat = MediaFolder.."combat.blp",
		raidicon = MediaFolder.."raidicons.blp",
	}

-----------
-- Fonts --
-----------

	G.Font = STANDARD_TEXT_FONT						-- general font / 字型
	G.NameFS = 14									-- general font size / 字型大小
	G.FontFlag = "OUTLINE"							-- general font flag / 描邊 "OUTLINE" or none
	
	G.NFont = MediaFolder.."myriadHW.ttf"			-- number font for auras / 光環數字字型
	G.NumberFS = 14
	
	G.NPNameFS = 12									-- nameplate font size / 名條的字型
	G.NPFont = MediaFolder.."Infinity Gears.ttf"	-- number style nameplate health text font / 數字模式名條的血量字型
	G.NPFS = 18										-- number style nameplate health text font size / 數字模式名條的血量字型大小

------------------------
-- UnitFrame settings --
------------------------

	C.vertPlayer = true			-- vertical player and pet frame / 直式玩家頭像
	C.vertTarget = true			-- vertical target and tot frame / 直式目標頭像	
	C.SimpleFocus = true		-- simply show fucos as simple number style / 簡易的數字模式焦點框體
	
	C.Boss = true				-- enable boss frame
	C.Arena = true				-- enable arena frame
	
	C.PWidth = 220				-- player/target/focus frame width / 主框體(血量條)寬度(玩家/目標/焦點)
	C.TOTWidth = 120			-- targettarget/focusetarget/pet frame width / 副框體寬度(寵物/目標的目標/焦點目標)
	C.BWidth = 160				-- arena/boss frame width / 首領和競技場寬度
	
	C.PHeight = 26				-- frame height /  通用框體高度
	C.PPHeight = 4				-- power bar height / 能量條高度
	C.PPOffset = 6				-- power bar offset / 能量條向下偏移

	C.buSize = 26				-- aura icon size for all frames except player debuff / 光環圖示大小
	C.maxAura = 14				-- how many auras show / 顯示光環數量
	
	C.PlayerDebuffs = true		-- show debuffs acting on the player frame / 顯示自身減益
	C.Totems = true				-- show player totems / 顯示玩家圖騰
	C.TankResource = true		-- show player main tank resource as class power / 以職業資源形式顯示坦克核心技能
	
	C.StandaloneCastbar = false	-- independent castbar for player and target / 獨立施法條
	C.CastbarWidth = 200		-- castbar width, only can be config when not vertical unitframe / 橫式頭像時，獨立施法條的寬度
	
	C.Fade = true				-- hide UFs when out of combat or not casting / 戰鬥外閒置狀態淡出頭象
	C.FadeOutAlpha = 0			-- fade out value / 淡出值
	
------------------------
-- RaidFrame settings --
------------------------
	--[[
	C.RWidth = 90				-- raid frame width
	C.RHeight = 48				-- raid frame height
	C.RPHeight = 2				-- raid frame power height
	
	C.sAuSize = 18				-- corner small aura size
	C.bAuSize = 18				-- middle big aura size
	C.RangeAlpha = 0.5			-- alpha for out of range units
	]]--
------------------------
-- Nameplate settings --
------------------------

	C.NumberStyle = true	-- number style nameplates / 數字模式的名條
	
	-- Number style nameplate config
	C.NPCastIcon = 32		-- number style nameplate cast icon size /  數字模式的施法圖示大小
	
	-- Bar style nameplate config
	C.NPWidth = 110			-- nameplate frame width / 名條寬度
	C.NPHeight = 8			-- nameplate frame height / 名條高度
	
	C.ShowAuras = true		-- show auras / 顯示光環
	C.Auranum = 5			-- how many aura show / 顯示光環數量
	C.AuraSize = 20			-- aura icon size / 光環大小

	C.friendlyCR = true		-- friendly unit class color / 友方職業染色
	C.enemyCR = true		-- enemy unit class color / 敵方職業染色

	C.HLTarget = true		-- highlight target and focus / 高亮目標和焦點
	C.HLMouseover = true	-- highlight mouseover / 高亮滑鼠指向
	
	-- [[ player plate ]] --
	
	C.PlayerPlate = false	-- enable player plate / 玩家名條(個人資源)
	C.NumberstylePP = false	-- number style player plate / 數字模式的玩家名條
	C.PlayerBuffs = false	-- show player buff on player plate / 顯示自身增益

	--[[ nameplates cvar ]] --
	
	C.Inset = true			-- Let Nameplates don't go off screen / 名條貼齊畫面邊緣
	C.MaxDistance = 45		-- Max distance for nameplate show on / 名條顯示的最大距離
	C.SelectedScale = 1		-- Scale select target nameplate / 縮放當前目標的名條大小
	C.MinAlpha = 1			-- Set fadeout for out of range and non-target / 非當前目標與遠距離名條的透明度
	
-----------------------
-- Position settings --
-----------------------

	C.Position = {	-- 各元素座標 / Elements positions
	
		-- [[ 直式 / vertical ]] --
		
		VPlayer	= {"CENTER", -320, 0},
		VPet	= {"TOPRIGHT", "oUF_Player", "TOPLEFT", -C.PHeight, 0},
		
		VTarget	= {"CENTER", 320, 0},
		VTOT	= {"TOPLEFT", "oUF_Target", "TOPRIGHT", C.PHeight, 0},
		
		-- [[ 橫式 / horizontal ]] --
		
		Player	= {"CENTER", -360, -180},
		Pet		= {"TOPLEFT", "oUF_Player", "BOTTOMLEFT", 0, -(C.PHeight + C.PPOffset * 2)},
		
		Target	= {"CENTER", 360, -180},
		TOT		= {"TOPRIGHT", "oUF_Target", "BOTTOMRIGHT", 0, -(C.PHeight + C.PPOffset * 2)},
		
		-- [[ 焦點 / focus ]] --
		
		-- 橫式目標時，焦點與焦點目標座標 / focus and fot position when horizontal target frame.
		Focus	= {"CENTER", 360, 0},
		FOT		= {"TOPRIGHT", "oUF_Focus", "BOTTOMRIGHT", 0, -(C.PHeight + C.PPOffset * 2)},

		-- 直式目標時，焦點與焦點目標座標 / focus and fot position when vertical target frame.
		VFocus	= {"CENTER", 0, -250},
		VFOT	= {"LEFT", "oUF_Focus", "RIGHT", C.PPOffset * 2, 0},
		
		-- 橫式的簡易焦點目標 / simple style focus postion
		SFOT	= {"TOPLEFT", "oUF_Focus", "BOTTOMLEFT", 0, -C.PPOffset},

		-- [[ other / 其他 ]] --
		
		Boss	= {"LEFT", 10, 80},
		Arena	= {"LEFT", 10, 80},
		
		-- [[ 玩家個人資源 / player plate ]] --
		
		PlayerPlate	= {"CENTER", 0, -200},
		
		-- [[ 獨立施法條 / standalone castbar ]] --
		
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

	-- SpecialTotemBar by HopeASD
	
	-- [oUF] 1.5版 oUF系插件 通用说明 (FD) NGA玩家社区
	-- https://nga.178.com/read.php?tid=4107042

	-- [oUF][最基础扫盲][初稿完工！]以Ouf_viv5为例，不完全不专业注释
	-- https://nga.178.com/read.php?tid=4184224

	-- [未完成]oUF系列头像编写教程 NGA玩家社区
	-- https://bbs.nga.cn/read.php?tid=7212677