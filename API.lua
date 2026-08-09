local _, ns = ...
local unpack = unpack
local F, G = ns[2], ns[3]

local select, type = select, type
local floor, format = math.floor, format
local CreateFrame, CreateAbbreviateConfig, AbbreviateNumbers = CreateFrame, CreateAbbreviateConfig, AbbreviateNumbers

--======================================================--
-----------------    [[ Functions ]]    ------------------
--======================================================--

--[[
/run for _,s in ipairs({"Chat","ChallengeMode","Encounter","Map","PvPMatch","Combat"})do C_CVar.SetCVar("addon"..s.."RestrictionsForced","1")end

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

-- [[ 單位框架提示 ]] --

-- oUF 14 以 __unit 保存目前單位；暴雪 UnitFrame_OnEnter 仍讀取舊的 self.unit。
F.UnitFrameOnEnter = function(self)
	local unit = self.__unit
	if not unit then
		self.UpdateTooltip = nil
		return
	end

	GameTooltip_SetDefaultAnchor(GameTooltip, self)
	if GameTooltip:SetUnit(unit, self.hideStatusOnTooltip) then
		GameTooltip_AddBlankLineToTooltip(GameTooltip)
		GameTooltip_AddInstructionLine(GameTooltip, UNIT_POPUP_RIGHT_CLICK)
		GameTooltip:Show()
		self.UpdateTooltip = F.UnitFrameOnEnter
	else
		self.UpdateTooltip = nil
	end
end

--===================================================--
-----------------    [[ Format ]]    ------------------
--===================================================--

-- [[ 數值 ]] --

-- 斷點，單位，有效數截斷除數，小數點縮放除數、是否使用全域縮寫
-- 1234 (1e3) 除以 100 (1e2) 並捨去小數得到 12，再除以 10 (1e1) 得到 1.2k
local NumberAbbrConfig = {
	config = CreateAbbreviateConfig({
		{ breakpoint = 1e9, abbreviation = "b", significandDivisor = 1e5, fractionDivisor = 1e4, abbreviationIsGlobal = false },
		{ breakpoint = 1e6, abbreviation = "m", significandDivisor = 1e4, fractionDivisor = 1e2, abbreviationIsGlobal = false },
		{ breakpoint = 1e5, abbreviation = "k", significandDivisor = 1e3, fractionDivisor = 1,   abbreviationIsGlobal = false },
		{ breakpoint = 1e3, abbreviation = "k", significandDivisor = 1e2, fractionDivisor = 1e1, abbreviationIsGlobal = false },
	})
}

-- 直接交給允許 secret number 的原生 formatter
F.NumberAbbrValue = function(value)
	return AbbreviateNumbers(value, NumberAbbrConfig)
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

-- [[ 背景與邊框 ]] --

-- 格式：父級框體，錨點，大小，紅，綠，藍，背景透明度，邊框透明度
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
	
	if height then bar:SetHeight(height) end
	if width then bar:SetWidth(width) end
	
	bar:SetStatusBarTexture(G.media.blank, layer)
	bar:GetStatusBarTexture():SetHorizTile(false)
	bar:GetStatusBarTexture():SetVertTile(false)
	
	if r then bar:SetStatusBarColor(r, g, b, alpha) end
	
	return bar
end
