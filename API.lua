local addon, ns = ... 
local unpack = unpack
local C, F, G, T = unpack(ns)

local tonumber, select, type = tonumber, select, type
local strmatch, floor, format = strmatch, math.floor, format
local CreateFrame, CreateAbbreviateConfig, AbbreviateNumbers = CreateFrame, CreateAbbreviateConfig, AbbreviateNumbers
local SetCVar = C_CVar.SetCVar
local C_Timer_After = C_Timer.After
local C_SpecializationInfo_GetSpecialization = C_SpecializationInfo.GetSpecialization
local C_SpecializationInfo_GetSpecializationInfo = C_SpecializationInfo.GetSpecializationInfo
local C_SpellBook_IsSpellKnownOrInSpellBook = C_SpellBook.IsSpellKnownOrInSpellBook
local C_ClassTalents_GetActiveConfigID = C_ClassTalents.GetActiveConfigID

--======================================================--
-----------------    [[ Functions ]]    ------------------
--======================================================--

--[[
local SecretValueTestMode = true
SetCVar("secretChallengeModeRestrictionsForced", 1)
SetCVar("secretCombatRestrictionsForced", 1)
SetCVar("secretEncounterRestrictionsForced", 1)
SetCVar("secretMapRestrictionsForced", 1)
SetCVar("secretPvPMatchRestrictionsForced", 1)
]]--

-- [[ 多重條件匹配 ]] --

-- 使用範例：
-- F.IsAny(unit, "player", "boss", "pet")
F.IsAny = function(check, ...)
	for i = 1, select("#", ...) do
		if check == select(i, ...) then
			return true
		end
	end
	return false
end

-- [[ 獲取NpcID]] --

F.GetNPCID = function(guid)
	local id = tonumber(strmatch((guid or ""), "%-(%d-)%-%x-$"))
	return id
end


-- [[ 獲取專精ID ]] --

-- 初始化
local SpecBoolean = 1

-- 提供調用函數
function F.SpecCheck()
	return SpecBoolean
end

-- 檢查專精返回需要的偏移量
local function SpecUpdate()
	local specIndex = C_SpecializationInfo_GetSpecialization()
	local specID = specIndex and C_SpecializationInfo_GetSpecializationInfo(specIndex) or 0
	local lightSmith = C_SpellBook_IsSpellKnownOrInSpellBook(432459)

	-- 第一層：坦克資源
	-- 啟用坦克資源的酒僧/血DK/復仇/防戰/熊/光鑄防騎
	local hasTankResource =
		C.TankResource and (F.IsAny(specID, 268, 250, 581, 73, 104) or (specID == 66 and lightSmith))

	-- 第二層：職業資源：ClassPower/Runes/Essence/Stagger/AdditionalPower 共用
	-- 死騎/盜賊/術士/喚能/聖騎
	-- 鳥貓/秘法/暗牧/元薩/酒僧/風僧
	local hasClassResource =
		F.IsAny(G.myClass, "DEATHKNIGHT", "ROGUE", "WARLOCK", "EVOKER", "PALADIN") or
		F.IsAny(specID, 102, 103, 62, 258, 262, 268, 269)

	if hasTankResource and hasClassResource then
		SpecBoolean = 3
	elseif hasTankResource or hasClassResource then
		SpecBoolean = 2
	else
		-- 無額外資源層
		SpecBoolean = 1
	end
end

-- PEW和切專精時獲取當前值
local frame = CreateFrame("Frame")
	frame:RegisterEvent("PLAYER_ENTERING_WORLD")
	frame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
	frame:RegisterEvent("ACTIVE_PLAYER_SPECIALIZATION_CHANGED")
	frame:RegisterEvent("PLAYER_TALENT_UPDATE")
	frame:RegisterEvent("SPELLS_CHANGED")
	frame:RegisterEvent("TRAIT_CONFIG_UPDATED")
	frame:SetScript("OnEvent", function(self, event, ...)
		local arg1 = ...

		if event == "PLAYER_SPECIALIZATION_CHANGED" and arg1 ~= "player" then return end
		if event == "TRAIT_CONFIG_UPDATED" and C_ClassTalents_GetActiveConfigID() ~= arg1 then return end

		SpecUpdate()
		C_Timer_After(1, SpecUpdate)
	end)

--===================================================--
-----------------    [[ Format ]]    ------------------
--===================================================--

-- [[ 數值 ]] --

local NumberAbbrConfig = {
    config = CreateAbbreviateConfig({
        { breakpoint = 1e12, abbreviation = "T", significandDivisor = 1e10, fractionDivisor = 1e2, abbreviationIsGlobal = false },
        { breakpoint = 1e9,  abbreviation = "B", significandDivisor = 1e7,  fractionDivisor = 1e2, abbreviationIsGlobal = false },
        { breakpoint = 1e6,  abbreviation = "M", significandDivisor = 1e4,  fractionDivisor = 1e2, abbreviationIsGlobal = false },
        { breakpoint = 1e3,  abbreviation = "K", significandDivisor = 1e2,  fractionDivisor = 1e1, abbreviationIsGlobal = false },
    })
}

F.NumberAbbrValue = function(value)
	-- 將字串轉換為數字
	value = tonumber(value)
    if not value then return "" end
    return AbbreviateNumbers(value, NumberAbbrConfig)
end

F.ShortValue = function(val)
	-- 讓20k不顯示為20.0k
	local round = function(val, idp)
		if idp and idp > 0 then
			local mult = 10^idp
			return floor(val * mult + 0.5) / mult
		end
		return floor(val + 0.5)
	end

	if val >= 1e9 then
		-- 億至小數點後四位
		return ("%.4fb"):format(val / 1e9)
	elseif val >= 1e6 then
		-- 百萬至小數點後二位
		return ("%.2fm"):format(val / 1e6)
	elseif val >= 1e5 then
		-- 十萬顯示千取整
		return ("%.fk"):format(val / 1e3)	
	elseif val >= 1e3 and val < 1e5 then
		-- 不滿十萬顯示千後小數點一位
		return round(val / 1e3, 1).."k"
	else
		-- 千以下
		return ("%d"):format(val)
	end
end

-- [[ 顏色 ]] --

F.Hex = function(r, g, b)
	-- 未定義則白色
	if not r then return "|cffFFFFFF" end
	
	if type(r) == "table" then
		if(r.r) then
			r, g, b = r.r, r.g, r.b
		else
			r, g, b = unpack(r)
		end
	end
	
	return ("|cff%02x%02x%02x"):format(r * 255, g * 255, b * 255)
end

-- [[ 計時 ]] --

F.FormatTime = function(s)
	local day, hour, minute = 86400, 3600, 60
	
	if s >= day then
		-- 天
		return format("%dd", floor(s/day + 0.5)), s % day
	elseif s >= hour then
		-- 時
		return format("%dh", floor(s/hour + 0.5)), s % hour
	elseif s >= minute then
		-- 五分以下
		if s <= minute * 5 then
			return format("%d:%02d", floor(s/60), s % minute), s - floor(s)
		else
		-- 五分以上
			return format("%dm", floor(s/minute + 0.5)), s % minute
		end
	else
		return format("%d", s + .5), s - floor(s)
	end
end

--======================================================--
-----------------    [[ Templates ]]    ------------------
--======================================================--

-- [[ 文字 ]] --

-- 格式：父級框體，層級，字型，字型大小，描邊，對齊
F.CreateText = function(parent, layer, font, fontsize, fontflag, justify)
	local text = parent:CreateFontString(nil, layer)
	text:SetFont(font, fontsize, fontflag)
	text:SetShadowOffset(0, 0)
	text:SetWordWrap(false)

	if justify then
		text:SetJustifyH(justify)
	end
	
	return text
end

-- [[ 框體模板 ]] --

-- 格式：父級框體，大小
F.CreateBackdrop = function(parent, size)
	parent:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8x8",		-- 背景
		edgeFile = G.media.glow,						-- 陰影邊框
		edgeSize = size,								-- 邊框大小
		tile = false, tilesize = size,
		insets = {left = size, right = size, top = size, bottom = size}	-- 正值內縮，負值外擴
	})
end

-- [[ 背景與邊框 ]] --

-- 格式：父級框體，錨點，大小，紅，綠，藍，透明度
F.CreateBD = function(parent, anchor, size, r, g, b, a1, a2)
	local bd = CreateFrame("Frame", nil, parent, "BackdropTemplate")
	local framelvl = parent:GetFrameLevel()
	
	bd:ClearAllPoints()
	bd:SetPoint("TOPLEFT", anchor, "TOPLEFT", -size, size)
	bd:SetPoint("BOTTOMRIGHT", anchor, "BOTTOMRIGHT", size, -size)
	bd:SetFrameLevel(framelvl == 0 and 0 or framelvl-2)
	bd:SetBackdrop({
		bgFile = G.media.blank,		-- 背景
		edgeFile = G.media.blank,	-- 邊框
		edgeSize = size or 1,		-- 邊框大小
		})
	bd:SetBackdropColor(r or 0, g or 0, b or 0, a1 or 0)
	bd:SetBackdropBorderColor(r or 0, g or 0, b or 0, a2 or 1)
	
	return bd
end

-- [[ 陰影 ]] --

-- 格式：父級框體，錨點，大小
F.CreateSD = function(parent, anchor, size, r, g, b, a)
	local sd = CreateFrame("Frame", nil, parent, "BackdropTemplate")
	local framelvl = parent:GetFrameLevel()
	
	sd:ClearAllPoints()
	sd:SetPoint("TOPLEFT", anchor, -size, size)
	sd:SetPoint("BOTTOMRIGHT", anchor, size, -size)
	sd:SetFrameLevel(framelvl == 0 and 0 or framelvl-1)
	sd:SetBackdrop({
		edgeFile = G.media.glow,	-- 陰影邊框
		edgeSize = size or 3,		-- 邊框大小
	})
	--sd:SetBackdropColor(0, 0, 0, 1)
	--sd:SetBackdropBorderColor(0, 0, 0, 1)
	sd:SetBackdropBorderColor(r or 0.05, g or 0.05, b or 0.05, a or 1)
	
	return sd
end

-- [[ 狀態條 ]] --

-- 格式：父級框體，自身框體名，層級，高度，寬度，紅，綠，藍，透明度
F.CreateStatusbar = function(parent, name, layer, height, width, r, g, b, alpha)
	local bar = CreateFrame("StatusBar", name, parent)
	
	if height then
		bar:SetHeight(height)
	end
	
	if width then
		bar:SetWidth(width)
	end
	
	bar:SetStatusBarTexture(G.media.blank, layer)
	
	-- fix bar texture
	bar:GetStatusBarTexture():SetHorizTile(false)
	bar:GetStatusBarTexture():SetVertTile(false)
	
	if r then
		bar:SetStatusBarColor(r, g, b, alpha)
	end
	
	return bar
end
