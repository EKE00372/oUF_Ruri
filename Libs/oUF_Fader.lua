local addon, ns = ...
local C, F, G, T = unpack(ns)
local oUF = ns.oUF or oUF

if not C.Fade then return end

------------------------------------------------------
-- Credits: zork, p3lim, Azilroka, Simpy, Witnesscm --
------------------------------------------------------

local MIN_ALPHA = C.FadeOutAlpha
local MAX_ALPHA = 1
local FADE_IN_TIME = 0.4
local FADE_OUT_TIME = 1.5
--[[
local isCasting
local inCombat
local hasTarget
local isHovered
]]--

-----------------
-- 獨立動畫框架 --
-----------------

local fadeManager = CreateFrame("Frame")
local fadeFrames = {}

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
    local unit = self.unit
    if not unit then return true end

    if GetMouseFoci()[1] == self then return true end
    if UnitAffectingCombat('player') then return true end
    if UnitExists('playertarget') then return true end
    if UnitCastingInfo(unit) or UnitChannelInfo(unit) then return true end

    return false
end

local function Update(self)
    if not self.fade then return end

    local shouldShow = ShouldFrameShow(self)
    local targetAlpha = shouldShow and MAX_ALPHA or MIN_ALPHA
    local duration = shouldShow and FADE_IN_TIME or FADE_OUT_TIME

    UIFrameFadeTo(self, duration, targetAlpha)
end

----------------------
-- oUF Element 註冊 --
----------------------
local function Enable(self, unit)
    if not self.fade then return end

    -- 只要 self.fade 為 true，自動註冊所有相關事件
    self:HookScript('OnEnter', Update)
    self:HookScript('OnLeave', Update)
    
    -- 戰鬥與目標
    self:RegisterEvent('PLAYER_REGEN_ENABLED', Update, true)
    self:RegisterEvent('PLAYER_REGEN_DISABLED', Update, true)
    self:RegisterEvent('PLAYER_TARGET_CHANGED', Update, true)
    self:RegisterEvent('UNIT_TARGET', Update)
    self:RegisterEvent('UNIT_FLAGS', Update)

    -- 施法
    local castEvents = {
        'UNIT_SPELLCAST_START', 'UNIT_SPELLCAST_FAILED', 'UNIT_SPELLCAST_STOP',
        'UNIT_SPELLCAST_INTERRUPTED', 'UNIT_SPELLCAST_CHANNEL_START', 'UNIT_SPELLCAST_CHANNEL_STOP',
        'UNIT_SPELLCAST_EMPOWER_START', 'UNIT_SPELLCAST_EMPOWER_STOP'
    }
    for _, event in ipairs(castEvents) do
        self:RegisterEvent(event, Update)
    end

    Update(self)
    return true
end

local function Disable(self)
    self:UnregisterAllEvents()
    fadeFrames[self] = nil
end

oUF:AddElement('Fader', Update, Enable, Disable)