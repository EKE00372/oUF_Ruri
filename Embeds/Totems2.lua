--[[--------------------------------------------------------------------
  Embeds/TotemBar.lua
  把暴雪 TotemFrame 的 4 顆 Secure 按鈕收編成 oUF 元素 — TotemBar
------------------------------------------------------------------------]]

local addon, ns = ...
local C, F, G, T = unpack(ns)             -- API.lua 內工具
local oUF = ns.oUF or oUF
if not C.Totems then return end           -- Config.lua 開關

-- =====================================================================
-- 快取 API
-- =====================================================================
local MAX_TOTEMS       = 4
local GetTotemInfo     = GetTotemInfo
local GetTime          = GetTime
local InCombatLockdown = InCombatLockdown

-- =====================================================================
-- 冷卻文字更新
-- =====================================================================
local function CooldownOnUpdate(btn, elapsed)
    btn.elapsed = (btn.elapsed or 0) + elapsed
    if btn.elapsed < .25 then return end
    btn.elapsed = 0

    local remain = btn.expire - GetTime()
    if remain > 0 then
        btn.time:SetText(F.FormatTime(remain))
    else
        btn:SetScript("OnUpdate", nil)
        btn.time:SetText("")
    end
end

-- =====================================================================
-- 元素更新 (oUF Path)
-- =====================================================================
local function Update(self, event)
    local element = self.TotemBar
    if not element.styled then return end           -- 尚未完成 Setup

    if element.PreUpdate then element:PreUpdate(event) end

    local active = 0
    for slot = 1, MAX_TOTEMS do
        local btn = element.buttons[slot]
        local have, _, start, dur, icon = GetTotemInfo(slot)

        if have and dur > 0 then
            active      = active + 1
            btn.expire  = start + dur
            btn.icon:SetTexture(icon)
            btn:SetAlpha(1)
            btn:SetScript("OnUpdate", CooldownOnUpdate)
        else
            btn.icon:SetTexture(G.media.grey)
            btn:SetAlpha(.25)
            btn:SetScript("OnUpdate", nil)
            btn.time:SetText("")
        end
    end

    if element.PostUpdate then element:PostUpdate(active, event) end
end

local function Path(self, ...)
    return (self.TotemBar.Override or Update)(self, ...)
end

local function ForceUpdate(element)
    return Path(element.__owner, "ForceUpdate")
end

-- =====================================================================
-- 抓取 & 美化暴雪按鈕
-- =====================================================================
local function StyleButtons(element)
    for i = 1, MAX_TOTEMS do
        ----------------------------------------------------------------
        -- 1. 取得暴雪 Secure 按鈕
        ----------------------------------------------------------------
        local btn = _G["TotemFrameTotem"..i]
        if not btn and TotemFrame.totemPool then
            TotemFrame:Show()                          -- 確保 first build
            btn = TotemFrame.totemPool:Acquire()
        end
        if not btn then
            print("TotemBar: Blizzard buttons not ready, retry next PEW")
            return                                     -- 下次事件再試
        end
        element.buttons[i] = btn

        btn:SetParent(element)
        btn:Show()

        ----------------------------------------------------------------
        -- 2. 去框 & 抓 icon
        ----------------------------------------------------------------
        local border = btn.Border or select(1, btn:GetRegions())
        if border and border.SetTexture then border:SetTexture(nil) end

        -- 穩定抓 icon
        local icon = btn.Icon
                or _G[btn:GetName().."Icon"]
                or _G[btn:GetName().."IconTexture"]
        if not (icon and icon.GetObjectType and icon:GetObjectType()=="Texture") then
            icon = nil
            for r = 1, btn:GetNumRegions() do
                local region = select(r, btn:GetRegions())
                if region and region:IsObjectType("Texture") then
                    icon = region; break
                end
            end
        end
        if not icon then                                -- 最後保險
            icon = btn:CreateTexture(nil,"ARTWORK")
            icon:SetAllPoints()
        end
        btn.icon = icon
        icon:SetAllPoints()
        icon:SetTexCoord(.08, .92, .08, .92)

        ----------------------------------------------------------------
        -- 3. 背景 / 陰影 / 冷卻文字
        ----------------------------------------------------------------
        if not btn.bg then btn.bg = F.CreateBD(btn, btn, 1, 0,0,0, .6) end
        if not btn.sd then btn.sd = F.CreateSD(btn, btn, 4)           end

        if not btn.time then
            btn.time = F.CreateText(btn, "OVERLAY", G.Font, G.NumberFS, G.FontFlag, "CENTER")
            btn.time:SetPoint("BOTTOM", btn, "TOP", 0, 2)
        end
    end
    element.styled = true
end

-- =====================================================================
-- 重新排列 & 設容器大小
-- =====================================================================
local function Layout(element)
    local dir     = element.direction or "HORIZONTAL"
    local spacing = element.spacing   or 4

    for i, btn in ipairs(element.buttons) do
        btn:ClearAllPoints()
        if i == 1 then
            btn:SetPoint("TOPLEFT", element)
        else
            if dir == "VERTICAL" then
                btn:SetPoint("TOP", element.buttons[i-1], "BOTTOM", 0, -spacing)
            else
                btn:SetPoint("LEFT", element.buttons[i-1], "RIGHT", spacing, 0)
            end
        end
    end

    local w = element.buttons[1]:GetWidth()
    local h = element.buttons[1]:GetHeight()
    if dir == "HORIZONTAL" then
        element:SetSize(w * MAX_TOTEMS + spacing*(MAX_TOTEMS-1), h)
    else
        element:SetSize(w, h * MAX_TOTEMS + spacing*(MAX_TOTEMS-1))
    end
end

-- =====================================================================
-- 在 PLAYER_ENTERING_WORLD 之後執行完整 Setup
-- =====================================================================
local function StartStyling(self)
    local element = self.TotemBar
    if element.styled then return end     -- 已完成就跳過

    StyleButtons(element)
    if not element.styled then return end -- 還沒抓到按鈕，等下次事件

    Layout(element)
    Path(self, "InitialUpdate")           -- 立即刷新一次
end

-- =====================================================================
-- Enable / Disable
-- =====================================================================
local function Enable(self)
    local element = self.TotemBar
    if not element then return end

    element.__owner     = self
    element.buttons     = {}
    element.ForceUpdate = ForceUpdate
    element.styled      = false

    -- 直到 PLAYER_ENTERING_WORLD 才做美化，避免跟 oUF HideBlizzard 衝突
    self:RegisterEvent("PLAYER_ENTERING_WORLD", StartStyling, true)
    self:RegisterEvent("PLAYER_TOTEM_UPDATE", Path, true)

    return true
end

local function Disable(self)
    local element = self.TotemBar
    if not element then return end

    self:UnregisterEvent("PLAYER_ENTERING_WORLD", StartStyling)
    self:UnregisterEvent("PLAYER_TOTEM_UPDATE", Path)

    for _, btn in pairs(element.buttons) do
        btn:SetScript("OnUpdate", nil)
    end
end

-- =====================================================================
-- 正式註冊成 oUF 元素
-- =====================================================================
oUF:AddElement("TotemBar", Path, Enable, Disable)




if C.Totems then
    local bar = CreateFrame("Frame", nil, self)
    bar.direction = "HORIZONTAL"    -- or "VERTICAL"
    bar.spacing   = 6

    -- (可選) 沒圖騰時半透明
    bar.PostUpdate = function(elem, active) elem:SetAlpha(active==0 and .3 or 1) end

    -- 自行決定放哪
    bar:SetPoint("CENTER", self, 0, 4)

    self.TotemBar = bar            -- 關鍵：名字要與 AddElement 保持一致
end
