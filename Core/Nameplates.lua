local _, ns = ...
local oUF = ns.oUF
local C, F, G, T = unpack(ns)

local UnitIsTapDenied, UnitPlayerControlled, UnitIsConnected = UnitIsTapDenied, UnitPlayerControlled, UnitIsConnected
local UnitIsPlayer, UnitClass, UnitThreatSituation, UnitReaction = UnitIsPlayer, UnitClass, UnitThreatSituation, UnitReaction
local issecretvalue = issecretvalue

local CAST_NORMAL = CreateColor(.9, .9, .9)
local CAST_SHIELD = CreateColor(unpack(C.CastShield))
local CAST_FAILED = CreateColor(.6, .2, .2)
local NUMBER_NAMEPLATE_WIDTH = 100

local function Noop() end	-- 關閉喚能師的聚能分段

--==================================================--
-----------------    [[ Colors ]]    -----------------
--==================================================--

-- 專用 multiplier
local function CreateNameplateMultiplierBG(element)
	local shade = element:CreateTexture(nil, "BACKGROUND", nil, 0)
	shade:SetAllPoints()
	shade:SetColorTexture(0, 0, 0, 1)

	local bg = element:CreateTexture(nil, "BACKGROUND", nil, 1)
	bg:SetAllPoints()
	bg:SetTexture(G.media.blank)

	element.bg = bg
end

-- 血量文字透明度：未滿血顯示，滿血隱藏；由原生 calculator 評估以避開 secret 數值比較。
local HEALTH_TEXT_ALPHA_CURVE = C_CurveUtil.CreateCurve()
HEALTH_TEXT_ALPHA_CURVE:SetType(Enum.LuaCurveType.Step)
HEALTH_TEXT_ALPHA_CURVE:AddPoint(0, 1)
HEALTH_TEXT_ALPHA_CURVE:AddPoint(1, 0)

-- 條形名條同步更新血條背景色，並以 secret-safe 曲線隱藏滿血百分比。
local function PostUpdateBarHealthColor(element, unit, color)
	local r, g, b = color:GetRGB()
	element.bg:SetVertexColor(r, g, b, .3)
	element.value:SetAlpha(element.values:EvaluateCurrentHealthPercent(HEALTH_TEXT_ALPHA_CURVE))
end

-- 染色
local function UpdateNameplateHealthColor(self, event, unit)
	if not unit or self.__unit ~= unit then return end

	local element = self.Health
	local color
	local playerControlled = UnitPlayerControlled(unit)

	if element.colorDisconnected and not UnitIsConnected(unit) then
		color = self.colors.disconnected
	elseif element.colorTapping and not playerControlled and UnitIsTapDenied(unit) then
		color = self.colors.tapped
	elseif element.colorThreat and not playerControlled
		and not C_Secrets.ShouldUnitThreatStateBeSecret("player", unit) then
		local status = UnitThreatSituation("player", unit)
		if status then
			color = self.colors.threat[status]
		end
	end

	if not color and element.colorClass and UnitIsPlayer(unit) then
		local _, class = UnitClass(unit)
		if issecretvalue(class) then
			color = C_ClassColor.GetClassColor(class)
		else
			color = self.colors.class[class]
		end
	end

	if not color and element.colorReaction then
		local reaction = UnitReaction(unit, "player")
		if reaction then
			color = self.colors.reaction[reaction]
		end
	end

	if not color and element.colorHealth then
		color = self.colors.health
	end

	if color then
		element:SetStatusBarColor(color:GetRGB())
	end

	if element.PostUpdateColor then
		element:PostUpdateColor(unit, color)
	end
end

-- 將顏色套用到數字模式的名字文字
local function PostUpdateNumberHealthColor(element, unit, color)
	element.__owner.Name:SetTextColor(color:GetRGB())
end

--==================================================--
-----------------    [[ Health ]]    -----------------
--==================================================--

-- oUF 寫入真實血量後，將 Health 覆寫為二段布局值並更新血量文字透明度。
local function UpdateNumberHealthLayout(frame)
	local Health = frame.Health
	Health:SetMinMaxValues(0, 1)
	Health:SetValue(Health.values:EvaluateCurrentHealthPercent(Health.LayoutCurve))
	frame.HealthText:SetAlpha(Health.values:EvaluateCurrentHealthPercent(HEALTH_TEXT_ALPHA_CURVE))
end

-- 數字模式的血量變化時套用布局
local function PostUpdateNumberHealth(element, unit)
	local owner = element.__owner
	if owner.RingCastActive then
		element:SetMinMaxValues(0, 1)
		element:SetValue(1)
		owner.HealthText:SetAlpha(0)
		return
	end

	UpdateNumberHealthLayout(owner)
end

--=========================================================--
--------------    [[ Ring Castbar callbacks ]]    -----------
--=========================================================--

-- 施法環：顏色
local function SetRingCastbarColor(element, notInterruptible)
	element.Ring:SetVertexColorFromBoolean(notInterruptible, CAST_SHIELD, CAST_NORMAL)
end

-- 施法環：打斷狀態更新
local function PostRingCastInterruptible(element, unit, spellID, notInterruptible)
	SetRingCastbarColor(element, notInterruptible)
end

-- 施法開始和狀態變化時，更新施法環進度
local function UpdateRingCastDuration(element)
	element.RingCooldown:SetCooldownFromDurationObject(element:GetTimerDuration(), false)
	element.RingCooldown:Show()
end

-- 施法環：開始施法的布局變化
local function PostRingCastStart(element, unit, spellID, notInterruptible)
	SetRingCastbarColor(element, notInterruptible)
	element.Ring:Show()
	UpdateRingCastDuration(element)

	local owner = element.__owner
	owner.RingCastActive = true
	owner.Health:SetMinMaxValues(0, 1)
	owner.Health:SetValue(1)
	owner.HealthText:SetAlpha(0)
end

-- 施法環：狀態重置
local function ClearRingCastState(element)
	local owner = element.__owner
	if not owner.RingCastActive then return end

	owner.RingCastActive = false
	element.Ring:Hide()
	element.RingCooldown:Clear()
	element.RingCooldown:Hide()
	return true
end

-- 施法環：施法結束的狀態重置，並恢復血量文字與光環位置
local function ResetRingCastLayout(element)
	if not ClearRingCastState(element) then return end

	UpdateNumberHealthLayout(element.__owner)
end

-- 施法環：施法失敗與中斷
local function PostRingCastFailed(element, unit)
	element.Ring:SetVertexColor(CAST_FAILED:GetRGB())
end

--=====================================================--
--------------    [[ Castbar creation ]]    ------------
--=====================================================--

-- [[ 數字模式環形施法條 ]] --

local function CreateRingCastbar(self, ringBorderSize)
	local CAST_RING_TEXTURE = "Interface\\CharacterFrame\\TempPortraitAlphaMask"

	-- 尺寸繼承血量百分比文字大小
	local ringSize = math.max(ringBorderSize - 2, 1)
	local iconBorderSize = math.max(ringSize - 4 * 2, 1)	-- 施法環固定寬度
	local iconSize = math.max(iconBorderSize - 2, 1)

	-- 建立施法條的基底框架
	local Castbar = CreateFrame("StatusBar", nil, self)
	Castbar:SetSize(ringSize, ringSize)
	Castbar:SetPoint("CENTER", self.HealthText, "CENTER")
	Castbar:SetStatusBarTexture(G.media.blank)
	Castbar:GetStatusBarTexture():SetAlpha(0)			-- 使其不可見
	Castbar:SetFrameLevel(self:GetFrameLevel() + 10)	-- 層級必需高於光環

	-- 環形施法條結構：大圓疊小圓
	-- 1px邊框-施法環-1px邊框-法術圖示

	-- 外邊框：黑色大圓，被 RingBG 覆蓋後就變成 1px 邊框
	local RingBorderMask = Castbar:CreateMaskTexture(nil, "OVERLAY")
	RingBorderMask:SetPoint("CENTER")
	RingBorderMask:SetSize(ringBorderSize, ringBorderSize)
	RingBorderMask:SetTexture(CAST_RING_TEXTURE)
	local RingBorder = Castbar:CreateTexture(nil, "BACKGROUND", nil, -1)
	RingBorder:SetPoint("CENTER")
	RingBorder:SetSize(ringBorderSize, ringBorderSize)
	RingBorder:SetTexture(G.media.blank)
	RingBorder:SetVertexColor(0, 0, 0, 1)
	RingBorder:AddMaskTexture(RingBorderMask)

	-- 環形施法條的圓形遮罩
	local RingMask = Castbar:CreateMaskTexture(nil, "OVERLAY")
	RingMask:SetAllPoints()
	RingMask:SetTexture(CAST_RING_TEXTURE)

	-- 施法條背景：深灰色大圓
	local RingBG = Castbar:CreateTexture(nil, "BACKGROUND")
	RingBG:SetAllPoints()
	RingBG:SetTexture(G.media.blank)
	RingBG:SetVertexColor(.12, .12, .12, .95)
	RingBG:AddMaskTexture(RingMask)

	-- 施法條：根據打斷顏色染色
	local Ring = Castbar:CreateTexture(nil, "ARTWORK", nil, 1)
	Ring:SetAllPoints()
	Ring:SetTexture(G.media.blank)
	Ring:SetBlendMode("BLEND")
	Ring:SetVertexColor(CAST_NORMAL:GetRGB())
	Ring:AddMaskTexture(RingMask)
	Ring:SetRadialProgressBarFeather(0)
	Ring:SetRadialProgressBarStartOffset(.5)
	Ring:SetRadialProgressBarPercent(1)
	Ring:Hide()
	Castbar.Ring = Ring

	-- 施法條進度：根據施法時間以 Cooldown swipe 徑向掃過整圈，產生進度效果
	local RingCooldown = CreateFrame("Cooldown", nil, Castbar, "CooldownFrameTemplate")
	RingCooldown:SetFrameLevel(Castbar:GetFrameLevel() + 1)
	RingCooldown:SetAllPoints()
	RingCooldown:SetDrawBling(false)
	RingCooldown:SetDrawEdge(false)
	RingCooldown:SetDrawSwipe(true)
	RingCooldown:SetHideCountdownNumbers(true)
	RingCooldown:SetReverse(false)
	RingCooldown:SetSwipeTexture(CAST_RING_TEXTURE)
	RingCooldown:SetAlpha(.85)
	RingCooldown:Hide()
	Castbar.RingCooldown = RingCooldown

	-- 法術圖示的容器框體
	local IconBG = CreateFrame("Frame", nil, Castbar)
	IconBG:SetFrameLevel(Castbar:GetFrameLevel() + 2)
	IconBG:SetSize(iconSize, iconSize)
	IconBG:SetPoint("CENTER")

	-- 法術圖示的圓型遮罩
	local IconMask = IconBG:CreateMaskTexture(nil, "OVERLAY")
	IconMask:SetAllPoints()
	IconMask:SetTexture(CAST_RING_TEXTURE)

	-- 比法術圖示大 2px 的黑色背景，露出部分形成 1px 邊框
	local IconBorderMask = Castbar:CreateMaskTexture(nil, "OVERLAY")
	IconBorderMask:SetPoint("CENTER", IconBG)
	IconBorderMask:SetSize(iconBorderSize, iconBorderSize)
	IconBorderMask:SetTexture(CAST_RING_TEXTURE)
	local IconBorder = Castbar:CreateTexture(nil, "ARTWORK", nil, 2)
	IconBorder:SetPoint("CENTER", IconBG)
	IconBorder:SetSize(iconBorderSize, iconBorderSize)
	IconBorder:SetTexture(G.media.blank)
	IconBorder:SetVertexColor(0, 0, 0, 1)
	IconBorder:AddMaskTexture(IconBorderMask)

	-- 法術圖示
	Castbar.Icon = IconBG:CreateTexture(nil, "ARTWORK")
	Castbar.Icon:SetAllPoints()
	Castbar.Icon:SetTexCoord(.08, .92, .08, .92)
	Castbar.Icon:AddMaskTexture(IconMask)

	-- 選項
	Castbar.UpdatePips = Noop	-- 關閉喚能師的聚能分段
	Castbar.timeToHold = 0.05

	Castbar.PostCastStart = PostRingCastStart
	Castbar.PostCastUpdate = UpdateRingCastDuration
	Castbar.PostCastStop = ResetRingCastLayout
	Castbar.PostCastFail = PostRingCastFailed
	Castbar.PostCastInterrupted = PostRingCastFailed
	Castbar.PostCastInterruptible = PostRingCastInterruptible
	Castbar:HookScript("OnHide", ResetRingCastLayout)

	self.Castbar = Castbar
end

-- [[ 條形施法條 ]]--

local function CreateBarCastbar(self, unit)
	-- 創建施法條
	local Castbar = F.CreateStatusbar(self, G.addon..unit.."_CastBar", "ARTWORK", C.NPHeight)
	Castbar:SetPoint("TOPLEFT", self.Health, "BOTTOMLEFT", 0, -4)
	Castbar:SetPoint("TOPRIGHT", self.Health, "BOTTOMRIGHT", 0, -4)
	Castbar:SetFrameLevel(self:GetFrameLevel() + 3)
	Castbar.BarShadow = F.CreateSD(Castbar, Castbar, 3)
	-- 施法條背景
	Castbar.bg = Castbar:CreateTexture(nil, "BACKGROUND")
	Castbar.bg:SetAllPoints()
	Castbar.bg:SetTexture(G.media.blank)
	Castbar.bg:SetVertexColor(.15, .15, .15)
	-- 法術圖示的容器框體
	local IconBG = CreateFrame("Frame", nil, Castbar)
	IconBG:SetSize(C.NPHeight*2 + 4, C.NPHeight*2 + 4)
	IconBG:SetPoint("BOTTOMRIGHT", Castbar, "BOTTOMLEFT", -4, 0)
	Castbar.IconBG = IconBG
	-- 圖示
	Castbar.Icon = Castbar.IconBG:CreateTexture(nil, "OVERLAY")
	Castbar.Icon:SetAllPoints(IconBG)
	Castbar.Icon:SetTexCoord(.08, .92, .08, .92)
	-- 圖示邊框：Castbar.Icon 會 secret value，所以邊框陰影要自行創建
	Castbar.Shadow = F.CreateSD(Castbar.IconBG, Castbar.IconBG, 4)
	-- 法術名
	Castbar.Text = F.CreateText(Castbar, "OVERLAY", G.Font, G.NPNameFS, G.FontFlag, "CENTER")
	Castbar.Text:SetPoint("TOPLEFT", Castbar, "BOTTOMLEFT", 0, -2)
	Castbar.Text:SetPoint("TOPRIGHT", Castbar, "BOTTOMRIGHT", 0, -2)
	-- DurationTextBinding 直接格式化 secret duration，只顯示當前進度而不在 Lua 計算秒數。
	Castbar.Time = F.CreateText(Castbar, "OVERLAY", G.Font, G.NPNameFS, G.FontFlag, "RIGHT")
	Castbar.Time:SetPoint("TOPRIGHT", Castbar, "BOTTOMRIGHT", 0, 4)
	Castbar.Time.binding = T.CreateCastbarTimeBinding(true)
	-- 進度高亮
	Castbar.Spark = Castbar:CreateTexture(nil, "OVERLAY")
	Castbar.Spark:SetTexture(G.media.spark)
	Castbar.Spark:SetBlendMode("ADD")
	Castbar.Spark:SetVertexColor(1, 1, .85, .5)
	Castbar.Spark:SetSize(C.NPHeight*2, C.NPHeight)
	Castbar.Spark:SetPoint("RIGHT", Castbar:GetStatusBarTexture(), 0, 0)

	-- 選項
	Castbar.timeToHold = 0.05
	Castbar.isPlayerCastbar = false

	Castbar.castNormalColor = CAST_NORMAL
	Castbar.castShieldColor = CAST_SHIELD
	Castbar.castFailedColor = CAST_FAILED

	Castbar.PostCastStart = T.PostCastStart					-- 施法開始
	Castbar.PostCastFail = T.PostCastFailed					-- 施法失敗
	Castbar.PostCastInterrupted = T.PostCastFailed			-- 施法中斷
	Castbar.PostCastInterruptible = T.PostCastInterruptible	-- 打斷狀態更新

	self.Castbar = Castbar
end

--=====================================================--
-----------------    [[ Highlight ]]    -----------------
--=====================================================--

-- frame cache
local targetNameplate
local focusNameplate
local mouseoverNameplate
local indicatorController
local showTargetHighlight
local showMouseoverHighlight

-- 從原生名條取得 oUF frame，避免使用 UnitIsUnit() 的 secret value
local function GetNameplateUnitFrame(unit)
	local nameplate = C_NamePlate.GetNamePlateForUnit(unit)
	return nameplate and nameplate.unitFrame
end

-- NineSlice 只用固定資料建立材質與錨點，不會讀取由 secret 名字決定的框體尺寸。
local function SetupNameplateHighlightPiece(_, piece, setupInfo, pieceLayout)
	if setupInfo.pieceName == "Center" then
		piece:SetColorTexture(1, 1, 1, 1)
		return
	end

	piece:SetTexture(G.media.glow)
	piece:SetTexCoord(unpack(pieceLayout.texCoords))
	if setupInfo.tileHorizontal then
		piece:SetHeight(10)
	elseif setupInfo.tileVertical then
		piece:SetWidth(10)
	else
		piece:SetSize(10, 10)
	end
end

-- glow.tga 是 128x16 的八格 legacy edgeFile；長邊沿用固定 UV stretch。
local NAMEPLATE_HIGHLIGHT_LAYOUT = {
	setupPieceVisualsFunction = SetupNameplateHighlightPiece,
	TopLeftCorner = {
		layer = "BACKGROUND", subLevel = 1,
		texCoords = {.5078125, .0625, .5078125, .9375, .6171875, .0625, .6171875, .9375},
	},
	TopRightCorner = {
		layer = "BACKGROUND", subLevel = 1,
		texCoords = {.6328125, .0625, .6328125, .9375, .7421875, .0625, .7421875, .9375},
	},
	BottomLeftCorner = {
		layer = "BACKGROUND", subLevel = 1,
		texCoords = {.7578125, .0625, .7578125, .9375, .8671875, .0625, .8671875, .9375},
	},
	BottomRightCorner = {
		layer = "BACKGROUND", subLevel = 1,
		texCoords = {.8828125, .0625, .8828125, .9375, .9921875, .0625, .9921875, .9375},
	},
	TopEdge = {
		layer = "BACKGROUND", subLevel = 1,
		texCoords = {.2578125, .9375, .3671875, .9375, .2578125, .0625, .3671875, .0625},
	},
	BottomEdge = {
		layer = "BACKGROUND", subLevel = 1,
		texCoords = {.3828125, .9375, .4921875, .9375, .3828125, .0625, .4921875, .0625},
	},
	LeftEdge = {
		layer = "BACKGROUND", subLevel = 1,
		texCoords = {.0078125, .0625, .0078125, .9375, .1171875, .0625, .1171875, .9375},
	},
	RightEdge = {
		layer = "BACKGROUND", subLevel = 1,
		texCoords = {.1328125, .0625, .1328125, .9375, .2421875, .0625, .2421875, .9375},
	},
	Center = {layer = "BACKGROUND", subLevel = 0},
}

-- 以共用 NineSlice layout 重現 edgeSize 10 的 glow backdrop，避免 BackdropTemplate 計算 secret 寬度。
local function CreateNameplateHighlight(frame)
	local isNumberStyle = frame.mystyle == "NNP"
	local highlight = CreateFrame("Frame", nil, frame)
	-- 高亮是整張名條的底色，固定在所有可見名條元素下方的專用底層。
	highlight:SetFrameLevel(frame:GetFrameLevel() + 1)
	if isNumberStyle then
		highlight:SetPoint("TOPLEFT", frame.Name, -10, 8)
		highlight:SetPoint("BOTTOMRIGHT", frame.Name, 10, -10)
	else
		highlight:SetPoint("TOPLEFT", frame.Health, -12, 12)
		highlight:SetPoint("BOTTOMRIGHT", frame.Health, 12, -12)
	end

	NineSliceUtil.ApplyLayout(highlight, NAMEPLATE_HIGHLIGHT_LAYOUT)

	highlight:EnableMouse(false)
	highlight:Hide()

	return highlight
end

-- 依目標、焦點、指向的優先級更新單一高亮；快取公開狀態以跳過重複染色。
local function UpdateNameplateIndicator(frame)
	local indicator = frame and frame.HighlightIndicator
	if not indicator then return end

	local state
	if showTargetHighlight and frame == targetNameplate then
		state = "target"
	elseif showTargetHighlight and frame == focusNameplate then
		state = "focus"
	elseif showMouseoverHighlight
	and frame == mouseoverNameplate
	and frame ~= targetNameplate
	and frame ~= focusNameplate then
		state = "mouseover"
	end

	if indicator.highlightState == state then return end
	indicator.highlightState = state

	local r, g, b
	if state == "target" then
		r, g, b = 0, .85, 1
	elseif state == "focus" then
		r, g, b = .3, 1, .3
	elseif state == "mouseover" then
		r, g, b = 1, 1, 0
	else
		indicator:Hide()
		return
	end

	-- 純材質不讀取 secret 名字決定的尺寸；條形只顯示毛邊，數字模式同時顯示底色。
	NineSlicePanelMixin.SetCenterColor(indicator, r, g, b, frame.mystyle == "NNP" and .8 or 0)
	NineSlicePanelMixin.SetBorderColor(indicator, r, g, b, .8)
	indicator:Show()
end

-- 目標與焦點高亮的更新
local function RefreshTargetFocusIndicators()
	-- 儲存舊frame
	local previousTarget = targetNameplate
	local previousFocus = focusNameplate
	-- 取得新frame
	targetNameplate = GetNameplateUnitFrame("target")
	focusNameplate = GetNameplateUnitFrame("focus")

	UpdateNameplateIndicator(previousTarget)	-- 更新舊目標
	UpdateNameplateIndicator(previousFocus)		-- 更新舊焦點
	UpdateNameplateIndicator(targetNameplate)	-- 更新新目標
	UpdateNameplateIndicator(focusNameplate)	-- 更新新焦點
	UpdateNameplateIndicator(mouseoverNameplate)-- 更新指向判斷
end

-- 指向高亮的更新
local function RefreshMouseoverIndicator()
	-- 儲存舊frame
	local previous = mouseoverNameplate
	-- 取得新frame
	mouseoverNameplate = GetNameplateUnitFrame("mouseover")

	-- 指向改變時清除舊 frame 的高亮
	if previous ~= mouseoverNameplate then UpdateNameplateIndicator(previous) end

	UpdateNameplateIndicator(mouseoverNameplate)	-- 更新目前指向高亮
	indicatorController:SetShown(mouseoverNameplate ~= nil)
end

-- 統一處理高亮變化
local function OnIndicatorControllerEvent(self, event)
	if event == "UPDATE_MOUSEOVER_UNIT" then
		RefreshMouseoverIndicator()
	else
		RefreshTargetFocusIndicators()
	end
end

-- 指向高亮的 OnUpdate：UPDATE_MOUSEOVER_UNIT 只管移入，不管移出
local function OnIndicatorControllerUpdate(self, elapsed)
	self.elapsed = self.elapsed + elapsed
	if self.elapsed >= .1 then
		self.elapsed = 0
		RefreshMouseoverIndicator()
	end
end

-- 每張名條只建立一組高亮，由公開 frame 身分決定目前顏色與顯示狀態。
local function CreateNameplateIndicator(self)
	self.HighlightIndicator = CreateNameplateHighlight(self)
	UpdateNameplateIndicator(self)
end

--=======================================================--
-----------------    [[ NamePlates ]]    ------------------
--=======================================================--

-- setting cache
local showNameplateAuras

-- [[ 數字模式 ]] --

local function CreateNumberPlates(self, unit)
	self.mystyle = "NNP"

	self.RingCastActive = false

	-- Health 保持啟用供 oUF calculator 更新；透明材質的移動端同時作為光環錨點。
	local Health = F.CreateStatusbar(self, G.addon..unit.."_NumberHealth", "ARTWORK", 1, NUMBER_NAMEPLATE_WIDTH, 0, 0, 0, 0)
	Health:SetPoint("BOTTOM", self, "BOTTOM")
	Health:SetOrientation("VERTICAL")	-- 保持標準填充方向，texture TOP 才是光環的移動端
	Health:SetMinMaxValues(0, 1)
	Health:SetFrameLevel(self:GetFrameLevel() + 2)
	Health:GetStatusBarTexture():SetAlpha(0)
	Health.colorDisconnected = true
	Health.colorTapping = true
	Health.colorClass = true
	Health.colorReaction = true
	Health.colorThreat = true
	Health.colorHealth = true
	self.Health = Health
	self.Health.UpdateColor = UpdateNameplateHealthColor
	self.Health.PostUpdateColor = PostUpdateNumberHealthColor
	self.Health.PostUpdate = PostUpdateNumberHealth

	-- 名字放在 Health 底部；實際行高會用來計算 Health 與滿血光環位置。
	self.Name = F.CreateText(self.Health, "OVERLAY", G.Font, G.NPNameFS, G.FontFlag, "CENTER")
	self.Name:SetPoint("BOTTOM", self.Health, "BOTTOM")
	self:Tag(self.Name, "[name]")

	-- 百分比與名字相距 3px；環形施法條與文字共用中心。
	self.HealthText = F.CreateText(self.Health, "OVERLAY", G.NPFont, G.NPFS, G.FontFlag, "CENTER")
	self.HealthText:SetPoint("BOTTOM", self.Name, "TOP", 0, 3)
	self.HealthText:SetTextColor(1, 1, 1)
	self:Tag(self.HealthText, "[perhp]")

	-- 用兩個 FontString 的公開行高建立布局；曲線結果只傳給可接受 secret value 的 SetValue。
	local nameHeight = self.Name:GetLineHeight()
	local healthTextHeight = self.HealthText:GetLineHeight()
	local healthHeight = nameHeight + 3 + healthTextHeight
	local fullHealthValue = nameHeight / healthHeight
	self.Name:SetHeight(nameHeight)
	self.HealthText:SetHeight(healthTextHeight)
	Health:SetHeight(healthHeight)
	Health.LayoutFullValue = fullHealthValue
	Health.LayoutCurve = C_CurveUtil.CreateCurve()
	Health.LayoutCurve:SetType(Enum.LuaCurveType.Step)
	Health.LayoutCurve:AddPoint(0, 1)
	Health.LayoutCurve:AddPoint(1, fullHealthValue)
	Health:SetValue(fullHealthValue)

	local RaidIcon = self.Health:CreateTexture(nil, "OVERLAY")
	RaidIcon:SetSize(24, 24)
	RaidIcon:SetTexture(G.media.raidicon)
	RaidIcon:SetPoint("RIGHT", self.Name, "LEFT", -2, 0)
	self.RaidTargetIndicator = RaidIcon

	CreateRingCastbar(self, healthTextHeight + 8)	-- 上下超出

	if showNameplateAuras then
		T.CreateNameplateAuras(self)
		self.Auras:SetPoint("BOTTOM", self.Health:GetStatusBarTexture(), "TOP", 0, 3)
	end
	if showTargetHighlight or showMouseoverHighlight then
		CreateNameplateIndicator(self)
	end
end

-- [[ 條形模式 ]] --

local function CreateBarPlates(self, unit)
	self.mystyle = "BNP"
	
	-- 血量
	local Health = F.CreateStatusbar(self, G.addon..unit, "ARTWORK", C.NPHeight, C.NPWidth, 0, 0, 0, 1)
	Health:SetPoint("CENTER", self, 0, 0)
	Health:SetFrameLevel(self:GetFrameLevel() + 3)
	-- 選項
	Health.colorDisconnected = true
	Health.colorTapping = true
	Health.colorClass = true
	Health.colorReaction = true
	Health.colorThreat = true
	Health.colorHealth = true
	-- 陰影
	Health.border = F.CreateSD(Health, Health, 3)
	-- 背景
	CreateNameplateMultiplierBG(Health)
	-- 註冊到ouf
	self.Health = Health
	self.Health.UpdateColor = UpdateNameplateHealthColor
	self.Health.PostUpdateColor = PostUpdateBarHealthColor
	
	-- 名字
	self.Name = F.CreateText(self.Health, "OVERLAY", G.Font, G.NPNameFS, G.FontFlag, "CENTER")
	self.Name:SetPoint("BOTTOM", self.Health, "TOP",  0, 4)
	self:Tag(self.Name, "[name]")

	-- 血量
	self.Health.value = F.CreateText(self.Health, "OVERLAY", G.Font, G.NPNameFS, G.FontFlag, "RIGHT")
	self.Health.value:SetPoint("BOTTOMRIGHT", self.Health, "TOPRIGHT", 0, -4)
	self:Tag(self.Health.value, "[perhp]")
	-- 團隊標記
	local RaidIcon = Health:CreateTexture(nil, "OVERLAY")
	RaidIcon:SetSize(28, 28)
	RaidIcon:SetTexture(G.media.raidicon)
	RaidIcon:SetPoint("RIGHT", self.Name, "LEFT", -2, 0)
	self.RaidTargetIndicator = RaidIcon

	-- 施法條
	CreateBarCastbar(self, unit)
	-- 只顯示傷害吸收；治療吸收不放在敵方名條。
	T.CreateHealthPrediction(self, false)
	
	-- 光環
	if showNameplateAuras then
		T.CreateNameplateAuras(self)
		self.Auras:SetPoint("BOTTOM", self.Name, "TOP", 0, 4)
	end
	-- 目標、焦點與指向共用同一組高亮。
	if showTargetHighlight or showMouseoverHighlight then
		CreateNameplateIndicator(self)
	end
end

-- nameplate driver 新增框架時重置狀態、套用單位類型光環並刷新所有高亮。
local function UpdateNameplateState(self, _, unit)
	-- 名條重用時先清掉上一個單位留下的公開 cast layout state；其後 UAE 會重算 Health/Castbar。
	if self.mystyle == "NNP" then
		ClearRingCastState(self.Castbar)
		self.Health:SetMinMaxValues(0, 1)
		self.Health:SetValue(self.Health.LayoutFullValue)
		self.HealthText:SetAlpha(0)
	end

	if showNameplateAuras then
		T.UpdateNameplateAuraFilter(self.Auras, UnitIsPlayer(unit))
	end

	if indicatorController then
		RefreshTargetFocusIndicators()
		if showMouseoverHighlight then
			RefreshMouseoverIndicator()
		end
	end
end

-- nameplate driver 移除框架時隱藏高亮並清除數字模式布局狀態。
local function ResetNameplateIndicators(self)
	if targetNameplate == self then targetNameplate = nil end
	if focusNameplate == self then focusNameplate = nil end
	if mouseoverNameplate == self then
		mouseoverNameplate = nil
		-- 保留到下一幀補查；若移除事件與 mouseover 切換交錯，不會永久停掉 fallback。
		indicatorController.elapsed = .1
		indicatorController:Show()
	end

	if self.HighlightIndicator then
		-- pooled frame 再次使用時必須重算，不能沿用隱藏前的快取狀態。
		self.HighlightIndicator.highlightState = nil
		self.HighlightIndicator:Hide()
	end
	if self.mystyle == "NNP" then
		ClearRingCastState(self.Castbar)
		self.Health:SetMinMaxValues(0, 1)
		self.Health:SetValue(self.Health.LayoutFullValue)
		self.HealthText:SetAlpha(0)
	end
end

--=======================================================--
-----------------    [[ PlayerPlate ]]    -----------------
--=======================================================--

-- [[ 自行創建玩家名條，取代暴雪的個人資源 ]] --
local function CreatePlayerBarPlate(self, unit)
	self.mystyle = "BPP"

	self:SetSize(C.PlayerPlateWidth, C.NPHeight*5)

	-- 血量
	local Health = F.CreateStatusbar(self, G.addon..unit.."_PlayerPlateHealth", "ARTWORK", C.NPHeight+4, C.PlayerPlateWidth)
	Health:SetPoint("CENTER", self, 0, 0)
	Health:SetFrameLevel(self:GetFrameLevel() + 2)
	Health.colorClass = true
	Health.border = F.CreateSD(Health, Health, 4)
	T.CreateMultiplierBG(Health)
	self.Health = Health
	self.Health.PostUpdateColor = T.PostUpdateColor_MultiBGColor

	-- 能量
	local Power = F.CreateStatusbar(self, G.addon..unit.."_PlayerPlatePower", "ARTWORK", (C.NPHeight+4)/2, C.PlayerPlateWidth)
	Power:SetPoint("TOP", self.Health, "BOTTOM",  0, -1)
	Power:SetFrameLevel(self:GetFrameLevel() + 2)
	Power.frequentUpdates = true
	Power.colorPower = true
	Power.border = F.CreateSD(Power, Power, 4)
	T.CreateMultiplierBG(Power)
	self.Power = Power
	self.Power.PostUpdateColor = T.PostUpdateColor_MultiBGColor
	
	-- 團隊標記
	local RaidIcon = self:CreateTexture(nil, "OVERLAY")
	RaidIcon:SetSize(28, 28)
	RaidIcon:SetTexture(G.media.raidicon)
	RaidIcon:SetPoint("RIGHT", self.Health, "LEFT", -4, -2)
	self.RaidTargetIndicator = RaidIcon
	
	-- 職業資源
	T.CreateClassPower(self, unit)
	-- 吸收盾
	T.CreateHealthPrediction(self, true)

	if F.GetRuriOption("Fade") then self.fade = true end
end

--===================================================--
-----------------    [[ Spawn ]]     ------------------
--===================================================--

-- 建立 BPP 與名條 driver；兩個選項彼此獨立。
oUF:Factory(function(self)
	-- 官方 oUF 的 Spawn 會停用 Blizzard PlayerFrame；只在 Ruri 已接管玩家頭像時附加 BPP。
	if F.GetRuriOption("PlayerPlate") and F.GetRuriOption("UnitFrames") then
		SetCVar("nameplateShowSelf", 0)	-- 停用原生個人資源；停用 BPP 時不寫回
		self:RegisterStyle("PlayerPlate", CreatePlayerBarPlate)
		self:SetActiveStyle("PlayerPlate")
		local plate = self:Spawn("player", "oUF_PlayerPlate")
		plate:SetPoint(unpack(C.Position.PlayerPlate))
	end

	if not F.GetRuriOption("Nameplates") then return end

	local numberStyle = F.GetRuriOption("NumberStyle")
	showNameplateAuras = F.GetRuriOption("ShowAuras")
	showTargetHighlight = F.GetRuriOption("HLTarget")
	showMouseoverHighlight = F.GetRuriOption("HLMouseover")

	if showTargetHighlight or showMouseoverHighlight then
		indicatorController = CreateFrame("Frame")
		indicatorController:RegisterEvent("PLAYER_TARGET_CHANGED")
		indicatorController:RegisterEvent("PLAYER_FOCUS_CHANGED")
		indicatorController:SetScript("OnEvent", OnIndicatorControllerEvent)
		indicatorController:Hide()

		if showMouseoverHighlight then
			indicatorController.elapsed = 0
			indicatorController:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
			indicatorController:SetScript("OnUpdate", OnIndicatorControllerUpdate)
		end
	end

	self:RegisterStyle("Nameplate", (numberStyle and CreateNumberPlates) or CreateBarPlates)
	self:SetActiveStyle("Nameplate")

	local driver = self:SpawnNamePlates("oUF_Nameplate")
	if numberStyle then
		-- native frame 作為固定名字列、百分比與圓環核心的點擊及堆疊範圍。
		driver:SetSize(NUMBER_NAMEPLATE_WIDTH, 50)
	else
		driver:SetSize(C.NPWidth, C.NPHeight * 4)
	end
	driver:SetAddedCallback(UpdateNameplateState)
	driver:SetRemovedCallback(ResetNameplateIndicators)

	if indicatorController then
		RefreshTargetFocusIndicators()
		if showMouseoverHighlight then
			RefreshMouseoverIndicator()
		end
	end
end)
