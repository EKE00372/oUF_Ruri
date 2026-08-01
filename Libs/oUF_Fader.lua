local _, ns = ...
local C = ns[1]
local oUF = ns.oUF or oUF

------------------------------------------------------
-- Credits: zork, p3lim, Azilroka, Simpy, Witnesscm --
------------------------------------------------------

local MIN_ALPHA = C.FadeOutAlpha
local MAX_ALPHA = 1
local FADE_IN_TIME = 0.4
local FADE_OUT_TIME = 1.5

-----------------
-- 獨立動畫框架 --
-----------------

local fadeManager = CreateFrame("Frame")
local fadeFrames = {}
local activeFrames = {}

local function FadeOnUpdate(self, elapsed)
    local frameCount = 0
    for frame, info in pairs(fadeFrames) do
        info.timer = info.timer + elapsed
        if info.timer >= info.duration then
            frame:SetAlpha(info.endAlpha)
            fadeFrames[frame] = nil
        else
            local progress = info.timer / info.duration
            frame:SetAlpha(info.startAlpha + (info.endAlpha - info.startAlpha) * progress)
            frameCount = frameCount + 1
        end
    end
    if frameCount == 0 then
        self:SetScript("OnUpdate", nil)
    end
end

local function UIFrameFadeTo(frame, duration, endAlpha)
    if not frame then return end

    local pending = fadeFrames[frame]
    if pending and pending.endAlpha == endAlpha then return end

    -- 方向改變時先取消舊動畫，避免目前 Alpha 尚未變動而留下反向動畫。
    fadeFrames[frame] = nil

    local startAlpha = frame:GetAlpha()
    if startAlpha == endAlpha then return end

    fadeFrames[frame] = {
        timer = 0,
        duration = duration,
        startAlpha = startAlpha,
        endAlpha = endAlpha,
    }
    fadeManager:SetScript("OnUpdate", FadeOnUpdate)
end

-------------
-- 判斷邏輯 --
-------------

local function ShouldFrameShow(self)
    if self:IsMouseOver() then return true end
    if UnitAffectingCombat('player') then return true end
    if UnitExists('target') then return true end

    -- 玩家施法資料受限時無法安全判斷，保持顯示。
    if C_Secrets.ShouldUnitSpellCastingBeSecret('player') then return true end
    if UnitCastingInfo('player') or UnitChannelInfo('player') then return true end

    return false
end

local function Update(self)
    if not activeFrames[self] then return end

    local shouldShow = ShouldFrameShow(self)
    local targetAlpha = shouldShow and MAX_ALPHA or MIN_ALPHA
    local duration = shouldShow and FADE_IN_TIME or FADE_OUT_TIME

    UIFrameFadeTo(self, duration, targetAlpha)
end

local function UpdateAll()
    for frame in pairs(activeFrames) do
        Update(frame)
    end
end

local castEvents = {
    'UNIT_SPELLCAST_START',
    'UNIT_SPELLCAST_STOP',
    'UNIT_SPELLCAST_FAILED',
    'UNIT_SPELLCAST_FAILED_QUIET',
    'UNIT_SPELLCAST_INTERRUPTED',
    'UNIT_SPELLCAST_CHANNEL_START',
    'UNIT_SPELLCAST_CHANNEL_STOP',
    'UNIT_SPELLCAST_EMPOWER_START',
    'UNIT_SPELLCAST_EMPOWER_STOP',
}

local function RegisterDriverEvents()
    if fadeManager.eventsRegistered then return end

    fadeManager:RegisterEvent('PLAYER_ENTERING_WORLD')
    fadeManager:RegisterEvent('PLAYER_REGEN_ENABLED')
    fadeManager:RegisterEvent('PLAYER_REGEN_DISABLED')
    fadeManager:RegisterEvent('PLAYER_TARGET_CHANGED')
    for _, event in ipairs(castEvents) do
        fadeManager:RegisterUnitEvent(event, 'player')
    end

    fadeManager:SetScript('OnEvent', UpdateAll)
    fadeManager.eventsRegistered = true
end

local function UnregisterDriverEvents()
    if next(activeFrames) then return end

    fadeManager:UnregisterAllEvents()
    fadeManager:SetScript('OnEvent', nil)
    fadeManager.eventsRegistered = nil
end

----------------------
-- oUF Element 註冊 --
----------------------
local function Enable(self, unit)
    if not self.fade or (unit ~= 'player' and unit ~= 'pet') then return end

    activeFrames[self] = true
    if not self.__ruriFaderHooks then
        self:HookScript('OnEnter', Update)
        self:HookScript('OnLeave', Update)
        self.__ruriFaderHooks = true
    end

    RegisterDriverEvents()
    Update(self)
    return true
end

local function Disable(self)
    activeFrames[self] = nil
    fadeFrames[self] = nil
    self:SetAlpha(MAX_ALPHA)
    UnregisterDriverEvents()
end

oUF:AddElement('Fader', Update, Enable, Disable)
