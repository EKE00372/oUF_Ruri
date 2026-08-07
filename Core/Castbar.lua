local _, ns = ...
local C, F, G, T = unpack(ns)

-- 嵌入式顏色
local EMBED_CAST_NORMAL = CreateColor(.6, .6, .6, .6)
local EMBED_CAST_SHIELD = CreateColor(.6, 0, .6, .6)
local EMBED_CAST_FAILED = CreateColor(.6, .2, .2, .6)
local CAST_ICON_BORDER_NORMAL = CreateColor(.2, .2, .2, 1)
local CAST_ICON_BORDER_SHIELD = CreateColor(0, 0, 0, 1)
-- 獨立式顏色
local CAST_NORMAL = CreateColor(unpack(C.CastNormal))
local CAST_SHIELD = CreateColor(unpack(C.CastShield))
local CAST_FAILED = CreateColor(.6, .2, .2)

--=====================================================--
-----------------    [[ Functions ]]    -----------------
--=====================================================--

-- 施法時間格式：小於60秒顯示小數點後一位，大於60秒顯示x分x秒
local castTimeFormatter = C_StringUtil.CreateSecondsFormatter()
	castTimeFormatter:SetDefaultAbbreviation(Enum.SecondsFormatterAbbreviation.OneLetter)
	castTimeFormatter:SetMinInterval(Enum.SecondsFormatterInterval.Seconds)
	castTimeFormatter:SetMillisecondsThreshold(60)

-- 施法文字格式：當前/總共
T.CreateCastbarTimeBinding = function(currentOnly)
	local binding = C_DurationUtil.CreateDurationTextBinding()
	if currentOnly then
		binding:SetTextFormat("{}", {
			{
				property = Enum.DurationTextBindingProperty.ElapsedDuration,
				formatter = castTimeFormatter,
			},
		})
	else
		binding:SetTextFormat("{}/{}", {
			{ -- 當前
				property = Enum.DurationTextBindingProperty.ElapsedDuration,
				formatter = castTimeFormatter,
			},
			{ -- 總共
				property = Enum.DurationTextBindingProperty.TotalDuration,
				formatter = castTimeFormatter,
			},
		})
	end

	return binding
end

-- 施法延遲
local function CreateCastbarDelayText(element)
	element.Delay = F.CreateText(element, "OVERLAY", G.Font, G.NameFS, G.FontFlag, "LEFT")
	element.Delay:SetTextColor(1, 0, 0)
	element.Delay:SetText("")
	element.Delay:SetPoint("LEFT", element.Time, "RIGHT", 2, 0)
end

-- 施法條顏色
local function SetCastbarColor(element, notInterruptible)
	if element.isPlayerCastbar then
		element:SetStatusBarColor(element.castNormalColor:GetRGBA())
	else
		-- 施法條變色
		element:GetStatusBarTexture():SetVertexColorFromBoolean(notInterruptible, element.castShieldColor, element.castNormalColor)
		-- 嵌入式施法條的法術圖示邊框與陰影邊色
		if element.ShieldShadow then
			-- 邊框：常規深灰，不可打斷純黑
			element.IconBorder:SetVertexColorFromBoolean(notInterruptible, CAST_ICON_BORDER_SHIELD, CAST_ICON_BORDER_NORMAL)
			-- 陰影：常規黑色，不可打斷紅色
			element.Shadow:SetAlphaFromBoolean(notInterruptible, 0, 1)
			element.ShieldShadow:SetAlphaFromBoolean(notInterruptible, 1, 0)
		end
	end
end

--=======================================================--
-----------------    [[ Post Update ]]    -----------------
--=======================================================--

-- [[ 開始施法 ]] --

local function PostCastStart_Embed(element, unit, spellID, notInterruptible)
	local frame = element:GetParent()

	-- 嵌入式施法條：開始施法時隱藏名字
	if frame.Name then frame.Name:SetAlpha(0) end
	if frame.Status then frame.Status:SetAlpha(0) end

	SetCastbarColor(element, notInterruptible)
end

T.PostCastStart = function(element, unit, spellID, notInterruptible)
	SetCastbarColor(element, notInterruptible)
end

-- [[ 停止施法 ]] --

local function PostCastStop_Embed(element, unit)
	local frame = element:GetParent()

	-- 嵌入式施法條：結束施法時顯示名字
	if frame.Name then frame.Name:SetAlpha(1) end
	if frame.Status then frame.Status:SetAlpha(1) end
end

-- [[ 施法失敗 ]] --

T.PostCastFailed = function(element, unit)
	-- 一閃而過的施法失敗紅色條
	element:SetStatusBarColor(element.castFailedColor:GetRGBA())
end

-- [[ 施法過程中打斷狀態更新 ]] --

T.PostCastInterruptible = function(element, unit, spellID, notInterruptible)
	SetCastbarColor(element, notInterruptible)
end

--===========================================================--
-----------------    [[ Create elements ]]    -----------------
--===========================================================--

-- [[ 嵌入施法條 ]] --

T.CreateCastbar_Embed = function(self, unit)
	-- 創建一個條
	local Castbar = F.CreateStatusbar(self, G.addon..unit.."_CastBar", "ARTWORK")
	Castbar:SetAllPoints(self.Health)
	Castbar:SetFrameLevel(self:GetFrameLevel() + 4)

	-- 法術圖示的基底框架
	local IconBG = CreateFrame("Frame", nil, Castbar)
	IconBG:SetSize(C.PHeight + C.PPHeight * 2 - 1, C.PHeight + C.PPHeight * 2 - 1)
	Castbar.IconBG = IconBG
	-- 1px 邊框
	local IconBorder = IconBG:CreateTexture(nil, "ARTWORK")
	IconBorder:SetPoint("TOPLEFT", IconBG, "TOPLEFT", -1, 1)
	IconBorder:SetPoint("BOTTOMRIGHT", IconBG, "BOTTOMRIGHT", 1, -1)
	IconBorder:SetTexture(G.media.blank)
	IconBorder:SetVertexColor(CAST_ICON_BORDER_NORMAL:GetRGBA())
	Castbar.IconBorder = IconBorder
	-- 法術圖示
	Castbar.Icon = IconBG:CreateTexture(nil, "OVERLAY", nil, 1)
	Castbar.Icon:SetAllPoints()
	Castbar.Icon:SetTexCoord(.08, .92, .08, .92)
	-- 替法術圖示建立兩個陰影，設定顯示條件
	Castbar.Shadow = F.CreateSD(IconBG, IconBorder, 4, 0, 0, 0)	-- 常規陰影
	Castbar.ShieldShadow = F.CreateSD(IconBG, IconBorder, 4, .9, .05, .05)	-- 不可打斷陰影
	Castbar.ShieldShadow:SetAlpha(0)

	-- 文本
	Castbar.Text = F.CreateText(Castbar, "OVERLAY", G.Font, G.NameFS, G.FontFlag, nil)
	Castbar.Time = F.CreateText(Castbar, "OVERLAY", G.Font, G.NameFS, G.FontFlag, nil)
	Castbar.Time.binding = T.CreateCastbarTimeBinding()
	if unit == "player" then
		CreateCastbarDelayText(Castbar)
	end
	-- 進度高亮
	Castbar.Spark = Castbar:CreateTexture(nil, "OVERLAY", nil, -1)
	Castbar.Spark:SetTexture(G.media.spark)
	Castbar.Spark:SetBlendMode("ADD")
	Castbar.Spark:SetVertexColor(1, 1, .85, .8)
	-- 橫豎的spark不一樣
	if self.mystyle ~= "H" then
		Castbar:SetOrientation("VERTICAL")
		Castbar.Spark:SetRotation(math.rad(90))	-- spark材質也要轉90度
		Castbar.Spark:SetSize(C.PHeight, C.PHeight)
		Castbar.Spark:SetPoint("TOP", Castbar:GetStatusBarTexture(), 0, 0)
	else
		Castbar.Spark:SetSize(C.PHeight, C.PHeight)
		Castbar.Spark:SetPoint("RIGHT", Castbar:GetStatusBarTexture(), 0, 0)
	end
	
	-- 選項
	Castbar.timeToHold = 0.05
	-- 創建施法條時用公開 unit token 標記玩家施法條，而非用 UnitIsUnit() 觸發 secret value
	Castbar.isPlayerCastbar = (unit == "player")
	-- 指定顏色
	Castbar.castNormalColor = EMBED_CAST_NORMAL
	Castbar.castShieldColor = EMBED_CAST_SHIELD
	Castbar.castFailedColor = EMBED_CAST_FAILED

	Castbar.PostCastStart = PostCastStart_Embed			-- 施法開始
	Castbar.PostCastStop = PostCastStop_Embed			-- 施法結束
	Castbar.PostCastFail = T.PostCastFailed				-- 施法失敗
	Castbar.PostCastInterrupted = T.PostCastFailed		-- 施法中斷
	Castbar.PostCastInterruptible = T.PostCastInterruptible	-- 狀態刷新
	-- 施法結束恢復名字顯示
	Castbar:HookScript("OnHide", PostCastStop_Embed)

	self.Castbar = Castbar
end

-- [[ 獨立施法條 ]] --

T.CreateCastbar_Standalone = function(self, unit)
	-- 創建一個條
	local Castbar = F.CreateStatusbar(self, G.addon..unit.."_CastBar", "ARTWORK")
	Castbar:SetFrameLevel(self:GetFrameLevel() + 4)	

	-- 背景與邊框
	Castbar.BarBG = F.CreateBD(Castbar, Castbar, 1, .15, .15, .15, .6)
	-- 陰影
	Castbar.BarShadow = F.CreateSD(Castbar, Castbar, 4)

	-- 法術圖示的基底框架
	local IconBG = CreateFrame("Frame", nil, Castbar)
	IconBG:SetSize(C.PHeight + C.PPHeight * 2, C.PHeight + C.PPHeight * 2)
	Castbar.IconBG = IconBG
	--　1xp 邊框
	local IconBorder = IconBG:CreateTexture(nil, "ARTWORK")
	IconBorder:SetPoint("TOPLEFT", IconBG, "TOPLEFT", -1, 1)
	IconBorder:SetPoint("BOTTOMRIGHT", IconBG, "BOTTOMRIGHT", 1, -1)
	IconBorder:SetTexture(G.media.blank)
	IconBorder:SetVertexColor(CAST_ICON_BORDER_NORMAL:GetRGBA())
	-- 法術圖示
	Castbar.Icon = IconBG:CreateTexture(nil, "OVERLAY", nil, 1)
	Castbar.Icon:SetAllPoints()
	Castbar.Icon:SetTexCoord(.08, .92, .08, .92)
	Castbar.Shadow = F.CreateSD(IconBG, IconBorder, 5, 0, 0, 0)

	-- 進度高亮
	Castbar.Spark = Castbar:CreateTexture(nil, "OVERLAY", nil, -1)
	Castbar.Spark:SetTexture(G.media.spark)
	Castbar.Spark:SetBlendMode("ADD")
	Castbar.Spark:SetVertexColor(1, 1, .85, .5)
	Castbar.Spark:SetAlpha(.5)
	
	-- 不同模式的布局
	if self.mystyle == "S" then
		-- 簡易焦點
		Castbar:SetSize(C.PWidth/2, C.PHeight)
		
		Castbar.Spark:SetSize(C.PHeight, C.PHeight)
		Castbar.Spark:SetPoint("RIGHT", Castbar:GetStatusBarTexture(), 0, 0)

		Castbar.Text = F.CreateText(Castbar, "OVERLAY", G.Font, G.NameFS, G.FontFlag, "LEFT")
		Castbar.Text:SetPoint("LEFT", 5, 0)
		Castbar.Text:SetWidth(self:GetWidth())
	elseif self.mystyle == "H" then
		-- 橫式
		Castbar:SetHeight(C.PHeight)
		
		Castbar.Spark:SetSize(C.PHeight, C.PHeight)
		Castbar.Spark:SetPoint("RIGHT", Castbar:GetStatusBarTexture(), 0, 0)

		Castbar.Text = F.CreateText(Castbar, "OVERLAY", G.Font, G.NameFS, G.FontFlag, "LEFT")
		Castbar.Text:SetPoint("LEFT", 5, 0)
		Castbar.Time = F.CreateText(Castbar, "OVERLAY", G.Font, G.NameFS, G.FontFlag, "RIGHT")
		Castbar.Time.binding = T.CreateCastbarTimeBinding()
		Castbar.Time:SetPoint("RIGHT", -5, 0)
	else
		-- 直式
		Castbar:SetSize(C.PHeight, C.PWidth-(C.PHeight + C.PPHeight*2)-C.PPOffset)
		Castbar:SetOrientation("VERTICAL")
		
		Castbar.Spark:SetRotation(math.rad(90))	-- spark材質也要轉90度
		Castbar.Spark:SetSize(C.PHeight, C.PHeight)
		Castbar.Spark:SetPoint("TOP", Castbar:GetStatusBarTexture(), 0, 0)

		Castbar.Text = F.CreateText(Castbar, "OVERLAY", G.Font, G.NameFS, G.FontFlag, nil)
		Castbar.Time = F.CreateText(Castbar, "OVERLAY", G.Font, G.NameFS, G.FontFlag, nil)
		Castbar.Time.binding = T.CreateCastbarTimeBinding()
	end
	if unit == "player" and Castbar.Time then
		CreateCastbarDelayText(Castbar)
	end
	
	-- 選項
	Castbar.timeToHold = 0.05
	-- 創建施法條時用公開 unit token 標記玩家施法條，而非用 UnitIsUnit() 觸發 secret value
	Castbar.isPlayerCastbar = (unit == "player")
	-- 指定顏色
	Castbar.castNormalColor = CAST_NORMAL
	Castbar.castShieldColor = CAST_SHIELD
	Castbar.castFailedColor = CAST_FAILED

	Castbar.PostCastStart = T.PostCastStart					-- 施法開始
	Castbar.PostCastFail = T.PostCastFailed					-- 施法失敗
	Castbar.PostCastInterrupted = T.PostCastFailed			-- 施法中斷
	Castbar.PostCastInterruptible = T.PostCastInterruptible	-- 狀態更新

	self.Castbar = Castbar
end
