----------------------
-- Dont touch this! --
----------------------

local addon, ns = ...
	ns[1] = {} -- C, config
	ns[2] = {} -- F, functions, constants, variables
	ns[3] = {} -- G, globals (Optionnal)
	ns[4] = {} -- T, ouf custom
	ns[5] = {} -- L, locale

local F, G = ns[2], ns[3]

	G.addon = "oUF_Ruri_"
	G.myClass = select(2, UnitClass("player"))

	G.MediaFolder = "Interface\\AddOns\\oUF_Ruri\\Media\\"

local MediaFolder = G.MediaFolder

------------
-- Global --
------------

	-- NOTE: GUI-controlled toggles are defined in F.GUIOptionGroups below.

-------------
-- Texture --
-------------

	G.media = {
		blank = MediaFolder.."dM3",		-- "Interface\\Buttons\\WHITE8x8",
		absorb = MediaFolder.."absorb.tga",
		raidbar = MediaFolder.."Inner-Shadow.blp",
		glow = MediaFolder.."glow.tga",
		barhightlight = MediaFolder.."highlight.tga",

		spark = MediaFolder.."spark.tga",	-- "Interface\\UnitPowerBarAlt\\Generic1Player_Pill_Flash"

		resting = MediaFolder.."resting.blp",
		combat = MediaFolder.."combat.blp",
		raidicon = MediaFolder.."raidicons.blp",
		skull = MediaFolder.."RaidFrameDeathIcon.blp",

		circle = MediaFolder.."crosshair_circle.blp",
		arrows = MediaFolder.."crosshair_arrows.blp",

		role_dps = MediaFolder.."role_DPS.tga",
		role_tank = MediaFolder.."role_Tank.tga",
		role_healer = MediaFolder.."role_Healer.tga",
		info = "Interface\\FriendsFrame\\InformationIcon",
	}

------------------
-- GUI settings --
------------------

	F.GUIOptionGroups = {
		{
			name = "Overview",
			options = {
				{ type = "toggle", key = "UnitFrames", label = "UnitFrames", desc = "UnitFramesDesc", default = true },
				{ type = "toggle", key = "PartyFrames", label = "PartyFrames", desc = "PartyFramesDesc", default = false },
				{ type = "toggle", key = "RaidFrames", label = "RaidFrames", desc = "RaidFramesDesc", default = false },
				{ type = "toggle", key = "Nameplates", label = "Nameplates", desc = "NameplatesDesc", default = false },
			},
		},
		{
			name = "UnitFrames",
			requiresAny = { "UnitFrames" },
			sections = {
				{
					name = "StyleSwitch",
					options = {
						{ type = "toggle", key = "vertPlayer", label = "VerticalPlayer", default = true },
						{ type = "toggle", key = "vertTarget", label = "VerticalTarget", default = true },
						{ type = "toggle", key = "SimpleFocus", label = "SimpleFocus", default = true, tooltip = "SimpleFocusTip" },
					},
				},
				{
					name = "DisplayFrames",
					options = {
						{ type = "toggle", key = "Arena", label = "ArenaFrames", default = true },
						{ type = "toggle", key = "Boss", label = "BossFrames", default = true },
					},
				},
				{
					name = "DisplayElements",
					options = {
						{ type = "toggle", key = "PlayerDebuffs", label = "PlayerDebuffs", default = true },
						{ type = "toggle", key = "Totems", label = "Totems", default = false, tooltip = "TotemsTip" },
						{ type = "toggle", key = "TankResource", label = "TankResource", default = false, tooltip = "TankResourceTip" },
						{ type = "toggle", key = "StandaloneCastbar", label = "StandaloneCastbar", default = false, tooltip = "StandaloneCastbarTip" },
						{ type = "toggle", key = "Fade", label = "Fade", default = true, tooltip = "FadeTip" },
					},
				},
			},
		},
		{
			name = "RaidFrames",
			options = {
				{ type = "toggle", key = "HideBlizzardRaidFrames", label = "HideBlizzardRaidFrames", default = true, tooltip = "HideBlizzardRaidFramesTip", requiresAny = { "PartyFrames", "RaidFrames" } },
				{ type = "toggle", key = "HideCompactRaidManager", label = "HideCompactRaidManager", default = true, tooltip = "HideCompactRaidManagerTip" },
			},
		},
		{
			name = "Nameplates",
			sections = {
				{
					name = "Nameplates",
					requiresAny = { "Nameplates" },
					options = {
						{ type = "toggle", key = "NumberStyle", label = "NumberStyle", default = false },
						{ type = "toggle", key = "ShowAuras", label = "ShowAuras", default = true },
						{ type = "toggle", key = "HLTarget", label = "HighlightTargetFocus", default = true },
						{ type = "toggle", key = "HLMouseover", label = "HighlightMouseover", default = true },
					},
				},
				{
					name = "Extensions",
					options = {
						{ type = "toggle", key = "Crosshairs", label = "Crosshairs", default = false },
						{ type = "toggle", key = "FriendlyNameSize", label = "FriendlyNameSize", default = true, tooltip = "FriendlyNameSizeTip", requiresAny = { "Nameplates" } },
						{ type = "toggle", key = "CVars", label = "CVars", default = true, tooltip = "CVarsTip", requiresAny = { "Nameplates" } },
						{ type = "toggle", key = "PlayerPlate", label = "PlayerPlate", default = false, tooltip = "PlayerPlateTip", requiresAny = { "UnitFrames" } },
					},
				},
			},
		},
	}

-------------------------
-- Initialize settings --
-------------------------

	local type, pairs, ipairs = type, pairs, ipairs

	F.GUIOptionMap = {}

	local function AddGUIOption(option)
		F.GUIOptionMap[option.key] = option
	end

	for _, group in ipairs(F.GUIOptionGroups) do
		for _, option in ipairs(group.options or {}) do
			AddGUIOption(option)
		end
		for _, section in ipairs(group.sections or {}) do
			for _, option in ipairs(section.options or {}) do
				AddGUIOption(option)
			end
		end
	end

	local function GetGUIOptionsDB()
		if type(RuriDB) ~= "table" then
			RuriDB = {}
		end

		if type(RuriDB.Options) ~= "table" then
			RuriDB.Options = {}
		end

		return RuriDB.Options
	end

	local function ApplyGUIOptions()
		local db = GetGUIOptionsDB()

		-- Add missing defaults and lock disabled options to defaults / 補上缺少的預設值，並將禁用項鎖回預設值
		for key, option in pairs(F.GUIOptionMap) do
			if option.disabled then
				db[key] = option.default
			elseif db[key] == nil then
				db[key] = option.default
			end
		end

		-- Remove stale saved keys / 刪除插件已不存在的存檔項
		for key in pairs(db) do
			if F.GUIOptionMap[key] == nil then
				db[key] = nil
			end
		end
	end

	F.GetRuriOption = function(key)
		local option = F.GUIOptionMap[key]
		if not option then return nil end

		if option.disabled then return option.default end

		local db = GetGUIOptionsDB()
		if db[key] == nil then
			db[key] = option.default
		end

		return db[key]
	end

	F.SetRuriOption = function(key, value)
		local option = F.GUIOptionMap[key]
		if not option or option.disabled then
			return F.GetRuriOption(key)
		end

		local db = GetGUIOptionsDB()
		if option.type == "toggle" then
			db[key] = value == true
		else
			db[key] = value
		end

		return db[key]
	end

	local dbLoader = CreateFrame("Frame")
	dbLoader:RegisterEvent("ADDON_LOADED")
	dbLoader:SetScript("OnEvent", function(self, event, name)
		if name ~= addon then return end

		ApplyGUIOptions()
		self:UnregisterEvent(event)
		self:SetScript("OnEvent", nil)
	end)
