local _, ns = ...
local F, G = ns[2], ns[3]

local function CrosshairsEnabled()
	return F.GetRuriOption("Crosshairs")
end

local function CreateCrosshairs()

	local overallAlpha = 0.7
	local lineAlpha = 0.7 -- Set to 0 to hide lines but keep the circle

	local f = CreateFrame('Frame', nil, WorldFrame)
	f:SetFrameStrata('HIGH')
	f:SetFrameLevel(0)
	f:SetPoint('CENTER')
	f:SetSize(64, 64)

	local uiScale = 1
	local screen_size = {GetPhysicalScreenSize()}
	if screen_size and screen_size[2] then
		uiScale = 768 / screen_size[2]
	end
	local lineWidth = uiScale * 2

	local circle = f:CreateTexture(nil, 'BACKGROUND')
	circle:SetTexture(G.media.circle)
	circle:SetAllPoints(f)
	circle:SetAlpha(overallAlpha)

	local left = f:CreateTexture(nil, 'BACKGROUND')
	left:SetColorTexture(1, 1, 1, overallAlpha)
	left:SetPoint('RIGHT', f, 'LEFT', 8, 0)
	left:SetSize(2000, lineWidth)

	local right = f:CreateTexture(nil, 'BACKGROUND')
	right:SetColorTexture(1, 1, 1, overallAlpha)
	right:SetPoint('LEFT', f, 'RIGHT', -8, 0)
	right:SetSize(2000, lineWidth)

	local top = f:CreateTexture(nil, 'BACKGROUND')
	top:SetColorTexture(1, 1, 1, overallAlpha)
	top:SetPoint('BOTTOM', f, 'TOP', 0, -8)
	top:SetSize(lineWidth, 2000)

	local bottom = f:CreateTexture(nil, 'BACKGROUND')
	bottom:SetColorTexture(1, 1, 1, overallAlpha)
	bottom:SetPoint('TOP', f, 'BOTTOM', 0, 8)
	bottom:SetSize(lineWidth, 2000)

	---[[
	circle:SetBlendMode('ADD')
	left:SetBlendMode('ADD')
	right:SetBlendMode('ADD')
	top:SetBlendMode('ADD')
	bottom:SetBlendMode('ADD')
	--]]

	local tx = f:CreateTexture(nil, 'BACKGROUND')
	tx:SetTexture(G.media.arrows)
	tx:SetAllPoints(f)

	local rotationGroup

	local function HideEverything()
		circle:Hide()
		left:Hide()
		right:Hide()
		top:Hide()
		bottom:Hide()
		tx:Hide()
		if rotationGroup then rotationGroup:Stop() end
	end

	local function ShowEverything()
		circle:Show()
		left:Show()
		right:Show()
		top:Show()
		bottom:Show()
		tx:Show()
		if rotationGroup and not rotationGroup:IsPlaying() then
			rotationGroup:Play()
		end
	end

	f:HookScript('OnHide', HideEverything)
	f:HookScript('OnShow', ShowEverything)
	f:Hide()

	rotationGroup = tx:CreateAnimationGroup()
	local rotation = rotationGroup:CreateAnimation('Rotation')
	rotation:SetDegrees(-360)
	rotation:SetDuration(5)
	rotationGroup:SetLooping('REPEAT')

	local group = tx:CreateAnimationGroup()
	group:SetToFinalAlpha(true)
	local pulseAlpha = group:CreateAnimation('Alpha')
	pulseAlpha:SetFromAlpha(0)
	pulseAlpha:SetToAlpha(1)
	pulseAlpha:SetDuration(0.5)

	local scale1 = group:CreateAnimation('Scale')
	scale1:SetScale(2, 2)
	scale1:SetDuration(0)

	local scale = group:CreateAnimation('Scale')
	scale:SetScale(0.5, 0.5)
	scale:SetDuration(0.5)

	local fadeOut = f:CreateAnimationGroup()
	fadeOut:SetToFinalAlpha(true)
	local fadeOutAlpha = fadeOut:CreateAnimation('Alpha')
	fadeOutAlpha:SetFromAlpha(1)
	fadeOutAlpha:SetToAlpha(0)
	fadeOutAlpha:SetDuration(0.2)
	fadeOut:SetScript('OnFinished', function() f:Hide() end)

	local fadeIn = f:CreateAnimationGroup()
	fadeIn:SetToFinalAlpha(true)
	local fadeInAlpha = fadeIn:CreateAnimation('Alpha')
	fadeInAlpha:SetOrder(1)
	fadeInAlpha:SetFromAlpha(0)
	fadeInAlpha:SetToAlpha(1)
	fadeInAlpha:SetDuration(0.2)

	local function SetColor(r, g, b)
		circle:SetVertexColor(r, g, b)
		left:SetVertexColor(r, g, b)
		right:SetVertexColor(r, g, b)
		top:SetVertexColor(r, g, b)
		bottom:SetVertexColor(r, g, b)
		tx:SetVertexColor(r, g, b)
	end

	-- Adjust line alpha based on combat status
	local function SetLineAlpha(alpha)
		left:SetAlpha(alpha)
		right:SetAlpha(alpha)
		top:SetAlpha(alpha)
		bottom:SetAlpha(alpha)
	end

	-- Initial state
	SetLineAlpha(lineAlpha)

	local function FocusPlate(plate)
		fadeOut:Stop()
		f:ClearAllPoints()
		f:SetPoint('CENTER', plate)
		if not f:IsShown() then
			fadeIn:Play()
		end

		f:Show()
		group:Play()

		local r, g, b = 1, 1, 1
		--if UnitIsTapped('target') and not UnitIsTappedByPlayer('target') and not UnitIsTappedByAllThreatList('target') then
		if UnitIsTapDenied('target') then
			--SetColor(0.5, 0.5, 0.5)
			r, g, b = 0.5, 0.5, 0.5
		elseif UnitIsPlayer('target') then
			local _, class = UnitClass('target')
			local colors = C_ClassColor.GetClassColor(class)
			if colors then
				r, g, b = colors.r, colors.g, colors.b
			else
				r, g, b = 0.274, 0.705, 0.392 --70/255,  180/255, 100/255
			end
		elseif UnitIsOtherPlayersPet('target') then
			r, g, b = 0.6, 0.6, 0.6
		else
			r, g, b = UnitSelectionColor('target')
		end
		SetColor(r, g, b)
	end

	function f:PLAYER_TARGET_CHANGED()
		if not CrosshairsEnabled() then
			fadeOut:Play()
			return
		end

		local nameplate = C_NamePlate.GetNamePlateForUnit('target')
		if nameplate then
			FocusPlate(nameplate)
			--TargetLock:Show()
		else
			fadeOut:Play()
		end
	end
	f:RegisterEvent('PLAYER_TARGET_CHANGED')

	function f:PLAYER_ENTERING_WORLD()
		-- PLAYER_TARGET_CHANGED doesn't fire when you lose your target from zoning
		self:PLAYER_TARGET_CHANGED()
	end
	f:RegisterEvent('PLAYER_ENTERING_WORLD')

	function f:NAME_PLATE_UNIT_ADDED(unit)
		if not CrosshairsEnabled() then return end

		local nameplate = C_NamePlate.GetNamePlateForUnit(unit)
		if nameplate and nameplate == C_NamePlate.GetNamePlateForUnit('target') then
			FocusPlate(nameplate)
			--TargetLock:Show()
		end
	end
	f:RegisterEvent('NAME_PLATE_UNIT_ADDED')

	function f:NAME_PLATE_UNIT_REMOVED(unit)
		if not CrosshairsEnabled() then return end

		local nameplate = C_NamePlate.GetNamePlateForUnit(unit)
		local targetPlate = C_NamePlate.GetNamePlateForUnit('target')
		if not targetPlate or targetPlate == nameplate then
			fadeOut:Play()
		end
	end
	f:RegisterEvent('NAME_PLATE_UNIT_REMOVED')

	f:SetScript('OnEvent', function(self, event, ...) return self[event] and self[event](self, ...) end)
end

local loader = CreateFrame('Frame')
loader:RegisterEvent('PLAYER_LOGIN')
loader:SetScript('OnEvent', function(self, event)
	self:UnregisterEvent(event)
	self:SetScript('OnEvent', nil)
	if CrosshairsEnabled() then
		CreateCrosshairs()
	end
end)
