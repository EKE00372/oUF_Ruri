local _, ns = ...
local F = ns[2]

local reopeningUnit

-- Lua 重開的選單帶有 addon taint，停用會觸發受保護操作的項目以避免污染
local function DisableProtectedItems(_, rootDescription, contextData)
	if not reopeningUnit or not contextData or contextData.unit ~= reopeningUnit then return end

	for _, description in rootDescription:EnumerateElementDescriptions() do
		local text = MenuUtil.GetElementText(description)
		if description.SetEnabled and (text == SET_FOCUS or text == FOLLOW or text == UNIT_VIEW_HOUSES) then
			description:SetEnabled(false)
		end
	end
end

Menu.ModifyMenu("MENU_UNIT_RAID_PLAYER", DisableProtectedItems)

hooksecurefunc("UnitPopup_OpenMenu", function(which, contextData)
	if reopeningUnit then return end
	if which ~= "PET" and which ~= "OTHERPET" and which ~= "OTHERBATTLEPET" then return end
	if not F.GetRuriOption("RaidFrames") then return end

	local unit = contextData and contextData.unit
	-- raidN 必定是玩家成員
	if type(unit) ~= "string" or not unit:match("^raid%d+$") then return end

	reopeningUnit = unit
	-- UnitPopup_OpenMenu 會修改 contextData，不能沿用原本的 table
	UnitPopup_OpenMenu("RAID_PLAYER", { unit = unit })
	reopeningUnit = nil
end)
