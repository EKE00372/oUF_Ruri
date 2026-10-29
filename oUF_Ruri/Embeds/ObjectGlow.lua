local _, ns = ...
local F, G = ns[2], ns[3]

local function CreateObjectGlow()
	local glow = CreateFrame("Frame", nil, WorldFrame)
	glow:SetSize(96, 96)
	glow:Hide()

	local ring = glow:CreateTexture(nil, "BACKGROUND")
	ring:SetAllPoints(glow)
	ring:SetTexture(G.media.circle)
	ring:SetVertexColor(1, 0.82, 0.25)
	ring:SetBlendMode("ADD")

	local pulse = ring:CreateAnimationGroup()
	pulse:SetLooping("BOUNCE")
	local alpha = pulse:CreateAnimation("Alpha")
	alpha:SetFromAlpha(0.45)
	alpha:SetToAlpha(0.9)
	alpha:SetDuration(0.8)
	alpha:SetSmoothing("IN_OUT")
	glow:SetScript("OnShow", function() pulse:Play() end)
	glow:SetScript("OnHide", function() pulse:Stop() end)

	local currentPlate
	local inWorld = true
	local function Release()
		glow:Hide()
		glow:ClearAllPoints()
		glow:SetParent(WorldFrame)
		currentPlate = nil
	end

	local function Update()
		if not inWorld then return end

		-- 固定 token 的 GameObject 判定為公開 bool；不讀取單位 GUID、名稱或游標材質。
		local plate = UnitIsGameObject("softinteract") and C_NamePlate.GetNamePlateForUnit("softinteract")
		if not plate then
			Release()
			return
		end

		if plate ~= currentPlate then
			Release()
			glow:SetParent(plate)
			glow:SetPoint("CENTER", plate, "CENTER", 0, 0)
			currentPlate = plate
		end
		glow:Show()
	end

	-- oUF 的 GameObject 分支不會呼叫 addedCallback；獨立追蹤原生名條生命週期。
	local driver = CreateFrame("Frame")
	driver:RegisterEvent("PLAYER_SOFT_INTERACT_CHANGED")
	driver:RegisterEvent("NAME_PLATE_UNIT_ADDED")
	driver:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
	driver:RegisterEvent("PLAYER_ENTERING_WORLD")
	driver:RegisterEvent("PLAYER_LEAVING_WORLD")
	driver:SetScript("OnEvent", function(_, event, unit)
		if event == "NAME_PLATE_UNIT_REMOVED" then
			-- 移除事件內仍可能查到舊 root；清除後不可立即重新掛回。
			local removedPlate = C_NamePlate.GetNamePlateForUnit(unit)
			if removedPlate == currentPlate or not C_NamePlate.GetNamePlateForUnit("softinteract") then
				Release()
			end
		elseif event == "PLAYER_LEAVING_WORLD" then
			inWorld = false
			Release()
		else
			if event == "PLAYER_ENTERING_WORLD" then inWorld = true end
			-- soft 事件的 GUID payload 可能為 secret，僅以事件通知重新取得固定 token。
			Update()
		end
	end)
	Update()
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", function(self, event)
	self:UnregisterEvent(event)
	self:SetScript("OnEvent", nil)
	if F.GetRuriOption("ObjectGlow") then
		CreateObjectGlow()
	end
end)
