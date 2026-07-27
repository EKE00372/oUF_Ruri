local addon, ns = ...
local oUF = ns.oUF
local C, F, G, T = unpack(ns)

local GetFrameLevel, SetFrameLevel = GetFrameLevel, SetFrameLevel
--local standalone = C.StandaloneCastbar

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

T.PostCastStart_Embed = function(element, unit)
	local frame = element:GetParent()
	local castingColor = CreateColor(.6, .6, .6, .6)
	local notInterruptColor = CreateColor(.6, 0, .6, .6)
	
    -- 嵌入式施法條：施法開始時隱藏名字
    frame.Name:SetAlpha(0)
    frame.Status:SetAlpha(0)
    element.Spark:SetAlpha(.8)

    -- 判斷打斷顏色
    if unit == "player" then
        element:SetStatusBarColor(.6, .6, .6, .6)
    else
        element:GetStatusBarTexture():SetVertexColorFromBoolean(element.notInterruptible, notInterruptColor, castingColor)
    end
end

T.PostCastStart = function(element, unit)
	local frame = element:GetParent()
	local castingColor = CreateColor(unpack(C.CastNormal))
	local notInterruptColor = CreateColor(unpack(C.CastShield))
	
    -- 判斷打斷顏色
    if unit == "player" then
        element:SetStatusBarColor(unpack(C.CastNormal))
    else
        element:GetStatusBarTexture():SetVertexColorFromBoolean(element.notInterruptible, notInterruptColor, castingColor)
    end
end

-- [[ 停止施法 ]] --

T.PostCastStop_Embed = function(element, unit)
	local frame = element:GetParent()

	-- 嵌入式施法條：施法結束時顯示名字
	frame.Name:SetAlpha(1)
	frame.Status:SetAlpha(1)
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

T.PostCastStopUpdate = function(element, event, unit)
	-- 嵌入式施法條：施法過程中切換目標、新生成的名條，按施法結束處理
	if unit ~= element.unit then return end
	return T.PostCastStop_Embed(element.Castbar, unit)
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
	local frame = element:GetParent()

    --[[if frame.mystyle == "NP" then
        -- 使數字模式名條的名字復位
        frame.Name:SetPoint("BOTTOM", 0, 6)
    else]]--
    -- 嵌入式施法條：施法結束時顯示名字
    C_Timer.After(.05, function()   -- timeToHold 是0.05
        if element.casting or element.channeling or element.empowering then return end
        local frame = element:GetParent()
        frame.Name:SetAlpha(1)
        frame.Status:SetAlpha(1)
    end)
    -- 一閃而過的施法失敗紅色條
    element:SetStatusBarColor(.5, .2, .2, .6)
    element:SetValue(1)
    element.Spark:SetAlpha(0)
end

T.PostCastFailed = function(element, unit)
	local frame = element:GetParent()

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
T.PostCastInterruptible_Embed = function(element, unit)
	-- 打斷狀態更新
	if UnitIsUnit(unit, "player") then return end

	local castingColor = CreateColor(.6, .6, .6, .6)
	local notInterruptColor = CreateColor(.6, 0, .6, .6)
	element:GetStatusBarTexture():SetVertexColorFromBoolean(element.notInterruptible, notInterruptColor, castingColor)
	-- 被誰打斷
	
end

T.PostCastInterruptible = function(element, unit)
	-- 打斷狀態更新
	if UnitIsUnit(unit, "player") then return end

	local castingColor = CreateColor(unpack(C.CastNormal))
	local notInterruptColor = CreateColor(unpack(C.CastShield))
	element:GetStatusBarTexture():SetVertexColorFromBoolean(element.notInterruptible, notInterruptColor, castingColor)
	-- 被誰打斷
	
end

-- [[ 自定格式的施法時間 ]] --

T.CustomTimeText = function(element, durationObject)
	if durationObject then
		local duration = durationObject:GetRemainingDuration()
		local total = durationObject:GetTotalDuration()
		local delayText = ""
		if element.delay ~= 0 then
			delayText = format("|cffff0000%s%.2f|r", element.channeling and '-' or '+', element.delay)
		end
		element.Time:SetFormattedText('%.1f%s/%.1f', duration, delayText, total)
	end
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
	self.Castbar.CustomTimeText = T.CustomTimeText			-- 施法時間
	self.Castbar.CustomDelayText = T.CustomTimeText			-- 施法時間
	self.Castbar.PostCastFail = T.PostCastFailed_Embed			-- 施法失敗
	self.Castbar.PostCastInterrupted = T.PostCastFailed_Embed		-- 施法中斷
	self.Castbar.PostCastInterruptible = T.PostCastInterruptible_Embed	-- 狀態刷新
	-- 當前目標正在施法時，切換目標會重新獲取名字，防止丟失
	self:RegisterEvent("UNIT_NAME_UPDATE", T.PostCastStopUpdate)
	table.insert(self.__elements, T.PostCastStopUpdate)
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
		Castbar.Time:SetPoint("RIGHT", -5, 0)
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
	end
	
	-- 選項
	Castbar.timeToHold = 0.05
	-- 註冊到ouf
	self.Castbar = Castbar	
	self.Castbar.PostCastStart = T.PostCastStart                            -- 施法開始
	self.Castbar.CustomTimeText = T.CustomTimeText                          -- 施法時間
    self.Castbar.CustomDelayText = T.CustomTimeText                         -- 施法時間
	self.Castbar.PostCastFail = T.PostCastFailed                  -- 施法失敗
    self.Castbar.PostCastInterrupted = T.PostCastFailed		    -- 施法中斷
	self.Castbar.PostCastInterruptible = T.PostCastInterruptible	        -- 狀態更新
end
