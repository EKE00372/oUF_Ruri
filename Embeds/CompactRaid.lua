local addon, ns = ...
local C, F, G, T = unpack(ns)


do
	-- 隱藏原生團隊框架，但保留團隊管理介面
	local function SetRaidShown(shown)
		if InCombatLockdown() then return end
		-- Blizzard_CompactRaidFrames 載入後才有 CompactRaidFrameManager_SetSetting
		if not CompactRaidFrameManager_SetSetting then return end

		local value = shown and "1" or "0"
		if GetCVar("raidOptionIsShown") ~= value then
			SetCVar("raidOptionIsShown", value)
		end

		CompactRaidFrameManager_SetSetting("IsShown", shown)
	end

	-- 隱藏原生隊伍框架
	local function SetPartyShown(shown)
		if shown or InCombatLockdown() then return end

		if EditModeManagerFrame:UseRaidStylePartyFrames() then
			if CompactPartyFrame then CompactPartyFrame:Hide() end
		else
			if PartyFrame then PartyFrame:Hide() end
		end
	end

	-- 一次套用到隊伍與團隊
	local function ApplyFrames()
		local hideNative = F.GetRuriOption("HideBlizzardRaidFrames")
		local raidShown = not (hideNative and F.GetRuriOption("RaidFrames"))
		local partyShown = not (hideNative and F.GetRuriOption("PartyFrames"))
		SetRaidShown(raidShown)
		SetPartyShown(partyShown)
	end

	-- 延遲載入：在暴雪載入之後套用
	local applyQueued = false
	local function QueueApply()
		if applyQueued then return end

		applyQueued = true
		C_Timer.After(0, function()
			applyQueued = false
			ApplyFrames()
		end)
	end

	-- 監聽會更新框架的事件
	local loader = CreateFrame("Frame")
	loader:RegisterEvent("PLAYER_ENTERING_WORLD")
	loader:RegisterEvent("GROUP_ROSTER_UPDATE")
	loader:RegisterEvent("UPDATE_ACTIVE_BATTLEFIELD")
	loader:RegisterEvent("PLAYER_REGEN_ENABLED")
	loader:SetScript("OnEvent", QueueApply)

	if EventRegistry then
		EventRegistry:RegisterCallback("EditMode.Enter", QueueApply, loader)
		EventRegistry:RegisterCallback("EditMode.Exit", QueueApply, loader)
		EventRegistry:RegisterCallback("EditMode.SavedLayouts", QueueApply, loader)
	end
end

-- 團隊管理介面滑鼠淡入淡出
do
	if not F.GetRuriOption("HideCompactRaidManager") then return end

	local fadeOutDelay = 1	-- 延遲一秒淡出
	local fadeOutToken = 0	-- C_Timer.After 無法取消，用 token 判斷已排程的淡出是否需要取消
	local fadeOutAnimation

	-- 取消淡出
	local function CancelFadeOut()
		fadeOutToken = fadeOutToken + 1
		if fadeOutAnimation and fadeOutAnimation:IsPlaying() then
			fadeOutAnimation:Stop()
		end
	end

	-- 建立淡出動畫
	local function GetFadeOutAnimation(manager)
		if fadeOutAnimation then return fadeOutAnimation end

		fadeOutAnimation = manager:CreateAnimationGroup()
		fadeOutAnimation:SetToFinalAlpha(true)
		fadeOutAnimation:SetScript("OnFinished", function()
			if manager.collapsed and not manager:IsMouseOver() then
				manager:SetAlpha(0)
			end
		end)

		local alpha = fadeOutAnimation:CreateAnimation("Alpha")
		alpha:SetFromAlpha(1)
		alpha:SetToAlpha(0)
		alpha:SetDuration(0.5)
		alpha:SetSmoothing("IN_OUT")

		return fadeOutAnimation
	end

	-- 延遲一秒淡出
	local function HideManager(manager)
		CancelFadeOut()
		local token = fadeOutToken

		C_Timer.After(fadeOutDelay, function()
			if token ~= fadeOutToken then return end
			if not manager.collapsed or manager:IsMouseOver() then return end

			manager:SetAlpha(1)
			GetFadeOutAnimation(manager):Play()
		end)
	end

	-- 滑鼠移入或介面展開時顯示
	local function ShowManager(self)
		CancelFadeOut()
		self:SetAlpha(1)
	end

	-- 只有收合狀態才排程淡出
	local function HideCollapsedManager(self)
		if self.collapsed then
			HideManager(self)
		end
	end

	-- 團隊管理介面展開時，重新套用透明度
	local function RefreshManagerAlpha()
		local manager = CompactRaidFrameManager
		if not manager then return end

		if manager.collapsed and not manager:IsMouseOver() then
			CancelFadeOut()
			manager:SetAlpha(0)
		else
			ShowManager(manager)
		end
	end

	-- 進入世界後掛上 mouseover
	local loader = CreateFrame("Frame")
	loader:RegisterEvent("PLAYER_ENTERING_WORLD")
	loader:SetScript("OnEvent", function(self)
		self:UnregisterAllEvents()
		CompactRaidFrameManager:HookScript("OnEnter", ShowManager)
		CompactRaidFrameManager:HookScript("OnLeave", HideCollapsedManager)
		CompactRaidFrameManager:HookScript("OnShow", RefreshManagerAlpha)

		RefreshManagerAlpha()
	end)
end
