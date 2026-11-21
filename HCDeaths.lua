-- HCDeaths: original addon by Grylls / GryllsAddons.
-- Copyright (c) 2023 GryllsAddons. MIT License; see LICENSE.
-- Unofficial fork modifications: settings GUI and paged log (2026-11-20).
-- This modified version is not an official release by the original author.

-- Octo WoW is the primary target. Other compatible 1.12 servers are unverified.

HCDeaths_Settings = {
	message = true,
	log = false,
	toast = true,
	color = false,
	deathsound = true,
	levelsound = true,
	roar = false,
	toastscale = 1,
	logscale = 1,
	toasttime = 10,
	progress = true,
}

local deathsound = {
	["Dwarf"] = {
		[1] = "Sound\\Character\\Dwarf\\DwarfFemale\\Emote\\DwarfFemale_Roar01.wav",
		[2] = "Sound\\Character\\Dwarf\\DwarfMale\\Emote\\DwarfMale_Roar02.wav",
	},

	["Gnome"] = {
		[1] = "Sound\\Character\\Gnome\\GnomeFemale\\Emote\\GnomeFemale_Roar01.wav",
		[2] = "Sound\\Character\\Gnome\\GnomeMale\\Emote\\GnomeMale_Roar01.wav",
	},

	["Goblin"] = {
		[1] = "Sound\\Character\\Goblin\\GoblinFemale\\Emote\\GoblinFemale_Roar01.ogg",
		[2] = "Sound\\Character\\Goblin\\GoblinMale\\Emote\\GoblinMale_Roar02.wav",
	},
		
	["High Elf"] = {
		[1] = "Sound\\Character\\HighElf\\HighElfFemale\\Emote\\HighElfFemale_Roar01.wav",
		[2] = "Sound\\Character\\HighElf\\HighElfMale\\Emote\\HighElfMale_Roar01.wav",		
	},

	["Human"] = {
		[1] = "Sound\\Character\\Human\\HumanFemale\\Emote\\HumanFemale_Roar01.wav",
		[2] = "Sound\\Character\\Human\\HumanMale\\Emote\\HumanMale_Roar02.wav",
	},
	
	["Night Elf"] = {
		[1] = "Sound\\Character\\NightElf\\NightElfFemale\\Emote\\NightElfFemale_Roar01.wav",
		[2] = "Sound\\Character\\NightElf\\NightElfMale\\Emote\\NightElfMale_Roar02.wav",
	},

	["Orc"] = {
		[1] = "Sound\\Character\\Orc\\OrcFemale\\Emote\\OrcFemale_Roar01.wav",
		[2] = "Sound\\Character\\Orc\\OrcMale\\Emote\\OrcMale_Roar01.wav",
	},

	["Tauren"] = {
		[1] = "Sound\\Character\\Tauren\\TaurenFemale\\Emote\\TaurenFemale_Roar01.wav",
		[2] = "Sound\\Character\\Tauren\\TaurenMale\\Emote\\TaurenMale_Roar01.wav",
	},

	["Troll"] = {
		[1] = "Sound\\Character\\Troll\\TrollFemale\\Emote\\TrollFemale_Roar01.wav",
		[2] = "Sound\\Character\\Troll\\TrollMale\\Emote\\TrollMale_Roar02.wav",
	},

	["Undead"] = {
		[1] = "Sound\\Character\\Undead\\UndeadFemale\\Emote\\UndeadFemale_Roar01.wav",
		[2] = "Sound\\Character\\Undead\\UndeadMale\\Emote\\UndeadMale_Roar02.wav",
	},
}

local progress = {
	["Dwarf"] = {		
		[1] = "\\Sound\\Character\\Dwarf\\DwarfVocalFemale\\DwarfFemaleCheer01.wav",
		[2] = "\\Sound\\Character\\Dwarf\\DwarfVocalFemale\\DwarfFemaleCheer02.wav",
		[3] = "\\Sound\\Character\\Dwarf\\DwarfVocalMale\\DwarfMaleCheer01.wav",
		[4] = "\\Sound\\Character\\Dwarf\\DwarfVocalMale\\DwarfMaleCheer02.wav",
	},

	["Gnome"] = {
		[1] = "\\Sound\\Character\\Gnome\\GnomeVocalFemale\\GnomeFemaleCheer01.wav",
		[2] = "\\Sound\\Character\\Gnome\\GnomeVocalFemale\\GnomeFemaleCheer02.wav",
		[3] = "\\Sound\\Character\\Gnome\\GnomeVocalMale\\GnomeMaleCheer01.wav",
		[4] = "\\Sound\\Character\\Gnome\\GnomeVocalMale\\GnomeMaleCheer02.wav",
	},

	["Goblin"] = {
		[1] = "Sound\\Character\\Goblin\\GoblinFemale\\Emote\\GoblinFemale_Cheer01.ogg",
		[2] = "Sound\\Character\\Goblin\\GoblinFemale\\Emote\\GoblinFemale_Cheer02.ogg",
		[3] = "Sound\\Character\\Goblin\\GoblinMale\\Emote\\GoblinMale_Cheer01.wav",
		[4] = "Sound\\Character\\Goblin\\GoblinMale\\Emote\\GoblinMale_Cheer02.wav",
	},
		
	["High Elf"] = {
		[1] = "Sound\\Character\\HighElf\\HighElfFemale\\Emote\\HighElfFemale_Cheer01.wav",
		[2] = "Sound\\Character\\HighElf\\HighElfFemale\\Emote\\HighElfFemale_Cheer03.wav",
		[3] = "Sound\\Character\\HighElf\\HighElfMale\\Emote\\HighElfMale_Cheer01.wav",
		[4] = "Sound\\Character\\HighElf\\HighElfMale\\Emote\\HighElfMale_Cheer02.wav",
	},

	["Human"] = {
		[1] = "Sound\\Character\\Human\\HumanVocalFemale\\HumanFemaleCheer01.wav",
		[2] = "Sound\\Character\\Human\\HumanVocalFemale\\HumanFemaleCheer02.wav",
		[3] = "Sound\\Character\\Human\\HumanVocalMale\\HumanMaleCheer01.wav",
		[4] = "Sound\\Character\\Human\\HumanVocalMale\\HumanMaleCheer02.wav",
	},
	
	["Night Elf"] = {
		[1] = "Sound\\Character\\NightElf\\NightElfVocalFemale\\NightElfFemaleCheer01.wav",
		[2] = "Sound\\Character\\NightElf\\NightElfVocalFemale\\NightElfFemaleCheer02.wav",
		[3] = "Sound\\Character\\NightElf\\NightElfVocalMale\\NightElfMaleCheer01.wav",
		[4] = "Sound\\Character\\NightElf\\NightElfVocalMale\\NightElfMaleCheer02.wav",
	},

	["Orc"] = {
		[1] = "Sound\\Character\\Orc\\OrcVocalFemale\\OrcFemaleCheer01.wav",
		[2] = "Sound\\Character\\Orc\\OrcVocalFemale\\OrcFemaleCheer02.wav",
		[3] = "Sound\\Character\\Orc\\OrcVocalMale\\OrcMaleCheer01.wav",
		[4] = "Sound\\Character\\Orc\\OrcVocalMale\\OrcMaleCheer02.wav",
	},

	["Tauren"] = {
		[1] = "Sound\\Character\\Tauren\\TaurenVocalFemale\\TaurenFemaleCheer01.wav",
		[2] = "Sound\\Character\\Tauren\\TaurenVocalFemale\\TaurenFemaleCheer02.wav",
		[3] = "Sound\\Character\\Tauren\\TaurenVocalMale\\TaurenMaleCheer01.wav",
		[4] = "Sound\\Character\\Tauren\\TaurenVocalMale\\TaurenMaleCheer02.wav",
	},

	["Troll"] = {
		[1] = "Sound\\Character\\Troll\\TrollVocalFemale\\TrollFemaleCheer01.wav",
		[2] = "Sound\\Character\\Troll\\TrollVocalFemale\\TrollFemaleCheer02.wav",
		[3] = "Sound\\Character\\Troll\\TrollVocalMale\\TrollMaleCheer01.wav",
		[4] = "Sound\\Character\\Troll\\TrollVocalMale\\TrollMaleCheer02.wav",
	},

	["Undead"] = {
		[1] = "Sound\\Character\\Scourge\\ScourgeVocalFemale\\UndeadFemaleCheer01.wav",
		[2] = "Sound\\Character\\Scourge\\ScourgeVocalFemale\\UndeadFemaleCheer02.wav",
		[3] = "Sound\\Character\\Scourge\\ScourgeVocalMale\\UndeadMaleCheer01.wav",
		[4] = "Sound\\Character\\Scourge\\ScourgeVocalMale\\UndeadMaleCheer02.wav",
	},
}

local instances = {
	-- Turtle
	"Hateforge Quarry",
	"Black Morass",
	"Karazhan Crypt",
	"Stormwind Vault",
	"Crescent Grove",
	-- Dungeons
	"Blackfathom Deeps",
	"Blackrock Depths",
	"Blackrock Spire",
	"Dire Maul",
	"Gnomeregan",
	"Maraudon",
	"Ragefire Chasm",
	"Razorfen Downs",
	"Razorfen Kraul",
	"Scarlet Monastery",
	"Scholomance",
	"Shadowfang Keep",
	"Stratholme",
	"The Deadmines",
	"The Stockade",
	"Uldaman",
	"Wailing Cavems",
	"Zul'Farrak",
	-- Raids
	"Blackwing Lair",
	"Molten Core",
	"Naxxramas",
	"Onyxia's Lair",
	"Ruins of Ahn'Qiraj",
	"Temple of Ahn'Qiraj",
	"Zul'Gurub",
}

local HCDeath = CreateFrame("Frame", nil, UIParent)
HCDeaths_API = HCDeath
HCDeaths = HCDeaths or {}
HCDeaths_LastWords = HCDeaths_LastWords or {}

local media = "Interface\\Addons\\HCDeaths\\media\\"
local deaths = {}
local pendingLastWords = {}
local activeToastRecord
local whoQueue = {}
local currentWho
local nextWhoAt = 0
local WHO_INTERVAL = 10
local WHO_TIMEOUT = 5
local toastMove -- state of toast moving

local is_pfUI

local twidth, theight = 332.8, 166.4

local queryTimer = CreateFrame("Frame", nil, HCDeath)
queryTimer:Hide()
queryTimer:SetScript("OnUpdate", function()
    HCDeath:PumpWho()
end)

do
	-- toast
	local HCDeathsToast = CreateFrame("Button", "HCDeathsToast", HCDeath)
	HCDeathsToast:SetWidth(twidth)
	HCDeathsToast:SetHeight(theight)
	HCDeathsToast:Hide()

	-- texture
	HCDeath.texture = HCDeathsToast:CreateTexture(nil,"LOW")
	HCDeath.texture:SetAllPoints(HCDeathsToast)	

	HCDeath.race = HCDeathsToast:CreateTexture(nil,"BACKGROUND")
	HCDeath.race:SetPoint("CENTER", HCDeath.texture, "CENTER", -43, -24)

	HCDeath.class = HCDeathsToast:CreateTexture(nil,"BACKGROUND")
	HCDeath.class:SetPoint("CENTER", HCDeath.texture, "CENTER", 0, 10)

	-- text
	local font, size, outline = "Fonts\\FRIZQT__.TTF", 16, "OUTLINE"
	
	HCDeath.level = HCDeathsToast:CreateFontString(nil, "LOW", "GameFontNormal")
	HCDeath.level:SetPoint("TOP", HCDeath.texture, "CENTER", 42, -15)
	HCDeath.level:SetWidth(HCDeath.texture:GetWidth())
	HCDeath.level:SetFont(font, size, outline)

	HCDeath.name = HCDeathsToast:CreateFontString(nil, "LOW", "GameFontNormal")	
	HCDeath.name:SetWidth(HCDeath.texture:GetWidth())
	HCDeath.name:SetFont(font, size, outline)

	outline = "THINOUTLINE"

	HCDeath.guild = HCDeathsToast:CreateFontString(nil, "LOW", "GameFontNormal")	
	HCDeath.guild:SetWidth(HCDeath.texture:GetWidth())
	HCDeath.guild:SetFont(font, size-1, outline)

	HCDeath.location = HCDeathsToast:CreateFontString(nil, "LOW", "GameFontNormal")	
	HCDeath.location:SetWidth(HCDeath.texture:GetWidth()*1.5)
	HCDeath.location:SetFont(font, size, outline)

	HCDeath.death = HCDeathsToast:CreateFontString(nil, "LOW", "GameFontNormal")	
	HCDeath.death:SetWidth(HCDeath.texture:GetWidth()*1.5)
	HCDeath.death:SetFont(font, size, outline)

	HCDeath.lastwords = HCDeathsToast:CreateFontString(nil, "LOW", "GameFontNormal")
	HCDeath.lastwords:SetWidth(HCDeath.texture:GetWidth())
	HCDeath.lastwords:SetFont(font, size, outline)
	HCDeath.lastwords:SetTextColor(.5,.5,.5)
	
	-- HCDeath.quote = HCDeathsToast:CreateFontString(nil, "LOW", "GameFontNormal")
	-- HCDeath.quote:SetPoint("TOP", HCDeath.death, "BOTTOM", 0, -10)
	-- HCDeath.quote:SetWidth(HCDeath.texture:GetWidth()*1.5)
	-- HCDeath.quote:Hide()
	-- HCDeath.quote:SetFont("Fonts\\SKURRI.TTF", size, outline)

	if is_pfUI then
		HCDeath.texture:SetTexture(media.."Ring\\".."Ring_pfUI")		
		HCDeath.name:SetPoint("TOP", HCDeath.texture, "CENTER", 0, -44)
		HCDeath.guild:SetPoint("TOP", HCDeath.name, "BOTTOM", 0, -2)
		HCDeath.location:SetPoint("TOP", HCDeath.guild, "BOTTOM", 0, -10)
		HCDeath.death:SetPoint("TOP", HCDeath.location, "BOTTOM", 0, -5)		
		HCDeath.lastwords:SetPoint("TOP", HCDeath.death, "BOTTOM", 0, -10)
	else
		HCDeath.texture:SetTexture(media.."Ring\\".."Ring")
		HCDeath.name:SetPoint("TOP", HCDeath.texture, "CENTER", 0, -44)
		HCDeath.guild:SetPoint("TOP", HCDeath.name, "BOTTOM", 0, -12)
		HCDeath.location:SetPoint("TOP", HCDeath.guild, "BOTTOM", 0, -10)
		HCDeath.death:SetPoint("TOP", HCDeath.location, "BOTTOM", 0, -5)		
		HCDeath.lastwords:SetPoint("TOP", HCDeath.death, "BOTTOM", 0, -10)
	end

	HCDeathsToast:SetMovable(true)
	HCDeathsToast:SetClampedToScreen(true)
	HCDeathsToast:SetUserPlaced(true)
	HCDeathsToast:EnableMouse(true)
	HCDeathsToast:RegisterForClicks("RightButtonDown")
	HCDeathsToast:RegisterForDrag("LeftButton")
  
	function HCDeathsToast:position()
		HCDeathsToast:ClearAllPoints()
		HCDeathsToast:SetPoint("CENTER", UIErrorsFrame, "CENTER", 0, -20)
	end
  
	HCDeathsToast:position()
  
	HCDeathsToast:SetScript("OnDragStart", function()
	  if (IsShiftKeyDown() and IsControlKeyDown()) then
		HCDeathsToast:StartMoving()
	  end
	end)
  
	HCDeathsToast:SetScript("OnDragStop", function()
		HCDeathsToast:StopMovingOrSizing()
	end)
  
	HCDeathsToast:SetScript("OnClick", function()
	  if (IsShiftKeyDown() and IsControlKeyDown()) then
		HCDeathsToast:SetUserPlaced(false)
		HCDeathsToast:position()
	  end
	end)
end

local toastTimer = CreateFrame("Frame", nil, HCDeath)
toastTimer:Hide()
toastTimer:SetScript("OnUpdate", function()
	if GetTime() >= this.time then
		this.time = nil
		HCDeath:hideToast()
		this:Hide()
		HCDeath:Toast()
	end
end)

function HCDeath:Check_pfUI()
    is_pfUI = IsAddOnLoaded("pfUI")
end

function HCDeath:classSize()
	local s = 85
	HCDeath.class:SetWidth(s)
	HCDeath.class:SetHeight(s)
end

function HCDeath:raceSize()
	local s = 25
	HCDeath.race:SetWidth(s)
	HCDeath.race:SetHeight(s)
end

function HCDeath:showToast()
	HCDeath:classSize()
	HCDeath:raceSize()
	HCDeathsToast:Show()

	toastTimer.time = GetTime() + HCDeaths_Settings.toasttime
	toastTimer:Show()
end

function HCDeath:hideToast()
    activeToastRecord = nil
	HCDeathsToast:Hide()

	HCDeath.name:SetText("")
	HCDeath.level:SetText("")
	HCDeath.guild:SetText("")
	HCDeath.location:SetText("")
	HCDeath.death:SetText("")
	HCDeath.lastwords:SetText("")
	-- HCDeath.quote:SetText("")
end

function HCDeath:texColor(level)
	HCDeath.texture:SetVertexColor(.75,.75,.75)
	if HCDeaths_Settings.color then
		if level == 60 then
			-- gold
			-- #ffd700
			HCDeath.texture:SetVertexColor(255/255, 215/255, 0/255)
		elseif level >= 50 then
			-- #e0cc5f
			HCDeath.texture:SetVertexColor(224/255, 204/255, 95/255)
		elseif level >= 40 then
			-- silver
			HCDeath.texture:SetVertexColor(1,1,1)
		elseif level >= 30 then
			-- #b79d8c
			HCDeath.texture:SetVertexColor(183/255, 157/255, 140/255)
		elseif level >= 20 then
			-- #ad7a56
			HCDeath.texture:SetVertexColor(173/255, 122/255, 86/255)
		end
	end
end

function HCDeath:color(level)
	HCDeath:texColor(level)
	HCDeath.guild:SetTextColor(116/255, 113/255, 255/255) -- #7471FF
end

function HCDeath:sound(deathType, playerRace, playerLevel)
	if (deathType == "PVP" or deathType == "PVE") then
		if HCDeaths_Settings.deathsound then
			if HCDeaths_Settings.roar then
				local num = math.random(1, 2)
				if deathsound[playerRace] then PlaySoundFile(deathsound[playerRace][num])
                else PlaySoundFile("Sound/interface/RaidWarning.wav") end
			else
				PlaySoundFile("Sound/interface/RaidWarning.wav")
			end
		end
	else		
		if HCDeaths_Settings.levelsound then
			if deathType == "LVL" then
				if playerLevel == 60 then
					PlaySoundFile("Sound\\Doodad\\G_FireworkLauncher02Custom0.wav")
				end
			elseif deathType == "INFSTART" then
				PlaySoundFile("\\Sound\\Creature\\Razuvious\\RAZ_NAXX_AGGRO01.wav")				
			end

			local num = math.random(1, 4)
			if progress[playerRace] then PlaySoundFile(progress[playerRace][num])
            else PlaySound("LevelUp") end
		end		
	end
end

-- Values may be missing in legacy logs and incomplete /who responses.
function HCDeath:Value(value)
    if value == nil or value == "nil" or value == "" then return "Unknown" end
    return tostring(value)
end

function HCDeath:Icon(kind, value)
    if value and value ~= "Unknown" and value ~= "nil" and value ~= "" then
        return media .. kind .. "\\" .. value
    end
    return "Interface\\Icons\\INV_Misc_QuestionMark"
end

function HCDeath:Toast()
    if toastMove or HCDeathsToast:IsShown() then return end
    while table.getn(deaths) > 0 do
        local record = table.remove(deaths, 1)
        if HCDeaths_Settings.toast and (record.deathType ~= "LVL" or HCDeaths_Settings.progress) then
            local level = tonumber(record.playerLevel) or 0
            local class = RAID_CLASS_COLORS[string.upper(HCDeath:Value(record.playerClass))] or {r=.5,g=.5,b=.5}
            local hex = HCDeath:rgbToHex(class.r,class.g,class.b)
            HCDeath.class:SetTexture(HCDeath:Icon("Ring",record.playerClass))
            HCDeath.race:SetTexture(HCDeath:Icon("Ring",record.playerRace))
            HCDeath.level:SetText(HCDeath:Value(record.playerLevel))
            HCDeath.name:SetText("|cff"..hex..HCDeath:Value(record.playerName).."|r")
            if record.playerGuild == "" or record.playerGuild == "nil" then
                HCDeath.guild:SetText("")
            else HCDeath.guild:SetText("<"..HCDeath:Value(record.playerGuild)..">") end
            HCDeath.death:SetText("")
            HCDeath.lastwords:SetText("")
            if record.deathType == "LVL" then
                if level == 60 then HCDeath.location:SetText("Has transcended death and reached level 60!")
                else HCDeath.location:SetText("Has reached level "..HCDeath:Value(record.playerLevel).."!") end
            elseif record.deathType == "INFSTART" then
                HCDeath.location:SetText("Has begun the Inferno Challenge!")
            else
                HCDeath.location:SetText("Has died in "..HCDeath:DeathLocation(record))
                HCDeath.death:SetText("to "..HCDeath:Value(record.killerName).." level "..HCDeath:Value(record.killerLevel))
                if HCDeath:Value(record.lastWords) ~= "Unknown" then
                    HCDeath.lastwords:SetText('"'..record.lastWords..'"')
                end
            end
            HCDeath:sound(record.deathType,record.playerRace,level)
            HCDeath:color(level)
            activeToastRecord = record
            HCDeath:showToast()
            return
        end
    end
end

function HCDeath:tableLength()
	local count = 0
	for _ in pairs(HCDeaths) do
		count = count + 1
	end
	return count	
end

function HCDeath:rgbToHex(r, g, b)
    return string.format("%02X%02X%02X", math.floor(r * 255), math.floor(g * 255), math.floor(b * 255))
end

function HCDeath:isInstance(location)
	for _, loc in pairs(instances) do
		if loc == location then
			return true
		end
	end
  	return false
end

function HCDeath:locHex(location)
	if HCDeath:isInstance(location) then
		return "A330C9"
	end
	return HCDeath:rgbToHex(1, .5, 0)
end

function HCDeath:locTex(dtype, hctype, location)
	if dtype == "PVP" then
		return media.."Log\\PVP"
	elseif hctype == "INF" then
		return media.."Log\\INFERNO"
	else
		return media.."Log\\PVE"
	end
end

function HCDeath:GetWhoInfo(player)
    local numWhos = GetNumWhoResults()
	for i=1, numWhos do
        local name, guild, level, race, class, zone = GetWhoInfo(i)
		if (name == player) then
			if guild == "" then
				return "nil", level, race, class, zone
			else
				return guild, level, race, class, zone
			end
		end
	end
end

-- Death-message location is distinct from the broad /who zone.
function HCDeath:DeathLocation(record)
    if record and type(record.location) == "string" and record.location ~= "" then
        return record.location
    end
    return HCDeath:Value(record and record.zone)
end

-- Current Octo death notices put the victim's level before "has fallen".
-- Keep the legacy parser below for older notices without this format.
function HCDeath:ParseDeathMessage(message)
    if type(message) ~= "string" then return nil end
    local clean = string.gsub(message, "|c%x%x%x%x%x%x%x%x", "")
    clean = string.gsub(clean, "|r", "")
    clean = string.gsub(clean, "|H.-|h(.-)|h", "%1")
    clean = string.gsub(clean, "%.%s+May this sacrifice not be forgotten%.?%s*$", "")
    local _, _, name, level, body = string.find(clean,
        "Hardcore character ([^%s%(]+)%s*%(level%s+(%d+)%)%s+(.+)$")
    if not name then return nil end
    name = string.gsub(name, "^%[(.-)%]$", "%1")
    local _, _, killer, killerLevel, location = string.find(body,
        "^has fallen to (.-)%s+%(level%s+([^%)]+)%)%s+in%s+(.+)$")
    if killer then
        return {playerName=name, playerLevel=level, killerName=killer,
            killerLevel=killerLevel, killerClass="NPC", deathType="PVE", location=location}
    end
    local _, _, naturalLocation = string.find(body, "^died of natural causes%s+in%s+(.+)$")
    if naturalLocation then
        return {playerName=name, playerLevel=level, killerName="Natural Causes",
            killerClass="ENV", deathType="PVE", location=naturalLocation}
    end
    local _, _, playerKiller, pvpLocation = string.find(body,
        "^has fallen in PvP to ([^%s]+)%s+in%s+(.+)$")
    if playerKiller then
        return {playerName=name, playerLevel=level, killerName=playerKiller,
            deathType="PVP", location=pvpLocation}
    end
    return nil
end

-- Octo milestone notices include class and optionally a multi-word guild name.
function HCDeath:ParseLevelMessage(message)
    if type(message) ~= "string" then return nil end
    local clean = string.gsub(message, "|c%x%x%x%x%x%x%x%x", "")
    clean = string.gsub(clean, "|r", "")
    clean = string.gsub(clean, "|H.-|h(.-)|h", "%1")
    local _, _, class, name, guild, level = string.find(clean,
        "(%a+) ([^%s]+) of guild (.-) has reached level (%d+)")
    if not name then
        _, _, class, name, level = string.find(clean,
            "(%a+) ([^%s]+) has reached level (%d+)")
    end
    if name then
        local classes = {warrior="Warrior", paladin="Paladin", hunter="Hunter",
            rogue="Rogue", priest="Priest", shaman="Shaman", mage="Mage",
            warlock="Warlock", druid="Druid"}
        class = classes[string.lower(class)]
        local number = tonumber(level)
        if class and number and number >= 1 and number <= 60 then
            name = string.gsub(name, "^%[(.-)%]$", "%1")
            return {playerName=name, playerLevel=level, playerClass=class, playerGuild=guild}
        end
    end
    -- Legacy Turtle-style milestone and level-60 messages remain supported.
    _, _, name, level = string.find(clean, "([^%s]+) has reached level (%d+) in Hardcore mode")
    if name then return {playerName=name, playerLevel=level} end
    _, _, name = string.find(clean, "([^%s]+) has transcended death and reached level 60")
    if name then return {playerName=name, playerLevel="60"} end
    return nil
end

-- Persist immediately. /who only enriches these same records afterwards.
function HCDeath:ReceiveRecord(record)
    -- Octo supplies last words in a separate server notice after the death.
    record.lastWords = nil
    local fields = {"playerName","playerLevel","playerClass","playerRace","playerGuild",
        "killerName","killerLevel","killerClass","killerRace","killerGuild","zone","lastWords"}
    for _, key in ipairs(fields) do
        if record[key] == nil or record[key] == "nil" then record[key] = "Unknown" end
    end
    record.info = nil
    if record.deathType == "PVE" or record.deathType == "PVP" then
        if self.Sync then record=self.Sync:StoreLocal(record)
        else table.insert(HCDeaths,record) end
        if self.Retention then self.Retention:Enforce() end
        pendingLastWords[record.playerName] = record
        HCDeath:updateLog()
    end
    if HCDeaths_Settings.toast and (record.deathType ~= "LVL" or HCDeaths_Settings.progress) then
        table.insert(deaths,record)
    end
    table.insert(whoQueue,{record=record,name=record.playerName})
    if record.deathType == "PVP" and record.killerName ~= "Unknown" then
        table.insert(whoQueue,{record=record,name=record.killerName,killer=true})
    end
    HCDeaths_LastWords[record.playerName] = nil
    HCDeath:Toast()
    HCDeath:PumpWho()
end

-- Drop references held by pending display/lookup work after storage cleanup.
function HCDeath:OnPrunedRecords(removed)
    for name,r in pairs(pendingLastWords) do if removed[r] then pendingLastWords[name]=nil end end
    for i=table.getn(whoQueue),1,-1 do if removed[whoQueue[i].record] then table.remove(whoQueue,i) end end
    if currentWho and removed[currentWho.record] then currentWho=nil end
    for i=table.getn(deaths),1,-1 do if removed[deaths[i]] then table.remove(deaths,i) end end
    if activeToastRecord and removed[activeToastRecord] then HCDeath:hideToast() end
end

-- Match only deaths received in this session, never historical records on login.
function HCDeath:RefreshToastLastWords(record)
    if activeToastRecord==record and HCDeath:Value(record.lastWords)~="Unknown" then
        HCDeath.lastwords:SetText('"'..record.lastWords..'"')
    end
end

function HCDeath:ReceiveLastWords(message)
    local clean = HCDeath:extractLinks(message)
    clean = string.gsub(clean, "|c%x%x%x%x%x%x%x%x", "")
    clean = string.gsub(clean, "|r", "")
    local _, _, name, words = string.find(clean, "^%s*(%S+)'s last words:%s*\"(.*)\"%s*$")
    if not name then return false end
    name = string.gsub(name, "^%[(.-)%]$", "%1")
    local record = pendingLastWords[name]
    if record then
        record.lastWords = words
        if self.Sync then self.Sync:Remember(record) end
        pendingLastWords[name] = nil
        if activeToastRecord == record then
            HCDeath.lastwords:SetText('"'..words..'"')
        end
        HCDeath:updateLog()
    end
    return true
end

function HCDeath:PumpWho()
    local now = GetTime()
    if currentWho and now >= currentWho.deadline then currentWho = nil end
    if not currentWho and table.getn(whoQueue) == 0 then queryTimer:Hide();return end
    queryTimer:Show()
    if currentWho or now < nextWhoAt then return end
    local task = table.remove(whoQueue,1)
    if not task or task.name == "Unknown" or not SendWho then return end
    currentWho = task
    task.deadline = now + WHO_TIMEOUT
    nextWhoAt = now + WHO_INTERVAL
    local ok = pcall(SendWho,"n-"..task.name)
    if not ok then currentWho = nil end
end

function HCDeath:QueryPlayer()
    if not currentWho then return end
    local guild, level, race, class, zone = HCDeath:GetWhoInfo(currentWho.name)
    if not class and not race and not zone and not level then return end
    local r = currentWho.record
    local prefix = currentWho.killer and "killer" or "player"
    if guild ~= nil then r[prefix.."Guild"] = guild == "nil" and "" or guild end
    if race and race ~= "" then r[prefix.."Race"] = race end
    if class and class ~= "" then r[prefix.."Class"] = class end
    if HCDeath:Value(r[prefix.."Level"]) == "Unknown" and level then r[prefix.."Level"] = level end
    if not currentWho.killer and zone and zone ~= "" then r.zone = zone end
    currentWho = nil
    if self.Sync then self.Sync:Remember(r) end
    HCDeath:updateLog()
    HCDeath:PumpWho()
end

function HCDeath:SendWho()
    HCDeath:PumpWho()
end

-- ChatFrame_OnEvent can be invoked once for each chat window for one notice.
function HCDeath:IsDuplicateNotice(message)
    local now = GetTime()
    if self.lastNotice == message and now - (self.lastNoticeTime or 0) < 1 then return true end
    self.lastNotice = message;self.lastNoticeTime = now
    return false
end

function HCDeath:systemMessage(message)
	if HCDeaths_Settings.message then
		local info = ChatTypeInfo["SYSTEM"]
		DEFAULT_CHAT_FRAME:AddMessage(message, info.r, info.g, info.b, info.id)
	end
end

function HCDeath:extractLinks(str)
	local start = 1
    local result = ""
    while true do
        local s, e, link = string.find(str, "|c.-|H.-|h%[(.-)%]|h|r", start)
        if not s then break end
        result = result .. string.sub(str, start, s - 1) .. "[" .. link .. "]"
        start = e + 1
    end
    result = result .. string.sub(str, start)
    return result
end

local testmsg
function HCDeath:test(dtype, player, plevel, killer)	
	if dtype == "pve" then
		testmsg = "A tragedy has occurred. Hardcore character "..player.." died of natural causes at level "..plevel..". May this sacrifice not be forgotten."
	elseif dtype == "pvp" then
		testmsg = "A tragedy has occurred. Hardcore character "..player.." has fallen in PvP to "..killer.." at level "..plevel.."."
	end
	SendChatMessage(".server info")
end

local HookChatFrame_OnEvent = ChatFrame_OnEvent
function ChatFrame_OnEvent(event)
    -- A separate frame receives protocol events exactly once. Hide channel traffic
    -- in every normal chat window, including join/leave notices.
    if HCDeath.Sync and string.find(event,"^CHAT_MSG_CHANNEL")
        and HCDeath.Sync:IsChannel(arg9,arg8,arg4) then return end
	if (event == "CHAT_MSG_SYSTEM") then
		if testmsg then
			arg1 = testmsg
			testmsg = nil
		end

		-- Examples of Turtle WoW HC progress messages:
		-- "PLAYERNAME has reached level 20/30/40/50 in Hardcore mode! Their ascendance towards immortality continues, however, so do the dangers they will face.
		-- "PLAYERNAME has transcended death and reached level 60 on Hardcore mode without dying once! PLAYERNAME shall henceforth be known as the Immortal!"

		-- Examples of Turtle WoW Inferno messages:
		-- Started = "PLAYERNAME has laughed in the face of death in the Hardcore challenge. PLAYERNAME has begun the Inferno Challenge!"
		-- PVE (*does not show PLAYERNAME*) = "A tragedy has occurred. Inferno character has fallen to MOBNAME1 MOBNAME2 (level KILLERLEVEL) at level PLAYERLEVEL..."
		-- NAT = ??
		-- PVP = ??

		-- Examples of Turtle WoW Hardcore messages:
		-- PVE = "A tragedy has occurred. Hardcore character PLAYERNAME has fallen to MOBNAME1 MOBNAME2 (level KILLERLEVEL) at level PLAYERLEVEL..."
		-- NAT = "A tragedy has occurred. Hardcore character PLAYERNAME died of natural causes at level PLAYERLEVEL..."
		-- PvP = "A tragedy has occurred. Hardcore character PLAYERNAME has fallen in PvP to KILLERNAME at level PLAYERLEVEL..."

		-- Example of /who result messages:
		-- [PLAYERNAME]: Level PLAYERLEVEL PLAYERRACE PLAYERCLASS <PLAYERGUILD> - AREA
		-- 1 player Total

        if HCDeath:ReceiveLastWords(arg1) then
            HookChatFrame_OnEvent(event)
            return
        end
        local parsedLevel = HCDeath:ParseLevelMessage(arg1)
		local parsedDeath = HCDeath:ParseDeathMessage(arg1)
        local _, _, hcdeath = string.find(arg1,"A tragedy has occur+ed%. Hardcore character (%a+)")
        if parsedDeath then hcdeath = parsedDeath.playerName end
		local _, _, infstart = string.find(arg1,"(%a+) has begun the Inferno Challenge")
		-- local _, _, infdeath = string.find(arg1,"A tragedy has occurred. Inferno character (%a+)")
        if parsedLevel or hcdeath or infstart then
            if HCDeath:IsDuplicateNotice(arg1) then return end
        end

		if parsedLevel then
			HCDeath:systemMessage(arg1)
			
            local playerName = parsedLevel.playerName
            local playerLevel = parsedLevel.playerLevel

			HCDeath:ReceiveRecord({
				sdate = date("!%Y/%m/%d"),
				stime = date("!%H:%M:%S"),
				deathType = "LVL",
				hcType = "HC",
				zone = nil,
				playerName = playerName,
				playerLevel = playerLevel,
				playerClass = parsedLevel.playerClass,
				playerRace = nil,
				playerGuild = parsedLevel.playerGuild,
				info = nil
			})

			HCDeath:SendWho()
			return
		elseif infstart then
			HCDeath:systemMessage(arg1)
			
			local _, _, playerName = string.find(arg1,"(%a+) has")

			HCDeath:ReceiveRecord({
				sdate = date("!%Y/%m/%d"),
				stime = date("!%H:%M:%S"),
				deathType = "INFSTART",
				hcType = "INF",
				zone = nil,
				playerName = playerName,
				playerLevel = nil,
				playerClass = nil,
				playerRace = nil,
				playerGuild = nil,
				info = nil
			})

			HCDeath:SendWho()
			return
		elseif hcdeath then --or infdeath then
			HCDeath:systemMessage(arg1)

			local hcType = "HC"
			-- local hcType 
			-- if hcdeath then
			-- 	hcType = "HC"
			-- elseif infdeath then
			-- 	hcType = "INF"
			-- end			

			local pvp, natural, playerLevel, deathType, killerName, killerLevel, killerClass
			_, _, pvp = string.find(arg1,"(PvP)")
			_, _, natural = string.find(arg1,"(natural causes)")
			_, _, playerLevel = string.find(arg1,"at level (%d+)")

			if pvp then 
				deathType = "PVP"
				_, _, killerName = string.find(arg1,"to%s+(%a+)")
			else
				deathType = "PVE"
				if natural then
					killerName = "Natural Causes"
					killerClass = "ENV"
				else
					_, _, killerName = string.find(arg1,"to%s+(.-)%s*%(")
					_, _, killerLevel = string.find(arg1,"%(level%s*(.-)%).-at")
					killerClass = "NPC"
				end
			end

            local deathLocation
            if parsedDeath then
                playerLevel = parsedDeath.playerLevel
                deathType = parsedDeath.deathType
                killerName, killerLevel, killerClass = parsedDeath.killerName, parsedDeath.killerLevel, parsedDeath.killerClass
                deathLocation = parsedDeath.location
            else
                -- Legacy notices may also append a location after "at level N".
                local _, _, place = string.find(arg1,
                    "at level %d+ in (.-)%.%s+May this sacrifice not be forgotten")
                deathLocation = place
            end

			HCDeath:ReceiveRecord({
				sdate = date("!%Y/%m/%d"),
				stime = date("!%H:%M:%S"),
				deathType = deathType,
				hcType = hcType,
				zone = nil,
                location = deathLocation,
				playerName = hcdeath,
				playerLevel = playerLevel,
				playerClass = nil,
				playerRace = nil,
				playerGuild = nil,
				killerName = killerName,
				killerLevel = killerLevel,
				killerClass = killerClass,
				killerRace = nil,
				killerGuild = nil,
				lastWords = nil,
				info = nil
			})

			HCDeath:SendWho()
			return
		end
		
        if currentWho then HCDeath:QueryPlayer() end

	end

	HookChatFrame_OnEvent(event)
end

function HCDeath:reset()
	HCDeaths_Settings.message = true
	HCDeaths_Settings.log = false
	HCDeaths_Settings.toast = true
	HCDeaths_Settings.color = false
	HCDeaths_Settings.deathsound = true
	HCDeaths_Settings.levelsound = true
	HCDeaths_Settings.roar = false
	HCDeaths_Settings.toastscale = 1
	HCDeaths_Settings.logscale = 1
	HCDeaths_Settings.toasttime = 10
	HCDeaths_Settings.progress = true
    HCDeaths_Settings.sync = true
    HCDeaths_Settings.maxrecords = 0
    HCDeaths_Settings.minimapAngle = 220
    HCDeathsLog.page = 1
    if HCDeath.PositionMinimap then HCDeath:PositionMinimap() end

	HCDeath:ToastScale()
	HCDeathsToast:SetUserPlaced(false)
	HCDeathsToast:position()

	HCDeath:ToggleLog()
	HCDeathsLog:SetUserPlaced(false)
	HCDeathsLog:position()
end

function HCDeath:print(message)
	DEFAULT_CHAT_FRAME:AddMessage("HCDeaths: "..message, 1, .5, 0)
end

local function HCDeaths_commands(msg, editbox, silent)
    local function feedback(message)
        if not silent then HCDeath:print(message) end
    end
    msg = string.lower((string.gsub(msg or "", "^%s*(.-)%s*$", "%1")))
    if msg == "" or msg == "gui" or msg == "config" then
        if HCDeath.ToggleGUI then HCDeath:ToggleGUI() end
        return
    end
    if msg=="sync status" or msg=="sync check" then
        if HCDeath.Sync then HCDeath.Sync:Report(msg=="sync check")
        else HCDeath:print("Sync module not loaded. Install the full HCDeaths folder, then /reload.") end
        return
    end
    if msg=="grave status" or msg=="grave check" then
        if HCDeath.Graves then HCDeath.Graves:Report(msg=="grave check")
        else HCDeath:print("Grave module not loaded. Install HCDeathsGraves.lua with the full addon folder, then /reload.") end
        return
    end
    if HCDeath.Retention and HCDeath.Retention:Command(msg,silent) then
        if HCDeath.RefreshGUI then HCDeath:RefreshGUI() end
        return
    end
    local toggles = {message=true, log=true, toast=true, progress=true, color=true,
        deathsound=true, levelsound=true, roar=true, sync=true}
    if toggles[msg] then
        HCDeaths_Settings[msg] = not HCDeaths_Settings[msg]
        feedback(msg .. " is " .. (HCDeaths_Settings[msg] and "on" or "off"))
        if msg == "log" then HCDeath:ToggleLog() end
    elseif msg == "move" then
        if toastMove then
            toastMove = nil
            HCDeath:hideToast()
        else
            toastMove = true
            HCDeath:toastMove()
        end
    elseif msg == "reset" then
        HCDeath:reset()
        feedback("settings reset (saved deaths retained)")
    else
        local _, _, area, option, value = string.find(msg, "^(%a+)%s+(%a+)%s+(%S+)$")
        local num = tonumber(value)
        if (area == "toast" and (option == "scale" or option == "time"))
            or (area == "log" and option == "scale") then
            if not num or num-num ~= 0 or num <= 0
                or (option == "scale" and (num < 0.25 or num > 3))
                or (option == "time" and num > 300) then
                feedback("Use scale 0.25-3 or toast time greater than 0 and at most 300 seconds.")
            else
                HCDeaths_Settings[area .. option] = num
                if option == "scale" then
                    if area == "toast" then HCDeath:ToastScale() else HCDeath:LogScale() end
                end
                feedback(area .. " " .. option .. " set to " .. num)
            end
        else
            feedback("/hcd - settings GUI; /hcd help - commands")
            feedback("/hcd message | move | log | toast | progress | color | deathsound | levelsound | roar | sync | reset")
            feedback("/hcd log scale number | toast scale number | toast time seconds")
            feedback("/hcd log max number (0 = unlimited) | prune level number | prune days number | prune keep number")
            feedback("/hcd grave check | grave status - grave recording diagnostics")
            feedback("/hcd sync check | sync status - synchronization diagnostics")
        end
    end
    if HCDeath.RefreshGUI then HCDeath:RefreshGUI() end
end

function HCDeath:RunCommand(command, silent)
    HCDeaths_commands(command, nil, silent)
end

-- Existing records store UTC receipt date/time, not the victim's local time.
function HCDeath:LogTimestamp(record)
    local day = record and record.sdate
    local clock = record and record.stime
    if type(day) ~= "string" or day == "" or day == "nil" then day = "----/--/--" end
    if type(clock) ~= "string" or clock == "" or clock == "nil" then clock = "--:--:--" end
    return day .. " " .. clock
end

-- Bounded UI row pool; all saved death records remain accessible by page.
do
    local log = CreateFrame("Frame", "HCDeathsLog", UIParent)
    log:Hide()
    log:SetWidth(590); log:SetHeight(490)
    log:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", tile=true, tileSize=16,
        edgeSize=16, insets={left=4,right=4,top=4,bottom=4}})
    log:SetBackdropColor(0.04,0.04,0.04,0.95)
    log:SetMovable(true); log:SetClampedToScreen(true); log:EnableMouse(true)
    log:RegisterForDrag("LeftButton"); log:SetUserPlaced(true)
    function log:position()
        self:ClearAllPoints(); self:SetPoint("CENTER", UIParent, "CENTER", -220, 0)
    end
    log:position()
    log:SetScript("OnDragStart", function() this:StartMoving() end)
    log:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
    log.page=1; log.pageSize=20; log.rows={}
    log.title=log:CreateFontString(nil,"OVERLAY","GameFontNormalLarge")
    log.title:SetPoint("TOP",log,"TOP",0,-14);log.title:SetText("Hardcore Deaths (UTC)")
    local close=CreateFrame("Button",nil,log,"UIPanelCloseButton")
    close:SetPoint("TOPRIGHT",log,"TOPRIGHT",0,0)
    close:SetScript("OnClick",function()
        HCDeaths_Settings.log=false;HCDeath:ToggleLog()
        if HCDeath.RefreshGUI then HCDeath:RefreshGUI() end
    end)
    log.pageLabel=log:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    log.pageLabel:SetPoint("BOTTOM",log,"BOTTOM",0,22)
    log.empty=log:CreateFontString(nil,"OVERLAY","GameFontHighlight")
    log.empty:SetPoint("CENTER",log,"CENTER",0,0);log.empty:SetText("No recorded deaths")
    local function pageButton(text,x,step)
        local button=CreateFrame("Button",nil,log,"UIPanelButtonTemplate")
        button:SetWidth(75);button:SetHeight(24);button:SetText(text)
        button:SetPoint("BOTTOMLEFT",log,"BOTTOMLEFT",x,12)
        button:SetScript("OnClick",function() HCDeath:ChangeLogPage(step) end)
        return button
    end
    log.previous=pageButton("< Newer",12,-1)
    log.next=pageButton("Older >",503,1)
    log:EnableMouseWheel(true)
    log:SetScript("OnMouseWheel",function()
        if arg1>0 then HCDeath:ChangeLogPage(-1) elseif arg1<0 then HCDeath:ChangeLogPage(1) end
    end)
    for i=1,log.pageSize do
        local row=CreateFrame("Button",nil,log)
        row:SetWidth(564);row:SetHeight(20)
        row:SetPoint("TOPLEFT",log,"TOPLEFT",12,-44-(i-1)*20)
        row:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background"})
        row:SetBackdropColor(1,1,1,math.mod(i,2)==0 and 0.05 or 0.12)
        row.kind=row:CreateTexture(nil,"ARTWORK");row.kind:SetWidth(16);row.kind:SetHeight(16)
        row.kind:SetPoint("LEFT",row,"LEFT",2,0)
        row.text=row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
        row.text:SetPoint("LEFT",row,"LEFT",184,0);row.text:SetWidth(330);row.text:SetHeight(18);row.text:SetJustifyH("LEFT")
        row.timestamp=row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
        row.timestamp:SetPoint("LEFT",row,"LEFT",24,0)
        row.timestamp:SetWidth(154);row.timestamp:SetHeight(18)
        row.timestamp:SetJustifyH("LEFT");row.timestamp:SetTextColor(0.7,0.7,0.7)
        row.race=row:CreateTexture(nil,"ARTWORK");row.race:SetWidth(16);row.race:SetHeight(16)
        row.race:SetPoint("RIGHT",row,"RIGHT",-22,0)
        row.class=row:CreateTexture(nil,"ARTWORK");row.class:SetWidth(16);row.class:SetHeight(16)
        row.class:SetPoint("RIGHT",row,"RIGHT",-2,0)
        row:SetScript("OnLeave",function() GameTooltip:Hide() end)
        			row:SetScript("OnEnter", function()
            local r=this.record
            if not r then return end
            GameTooltip:SetOwner(this,"ANCHOR_RIGHT");GameTooltip:ClearLines()
            GameTooltip:AddLine(r.deathType == "PVP" and "PvP Death" or "PvE Death",1,0.5,0)
            GameTooltip:AddLine(HCDeath:Value(r.playerName).." - Level "..HCDeath:Value(r.playerLevel),1,1,1)
            GameTooltip:AddLine("Class: "..HCDeath:Value(r.playerClass).." / Race: "..HCDeath:Value(r.playerRace),1,1,1)
            GameTooltip:AddLine("Guild: "..(r.playerGuild == "" and "None" or HCDeath:Value(r.playerGuild)),1,1,1)
            GameTooltip:AddLine("Location: "..HCDeath:DeathLocation(r),1,1,1)
            GameTooltip:AddLine("Zone (/who): "..HCDeath:Value(r.zone),0.7,0.7,0.7)
            GameTooltip:AddLine("Killer: "..HCDeath:Value(r.killerName).." - Level "..HCDeath:Value(r.killerLevel),1,1,1)
            if r.deathType == "PVP" then
                GameTooltip:AddLine("Killer class: "..HCDeath:Value(r.killerClass).." / Race: "..HCDeath:Value(r.killerRace),1,1,1)
            end
            GameTooltip:AddLine("Last words: "..HCDeath:Value(r.lastWords),0.7,0.7,0.7,true)
            if r.shared then
                GameTooltip:AddLine("Source: shared by "..HCDeath:Value(r.sourcePlayer),0.7,0.7,0.7)
            else GameTooltip:AddLine("Source: directly received",0.7,0.7,0.7) end
            if r.sharedDetails then
                GameTooltip:AddLine("Details supplemented by "..HCDeath:Value(r.detailsSource),0.7,0.7,0.7)
            end
            if r.gravePositionKind=="observer" then
                GameTooltip:AddLine("Grave visit: "..HCDeath:Value(r.graveZone).." / "..HCDeath:Value(r.graveSubzone),0.6,0.9,1)
                local x,y=tonumber(r.graveX),tonumber(r.graveY)
                if x and y then GameTooltip:AddLine(string.format("Observer map position: %.2f, %.2f",x*100,y*100),0.6,0.9,1)
                else
                    local a,b,c=tonumber(r.graveWorld1),tonumber(r.graveWorld2),tonumber(r.graveWorld3)
                    if a and b and c then
                        GameTooltip:AddLine(string.format("Observer raw UnitPosition: %.2f, %.2f, %.2f",a,b,c),0.6,0.9,1,true)
                        GameTooltip:AddLine("Zone map coordinates unavailable; raw position was saved.",0.7,0.7,0.7,true)
                    end
                end
                GameTooltip:AddLine("Observed by "..HCDeath:Value(r.graveObserver).." at "..HCDeath:Value(r.graveObservedAt).." UTC",0.7,0.7,0.7,true)
                GameTooltip:AddLine("Player position when inspecting the grave; approximate death location.",0.7,0.7,0.7,true)
            end
            GameTooltip:AddLine("Recorded (UTC): "..HCDeath:LogTimestamp(r),0.7,0.7,0.7)
            GameTooltip:Show()
        end)
        log.rows[i]=row;row:Hide()
    end
end

function HCDeath:ChangeLogPage(step)
    HCDeathsLog.page=HCDeathsLog.page+step
    HCDeath:updateLog()
end

function HCDeath:ToggleLog()
    if HCDeaths_Settings.log then
        HCDeath:LogScale();HCDeathsLog:Show();HCDeath:updateLog()
    else HCDeathsLog:Hide() end
end

function HCDeath:updateLog()
    if not HCDeathsLog:IsShown() then return end
    local log=HCDeathsLog
    -- The original saved table also contains non-death records on some versions.
    local entries={}
    for i=table.getn(HCDeaths),1,-1 do
        local record=HCDeaths[i]
        if record and (record.deathType=="PVE" or record.deathType=="PVP") then
            table.insert(entries,record)
        end
    end
    if HCDeath.Sync then
        local order={}
        for i,r in ipairs(entries) do order[r]=i end
        table.sort(entries,function(a,b)
            local x,y=HCDeath.Sync:Stamp(a),HCDeath.Sync:Stamp(b)
            if x and y and x~=y then return x>y end
            if x and not y then return true end
            if y and not x then return false end
            return order[a]<order[b]
        end)
    end
    local count=table.getn(entries)
    local pages=math.max(1,math.ceil(count/log.pageSize))
    log.page=math.max(1,math.min(log.page,pages))
    log.pageLabel:SetText("Page "..log.page.." / "..pages.."  ("..count.." deaths)")
    if count==0 then log.empty:Show() else log.empty:Hide() end
    if log.page>1 then log.previous:Enable() else log.previous:Disable() end
    if log.page<pages then log.next:Enable() else log.next:Disable() end
    GameTooltip:Hide()
    for i=1,log.pageSize do
        local row=log.rows[i]
        local record=entries[(log.page-1)*log.pageSize+i]
        row.record=record
        if record then
            local c=RAID_CLASS_COLORS[string.upper(HCDeath:Value(record.playerClass))] or {r=.5,g=.5,b=.5}
            row.timestamp:SetText(HCDeath:LogTimestamp(record))
            row.text:SetText(HCDeath:Value(record.playerLevel).."  |cff"..HCDeath:rgbToHex(c.r,c.g,c.b)
                ..HCDeath:Value(record.playerName).."|r  "..HCDeath:DeathLocation(record))
            row.kind:SetTexture(HCDeath:locTex(record.deathType,record.hcType,HCDeath:DeathLocation(record)))
            row.race:SetTexture(HCDeath:Icon("Log",record.playerRace))
            row.class:SetTexture(HCDeath:Icon("Log",record.playerClass))
            row:Show()
        else row:Hide() end
    end
end

function HCDeath:ToastScale()
	HCDeathsToast:SetScale(HCDeaths_Settings.toastscale)
end

function HCDeath:LogScale()
	HCDeathsLog:SetScale(HCDeaths_Settings.logscale)
end

HCDeath:RegisterEvent("PLAYER_ENTERING_WORLD")
HCDeath:RegisterEvent("WHO_LIST_UPDATE")
HCDeath:SetScript("OnEvent", function()
    if event == "WHO_LIST_UPDATE" then HCDeath:QueryPlayer();return end
	if not this.loaded then
		this.loaded = true
		SLASH_HCDEATHS1 = "/hcdeaths"
		SLASH_HCDEATHS2 = "/hcd"
		SlashCmdList["HCDEATHS"] = HCDeaths_commands
        HCDeaths_Settings = HCDeaths_Settings or {}
        HCDeaths_Settings.minlevel = nil
        local defaults = {message=true, log=false, toast=true, color=false, deathsound=true,
            levelsound=true, roar=false, toastscale=1, logscale=1, toasttime=10, progress=true, sync=true, maxrecords=0}
        for key, value in pairs(defaults) do
            if HCDeaths_Settings[key] == nil then HCDeaths_Settings[key] = value end
        end
        if not HCDeaths_Settings.pagedLogVersion then
            HCDeaths_Settings.log = false
            HCDeaths_Settings.pagedLogVersion = 1
        end
        HCDeaths = HCDeaths or {}
        HCDeaths_LastWords = HCDeaths_LastWords or {}
        if HCDeath.Retention then HCDeath.Retention:Initialize() end
        if HCDeath.InitializeGUI then HCDeath:InitializeGUI() end
		HCDeath:Check_pfUI()
		HCDeath:ToastScale()
		HCDeath:ToggleLog()			
		HCDeath:print("HCDeaths Loaded! /hcdeaths or /hcd")
	end
end)

function HCDeath:toastMove()
	HCDeath.level:SetText("60")
	HCDeath.name:SetText("Toast")
	HCDeath.guild:SetText("<HCDeaths>")
	HCDeath.location:SetText("Has died in Blackrock Mountains")
	HCDeath.death:SetText("to Torta level 60")
	HCDeath.lastwords:SetText('"'.."I like turtles!"..'"')
	-- HCDeath.quote:SetText("May this sacrifice not be forgotten!")
	
	HCDeath:color(60)
	HCDeath.texture:SetVertexColor(.75,.75,.75)	
	HCDeath.class:SetTexture(media.."Ring\\".."Warrior")
	HCDeath.race:SetTexture(media.."Ring\\".."Human")
	HCDeath:classSize()
	HCDeath:raceSize()
	HCDeathsToast:Show()
end

