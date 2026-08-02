local addon, ns = ...
local oUF = ns.oUF
local C, F, G, T = unpack(ns)

local EMBED_CAST_NORMAL = CreateColor(.6, .6, .6, .6)
local EMBED_CAST_SHIELD = CreateColor(.6, 0, .6, .6)
local CAST_NORMAL = CreateColor(unpack(C.CastNormal))
local CAST_SHIELD = CreateColor(unpack(C.CastShield))

--=====================================================--
-----------------    [[ Functions ]]    -----------------
--=====================================================--

-- 施法時間格式
local function CreateCastbarTimeBinding()
	local formatter = C_StringUtil.CreateSecondsFormatter()
	formatter:SetDefaultAbbreviation(Enum.SecondsFormatterAbbreviation.OneLetter)
	formatter:SetMinInterval(Enum.SecondsFormatterInterval.Seconds)
	formatter:SetMillisecondsThreshold(60)

	local binding = C_DurationUtil.CreateDurationTextBinding()
	binding:SetTextFormat("{}/{}", {
		{ -- 當前
			property = Enum.DurationTextBindingProperty.ElapsedDuration,
			formatter = formatter,
		},
		{ -- 總共
			property = Enum.DurationTextBindingProperty.TotalDuration,
			formatter = formatter,
		},
	})

	return binding
end

-- 施法延遲
local function CreateCastbarDelayText(element)
	if not element.Time then return end

	element.Delay = F.CreateText(element, "OVERLAY", G.Font, G.NameFS, G.FontFlag, "LEFT")
	element.Delay:SetTextColor(1, 0, 0)
	element.Delay:SetText("")
	element.Delay:SetPoint("LEFT", element.Time, "RIGHT", 2, 0)
end

-- 施法條顏色
local function SetCastbarColor(element, notInterruptible, normalColor, shieldColor)
	if not element then return end

	local texture = element.GetStatusBarTexture and element:GetStatusBarTexture()
	if texture then
		texture:SetVertexColorFromBoolean(notInterruptible, shieldColor, normalColor)
	end
end

--=======================================================--
-----------------    [[ Post Update ]]    -----------------
--=======================================================--

-- [[ 更新施法目標 ]] --
--[[
T.UpdateSpellTarget = function(element, unit)
	if not unit then return end
	if (F.GetNPCID(UnitGUID(unit)) ~= C.UnitSpellTarget[element.npcID]) then return end
	
	local unitTarget = unit.."target"
	if UnitExists(unitTarget) then
		local nameString
		if UnitIsUnit(unitTarget, "player") then
			nameString = format("|cffff0000%s|r", ">"..strupper(YOU).."<")
		else
			local class = select(2, UnitClass(unitTarget))
			nameString = F.Hex(oUF.colors.class[class])..UnitName(unitTarget)
		end
		element.Text:SetText(nameString)
	end
end
]]--
-- [[ 重置施法目標 ]] --
--[[
T.ResetSpellTarget = function(element)
	if element.Text then
		element.Text:SetText("")
	end
end
]]--
-- [[ 開始施法 ]] --

T.PostCastStart_Embed = function(element, unit, name, texture, isTradeSkill, notInterruptible, spellID, castID)
	local frame = element:GetParent()
	
    -- 嵌入式施法條：施法開始時隱藏名字
    if frame.Name then frame.Name:SetAlpha(0) end
    if frame.Status then frame.Status:SetAlpha(0) end
    if element.Spark then element.Spark:SetAlpha(.8) end

    -- 判斷打斷顏色
    if unit == "player" then
        element:SetStatusBarColor(.6, .6, .6, .6)
    else
        SetCastbarColor(element, notInterruptible, EMBED_CAST_NORMAL, EMBED_CAST_SHIELD)
    end
end

T.PostCastStart = function(element, unit, name, texture, isTradeSkill, notInterruptible, spellID, castID)
    -- 判斷打斷顏色
    if unit == "player" then
        element:SetStatusBarColor(unpack(C.CastNormal))
    else
        SetCastbarColor(element, notInterruptible, CAST_NORMAL, CAST_SHIELD)
    end
end

-- [[ 停止施法 ]] --

T.PostCastStop_Embed = function(element, unit)
	local frame = element:GetParent()

	-- 嵌入式施法條：施法結束時顯示名字
	if frame.Name then frame.Name:SetAlpha(1) end
	if frame.Status then frame.Status:SetAlpha(1) end
end
--[[
T.PostCastStop = function(element, unit)
	local frame = element:GetParent()
	
	if frame.mystyle == "NP" then
		-- 使數字模式名條的名字復位
		frame.Name:SetPoint("BOTTOM", 0, 6)
	elseif frame.mystyle == "BP" then
		-- 清空施法目標
		T.ResetSpellTarget(element)
    end
end
]]--
-- [[ 狀態更新 ]] --

T.PostCastStopUpdate = function(element)
	-- target / focus 切換單位時，先復原嵌入式施法條的名字狀態
	return T.PostCastStop_Embed(element.Castbar, element.unit)
end

-- [[ 名條條形施法條：施法目標更新 ]] --
--[[
T.PostCastUpdate = function(element, unit)
	T.ResetSpellTarget(element)
	T.UpdateSpellTarget(element, unit)
end
]]--
-- [[ 施法失敗 ]] --

T.PostCastFailed_Embed = function(element, unit)
    --[[if frame.mystyle == "NP" then
        -- 使數字模式名條的名字復位
        frame.Name:SetPoint("BOTTOM", 0, 6)
    else]]--
    -- 嵌入式施法條：施法結束時顯示名字
    C_Timer.After(.05, function()   -- timeToHold 是0.05
        local frame = element:GetParent()
        if frame.Name then frame.Name:SetAlpha(1) end
        if frame.Status then frame.Status:SetAlpha(1) end
    end)
    -- 一閃而過的施法失敗紅色條
    element:SetStatusBarColor(.5, .2, .2, .6)
    element:SetValue(1)
    if element.Spark then element.Spark:SetAlpha(0) end
end

T.PostCastFailed = function(element, unit)
    --[[if frame.mystyle == "BP" then
        -- 條形模式清空施法目標
        T.ResetSpellTarget(element)
    end]]--
    -- 一閃而過的施法失敗紅色條
    element:SetStatusBarColor(unpack(C.CastFailed))
    element:SetValue(1)
    --element:Show()
end

-- [[ 施法過程中打斷狀態更新 ]] --

-- 例子：燃燒王座三王小怪
T.PostCastInterruptible_Embed = function(element, unit, notInterruptible)
	-- 打斷狀態更新
	if UnitIsUnit(unit, "player") then return end

	SetCastbarColor(element, notInterruptible, EMBED_CAST_NORMAL, EMBED_CAST_SHIELD)
	-- 被誰打斷
	
end

T.PostCastInterruptible = function(element, unit, notInterruptible)
	-- 打斷狀態更新
	if UnitIsUnit(unit, "player") then return end
	SetCastbarColor(element, notInterruptible, CAST_NORMAL, CAST_SHIELD)

	-- 被誰打斷
end

--===========================================================--
-----------------    [[ Create elements ]]    -----------------
--===========================================================--

-- [[ 嵌入施法條 ]] --

T.CreateCastbar = function(self, unit)
    self.standalone = false

	-- 創建一個條
	local Castbar = F.CreateStatusbar(self, G.addon..unit.."_CastBar", "ARTWORK", nil, nil, 0, 0, 0, 0)
	Castbar:SetAllPoints(self.Health)
	Castbar:SetFrameLevel(self:GetFrameLevel() + 4)

	-- Castbar.Icon 被保護了所以邊框陰影要自行創建
	local IconBG = CreateFrame("Frame", nil, Castbar)
	IconBG:SetSize(C.PHeight + C.PPHeight*2, C.PHeight + C.PPHeight*2)
	Castbar.IconBG = IconBG
	-- 圖示
	Castbar.Icon = Castbar.IconBG:CreateTexture(nil, "OVERLAY", nil, 1)
	Castbar.Icon:SetAllPoints(IconBG)
	--Castbar.Icon:SetSize(C.PHeight + (C.PPHeight*2), C.PHeight + (C.PPHeight*2))
	Castbar.Icon:SetTexCoord(.08, .92, .08, .92)
	-- 圖示邊框
    --Castbar.Border = F.CreateBD(Castbar, Castbar.Icon, 1, 0, 0, 0, 1)
	--Castbar.Border = F.CreateBD(Castbar.IconBG, Castbar.IconBG, 1, 0, 0, 0, 1)
	-- 陰影
    --Castbar.Shadow = F.CreateSD(Castbar, Castbar.Border, 4)
	Castbar.Shadow = F.CreateSD(Castbar.IconBG, Castbar.IconBG, 5)
	-- 文本
	Castbar.Text = F.CreateText(Castbar, "OVERLAY", G.Font, G.NameFS, G.FontFlag, nil)
	Castbar.Time = F.CreateText(Castbar, "OVERLAY", G.Font, G.NameFS, G.FontFlag, nil)
	Castbar.Time.binding = CreateCastbarTimeBinding()
	if unit == "player" then
		CreateCastbarDelayText(Castbar)
	end
	-- 隊列
	--Castbar.SafeZone = Castbar:CreateTexture(nil, "OVERLAY")
	--Castbar.SafeZone:SetAlpha(.6)
	-- 進度高亮
	Castbar.Spark = Castbar:CreateTexture(nil, "OVERLAY", nil, -1)
	Castbar.Spark:SetTexture(G.media.spark)
	Castbar.Spark:SetBlendMode("ADD")
	Castbar.Spark:SetVertexColor(1, 1, .85, .8)
	Castbar.Spark:SetAlpha(.8)
	-- 橫豎的spark不一樣
	if self.mystyle ~= "H" then
		Castbar:SetOrientation("VERTICAL")
		Castbar.Spark:SetRotation(math.rad(90))	-- spark材質也要轉90度
		Castbar.Spark:SetSize(C.PHeight, C.PHeight)
		Castbar.Spark:SetPoint("TOP", Castbar:GetStatusBarTexture(), 0, 0)
	else
		Castbar.Spark:SetSize(C.PHeight, C.PHeight)
		Castbar.Spark:SetPoint("RIGHT", Castbar:GetStatusBarTexture(), 0, 0)
	end
	
	-- 選項
	Castbar.timeToHold = 0.05
	-- 註冊到ouf
	self.Castbar = Castbar
	self.Castbar.PostCastStart = T.PostCastStart_Embed		-- 施法開始
	self.Castbar.PostCastStop = T.PostCastStop_Embed		-- 施法結束
	self.Castbar.PostCastFail = T.PostCastFailed_Embed			-- 施法失敗
	self.Castbar.PostCastInterrupted = T.PostCastFailed_Embed		-- 施法中斷
	self.Castbar.PostCastInterruptible = T.PostCastInterruptible_Embed	-- 狀態刷新
	-- target / focus 切換後由 oUF 更新施法條，重新決定名字是否隱藏
	if unit == "target" then
		self:RegisterEvent("PLAYER_TARGET_CHANGED", T.PostCastStopUpdate, true)
	elseif unit == "focus" then
		self:RegisterEvent("PLAYER_FOCUS_CHANGED", T.PostCastStopUpdate, true)
	end
end

-- [[ 獨立施法條 ]] --

T.CreateStandaloneCastbar = function(self, unit)
    self.standalone = true

	-- 創建一個條
	local Castbar = F.CreateStatusbar(self, G.addon..unit.."_CastBar", "ARTWORK", nil, nil, .6, .6, .6, 1)
	Castbar:SetFrameLevel(self:GetFrameLevel() + 4)	

	-- 背景與邊框
	Castbar.BarBG = F.CreateBD(Castbar, Castbar, 1, .15, .15, .15, .6)
	-- 陰影
	Castbar.BarShadow = F.CreateSD(Castbar, Castbar, 4)
    -- Castbar.Icon 被保護了所以邊框陰影要自行創建
    local IconBG = CreateFrame("Frame", nil, Castbar)
	IconBG:SetSize(C.PHeight + C.PPHeight*2, C.PHeight + C.PPHeight*2)
	Castbar.IconBG = IconBG
	-- 圖示
	Castbar.Icon = Castbar.IconBG:CreateTexture(nil, "OVERLAY", nil, 1)
	Castbar.Icon:SetAllPoints(IconBG)
	Castbar.Icon:SetTexCoord(.08, .92, .08, .92)
	-- 圖示邊框
	Castbar.Shadow = F.CreateSD(Castbar.IconBG, Castbar.IconBG, 4)
	-- 進度高亮
	Castbar.Spark = Castbar:CreateTexture(nil, "OVERLAY", nil, -1)
	Castbar.Spark:SetTexture(G.media.spark)
	Castbar.Spark:SetBlendMode("ADD")
	Castbar.Spark:SetVertexColor(1, 1, .85, .5)
	Castbar.Spark:SetAlpha(.5)
	
	-- 不同模式的布局
	if self.mystyle == "S" then
		-- 簡易焦點
		Castbar:SetSize(C.PWidth/2, C.PHeight)
		--Castbar.Icon:SetSize(C.PHeight * 1.5, C.PHeight * 1.5)
		
		Castbar.Spark:SetSize(C.PHeight, C.PHeight)
		Castbar.Spark:SetPoint("RIGHT", Castbar:GetStatusBarTexture(), 0, 0)

		Castbar.Text = F.CreateText(Castbar, "OVERLAY", G.Font, G.NameFS, G.FontFlag, "LEFT")
		Castbar.Text:SetPoint("LEFT", 5, 0)
		Castbar.Text:SetWidth(self:GetWidth())		
	elseif self.mystyle == "H" then
		-- 橫式
		Castbar:SetHeight(C.PHeight)
		--Castbar.Icon:SetSize(C.PHeight, C.PHeight)
		
		Castbar.Spark:SetSize(C.PHeight, C.PHeight)
		Castbar.Spark:SetPoint("RIGHT", Castbar:GetStatusBarTexture(), 0, 0)

		Castbar.Text = F.CreateText(Castbar, "OVERLAY", G.Font, G.NameFS, G.FontFlag, "LEFT")
		Castbar.Text:SetPoint("LEFT", 5, 0)
		Castbar.Time = F.CreateText(Castbar, "OVERLAY", G.Font, G.NameFS, G.FontFlag, "RIGHT")
		Castbar.Time.binding = CreateCastbarTimeBinding()
		Castbar.Time:SetPoint("RIGHT", -5, 0)
		if unit == "player" then
			CreateCastbarDelayText(Castbar)
		end
	else
		-- 直式
		Castbar:SetSize(C.PHeight, C.PWidth-(C.PHeight + C.PPHeight*2)-C.PPOffset)
		--Castbar.Icon:SetSize(C.PHeight, C.PHeight)
		Castbar:SetOrientation("VERTICAL")
		
		Castbar.Spark:SetRotation(math.rad(90))	-- spark材質也要轉90度
		Castbar.Spark:SetSize(C.PHeight, C.PHeight)
		Castbar.Spark:SetPoint("TOP", Castbar:GetStatusBarTexture(), 0, 0)

		Castbar.Text = F.CreateText(Castbar, "OVERLAY", G.Font, G.NameFS, G.FontFlag, nil)
		Castbar.Time = F.CreateText(Castbar, "OVERLAY", G.Font, G.NameFS, G.FontFlag, nil)
		Castbar.Time.binding = CreateCastbarTimeBinding()
		if unit == "player" then
			CreateCastbarDelayText(Castbar)
		end
	end
	
	-- 選項
	Castbar.timeToHold = 0.05
	-- 註冊到ouf
	self.Castbar = Castbar	
	self.Castbar.PostCastStart = T.PostCastStart                            -- 施法開始
	self.Castbar.PostCastFail = T.PostCastFailed                  -- 施法失敗
    self.Castbar.PostCastInterrupted = T.PostCastFailed		    -- 施法中斷
	self.Castbar.PostCastInterruptible = T.PostCastInterruptible	        -- 狀態更新
end
