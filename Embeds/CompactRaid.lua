local addon, ns = ...
local F = ns[2]

do
	local function Initialize(loader)
		if not F.GetRuriOption("RaidFrames") or not F.GetRuriOption("HideBlizzardRaidFrames") then return end

		local hiddenParent = CreateFrame("Frame", nil, UIParent)
		hiddenParent:Hide()
		local hooked

		-- 停用原生團框容器，但保留左側的團隊管理介面
		local function DisableFrames()
			local container = CompactRaidFrameContainer
			if InCombatLockdown() or not container then return end

			container:UnregisterAllEvents()
			container:Hide()
			container:SetParent(hiddenParent)

			if not hooked then
				hooked = true
				container:HookScript("OnShow", function(self)
					if InCombatLockdown() then
						loader:RegisterEvent("PLAYER_REGEN_ENABLED")
					else
						self:Hide()
					end
				end)
				hooksecurefunc(container, "SetParent", function(self, parent)
					if parent == hiddenParent then return end
					if InCombatLockdown() then
						loader:RegisterEvent("PLAYER_REGEN_ENABLED")
					else
						self:SetParent(hiddenParent)
					end
				end)
			end

			-- 團框已由隱藏父框架停用，保持 CVar 開啟以修復舊版本留下的持久隱藏
			if not GetCVarBool("raidOptionIsShown") then
				SetCVar("raidOptionIsShown", "1")
			end

			loader:UnregisterAllEvents()
		end

		-- 延遲載入：在暴雪載入之後套用
		local applyQueued = false
		local function QueueApply()
			if applyQueued then return end

			applyQueued = true
			C_Timer.After(0, function()
				applyQueued = false
				DisableFrames()
			end)
		end

		-- 等待暴雪模組載入，並在戰鬥外完成初始化
		local _, compactRaidFramesLoaded = C_AddOns.IsAddOnLoaded("Blizzard_CompactRaidFrames")
		if not compactRaidFramesLoaded then
			loader:RegisterEvent("ADDON_LOADED")
		end
		loader:RegisterEvent("PLAYER_ENTERING_WORLD")
		loader:RegisterEvent("PLAYER_REGEN_ENABLED")
		loader:SetScript("OnEvent", function(self, event, name)
			if event == "ADDON_LOADED" then
				if name ~= "Blizzard_CompactRaidFrames" then return end
				self:UnregisterEvent(event)
			end

			QueueApply()
		end)
	end

	-- SavedVariables 只保證在插件自身 ADDON_LOADED 時可用
	local loader = CreateFrame("Frame")
	loader:RegisterEvent("ADDON_LOADED")
	loader:SetScript("OnEvent", function(self, event, name)
		if name ~= addon then return end

		self:UnregisterEvent(event)
		self:SetScript("OnEvent", nil)
		Initialize(self)
	end)
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
