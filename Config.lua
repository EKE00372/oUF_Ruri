local _, ns = ...
local C, G = ns[1], ns[3]

local MediaFolder = G.MediaFolder

-------------------
-- User settings --
-------------------

	-- GUI-controlled toggles are defined in Init.lua.
	-- GUI 控制的開關定義在 Init.lua。

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
	G.NPFS = 28										-- Number style nameplate health text font size / 數字模式名條的血量字型大小

------------------------
-- UnitFrame settings --
------------------------

	-- [[ UnitFrames / 單位框架 ]] --
	
	-- Size / 大小
	C.PWidth = 220				-- Player/Target/Focus frame width / 主框體寬度：玩家/目標/焦點
	C.TOTWidth = 120			-- Targettarget/Focusetarget/Pet frame width / 副框體寬度：寵物/目標的目標/焦點目標
	C.BWidth = 160				-- Arena/Boss frame width / 首領和競技場寬度
	
	C.PHeight = 26				-- Frame height /  通用的框體高度
	C.PPHeight = 4				-- Power bar height / 能量條高度
	C.PPOffset = 6				-- Power bar offset / 能量條向下偏移

	C.AuraSize = 26				-- Base aura icon size / 基準光環圖示大小
	C.MaxAura = 14				-- How many auras show / 顯示光環數量

	C.FadeOutAlpha = 0			-- Fade out value / 淡出值
	
	--[[ Castbar / 施法條 ]] --
	
	-- Size / 大小
	-- NOTICE: when Vertical style and StandaloneCastbar both enable, castbar size will match vert frame height.
	C.CastbarWidth = 200		-- Horizontal castbar width / 橫式頭像時，獨立施法條的寬度
	
	-- Colors / 顏色
	-- NOTICE: This effect on BOTH unitframe standalone castbar and nameplates castbar.
	C.CastNormal = {.6, .6, .6}	-- Normal castbar / 普通施法條
	C.CastShield = {.9, .3, .5}	-- Non-interruptible castbar / 不可打斷的施法條

------------------------
-- GroupFrame settings --
------------------------
	
	C.RWidth = 124				-- Raid frame width / 團隊寬度
	C.RHeight = 50				-- Raid frame height / 團隊高度
	
	C.RPHeight = 2				-- Raid frame power height / 團隊能量條高度
	C.RSpace = 6				-- Raid frame space / 團隊間距
	C.RaidAuraSize = 18			-- Group frame aura icon size / 組隊框架光環圖示大小
	--C.midAuraSize = 20				-- Middle big aura size
	C.RangeAlpha = 0.4			-- Alpha for out of range units / 超距離淡出透明度
	
	C.PartyWidth = 130			-- Party frame width / 隊伍寬度
	C.PartyHeight = 50			-- Party frame height / 隊伍高度
	
	C.PartyPHeight = 2			-- Party frame power height / 隊伍能量條高度
	C.PartySpace = 6			-- Party frame space / 隊伍間距
	
------------------------
-- Nameplate settings --
------------------------

	-- Bar style nameplate config
	C.NPWidth = 140			-- Nameplate frame width / 名條寬度
	C.NPHeight = 10			-- Nameplate frame height / 名條高度
	
	-- Auras / 光環
	C.NPMaxAura = 6			-- Auras per row / 每行顯示光環數量
	C.NPAuraSize = 20		-- Nameplate aura icon size / 名條光環圖示大小

	-- [[ Player plate ]] --
	
	C.PlayerPlateWidth = 180	-- Player plate width / 玩家個人資源寬度
	
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
		
		-- 簡易焦點目標 / Simple style focus target postion
		SFOT	= {"TOP", "oUF_Focus", "BOTTOM", C.BWidth/4, -C.PPOffset},

		-- [[ Other / 其他 ]] --
		
		Boss	= {"LEFT", 10, 80},
		Arena	= {"LEFT", 10, 80},
		
		-- [[ Groups / 團隊 ]] --
		Party	= {"CENTER", UIParent, 530, 140},
		Raid	= {"CENTER", UIParent, 340, -160},
		
		-- [[ Player plate / 玩家個人資源 ]] --
		
		PlayerPlate	= {"CENTER", 0, -200},
		
		-- [[ Standalone castbar / 獨立施法條 ]] --
		
		PlayerCastbar = {"LEFT", "oUF_Player", "RIGHT", C.PPOffset, 0},
		TargetCastbar = {"RIGHT", "oUF_Target", "LEFT", -C.PPOffset, 0},
		FocusCastbar = {"RIGHT", "oUF_Focus", "LEFT", -C.PPOffset, 0},
		
		VPlayerCastbar = {"BOTTOMLEFT", "oUF_Player", "BOTTOMRIGHT", C.AuraSize + C.PPOffset + C.PHeight, 0},
		VTargetCastbar = {"BOTTOMRIGHT", "oUF_Target", "BOTTOMLEFT", -(C.AuraSize*2 + C.PPOffset*2 + C.PHeight), 0},
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
