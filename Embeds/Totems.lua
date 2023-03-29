local addon, ns = ...
local C, F, G, T = unpack(ns)

local _G = _G
local GetTotemInfo = GetTotemInfo

-- Style
local totems = {}

local function TotemBar_Init()
	local margin = 2
	local iconSize = 100
	local width = (iconSize*4 + margin*5)
	local height = (iconSize + margin*2)

	print("2")
	
	local totemBar = CreateFrame("Frame", "Ruri_TotemBar", UIParent)
	totemBar:SetSize(width, height)
	totemBar:ClearAllPoints()
	totemBar:SetPoint("CENTER", 0,0)

	for i = 1, 4 do
		local totem = totems[i]
		if not totem then
			totem = F.CreateSD(totemBar, totemBar, 3)
			totem.Icon = totem:CreateTexture(nil, "ARTWORK")
			totem.Icon:SetTexCoord(.08, .92, .08, .92)
			--totem.Icon:SetTexture("")
			--totem.CD = F.CreateText(totem, 
			
			
			totem:SetAlpha(0)
			totem:EnableMouse(true)
			totems[i] = totem
		end

		totem:SetSize(iconSize, iconSize)
		totem:ClearAllPoints()
		if i == 1 then
			totem:SetPoint("BOTTOMLEFT", margin, margin)
		else
			totem:SetPoint("LEFT", totems[i-1], "RIGHT", margin, 0)
		end
	end
end

local function TotemBar_Update()

	local activeTotems = 0
	for button in _G.TotemFrame.totemPool:EnumerateActive() do
		activeTotems = activeTotems + 1

		local haveTotem, _, start, dur, icon = GetTotemInfo(button.slot)
		print(GetTotemInfo(button.slot))
		local totem = totems[activeTotems]
		if haveTotem and dur > 0 then
			print("1")
			totem.Icon:SetTexture(icon)
			--totem.CD:SetCooldown(start, dur)
			--totem.CD:Show()
			totem:SetAlpha(1)
			totem:Show()
		else
			totem.Icon:SetTexture("")
			--totem.CD:Hide()
			totem:SetAlpha(0)
		end

		button:ClearAllPoints()
		button:SetParent(totem)
		button:SetAllPoints(totem)
		button:SetAlpha(0)
		button:SetFrameLevel(totem:GetFrameLevel() + 1)
	end

	for i = activeTotems+1, 4 do
		local totem = totems[i]
		totem.Icon:SetTexture("")
		--totem.CD:Hide()
		totem:SetAlpha(0)
	end
end


local frame = CreateFrame("FRAME")
	frame:RegisterEvent("PLAYER_LOGIN")
	frame:SetScript("OnEvent", function()
		TotemBar_Init()
		hooksecurefunc(TotemFrame, "Update", TotemBar_Update)
	end)
