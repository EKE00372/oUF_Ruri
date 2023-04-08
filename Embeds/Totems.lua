local addon, ns = ...
local C, F, G, T = unpack(ns)
local oUF = ns.oUF or oUF

-- https://github.com/FireSiku/LUI/blob/master/modules/unitframes/layout/layout.lua
-- https://github.com/siweia/NDui/blob/master/Interface/AddOns/NDui/Modules/Auras/Totems.lua

if not C.Totems then return end

local _G = _G
local GetTotemInfo = GetTotemInfo
local totems = {}

-- 幹掉CooldownFrameTemplate，用OnUpdate顯示秒數
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

-- 初始化
local function TotemBar_Init()
	local margin = C.PPOffset
	local iconSize = (C.buSize + 4)			-- 和玩家自身光環一樣大
	local width = (iconSize*4 + margin*5)	-- 上下左右都要多margin
	local height = (iconSize + margin*2)
	
	-- 創建圖騰條
	local totemBar = CreateFrame("Frame", "Ruri_TotemBar", oUF_Player)
	totemBar:ClearAllPoints()
	if C.vertPlayer then
		totemBar:SetSize(height, width)
		totemBar:SetPoint("TOPRIGHT", oUF_Player, "TOPLEFT", -(C.PPHeight + C.PPOffset), 0)	-- C.PPHeight + C.PPOffset*2 - margin
	else
		totemBar:SetSize(width, height)
		totemBar:SetPoint("BOTTOMLEFT", oUF_Player, "TOPLEFT", -C.PPOffset, 0)
	end

	for i = 1, 4 do
		local totem = totems[i]
		if not totem then
			totem = F.CreateBD(totemBar, totemBar, 1)
			totem.BD = F.CreateSD(totem, totem, 3)
			
			totem.Icon = totem:CreateTexture(nil, "OVERLAY")
			totem.Icon:SetTexCoord(.08, .92, .08, .92)
			totem.Icon:SetAllPoints(totem)
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
		if C.vertPlayer then
			if i == 1 then
				totem:SetPoint("TOP", 0, 0)
			else
				totem:SetPoint("TOP", totems[i-1], "BOTTOM", 0, -margin)
			end
		else
			if i == 1 then
				totem:SetPoint("BOTTOMLEFT", margin, margin)
			else
				totem:SetPoint("LEFT", totems[i-1], "RIGHT", margin, 0)
			end
		end
	end
end

-- 更新
local function TotemBar_Update(self)

	local activeTotems = 0
	for button in _G.TotemFrame.totemPool:EnumerateActive() do
		activeTotems = activeTotems + 1

		local haveTotem, _, start, dur, icon = GetTotemInfo(button.slot)
		
		local totem = totems[activeTotems]
		if haveTotem and dur > 0 then
			totem.Icon:SetTexture(icon)
			totem:SetAlpha(1)
			
			-- 獲取時間，起始+持續=結束
			totem.expirationTime = dur + start
			totem:SetScript("OnUpdate", Totems_Update)
			totem:Show()
		else
			totem.Icon:SetTexture("")
			totem:SetAlpha(0)
		end

		-- hide blizzard original totem frame / 幹掉暴雪圖騰條
		button:ClearAllPoints()
		button:SetParent(totem)
		button:SetAllPoints(totem)
		button:SetAlpha(0)
		button:SetFrameLevel(totem:GetFrameLevel() + 1)
	end

	for i = activeTotems + 1, 4 do
		local totem = totems[i]
		totem.Icon:SetTexture("")
		totem:SetAlpha(0)
	end
end

-- 動起來
--[[local frame = CreateFrame("FRAME")
	frame:RegisterEvent("PLAYER_LOGIN")
	frame:SetScript("OnEvent", function()
		TotemBar_Init()
		hooksecurefunc(TotemFrame, "Update", TotemBar_Update)
	end)]]--

T.CreateTotemBar = function(self)
	TotemBar_Init()
	hooksecurefunc(TotemFrame, "Update", TotemBar_Update)
end
	
--[[
local function Enable(self, unit)
	if self.unit ~= unit or unit ~= 'player' then return end
	
	local element = self.Totems
	if element then
		element.__owner = self
		element.ForceUpdate = ForceUpdate
		
		self:RegisterEvent("PLAYER_ENTERING_WORLD")
	
	end
end

local function Disable(self)
	self:UnregisterEvent("PLAYER_ENTERING_WORLD")
end

oUF:AddElement('TotemBar', Update, Enable, Disable)]]--