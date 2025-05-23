local addon, ns = ...
local C, F, G, T = unpack(ns)
local oUF = ns.oUF or oUF

-- https://github.com/FireSiku/LUI/blob/master/modules/unitframes/layout/layout.lua
-- https://github.com/siweia/NDui/blob/master/Interface/AddOns/NDui/Modules/Auras/Totems.lua

if not C.Totems then return end

local _G = _G
local GetTotemInfo = GetTotemInfo
local GetTime = GetTime
local totems = {}
local MAX_TOTEMS = 4

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
	local vertical = C.vertPlayer				-- 判斷直式或橫式
	local Offset = C.PPOffset					-- 圖騰間距
	local altOffset = C.PPHeight + C.PPOffset	-- 特殊能量條存在時偏移
	local iconSize = (C.buSize + 4)				-- 和玩家自身光環一樣大
	local width = (iconSize*4 + Offset*5)		-- 上下左右都要多
	local height = (iconSize + Offset*2)
	
	-- 創建圖騰條
	local totemBar = CreateFrame("Frame", "Ruri_TotemBar", oUF_Player)
	totemBar:ClearAllPoints()
	if vertical then
		totemBar:SetSize(height, width)
		totemBar:SetPoint("TOPRIGHT", oUF_Player, "TOPLEFT", -altOffset, 0) -- 直式在能量條左
	else
		totemBar:SetSize(width, height)
		totemBar:SetPoint("TOPRIGHT", oUF_Player, "BOTTOMRIGHT", -altOffset, -Offset) -- 橫式在能量條下
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
		if vertical then
			if i == 1 then
				totem:SetPoint("TOP", 0, 0)
			else
				totem:SetPoint("TOP", totems[i-1], "BOTTOM", 0, -Offset)
			end
		else
			if i == 1 then
				totem:SetPoint("BOTTOMRIGHT", Offset, Offset)
			else
				totem:SetPoint("RIGHT", totems[i-1], "LEFT", -Offset, 0)
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
			--totem.CD:SetCooldown(start, dur)
			--totem.CD:Show()
			totem:SetAlpha(1)
			
			-- 獲取時間，起始+持續=結束
			totem.expirationTime = dur + start
			totem:SetScript("OnUpdate", Totems_Update)
			totem:Show()
		else
			totem.Icon:SetTexture("")
			--totem.CD:Hide()
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

T.CreateTotemBar = function(self)
	TotemBar_Init()
	hooksecurefunc(TotemFrame, "Update", TotemBar_Update)
end

-- 判斷是否顯示替代能量

local function HasAltPower()
    local barID = UnitPowerBarID("player")       -- 0 == 沒有 AltPowerBar
    return barID and barID ~= 0
end

local function UpdateTotemBarOffset()
    if not Ruri_TotemBar then return end         -- 圖騰條還未建立時防呆

	local hasAlt = HasAltPower()
	local hasPet = UnitExists("pet")

	local vertical = C.vertPlayer
	local offsetBase = C.PPOffset
    local altOffset  = C.PPHeight + offsetBase
    local petOffset  = C.PHeight  + offsetBase

    Ruri_TotemBar:ClearAllPoints()
	if vertical then
		local x
		if hasAlt and hasPet then
			x = -(altOffset + petOffset)
		elseif hasAlt then
			x = -altOffset*2
		elseif hasPet then
			x = -petOffset
		else
			x = -offsetBase
		end

		Ruri_TotemBar:SetPoint("TOPRIGHT", oUF_Player, "TOPLEFT", x, 0)
	else
		local x, y
		if hasAlt then
			x, y = -OffsetBase, -altOffset*2
		else
			x, y = -offsetBase, -altOffset
		end

		Ruri_TotemBar:SetPoint("TOPRIGHT", oUF_Player, "BOTTOMRIGHT", x, y)
	end
end

--========================================================
-- 事件監聽：登入／寵物變化／AltPower 顯示 & 隱藏
--========================================================
local offsetWatcher = CreateFrame("Frame")
offsetWatcher:RegisterEvent("PLAYER_ENTERING_WORLD")
offsetWatcher:RegisterEvent("UNIT_PET")
offsetWatcher:RegisterEvent("UNIT_POWER_BAR_SHOW")
offsetWatcher:RegisterEvent("UNIT_POWER_BAR_HIDE")
offsetWatcher:SetScript("OnEvent", UpdateTotemBarOffset)