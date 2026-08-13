local _, ns = ...
local F, G = ns[2], ns[3]

do
	-- * = Secure CVar = 插件只能在戰鬥外透過 SetCVar() 修改，不能 /console

	-- 名條多選 CVar 格式：
	-- 版本 byte + mask 資料 byte，12.1 版本 byte 是 "\002"
	-- 選項權重依序為 1、2、4、8、16、32；設定值為數值相加之和
	-- 資料 byte = 0x40 + mask：A=1、B=2、C=3、D=4、E=5、G=7、[=27、_=31
	-- mask 為 0 時省略資料 byte，因此選項全部取消的值為 "\002"

	local function ApplyNameplateCVars()
		SetCVar("nameplateShowAll", 1)			-- Default 0；總是顯示名條
		-- SetCVar("nameplateShowSelf", 0)		-- * Default 0；顯示個人資源
		-- SetCVar("nameplateShowCastBars", 1)	-- * Default 1；顯示施法條
		-- SetCVar("showSpenderFeedback", 0)	-- Default 1；資源溢出閃光

		-- 非簡易名條的名字是否顯示，與 UnitName* 系列 CVar 聯動
		-- 例：如果 UnitNameFriendlyPetName 為 0 則敵方寵物名條也不顯示名字，除非是當前目標
		-- 設為 1 則無視 UnitName* 系列設定，強制顯示名字
		-- SetCVar("nameplateForceShowUnitName", 0)	-- * Default 0
		
		-- 簡易名條類型：0=無 1=僕從 2=次要敵人 4=友方玩家 8=友方NPC
		-- SetCVar("nameplateSimplifiedTypes", "\002")	-- * Default "\002"
		-- SetCVar("nameplateSimplifiedScale", 1)		-- * Default 0.3 範圍 0.15~1

		-- Enemy show / 敵方顯示
		SetCVar("nameplateShowEnemies", 1)			-- Default 1
		SetCVar("nameplateShowEnemyGuardians", 1)	-- * Default 0 守護者
		SetCVar("nameplateShowEnemyMinions", 1)		-- Default 0 僕從
		SetCVar("nameplateShowEnemyPets", 1)		-- * Default 0 寵物
		SetCVar("nameplateShowEnemyTotems", 1)		-- * Default 0 圖騰
		SetCVar("nameplateShowEnemyMinus", 1)		-- * Default 1 次要
		
		-- Friendly show / 友方顯示
		-- SetCVar("nameplateShowFriends", 1)
		-- SetCVar("nameplateShowFriendlyPlayers", 1)		-- Default 0 玩家
		SetCVar("nameplateShowFriendlyPlayerGuardians", 0)	-- * Default 0 守護者
		SetCVar("nameplateShowFriendlyPlayerMinions", 0)	-- Default 0 僕從
		SetCVar("nameplateShowFriendlyNpcs", 0)				-- Default 0 NPC
		SetCVar("nameplateShowFriendlyPlayerPets", 0)		-- * Default 0 寵物
		SetCVar("nameplateShowFriendlyPlayerTotems", 0)		-- * Default 0 圖騰

		-- 外觀
		-- 名條尺寸，數字越大尺寸越大
		-- SetCVar("nameplateSize", 4)					-- !* Default 1，範圍 1~5，整數			
		-- 名條外觀：0=Modern 1=Thin 2=Block 3=HealthFocus 4=CastFocus 5=Legacy (6=Classic)
		-- SetCVar("nameplateStyle", 0)					-- * Default 0 六種外觀 0~5
		-- 名條位置：0=全部在頭頂 1=友方和中立在頭頂、敵方在腳下 2=全部在腳下
		SetCVar("nameplateOtherAtBase", 0)				-- * Default 0
		SetCVar("nameplateShowClassColor", 1)			-- * Default 1；敵方玩家血條職業染色
		SetCVar("nameplateShowFriendlyClassColor", 1)	-- * Default 1；友方玩家血條職業染色
		SetCVar("nameplatePlayRemovalAnimation", 1)		-- * Default 1；名條移除動畫

		-- 名條堆疊：0=無 1=敵方 2=友方
		SetCVar("nameplateStackingTypes", "\002A")		-- Default "\002" (0)
		SetCVar("nameplateOverlapH", .6)				-- * Default 0.8；水平堆疊間距
		SetCVar("nameplateOverlapV", .8)				-- * Default 1.1；垂直堆疊間距

		-- Friendly player name-only mode / 友方名字模式
		SetCVar("nameplateShowOnlyNameForFriendlyPlayerUnits", 1)		-- Default 0；名字模式
		SetCVar("nameplateUseClassColorForFriendlyPlayerUnitNames", 1)	-- Default 0；職業顏色
		SetCVar("nameplateShowFriendlyRealmName", 0)					-- Default 1；顯示伺服器
		SetCVar("nameplateShowDebuffsOnFriendly", 0)					-- * Default 1；顯示減益

		-- 顯示距離
		SetCVar("nameplateMaxDistance", 60)				-- * Default 60 一般名條（主要為 NPC）
		SetCVar("nameplatePlayerMaxDistance", 60)		-- * Default 60 玩家名條
		SetCVar("nameplateGameObjectMaxDistance", 30)	-- * Default 30 遊戲物件名條

		-- 顯示條件
		-- 徑向定位：以畫面中心為基準，根據單位相對方向，把離屏名條投影到畫面左右及下方邊緣
		-- 例：單位在畫面左側外，則名條在左側貼邊；單位由左側往左後移動，名條「走弧線」往左下移動
		-- 白話文：徑向定位 = 模擬鏡頭，沿圓弧貼邊；非徑向定位 = 按矩形畫面邊界夾持及堆疊
		-- showOffscreen=1 & radial=0 畫面外顯示的名條，不使用徑向定位
		-- showOffscreen=1 & radial=1 畫面外顯示的名條，只有當前目標使用徑向定位
		-- showOffscreen=1 & radial=2 畫面外顯示的名條，全部使用徑向定位
		SetCVar("nameplateShowOffscreen", 1)			-- * Default 0；顯示畫面外名條 (目標/交戰)
		SetCVar("nameplateTargetBehindMaxDistance", 40)	-- * Default 0.1；鏡頭後方目標名條顯示距離
		SetCVar("nameplateTargetRadialPosition", 2)		-- * Default 0；畫面外名條顯示方式；0=關、1=僅目標、2=戰鬥中全部
		SetCVar("nameplateCheckDistanceForTarget", 0)	-- * Default 0；1=當前目標也受最大距離限制
		SetCVar("nameplateOccludedAlphaMult", 0.2)		-- * Default 0.4；障礙物後名條透明度
	
		-- 目標淡出和縮放
		SetCVar("nameplateSelectedScale", 1)			-- * Default 1.2
		SetCVar("nameplateSelectedAlpha", 1)			-- * Default 1
		SetCVar("nameplateNotSelectedAlpha", -1)		-- * Default -1 非當前目標透明度，範圍 0~1，-1=停用
		-- 距離淡出和縮放
		SetCVar("nameplateMaxAlpha", 1)					-- * Default 1
		SetCVar("nameplateMaxAlphaDistance", 40)		-- * Default 40
		SetCVar("nameplateMaxScale", 1)					-- * Default 1
		SetCVar("nameplateMaxScaleDistance", 40)		-- * Default 10
		SetCVar("nameplateMinAlpha", 1)					-- * Default 0.6
		SetCVar("nameplateMinAlphaDistance", 40)		-- * Default 10
		SetCVar("nameplateMinScale", 1)					-- * Default 0.8
		SetCVar("nameplateMinScaleDistance", 40)		-- * Default 10

		-- 名條資訊，0=無、1=生命百分比、2=目前生命值、4=稀有圖示
		-- SetCVar("nameplateInfoDisplay", "\002C")		-- ! Default "\002D" (4)
		-- 仇恨資訊，0=無、1=漸進、2=閃爍、4=血條染色
		-- SetCVar("nameplateThreatDisplay", "\002B")	-- ! Default "\002" (0)
		-- 施法資訊，0=無、1=法術名、2=圖示、4=目標、8=高亮重要施法、16=高亮目標是自己
		-- SetCVar("nameplateCastBarDisplay", "\002[")	-- Default "\002[" (27)
		-- 光環
		-- SetCVar("nameplateAuraScale", 1)				-- * Default 1；光環尺寸，範圍 0.7~1.4，最小單位 0.1
		-- SetCVar("nameplateDebuffPadding", 0)			-- * Default 0；光環間距，範圍 0~50，最小單位 1
		-- 擴展個人光環法術清單，顯示DOT和混沌烙印/奧秘之掌等被動易傷
		SetCVar("nameplateShowAllPersonalAuras", 0)		-- #* Default 0
		
		-- 敵方NPC光環資訊，0=無、1=敵方增益、2=你施放的減益、4=控場
		-- SetCVar("nameplateEnemyNpcAuraDisplay", "\002G")			-- Default "\002G" (7)
		-- 敵方玩家光環資訊，0=無、1=敵方增益、2=你施放的減益、4=控場
		-- SetCVar("nameplateEnemyPlayerAuraDisplay", "\002G")		-- Default "\002G" (7)
		-- 友方玩家光環資訊，0=無、1=你施放的增益、2=玩家減益、4=控場
		-- SetCVar("nameplateFriendlyPlayerAuraDisplay", "\002C")	-- Default "\002C" (3)
	end

	local loader = CreateFrame("Frame")
	loader:RegisterEvent("PLAYER_ENTERING_WORLD")
	loader:SetScript("OnEvent", function()
		if F.GetRuriOption("CVars") then
			ApplyNameplateCVars()
		end
	end)
end

do
	-- 設定文字外觀
	local function SetNameplateFont(obj)
		obj:SetFont(G.Font, G.NPNameFS, G.FontFlag)
		obj:SetShadowOffset(0, 0)
	end

	-- 名條名字尺寸的迂迴調整：實際字高由 nameplateSize 經原生 SetTextHeight 套用，不能直接改
	local function ApplyFriendlyNameSize()
		-- 戰鬥中不延後重試，直接跳過
		if InCombatLockdown() then return end
		-- 設定 nameplateSize
		if GetCVarNumberOrDefault("nameplateSize") ~= Enum.NamePlateSize.ExtraLarge then
			SetCVar("nameplateSize", Enum.NamePlateSize.ExtraLarge)	-- * ExtraLarge = 4
		end
		-- 套用文字外觀
		SetNameplateFont(SystemFont_NamePlate)
		SetNameplateFont(SystemFont_NamePlate_Outlined)
	end

	-- 進出副本後切換友方玩家名條；只在狀態改變時寫入，避免多餘的 CVAR_UPDATE
	local function UpdateFriendlyPlayerNameplates()
		local inInstance = IsInInstance()
		if GetCVarBool("nameplateShowFriendlyPlayers") ~= inInstance then
			SetCVar("nameplateShowFriendlyPlayers", inInstance and 1 or 0)
		end
	end

	local loader = CreateFrame("Frame")
	loader:RegisterEvent("VARIABLES_LOADED")	-- 早於 PLAYER_LOGIN，之後 OUF 才能接管名條尺寸
	loader:RegisterEvent("PLAYER_ENTERING_WORLD")
	loader:SetScript("OnEvent", function(_, event)
		if F.GetRuriOption("FriendlyNameSize") and F.GetRuriOption("Nameplates") then
			if event == "VARIABLES_LOADED" then
				ApplyFriendlyNameSize()
			elseif event == "PLAYER_ENTERING_WORLD" then
				UpdateFriendlyPlayerNameplates()
			end
		end
	end)
end
