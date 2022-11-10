local addon, ns = ...
local C, F, G, T = unpack(ns)
local oUF = ns.oUF or oUF

if not C.Crosshairs then return end

local alpha = 0.7 -- Overall alpha
local Speed = 10 -- Higher number moves crosshair faster
local lineAlpha = 0.7 -- Set to 0 to hide lines but keep the circle

local _, addon = ...

local f = CreateFrame('frame', "Crosshairs", WorldFrame)
--LibStub('LibNameplateRegistry-1.0'):Embed(f)
f:SetFrameLevel(0)
f:SetFrameStrata('BACKGROUND')
f:SetPoint('CENTER')
f:SetSize(64, 64)
--f:SetAlpha(0.5)

local uiScale = 1
local screen_size = {GetPhysicalScreenSize()}
if screen_size and screen_size[2] then
	uiScale = 768 / screen_size[2]
end
local lineWidth = uiScale * 2

local circle = WorldFrame:CreateTexture(nil, 'BACKGROUND')
circle:SetTexture(G.media.circle)
circle:SetAllPoints(f)
circle:SetAlpha(alpha)
--circle:SetPoint('CENTER')
--circle:SetSize(86, 86)

local left = WorldFrame:CreateTexture(nil, 'BACKGROUND')
left:SetColorTexture(1, 1, 1, alpha)
left:SetPoint('RIGHT', f, 'LEFT', 8, 0)
left:SetSize(2000, lineWidth)

local right = WorldFrame:CreateTexture(nil, 'BACKGROUND')
right:SetColorTexture(1, 1, 1, alpha)
right:SetPoint('LEFT', f, 'RIGHT', -8, 0)
right:SetSize(2000, lineWidth)

local top = WorldFrame:CreateTexture(nil, 'BACKGROUND')
top:SetColorTexture(1, 1, 1, alpha)
top:SetPoint('BOTTOM', f, 'TOP', 0, -8)
top:SetSize(lineWidth, 2000)

local bottom = WorldFrame:CreateTexture(nil, 'BACKGROUND')
bottom:SetColorTexture(1, 1, 1, alpha)
bottom:SetPoint('TOP', f, 'BOTTOM', 0, 8)
bottom:SetSize(lineWidth, 2000)

---[[
circle:SetBlendMode('ADD')
left:SetBlendMode('ADD')
right:SetBlendMode('ADD')
top:SetBlendMode('ADD')
bottom:SetBlendMode('ADD')
--]]

local tx = WorldFrame:CreateTexture(nil, 'BACKGROUND')
tx:SetTexture(G.media.arrows)
tx:SetAllPoints(f)
--tx:SetPoint('CENTER')
--tx:SetSize(86, 86)
--tx:SetAlpha(0.5)

local function HideEverything()
	circle:Hide()
	left:Hide()
	right:Hide()
	top:Hide()
	bottom:Hide()
	tx:Hide()
end

local function ShowEverything()
	circle:Show()
	left:Show()
	right:Show()
	top:Show()
	bottom:Show()
	tx:Show()
end

f:HookScript('OnHide', HideEverything)
f:HookScript('OnShow', ShowEverything)
f:Hide()

local ag = tx:CreateAnimationGroup()
local rotation = ag:CreateAnimation('Rotation')
rotation:SetDegrees(-360)
rotation:SetDuration(5)
ag:SetLooping('REPEAT')
ag:Play()

local group = tx:CreateAnimationGroup()
group:SetToFinalAlpha(true)
local alpha = group:CreateAnimation('Alpha')
alpha:SetFromAlpha(0)
alpha:SetToAlpha(1)
--alpha:SetChange(-1)
--alpha:SetOrder(1)
alpha:SetDuration(0.5)

--local alpha2 = group:CreateAnimation('Alpha')
--alpha2:SetChange(1)
--alpha2:SetDuration(0.5)
--alpha2:SetOrder(2)
--alpha2:SetSmoothing('OUT')

local scale1 = group:CreateAnimation('Scale')
--scale1:SetOrder(2)
scale1:SetScale(2, 2)
scale1:SetDuration(0)

local scale = group:CreateAnimation('Scale')
--scale:SetOrder(2)
scale:SetScale(0.5, 0.5)
scale:SetDuration(0.5)
--scale:SetSmoothing('IN')

local fadeOut = f:CreateAnimationGroup()
fadeOut:SetToFinalAlpha(true)
local alpha = fadeOut:CreateAnimation('Alpha')
--alpha:SetChange(-1)
alpha:SetFromAlpha(1)
alpha:SetToAlpha(0)
alpha:SetDuration(0.2)
fadeOut:SetScript('OnFinished', function(self) f:Hide() end)


local fadeIn = f:CreateAnimationGroup()
fadeIn:SetToFinalAlpha(true)
local alpha1 = fadeIn:CreateAnimation('Alpha')
alpha1:SetOrder(1)
--alpha1:SetChange(-1)
alpha1:SetFromAlpha(0)
alpha1:SetToAlpha(1)
alpha1:SetDuration(0.2)

--local alpha = fadeIn:CreateAnimation('Alpha')
--alpha:SetChange(1)
--alpha:SetOrder(2)
--alpha:SetDuration(0.2)
fadeOut:SetScript('OnFinished', function(self) f:Hide() end)

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

-- fade in if our crosshairs weren't visible
local Moving = false
local function FocusPlate(plate)
    --f:SetPoint('CENTER', plate)
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
		if class and RAID_CLASS_COLORS[class] then
			local colors = RAID_CLASS_COLORS[class]
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
	
	
	--Moving = GetTime()
end

function f:PLAYER_TARGET_CHANGED()
	local nameplate = C_NamePlate.GetNamePlateForUnit('target') --f:GetPlateByGUID(targetGUID)
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

local xFactor, yFactor = 1, 1 -- pixel perfect stuff, just try and prevent it from screwing up our lines
function ScaleCoords(xPixel, yPixel, trueScale)
	local x, y  = xPixel / xFactor, yPixel / yFactor
	x, y = x - x % 1, y - y % 1 -- floor
	return trueScale and (xPixel * xFactor) or (x * xFactor), trueScale and (xPixel * xFactor) or (y * yFactor)
end

function f:NAME_PLATE_UNIT_ADDED(unit)
	local nameplate = C_NamePlate.GetNamePlateForUnit(unit)
	if nameplate and UnitIsUnit('target', unit) then
		FocusPlate(nameplate)
		--TargetLock:Show()
	end
end
f:RegisterEvent('NAME_PLATE_UNIT_ADDED')

function f:NAME_PLATE_UNIT_REMOVED(unit)
	local nameplate = C_NamePlate.GetNamePlateForUnit(unit)
	if UnitIsUnit('target', unit) then
		fadeOut:Play()
	end
end
f:RegisterEvent('NAME_PLATE_UNIT_REMOVED')

f:SetScript('OnEvent', function(self, event, ...) return self[event] and self[event](self, ...) end)
