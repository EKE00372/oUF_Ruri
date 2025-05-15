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
		totemBar:SetPoint("TOPRIGHT", oUF_Player, "TOPLEFT", -altOffset, 0)
	else
		totemBar:SetSize(width, height)
		totemBar:SetPoint("BOTTOMLEFT", oUF_Player, "TOPLEFT", -Offset, 0)
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
				totem:SetPoint("BOTTOMLEFT", Offset, Offset)
			else
				totem:SetPoint("LEFT", totems[i-1], "RIGHT", Offset, 0)
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

local function UpdateTotemBarOffset()
    if not Ruri_TotemBar then return end            -- 圖騰條還未建立時防呆

    local extra = 0                                 -- 最終要再左移的距離
    local alt = _G["oUF_Player_AltPowerBar"]
    local pet = _G["ouf_pet"]

    -- 1. AltPower：多移 (C.PPHeight + C.PPOffset)
    if alt and alt:IsShown() then
        extra = extra + C.PPHeight + C.PPOffset
    end

    -- 2. Pet：多移 (C.PHeight + C.PPOffset)
    if pet and pet:IsShown() then
        extra = extra + C.PHeight + C.PPOffset
    end

    -- 3. 兩者皆存在時，自然加總；皆不存在時 extra 為 0
    local x = -C.PPOffset - extra                   -- 原始位移再減去 extra
    Ruri_TotemBar:ClearAllPoints()
    Ruri_TotemBar:SetPoint("BOTTOMLEFT", oUF_Player, "TOPLEFT", x, 0)
end

local alt = _G["oUF_Player_AltPowerBar"]
if alt then
alt:HookScript("OnShow", UpdateTotemBarOffset)
alt:HookScript("OnHide", UpdateTotemBarOffset)
end
local pet = _G["oUF_Pet"]
if pet then
pet:HookScript("OnShow", UpdateTotemBarOffset)
pet:HookScript("OnHide", UpdateTotemBarOffset)
UpdateTotemBarOffset()   -- 登入時執行一次
end

T.CreateTotemBar = function(self)
	TotemBar_Init()
	hooksecurefunc(TotemFrame, "Update", TotemBar_Update)
end
