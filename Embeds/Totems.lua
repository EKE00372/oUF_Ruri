local addon, ns = ...
local C, F, G, T = unpack(ns)

-- https://github.com/FireSiku/LUI/blob/master/modules/unitframes/layout/layout.lua
-- https://github.com/siweia/NDui/blob/master/Interface/AddOns/NDui/Modules/Auras/Totems.lua

local _G = _G
local GetTotemInfo = GetTotemInfo

-- Style
local totems = {}

local function Totems_Update(self, elapsed)
	self.elapsed = (self.elapsed or 0) + elapsed
	
	if self.elapsed >= .1 then
		local timeLeft = self.expirationTime - GetTime()
		if timeLeft > 0 then
			self.CD:SetText(F.FormatTime(timeLeft))
		else
			self:SetScript("OnUpdate", nil)
			self.CD:SetText("")
		end
		self.elapsed = 0
	end
end

local function TotemBar_Init()
	local margin = 6
	local iconSize = (C.buSize + 4)
	local width = (iconSize*4 + margin*5)
	local height = (iconSize + margin*2)
	
	local totemBar = CreateFrame("Frame", "Ruri_TotemBar", oUF_Player)
	totemBar:SetSize(width, height)
	totemBar:ClearAllPoints()
	totemBar:SetPoint("CENTER", 0,0)

	for i = 1, 4 do
		local totem = totems[i]
		if not totem then
			totem = F.CreateSD(totemBar, totemBar, 3)
			
			totem.Icon = totem:CreateTexture(nil, "OVERLAY")
			totem.Icon:SetTexCoord(.08, .92, .08, .92)
			totem.Icon:ClearAllPoints()
			totem.Icon:SetPoint("TOPLEFT", totem, 3, -3)
			totem.Icon:SetPoint("BOTTOMRIGHT", totem, -3, 3)
			totem.Icon:SetTexture("")
			
			totem.CD = F.CreateText(totem, "OVERLAY", G.Font, G.NumberFS, G.FontFlag, "CENTER")
			--totem.CD = CreateFrame("Cooldown", nil, self, "CooldownFrameTemplate")
			--totem.CD:SetAllPoints(totem)
			totem.CD:ClearAllPoints()
			totem.CD:SetPoint("TOP", totem, 0, 4)
			
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

local function TotemBar_Update(self)

	local activeTotems = 0
	for button in _G.TotemFrame.totemPool:EnumerateActive() do
		activeTotems = activeTotems + 1

		local haveTotem, _, start, dur, icon = GetTotemInfo(button.slot)
		
		local totem = totems[activeTotems]
		if haveTotem and dur > 0 then
			totem.Icon:SetTexture(icon)
			totem:SetAlpha(1)
			
			-- get time
			totem.expirationTime = dur + start
			totem:SetScript("OnUpdate", Totems_Update)
			totem:Show()
		else
			totem.Icon:SetTexture("")
			totem:SetAlpha(0)
		end

		-- hide blizzard original totem frame
		button:ClearAllPoints()
		button:SetParent(totem)
		button:SetAllPoints(totem)
		button:SetAlpha(0)
		button:SetFrameLevel(totem:GetFrameLevel() + 1)
	end

	for i = activeTotems+1, 4 do
		local totem = totems[i]
		totem.Icon:SetTexture("")
		totem:SetAlpha(0)
	end
end


local frame = CreateFrame("FRAME")
	frame:RegisterEvent("PLAYER_LOGIN")
	frame:SetScript("OnEvent", function()
		TotemBar_Init()
		hooksecurefunc(TotemFrame, "Update", TotemBar_Update)
	end)
