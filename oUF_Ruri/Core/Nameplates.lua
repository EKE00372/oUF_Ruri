local _, ns = ...
local oUF = ns.oUF
local C, F, G, T = unpack(ns)

local UnitIsTapDenied, UnitPlayerControlled = UnitIsTapDenied, UnitPlayerControlled
local UnitIsPlayer, UnitClass, UnitThreatSituation, UnitReaction = UnitIsPlayer, UnitClass, UnitThreatSituation, UnitReaction
local issecretvalue = issecretvalue

-- 設定快取
local showNameplateAuras
local showTargetHighlight
local showMouseoverHighlight
local reverseThreat = false

local CAST_NORMAL = CreateColor(.9, .9, .9)
local CAST_SHIELD = CreateColor(unpack(C.CastShield))
local CAST_FAILED = CreateColor(.6, .2, .2)

local function Noop() end	-- 關閉喚能師的聚能分段

--==================================================--
-----------------    [[ Colors ]]    -----------------
--==================================================--

-- 條形模式染色
local function PostUpdateHealthColor_Bar(element, unit, color)
	local r, g, b = color:GetRGB()
	element.bg:SetVertexColor(r, g, b, .3)
end

-- 名條染色更新
local function UpdateHealthColor(self, event, unit)
	if not unit or self.__unit ~= unit then return end
	-- 純血量與吸收值變化不影響名條顏色
	if event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" or event == "UNIT_ABSORB_AMOUNT_CHANGED" then return end

	local element = self.Health
	local color
	local playerControlled = UnitPlayerControlled(unit)

	if element.colorTapping and not playerControlled and UnitIsTapDenied(unit) then
		color = self.colors.tapped
	elseif element.colorThreat and not playerControlled
		and not C_Secrets.ShouldUnitThreatStateBeSecret("player", unit) then
		local status = UnitThreatSituation("player", unit)
		if status then
			color = self.colors.threat[reverseThreat and (3 - status) or status]
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

-- 只在組隊和職責變更時重新仇恨染色
local function UpdateThreatMode(_, event, unit)
	if event == "PLAYER_SPECIALIZATION_CHANGED" and unit ~= "player" then return end

	local shouldReverse = IsInGroup() and not PlayerUtil.IsPlayerEffectivelyTank()
	if reverseThreat == shouldReverse then return end
	reverseThreat = shouldReverse

	for _, nameplate in next, C_NamePlate.GetNamePlates() do
		local frame = nameplate.unitFrame
		if frame and frame:IsShown() then
			UpdateHealthColor(frame, event, frame.__unit)
		end
	end
end

-- 將顏色套用到數字模式的名字文字
local function PostUpdateHealthColor_Number(element, unit, color)
	element.__owner.Name:SetTextColor(color:GetRGB())
end

--==================================================--
---------------    [[ Number layout ]]    ------------
--==================================================--

-- 清除施法環的占位狀態與顯示狀態
local function ClearCastState_Ring(frame)
	if not frame.RingCastActive then return end

	frame.RingCastActive = false
	local Castbar = frame.Castbar
	Castbar.Ring:Hide()
	Castbar.RingCooldown:Clear()
	Castbar.RingCooldown:Hide()
	return true
end

-- 光環位置更新：始終跟隨同一定位條
local function UpdateLayout_Number(frame, reset)
	-- 名條建立/加入/移除時，重置施法環狀態
	if reset then
		ClearCastState_Ring(frame)
	end

	frame.HealthText:SetAlpha(frame.RingCastActive and 0 or 1)
	if not showNameplateAuras then return end

	local Health = frame.Health
	local value
	if reset then
		value = Health.LayoutFullValue
	elseif frame.RingCastActive then
		value = 1
	else
		value = Health.values:EvaluateCurrentHealthPercent(Health.LayoutCurve)
	end
	Health.Layout:SetValue(value)
end

local function PostUpdateHealth_Number(element)
	local owner = element.__owner
	if owner.RingCastActive then return end
	UpdateLayout_Number(owner)
end

--=========================================================--
--------------    [[ Ring Castbar callbacks ]]    -----------
--=========================================================--

-- 施法環：打斷狀態更新
local function PostCastInterruptible_Ring(element, unit, spellID, notInterruptible)
	element.Ring:SetVertexColorFromBoolean(notInterruptible, CAST_SHIELD, CAST_NORMAL)
end

-- 施法環：進度更新
local function UpdateCastDuration_Ring(element)
	element.RingCooldown:SetCooldownFromDurationObject(element:GetTimerDuration(), false)
	element.RingCooldown:Show()
end

-- 施法環：施法開始的布局變化
local function PostCastStart_Ring(element, unit, spellID, notInterruptible)
	PostCastInterruptible_Ring(element, unit, spellID, notInterruptible)
	element.Ring:Show()
	UpdateCastDuration_Ring(element)

	local owner = element.__owner
	owner.RingCastActive = true
	UpdateLayout_Number(owner)
end

-- 施法環：施法結束的狀態重置，並恢復血量文字與光環位置
local function ResetCastLayout_Ring(element)
	local owner = element.__owner
	if not ClearCastState_Ring(owner) then return end
	UpdateLayout_Number(owner)
end

-- 施法環：施法失敗與中斷
local function PostCastFailed_Ring(element, unit)
	element.Ring:SetVertexColor(CAST_FAILED:GetRGB())
end

--=====================================================--
--------------    [[ Castbar creation ]]    ------------
--=====================================================--

-- [[ 環形施法條 ]] --

local function CreateCastbar_Ring(self)
	local CAST_RING_TEXTURE = "Interface\\CharacterFrame\\TempPortraitAlphaMask"

	local ringBorderSize = self.HealthText:GetLineHeight() + 16	-- 環總體直徑，尺寸繼承血量百分比文字大小
	local ringSize = ringBorderSize - 2		-- 進度環直徑，尺寸=總體-邊框1px*2
	local iconBorderSize = ringSize - 6 * 2	-- 施法圖示總體直徑，尺寸=進度環直徑-寬度*2
	local iconSize = iconBorderSize - 2		-- 施法圖示本體直徑，尺寸=總體-邊框1px*2

	-- 建立施法條的基底框架
	local Castbar = CreateFrame("StatusBar", nil, self)
	Castbar:SetSize(ringSize, ringSize)
	Castbar:SetPoint("TOP", self.HealthText, "TOP", 0, 3)	-- 固定上緣，尺寸變化向下延伸
	Castbar:SetStatusBarTexture(G.media.blank)
	Castbar:GetStatusBarTexture():SetAlpha(0)		-- 使其不可見
	Castbar:SetFrameLevel(self:GetFrameLevel() + 6)	-- 光環按鈕占 +5，施法環 +6~+8。

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

	Castbar.PostCastStart = PostCastStart_Ring
	Castbar.PostCastUpdate = UpdateCastDuration_Ring
	Castbar.PostCastStop = ResetCastLayout_Ring
	Castbar.PostCastFail = PostCastFailed_Ring
	Castbar.PostCastInterrupted = PostCastFailed_Ring
	Castbar.PostCastInterruptible = PostCastInterruptible_Ring
	Castbar:HookScript("OnHide", ResetCastLayout_Ring)

	self.Castbar = Castbar
end

-- [[ 條形施法條 ]]--

local function CreateCastbar_Bar(self)
	-- 創建施法條
	local Castbar = F.CreateStatusbar(self, nil, "ARTWORK", C.NPHeight)
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
	-- 施法時間
	Castbar.Time = F.CreateText(Castbar, "OVERLAY", G.Font, G.NPNameFS, G.FontFlag, "RIGHT")
	Castbar.Time:SetPoint("TOPRIGHT", Castbar, "BOTTOMRIGHT", 0, 6)
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

	Castbar.PostCastStart = T.PostUpdateCastbarColor			-- 施法開始
	Castbar.PostCastFail = T.PostCastFailed					-- 施法失敗
	Castbar.PostCastInterrupted = T.PostCastFailed			-- 施法中斷
	Castbar.PostCastInterruptible = T.PostUpdateCastbarColor	-- 打斷狀態更新

	self.Castbar = Castbar
end

--=====================================================--
-----------------    [[ Highlight ]]    -----------------
--=====================================================--

-- frame cache
local targetNameplate
local focusNameplate
local mouseoverNameplate
local highlightController

-- 從原生名條取得 oUF frame，避免使用受限制的 UnitIsUnit()
local function GetNameplateUnitFrame(unit)
	local nameplate = C_NamePlate.GetNamePlateForUnit(unit)
	return nameplate and nameplate.unitFrame
end

-- 數字模式高亮跟隨名字自然寬度，名字為 secret value 時，需避免 BackdropTemplate 對寬度做運算觸發 secret taint
-- 改用 NineSlice 重建高亮外觀，由原生錨點跟隨名字伸縮
local function SetupHighlightPiece(_, piece, setupInfo, pieceLayout)
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
	setupPieceVisualsFunction = SetupHighlightPiece,
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
local function CreateHighlightTexture(frame)
	local isNumberStyle = frame.mystyle == "NNP"
	local highlight = CreateFrame("Frame", nil, frame)

	highlight:SetFrameLevel(frame:GetFrameLevel() + 1)	-- 高亮層級固定在所有可見名條元素下方
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

-- 高亮優先級：目標-焦點-指向；快取公開狀態以跳過重複染色
local function UpdateHighlight(frame)
	local highlight = frame and frame.Highlight
	if not highlight then return end

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

	if highlight.highlightState == state then return end
	highlight.highlightState = state

	local r, g, b
	if state == "target" then
		r, g, b = 0, .85, 1
	elseif state == "focus" then
		r, g, b = .3, 1, .3
	elseif state == "mouseover" then
		r, g, b = 1, 1, 0
	else
		highlight:Hide()
		return
	end

	-- 條形只顯示毛邊，數字模式同時顯示底色
	NineSlicePanelMixin.SetCenterColor(highlight, r, g, b, frame.mystyle == "NNP" and .8 or 0)
	NineSlicePanelMixin.SetBorderColor(highlight, r, g, b, .8)
	highlight:Show()
end

-- 目標與焦點高亮的更新
local function RefreshHighlight_TargetFocus()
	-- 儲存舊frame
	local previousTarget = targetNameplate
	local previousFocus = focusNameplate
	-- 取得新frame
	targetNameplate = GetNameplateUnitFrame("target")
	focusNameplate = GetNameplateUnitFrame("focus")

	UpdateHighlight(previousTarget)		-- 更新舊目標
	UpdateHighlight(previousFocus)		-- 更新舊焦點
	UpdateHighlight(targetNameplate)	-- 更新新目標
	UpdateHighlight(focusNameplate)		-- 更新新焦點
	UpdateHighlight(mouseoverNameplate)	-- 更新指向判斷
end

-- 指向高亮的更新
local function RefreshHighlight_Mouseover()
	-- 儲存舊frame
	local previous = mouseoverNameplate
	-- 取得新frame
	mouseoverNameplate = GetNameplateUnitFrame("mouseover")
	-- 指向改變時清除舊 frame 的高亮
	if previous ~= mouseoverNameplate then UpdateHighlight(previous) end
	-- 更新目前指向高亮
	UpdateHighlight(mouseoverNameplate)
	highlightController:SetShown(mouseoverNameplate ~= nil)
end

-- 統一處理高亮變化
local function OnHighlightEvent(self, event)
	if event == "UPDATE_MOUSEOVER_UNIT" then
		RefreshHighlight_Mouseover()
	else
		RefreshHighlight_TargetFocus()
	end
end

-- 指向高亮的 OnUpdate：UPDATE_MOUSEOVER_UNIT 只管移入，不管移出
local function OnHighlightUpdate(self, elapsed)
	self.elapsed = self.elapsed + elapsed
	if self.elapsed >= .1 then
		self.elapsed = 0
		RefreshHighlight_Mouseover()
	end
end

-- 每張名條只建立一組高亮，由公開 frame 身分決定目前顏色與顯示狀態
local function CreateHighlight(self)
	self.Highlight = CreateHighlightTexture(self)
	UpdateHighlight(self)
end

--=======================================================--
-----------------    [[ NamePlates ]]    ------------------
--=======================================================--

-- 堆疊範圍固定跟隨名條基底尺寸，以免出現變動
local function CreateNameplateStackingBounds(self)
	local bounds = CreateFrame("Frame", nil, self)
	if self.mystyle == "BNP" and showNameplateAuras then
		-- 固定向上預留一個光環高度，不隨光環顯隱改變
		bounds:SetPoint("TOPLEFT", self, "TOPLEFT", 0, C.NPAuraSize)
		bounds:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", 0, 0)
	else
		bounds:SetAllPoints(self)
	end

	-- 用透明材質填滿框架
	local texture = bounds:CreateTexture(nil, "BACKGROUND")
	texture:SetColorTexture(1, 1, 1, 0)
	texture:SetAllPoints(bounds)

	self.StackingBounds = bounds
end

-- [[ 數字模式 ]] --

local function CreateNameplate_Number(self)
	self.mystyle = "NNP"
	CreateNameplateStackingBounds(self)

	self.RingCastActive = false

	-- 隱藏的血量條：Health 只供 oUF 更新真實血量與 calculator
	local Health = F.CreateStatusbar(self, nil, "ARTWORK", 1, C.NPWidth, 0, 0, 0, 0)
	Health:SetPoint("BOTTOM", self, "BOTTOM")
	Health:SetFrameLevel(self:GetFrameLevel() + 2)
	Health:GetStatusBarTexture():SetAlpha(0)
	Health.colorTapping = true
	Health.colorClass = true
	Health.colorReaction = true
	Health.colorThreat = true
	Health.colorHealth = true
	self.Health = Health
	self.Health.UpdateColor = UpdateHealthColor
	self.Health.PostUpdateColor = PostUpdateHealthColor_Number
	self.Health.PostUpdate = PostUpdateHealth_Number

	-- 名字：保持在 Health 底部，層級低於施法環
	local NameLayer = CreateFrame("Frame", nil, self.Health)
	NameLayer:SetAllPoints(self.Health)
	NameLayer:SetFrameLevel(self:GetFrameLevel() + 3)
	self.Name = F.CreateText(NameLayer, "OVERLAY", G.Font, G.NPNameFS+4, G.FontFlag, "CENTER")
	self.Name:SetPoint("BOTTOM", self.Health, "BOTTOM")

	-- 百分比
	self.HealthText = F.CreateText(self.Health, "OVERLAY", G.NPFont, G.NPFS, G.FontFlag, "CENTER")
	self.HealthText:SetPoint("BOTTOM", self.Name, "TOP", 0, 3)
	self.HealthText:SetTextColor(1, 1, 1)

	-- 從兩個 FontString 的公開行高取得框體高度，建立布局
	local nameHeight = self.Name:GetLineHeight()
	local healthTextHeight = self.HealthText:GetLineHeight()
	local healthHeight = nameHeight + 3 + healthTextHeight
	self.Name:SetHeight(nameHeight)
	self.HealthText:SetHeight(healthTextHeight)
	Health:SetHeight(healthHeight)

	local RaidIcon = self.Health:CreateTexture(nil, "OVERLAY")
	RaidIcon:SetSize(24, 24)
	RaidIcon:SetTexture(G.media.raidicon)
	RaidIcon:SetPoint("RIGHT", self.Name, "LEFT", -2, 0)
	self.RaidTargetIndicator = RaidIcon

	-- 施法環
	CreateCastbar_Ring(self)

	if showNameplateAuras then
		-- 給光環定位用的隱藏狀態條
		local layoutHeight = (healthHeight - 2) -- 上位位置-2px 補回百分比字型的上方版面留空
		local Layout = F.CreateStatusbar(Health, nil, "BACKGROUND")
		Layout:SetPoint("BOTTOMLEFT", Health, "BOTTOMLEFT")
		Layout:SetPoint("BOTTOMRIGHT", Health, "BOTTOMRIGHT")
		Layout:SetHeight(layoutHeight)
		Layout:SetOrientation("VERTICAL")
		Layout:SetMinMaxValues(0, 1)
		Layout:SetStatusBarColor(0, 1, 1)
		Layout:GetStatusBarTexture():SetAlpha(0)
		Health.Layout = Layout
		Health.LayoutFullValue = (nameHeight / layoutHeight)	-- 滿血時高度，換成百分比
		Health.LayoutCurve = C_CurveUtil.CreateCurve()
		Health.LayoutCurve:SetType(Enum.LuaCurveType.Step)
		Health.LayoutCurve:AddPoint(0, 1)	-- 不滿血，填充100%
		Health.LayoutCurve:AddPoint(1, Health.LayoutFullValue)	-- 滿血，填到前面計算的高度

		T.CreateNameplateAuras(self)
		self.Auras:SetPoint("BOTTOM", Layout:GetStatusBarTexture(), "TOP", 0, 3)	-- 和百分比一樣與名字相距3px
	end
	if showTargetHighlight or showMouseoverHighlight then
		CreateHighlight(self)
	end
	UpdateLayout_Number(self, true)
end

-- [[ 條形模式 ]] --

local function CreateNameplate_Bar(self)
	self.mystyle = "BNP"
	CreateNameplateStackingBounds(self)
	
	-- 血量
	local Health = F.CreateStatusbar(self, nil, "ARTWORK", C.NPHeight, C.NPWidth, 0, 0, 0, 1)
	Health:SetPoint("CENTER", self, 0, 0)
	Health:SetFrameLevel(self:GetFrameLevel() + 3)
	-- 選項
	Health.colorTapping = true
	Health.colorClass = true
	Health.colorReaction = true
	Health.colorThreat = true
	Health.colorHealth = true
	-- 陰影
	Health.border = F.CreateSD(Health, Health, 3)
	-- 背景
	T.CreateMultiplierBG(Health)
	-- 註冊到ouf
	self.Health = Health
	self.Health.UpdateColor = UpdateHealthColor
	self.Health.PostUpdateColor = PostUpdateHealthColor_Bar
	
	-- 名字
	self.Name = F.CreateText(self.Health, "OVERLAY", G.Font, G.NPNameFS, G.FontFlag, "CENTER")
	self.Name:SetPoint("BOTTOM", self.Health, "TOP",  0, 4)

	-- 血量
	self.Health.value = F.CreateText(self.Health, "OVERLAY", G.Font, G.NPNameFS, G.FontFlag, "RIGHT")
	self.Health.value:SetPoint("BOTTOMRIGHT", self.Health, "TOPRIGHT", 0, -4)
	-- 團隊標記
	local RaidIcon = Health:CreateTexture(nil, "OVERLAY")
	RaidIcon:SetSize(28, 28)
	RaidIcon:SetTexture(G.media.raidicon)
	RaidIcon:SetPoint("RIGHT", self.Name, "LEFT", -2, 0)
	self.RaidTargetIndicator = RaidIcon

	-- 施法條
	CreateCastbar_Bar(self)
	-- 只顯示傷害吸收；敵方名條不顯示治療吸收
	T.CreateHealthPrediction(self, false)
	
	-- 光環
	if showNameplateAuras then
		T.CreateNameplateAuras(self)
		self.Auras:SetPoint("BOTTOM", self.Name, "TOP", 0, 4)
	end
	if showTargetHighlight or showMouseoverHighlight then
		CreateHighlight(self)
	end
end

-- nameplate driver 新增框架時重置狀態並更新所有高亮
local function UpdateNameplateState(self)
	-- 名條復用時先清掉上一個單位留下的施法狀態
	if self.mystyle == "NNP" then
		UpdateLayout_Number(self, true)
	end

	if highlightController then
		RefreshHighlight_TargetFocus()
		if showMouseoverHighlight then
			RefreshHighlight_Mouseover()
		end
	end
end

-- nameplate driver 移除框架時，隱藏高亮並清除數字模式布局狀態
local function ResetNameplateHighlights(self)
	if targetNameplate == self then targetNameplate = nil end
	if focusNameplate == self then focusNameplate = nil end
	if mouseoverNameplate == self then
		mouseoverNameplate = nil
		-- 延遲補查；若移除事件與 mouseover 切換交錯，不會永久停掉 fallback。
		highlightController.elapsed = .1
		highlightController:Show()
	end

	if self.Highlight then
		-- pooled frame 再次使用時必須重算，不能沿用隱藏前的快取狀態。
		self.Highlight.highlightState = nil
		self.Highlight:Hide()
	end
	if self.mystyle == "NNP" then
		UpdateLayout_Number(self, true)
	end
end

--=======================================================--
-----------------    [[ PlayerPlate ]]    -----------------
--=======================================================--

-- [[ 自行創建玩家名條，取代暴雪的個人資源 ]] --
local function CreateNameplate_PlayerPlate(self, unit)
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

oUF:Factory(function(self)
	-- oUF 的 Spawn 會停用 Blizzard PlayerFrame，所以玩家個人資源選項只能掛在 unitframes 下
	if F.GetRuriOption("PlayerPlate") and F.GetRuriOption("UnitFrames") then
		SetCVar("nameplateShowSelf", 0)
		self:RegisterStyle("PlayerPlate", CreateNameplate_PlayerPlate)
		self:SetActiveStyle("PlayerPlate")
		local plate = self:Spawn("player", "oUF_PlayerPlate")
		plate:SetPoint(unpack(C.Position.PlayerPlate))
	end

	-- 名條
	if not F.GetRuriOption("Nameplates") then return end
	local numberStyle = F.GetRuriOption("NumberStyle")
	showNameplateAuras = F.GetRuriOption("ShowAuras")
	showTargetHighlight = F.GetRuriOption("HLTarget")
	showMouseoverHighlight = F.GetRuriOption("HLMouseover")

	-- 仇恨反轉
	if F.GetRuriOption("ReverseThreat") then
		local threatController = CreateFrame("Frame")
		threatController:RegisterEvent("PLAYER_ENTERING_WORLD")
		threatController:RegisterEvent("GROUP_ROSTER_UPDATE")
		threatController:RegisterEvent("PLAYER_ROLES_ASSIGNED")
		threatController:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
		threatController:SetScript("OnEvent", UpdateThreatMode)
		UpdateThreatMode()
	end

	-- 目標高亮
	if showTargetHighlight or showMouseoverHighlight then
		highlightController = CreateFrame("Frame")
		highlightController:RegisterEvent("PLAYER_TARGET_CHANGED")
		highlightController:RegisterEvent("PLAYER_FOCUS_CHANGED")
		highlightController:SetScript("OnEvent", OnHighlightEvent)
		highlightController:Hide()

		if showMouseoverHighlight then
			highlightController.elapsed = 0
			highlightController:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
			highlightController:SetScript("OnUpdate", OnHighlightUpdate)
		end
	end

	local createStyleFrames = (numberStyle and CreateNameplate_Number) or CreateNameplate_Bar
	self:RegisterStyle("Nameplate", function(frame)
		createStyleFrames(frame)
		frame:GetParent():SetStackingBoundsFrame(frame.StackingBounds)
		frame:Tag(frame.Name, "[name]")
		frame:Tag(frame.HealthText or frame.Health.value, "[np:hp]")
	end)
	self:SetActiveStyle("Nameplate")

	local driver = self:SpawnNamePlates("oUF_Nameplate")
	if numberStyle then
		-- native frame 作為固定名字列、百分比與圓環核心的點擊及堆疊範圍。
		driver:SetSize(C.NPWidth, 50)
	else
		driver:SetSize(C.NPWidth, C.NPHeight * 4)
	end
	driver:SetAddedCallback(UpdateNameplateState)
	driver:SetRemovedCallback(ResetNameplateHighlights)

	-- 只分批預建 30 個光環容器；戰鬥中暫停背景建立，空池仍即時建立並顯示。
	if showNameplateAuras then
		C_Timer.After(2, function()
			local prewarmed = 0
			C_Timer.NewTicker(.1, function(ticker)
				if InCombatLockdown() then return end

				T.PrewarmNameplateAuras()
				prewarmed = prewarmed + 1
				if prewarmed == 30 then
					ticker:Cancel()
				end
			end)
		end)
	end

	if highlightController then
		RefreshHighlight_TargetFocus()
		if showMouseoverHighlight then
			RefreshHighlight_Mouseover()
		end
	end
end)
