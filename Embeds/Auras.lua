local addon, ns = ...
local oUF = ns.oUF
local C, F, G, T = unpack(ns)

if not C.AuraFrames then return end

local _G = getfenv(0)
local format, floor, strmatch, select, unpack, tonumber = format, floor, strmatch, select, unpack, tonumber
local GetTime = GetTime
local GetInventoryItemQuality, GetInventoryItemTexture, GetWeaponEnchantInfo = GetInventoryItemQuality, GetInventoryItemTexture, GetWeaponEnchantInfo
local GetAuraApplicationDisplayCount = C_UnitAuras.GetAuraApplicationDisplayCount
local GetAuraDataByIndex = C_UnitAuras.GetAuraDataByIndex
local GetAuraDuration = C_UnitAuras.GetAuraDuration
local issecretvalue = issecretvalue

local MIN_SPELL_COUNT, MAX_SPELL_COUNT = 2, 999
local FALLBACK_DEBUFFCOLOR = {r=1, g=0, b=0}

--==========================================--
--------------- [[ Function ]] ---------------
--==========================================--

local function SetFontSize(fontString, size)
    fontString:SetFont(STANDARD_TEXT_FONT, size, "OUTLINE")
    fontString:SetShadowColor(0, 0, 0, 0)
end

-- [[ Dispel color ]] --
local DispelColorCurve = C_CurveUtil.CreateColorCurve()
    DispelColorCurve:SetType(Enum.LuaCurveType.Step)
    for _, dispelIndex in next, oUF.Enum.DispelType do
        if(oUF.colors.dispel[dispelIndex]) then
            DispelColorCurve:AddPoint(dispelIndex, oUF.colors.dispel[dispelIndex])
        end
    end

--======================================--
--------------- [[ Core ]] ---------------
--======================================--

-- [[ Aura setting table ]] --
local Settings = {}

-- [[ Hide aura frame from editmode ]] --
local HiddenFrame = CreateFrame("Frame")
HiddenFrame:Hide()

local function HideObject(frame)
    if not frame then return end
    frame:Hide()
    frame:SetParent(HiddenFrame)
    if frame.UnregisterAllEvents then
        frame:UnregisterAllEvents()
    end
end

local function HideBlizBuff()
    local f = CreateFrame("Frame")
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:SetScript("OnEvent", function(_, event, isLogin, isReload)
        if isLogin or isReload then
            if _G.BuffFrame then
                HideObject(_G.BuffFrame)
                _G.BuffFrame.numHideableBuffs = 0
            end
            if _G.DebuffFrame then
                HideObject(_G.DebuffFrame)
            end
        end
    end)
end

-- [[ Setup tooltip ]] --

local function Button_SetTooltip(button)
    if button:GetAttribute("index") then
        GameTooltip:SetUnitAura(button.header:GetAttribute("unit"), button:GetID(), button.filter)
    elseif button:GetAttribute("target-slot") then
        GameTooltip:SetInventoryItem("player", button:GetID())
    end
end

-- [[ Timer update ]] --

local function UpdateTimer(self, elapsed)
    local onTooltip = GameTooltip:IsOwned(self)

    if not (self.timeLeft or self.expiration or onTooltip) then
        self:SetScript("OnUpdate", nil)
        return
    end

    if self.timeLeft then self.timeLeft = self.timeLeft - elapsed end

    if self.nextUpdate > 0 then
        self.nextUpdate = self.nextUpdate - elapsed
        return
    end

    if self.expiration then
        self.timeLeft = self.expiration / 1e3 - (GetTime() - self.oldTime)
    end

    if self.timeLeft and self.timeLeft >= 0 then
        local timer, nextUpdate = F.FormatTime(self.timeLeft)
        self.nextUpdate = nextUpdate
        self.timer:SetText(timer)
    end

    if onTooltip then Button_SetTooltip(self) end
end

-- [[ Load tooltip ]] --

local function Button_OnEnter(self)
    GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT", -5, -5)
    self.nextUpdate = -1
    self:SetScript("OnUpdate", UpdateTimer)
end

--============================================--
--------------- [[ Updat Aura ]] ---------------
--============================================--

local function UpdateAuras(button, index)
    local unit, filter = button.header:GetAttribute("unit"), button.filter
    local auraData = GetAuraDataByIndex(unit, index, filter)
    if not auraData then return end
--[[
	if auraData.duration and auraData.expirationTime then
		local timeLeft = auraData.expirationTime - GetTime()
		if not button.timeLeft then
			button.nextUpdate = -1
			button.timeLeft = timeLeft
			button:SetScript("OnUpdate", A.UpdateTimer)
		else
			button.timeLeft = timeLeft
		end
		button.nextUpdate = -1
		A.UpdateTimer(button, 0)
	else
		button.timeLeft = nil
		button.timer:SetText("")
	end
]]
    local auraDuration = unit and GetAuraDuration(unit, auraData.auraInstanceID)
    if auraDuration then
        button.Cooldown:SetCooldownFromDurationObject(auraDuration)
        button.Cooldown:Show()
    else
        button.Cooldown:Hide()
    end

    local count = auraData.applications
    if issecretvalue(count) then
        button.count:SetText(GetAuraApplicationDisplayCount(unit, auraData.auraInstanceID, MIN_SPELL_COUNT, MAX_SPELL_COUNT))
    else
        local hideCount = not count or (count < MIN_SPELL_COUNT or count > MAX_SPELL_COUNT)
        button.count:SetText(hideCount and "" or count)
    end

    if filter == "HARMFUL" then
		local color = C_UnitAuras.GetAuraDispelTypeColor(unit, auraData.auraInstanceID, DispelColorCurve) or FALLBACK_DEBUFFCOLOR
        button:SetBackdropBorderColor(.1, .1, .1)
        if button.shadow then
            button.shadow:SetBackdropBorderColor(color.r, color.g, color.b)
        end
    else
        button:SetBackdropBorderColor(.1, .1, .1)
        if button.shadow then
            button.shadow:SetBackdropBorderColor(.1, .1, .1)
        end
    end

    button.spellID = auraData.spellId
    button.icon:SetTexture(auraData.icon)
    
    button.expiration = nil
    button.timeLeft = nil
    button.timer:SetText("")
end

local function UpdateTempEnchant(button, index)
    local expirationTime = select(button.enchantOffset, GetWeaponEnchantInfo())
    if expirationTime then
        local quality = GetInventoryItemQuality("player", index)
        local color = BAG_ITEM_QUALITY_COLORS[quality or 1]
        
        button:SetBackdropBorderColor(color.r, color.g, color.b)
        if button.shadow then
            button.shadow:SetBackdropBorderColor(color.r, color.g, color.b)
        end
        
        button.icon:SetTexture(GetInventoryItemTexture("player", index))

        button.expiration = expirationTime
        button.oldTime = GetTime()
        button:SetScript("OnUpdate", UpdateTimer)
        button.nextUpdate = -1
        UpdateTimer(button, 0)
    else
        button.expiration = nil
        button.timeLeft = nil
        button.timer:SetText("")
    end
end

local function OnAttributeChanged(self, attribute, value)
    if attribute == "index" then
        UpdateAuras(self, value)
    elseif attribute == "target-slot" then
        UpdateTempEnchant(self, value)
    end
end

local function UpdateHeader(header)
    local cfg = Settings.Debuffs
    if header.filter == "HELPFUL" then
        cfg = Settings.Buffs
        header:SetAttribute("consolidateTo", 0)
        header:SetAttribute("weaponTemplate", format("GlowAuraTemplate%d", cfg.size))
    end

    header:SetAttribute("separateOwn", 1)
    header:SetAttribute("sortMethod", "INDEX")
    header:SetAttribute("sortDirection", "+")
    header:SetAttribute("wrapAfter", cfg.wrapAfter)
    header:SetAttribute("maxWraps", cfg.maxWraps)
    header:SetAttribute("point", cfg.reverseGrow and "TOPLEFT" or "TOPRIGHT")
    header:SetAttribute("minWidth", (cfg.size + C.Auras.Margin)*cfg.wrapAfter)
    header:SetAttribute("minHeight", (cfg.size + cfg.offset)*cfg.maxWraps)
    header:SetAttribute("xOffset", (cfg.reverseGrow and 1 or -1) * (cfg.size + C.Auras.Margin))
    header:SetAttribute("yOffset", 0)
    header:SetAttribute("wrapXOffset", 0)
    header:SetAttribute("wrapYOffset", -(cfg.size + cfg.offset))
    header:SetAttribute("template", format("GlowAuraTemplate%d", cfg.size))

    local fontSize = floor(cfg.size/30*12 + .5)
    local index = 1
    local child = select(index, header:GetChildren())
    while child do
        if (floor(child:GetWidth() * 100 + .5) / 100) ~= cfg.size then
            child:SetSize(cfg.size, cfg.size)
        end
        SetFontSize(child.count, C.Auras.CountFontSize)
        SetFontSize(child.timer, C.Auras.TimerFontSize)
        SetFontSize(child.CooldownText, C.Auras.TimerFontSize)

        if index > (cfg.maxWraps * cfg.wrapAfter) and child:IsShown() then
            child:Hide()
        end

        index = index + 1
        child = select(index, header:GetChildren())
    end
end

local function CreateAuraHeader(filter)
    local name = filter == "HELPFUL" and "StandalonePlayerBuffs" or "StandalonePlayerDebuffs"
    local header = CreateFrame("Frame", name, UIParent, "SecureAuraHeaderTemplate")
    header:SetClampedToScreen(true)
    header:UnregisterEvent("UNIT_AURA")
    header:RegisterUnitEvent("UNIT_AURA", "player", "vehicle")
    header:SetAttribute("unit", "player")
    header:SetAttribute("filter", filter)
    header.filter = filter
    RegisterAttributeDriver(header, "unit", "[vehicleui] vehicle; player")

    header.visibility = CreateFrame("Frame", nil, UIParent, "SecureHandlerStateTemplate")
    header.visibility:RegisterEvent("WEAPON_ENCHANT_CHANGED")
    SecureHandlerSetFrameRef(header.visibility, "AuraHeader", header)
    RegisterStateDriver(header.visibility, "customVisibility", "[petbattle] 0;1")
    header.visibility:SetAttribute("_onstate-customVisibility", [[
        local header = self:GetFrameRef("AuraHeader")
        local hide, shown = newstate == 0, header:IsShown()
        if hide and shown then header:Hide() elseif not hide and not shown then header:Show() end
    ]])

    if filter == "HELPFUL" then
        header:SetAttribute("consolidateDuration", -1)
        header:SetAttribute("includeWeapons", 1)
    end

    UpdateHeader(header)
    header:Show()
    return header
end

local function BuildBuffFrame()
    Settings = {
        Buffs = {
            offset = 12, size = C.Auras.BuffSize, wrapAfter = C.Auras.BuffsPerRow,
            maxWraps = 3, reverseGrow = C.Auras.ReverseBuff,
        },
        Debuffs = {
            offset = 12, size = C.Auras.DebuffSize, wrapAfter = C.Auras.DebuffsPerRow,
            maxWraps = 1, reverseGrow = C.Auras.ReverseDebuff,
        },
    }

    local BuffFrame = CreateAuraHeader("HELPFUL")
    BuffFrame:ClearAllPoints()
    BuffFrame:SetPoint(unpack(C.Auras.BuffPos))

    local DebuffFrame = CreateAuraHeader("HARMFUL")
    DebuffFrame:ClearAllPoints()
    DebuffFrame:SetPoint("TOPRIGHT", BuffFrame, "BOTTOMRIGHT", 0, -12)
end

--======================================--
--------------- [[ Load ]] ---------------
--======================================--

local indexToOffset = {2, 6, 10}

function GlowAura_CreateIcon(button)
    button.header = button:GetParent()
    button.filter = button.header.filter
    button.name = button:GetName()
    
    local enchantIndex = tonumber(strmatch(button.name, "TempEnchant(%d)$"))
    button.enchantOffset = enchantIndex and indexToOffset[enchantIndex] or nil

    local cfg = button.filter == "HELPFUL" and Settings.Buffs or Settings.Debuffs
    local fontSize = floor(cfg.size/30*12 + .5)

    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetPoint("TOPLEFT", 1, -1)
    button.icon:SetPoint("BOTTOMRIGHT", -1, 1)
    button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    button.count = button:CreateFontString(nil, "ARTWORK")
    button.count:SetPoint("BOTTOMRIGHT", 1, -5)
    SetFontSize(button.count, C.Auras.CountFontSize)
    button.count:SetTextColor(1, 1, 0)

    button.timer = button:CreateFontString(nil, "ARTWORK")
    button.timer:SetPoint("TOP", button, "BOTTOM", 1, 2)
    SetFontSize(button.timer, C.Auras.TimerFontSize)

    button.highlight = button:CreateTexture(nil, "HIGHLIGHT")
    button.highlight:SetColorTexture(1, 1, 1, 0.25)
    button.highlight:SetAllPoints()

    local cd = CreateFrame("Cooldown", "$parentCooldown", button, "CooldownFrameTemplate")
    cd:SetReverse(true)
    cd:SetEdgeTexture(G.media.blank)
    cd:SetDrawSwipe(false)
    cd:SetDrawEdge(false)
    cd:SetDrawBling(false)
    --cd:SetHideCountdownNumbers(true)
    button.Cooldown = cd

    local text = cd:GetRegions()
    if text then
        SetFontSize(text, C.Auras.TimerFontSize)
        text:ClearAllPoints()
        text:SetPoint("TOP", button, "BOTTOM", 1, 2)
        button.CooldownText = text
    end

    button.border = F.CreateBD(button, button, 1, .1, .1, .1, 1)
    button.shadow = F.CreateSD(button, button, 4)

    button:SetScript("OnAttributeChanged", OnAttributeChanged)
    button:SetScript("OnEnter", Button_OnEnter)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", function()
    HideBlizBuff()
    BuildBuffFrame()
end)