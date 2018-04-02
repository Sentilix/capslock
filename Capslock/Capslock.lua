--[[
Author:			Mimma
Create Date:	2018-02-04

The latest version of Capslock can always be found at:
https://armory.digam.dk/capslock

The source code can be found at Github:
https://github.com/Sentilix/capslock

Please see the ReadMe.txt for addon details.
]]


-- Channel settings:
local PARTY_CHANNEL					= "PARTY"
local RAID_CHANNEL					= "RAID"
local YELL_CHANNEL					= "YELL"
local SAY_CHANNEL					= "SAY"
local WARN_CHANNEL					= "RAID_WARNING"
local GUILD_CHANNEL					= "GUILD"
local CHAT_END						= "|r"
local COLOUR_CHAT   				= "|c804060F0"
local COLOUR_INTRO  				= "|c8080A0F8"
local CAPSLOCK_NAME					= "Capslock"
local CAPSLOCK_PREFIX				= "Capslockv1"
local CTRA_PREFIX					= "CTRA"

local CAPSLOCK_CURRENT_VERSION		= 0
local CAPSLOCK_UPDATE_MESSAGE_SHOWN = false



--[[
	Echo a message for the local user only.
]]
local function echo(msg)
	if not msg then
		msg = ""
	end
	DEFAULT_CHAT_FRAME:AddMessage(COLOUR_CHAT .. msg .. CHAT_END)
end

--[[
	Echo in raid chat (if in raid) or party chat (if not)
]]
local function partyEcho(msg)
	if CAPSLOCK_IsInRaid() then
		SendChatMessage(msg, RAID_CHANNEL)
	elseif CAPSLOCK_IsInParty() then
		SendChatMessage(msg, PARTY_CHANNEL)
	end
end

--[[
	Echo a message for the local user only, including CAPSLOCK "logo"
]]
function CAPSLOCK_Echo(msg)
	echo("<"..COLOUR_INTRO.."CAPSLOCK"..COLOUR_CHAT.."> "..msg);
end



--  *******************************************************
--
--	Slash commands
--
--  *******************************************************

--[[
	Main entry for CAPSLOCK.
	This will send the request to one of the sub slash commands.
	Syntax: /capslock [option, defaulting to "summon"]
	Added in: 0.0.1
]]
SLASH_CAPSLOCK_CAPSLOCK1 = "/capslock"
SLASH_CAPSLOCK_CAPSLOCK2 = "/caps"
SlashCmdList["CAPSLOCK_CAPSLOCK"] = function(msg)
	local _, _, option = string.find(msg, "(%S*)")

	if not option or option == "" then
		option = "SUMMON"
	end
	option = string.upper(option);
		
	if (option == "SUM" or option == "SUMMON") then
		SlashCmdList["CAPSLOCK_SUMMON"]();
	elseif (option == "CFG" or option == "CONFIG") then
		SlashCmdList["CAPSLOCK_CONFIG"]();
	elseif option == "DISABLE" then
		SlashCmdList["CAPSLOCK_DISABLE"]();
	elseif option == "ENABLE" then
		SlashCmdList["CAPSLOCK_ENABLE"]();
	elseif option == "HELP" then
		SlashCmdList["CAPSLOCK_HELP"]();
	elseif option == "VERSION" then
		SlashCmdList["CAPSLOCK_VERSION"]();
	else
		CAPSLOCK_Echo(string.format("Unknown command: %s", option));
	end
end



--[[
	Summon highest priority target.
	Syntax: /capslocksummon
	Alternatives: /capslock sum, /capslock summon, /summon
	Added in: 0.0.1
]]
SLASH_CAPSLOCK_SUMMON1 = "/capslocksummon"
SLASH_CAPSLOCK_SUMMON2 = "/capslocksum"
SLASH_CAPSLOCK_SUMMON3 = "/summon"
SlashCmdList["CAPSLOCK_SUMMON"] = function(msg)
	CAPSLOCK_Echo("*** Not implemented: CAPSLOCK_SUMMON");
end


--[[
	Request client version information
	Syntax: /capslockversion
	Alternative: /capslock version
	Added in: 0.0.1
]]
SLASH_CAPSLOCK_VERSION1 = "/capslockversion"
SlashCmdList["CAPSLOCK_VERSION"] = function(msg)
	if CAPSLOCK_IsInRaid() or CAPSLOCK_IsInParty() then
		CAPSLOCK_SendAddonMessage("TX_VERSION##");
	else
		CAPSLOCK_Echo(string.format("%s is using CAPSLOCK version %s", UnitName("player"), GetAddOnMetadata("Capslock", "Version")));
	end
end

--[[
	Show configuration options
	Syntax: /capslockconfig
	Alternative: /capslock config
	Added in: 0.0.1
]]
SLASH_CAPSLOCK_CONFIG1 = "/capslockconfig"
SLASH_CAPSLOCK_CONFIG2 = "/capslockcfg"
SlashCmdList["CAPSLOCK_CONFIG"] = function(msg)
	CAPSLOCK_Echo("*** Not implemented: CAPSLOCK_CONFIG");		
end

--[[
	Disable CAPSLOCK' messages
	Syntax: /capslock disable
	Added in: 0.0.1
]]
SLASH_CAPSLOCK_DISABLE1 = "/capslockdisable"
SlashCmdList["CAPSLOCK_DISABLE"] = function(msg)
	CAPSLOCK_Echo("*** Not implemented: CAPSLOCK_DISABLE");		
end

--[[
	Enable CAPSLOCK' messages
	Syntax: /capslock enable
	Added in: 0.0.1
]]
SLASH_CAPSLOCK_ENABLE1 = "/capslockenable"
SlashCmdList["CAPSLOCK_ENABLE"] = function(msg)
	CAPSLOCK_Echo("*** Not implemented: CAPSLOCK_ENABLE");		
end

--[[
	Show HELP options
	Syntax: /capslockhelp
	Alternative: /capslock help
	Added in: 0.0.1
]]
SLASH_CAPSLOCK_HELP1 = "/capslockhelp"
SlashCmdList["CAPSLOCK_HELP"] = function(msg)
	CAPSLOCK_Echo(string.format("CAPSLOCK version %s - by Mimma @ vanillagaming.org", GetAddOnMetadata("Capslock", "Version")));
	CAPSLOCK_Echo("Syntax:");
	CAPSLOCK_Echo("    /capslock [option]");
	CAPSLOCK_Echo("Where options can be:");
	CAPSLOCK_Echo("    Summon       (default) Summon next target.");
	CAPSLOCK_Echo("    Config       Open the configuration dialogue,");
	CAPSLOCK_Echo("    Disable      Disable CAPSLOCK summon messages.");
	CAPSLOCK_Echo("    Enable       Enable CAPSLOCK summon messages again.");
	CAPSLOCK_Echo("    Help         This help.");
	CAPSLOCK_Echo("    Version      Request version info from all clients.");
end



--  *******************************************************
--
--	Titan Panel integration
--
--  *******************************************************
function CAPSLOCK_TitanPanelButton_OnLoad()
    this.registry = {
        id = CAPSLOCK_NAME,
        menuText = CAPSLOCK_NAME,
        buttonTextFunction = nil,
        tooltipTitle = CAPSLOCK_NAME .. " Options",
        tooltipTextFunction = "CAPSLOCK_TitanPanelButton_GetTooltipText",
        frequency = 0,
	    icon = "Interface\\Icons\\Spell_Shadow_Twilight"
    };
end

function CAPSLOCK_TitanPanelButton_GetTooltipText()
    return "Click to toggle configuration panel";
end



--  *******************************************************
--
--	Configuration functions
--
--  *******************************************************
function CAPSLOCK_ToggleConfigurationDialogue()
	CAPSLOCK_Echo("TODO: Implement configuration dialogue");
end;




--  *******************************************************
--
--	Helper functions
--
--  *******************************************************
function CAPSLOCK_IsInParty()
	if not CAPSLOCK_IsInRaid() then
		return ( GetNumPartyMembers() > 0 );
	end
	return false
end


function CAPSLOCK_IsInRaid()
	return ( GetNumRaidMembers() > 0 );
end




--  *******************************************************
--
--	Internal Communication Functions
--
--  *******************************************************

function CAPSLOCK_SendAddonMessage(message)
	local channel = nil
	
	if CAPSLOCK_IsInRaid() then
		channel = "RAID";
	elseif CAPSLOCK_IsInParty() then
		channel = "PARTY";
	else
		return;
	end

	SendAddonMessage(CAPSLOCK_PREFIX, message, channel);
end


function CAPSLOCK_OnChatMsgAddon(event, prefix, msg, channel, sender)
	if prefix == CAPSLOCK_PREFIX then
		CAPSLOCK_HandleCapslockMessage(msg, sender);	
	end
--	if prefix == CTRA_PREFIX then
--		CAPSLOCK_HandleCTRAMessage(msg, sender);
--	end
end


--[[
	Respond to a TX_VERSION command.
	Input:
		msg is the raw message
		sender is the name of the message sender.
	We should whisper this guy back with our current version number.
	We therefore generate a response back (RX) in raid with the syntax:
	Capslock:<sender (which is actually the receiver!)>:<version number>
]]
local function HandleTXVersion(message, sender)
	local response = GetAddOnMetadata("Capslock", "Version")	
	CAPSLOCK_SendAddonMessage("RX_VERSION#"..response.."#"..sender)
end

--[[
	A version response (RX) was received. The version information is displayed locally.
]]
local function HandleRXVersion(message, sender)
	CAPSLOCK_Echo(string.format("%s is using CAPSLOCK version %s", sender, message))
end

local function HandleTXVerCheck(message, sender)
--	echo(string.format("HandleTXVerCheck: msg=%s, sender=%s", message, sender));
	CAPSLOCK_CheckIsNewVersion(message);
end


function CAPSLOCK_HandleCapslockMessage(msg, sender)
--	echo(sender.." --> "..msg);
	local _, _, cmd, message, recipient = string.find(msg, "([^#]*)#([^#]*)#([^#]*)");	
	
	--	Ignore message if it is not for me. 
	--	Receipient can be blank, which means it is for everyone.
	if not (recipient == "") then
		if not (recipient == UnitName("player")) then
			return
		end
	end

	if cmd == "TX_VERSION" then
		HandleTXVersion(message, sender)
	elseif cmd == "RX_VERSION" then
		HandleRXVersion(message, sender)
--	elseif cmd == "TX_SUMBEGIN" then
--		HandleTXSumBegin(message, sender)
	elseif cmd == "TX_VERCHECK" then
		HandleTXVerCheck(message, sender)
	end
end



--  *******************************************************
--
--	Timer functions
--
--  *******************************************************
local Timers = {}
local TimerTick = 0

function CAPSLOCK_OnTimer(elapsed)
	TimerTick = TimerTick + elapsed

	for n=1,table.getn(Timers),1 do
		local timer = Timers[n]
		if TimerTick > timer[2] then
			Timers[n] = nil
			timer[1]()
		end
	end
end

function CAPSLOCK_GetTimerTick()
	return TimerTick;
end



--  *******************************************************
--
--	Version functions
--
--  *******************************************************

--[[
	Broadcast my version if this is not a beta (CurrentVersion > 0) and
	my version has not been identified as being too low (MessageShown = false)
]]
function CAPSLOCK_OnRaidRosterUpdate(event, arg1, arg2, arg3, arg4, arg5)
	if CAPSLOCK_CURRENT_VERSION > 0 and not CAPSLOCK_UPDATE_MESSAGE_SHOWN then
		if CAPSLOCK_IsInRaid() or CAPSLOCK_IsInParty() then
			local versionstring = GetAddOnMetadata("Capslock", "Version");
			CAPSLOCK_SendAddonMessage(string.format("TX_VERCHECK#%s#", versionstring));
		end
	end
end

function CAPSLOCK_CalculateVersion(versionString)
	local _, _, major, minor, patch = string.find(versionString, "([^\.]*)\.([^\.]*)\.([^\.]*)");
	local version = 0;

	if (tonumber(major) and tonumber(minor) and tonumber(patch)) then
		version = major * 100 + minor;
		--echo(string.format("major=%s, minor=%s, patch=%s, version=%d", major, minor, patch, version));
	end
	
	return version;
end

function CAPSLOCK_CheckIsNewVersion(versionstring)
	local incomingVersion = CAPSLOCK_CalculateVersion( versionstring );

	if (CAPSLOCK_CURRENT_VERSION > 0 and incomingVersion > 0) then
		if incomingVersion > CAPSLOCK_CURRENT_VERSION then
			if not CAPSLOCK_UPDATE_MESSAGE_SHOWN then
				CAPSLOCK_UPDATE_MESSAGE_SHOWN = true;
				CAPSLOCK_Echo(string.format("NOTE: A newer version of ".. COLOUR_INTRO .."CAPSLOCK"..COLOUR_CHAT.."! is available (version %s)!", versionstring));
				CAPSLOCK_Echo("NOTE: Go to https://armory.digam.dk/capslock to download latest version.");
			end
		end	
	end
end


--  *******************************************************
--
--	Event handlers
--
--  *******************************************************

function CAPSLOCK_OnEvent(event)
	if (event == "ADDON_LOADED") then
		if arg1 == "Capslock" then
--		    CAPSLOCK_InitializeConfigSettings();
			CAPSLOCK_Echo("TODO: Initialize config settings");
		end		
	elseif (event == "CHAT_MSG_ADDON") then
		CAPSLOCK_OnChatMsgAddon(event, arg1, arg2, arg3, arg4, arg5)
	elseif (event == "RAID_ROSTER_UPDATE") then
		CAPSLOCK_OnRaidRosterUpdate()
	end
end

function CAPSLOCK_OnLoad()
	CAPSLOCK_CURRENT_VERSION = CAPSLOCK_CalculateVersion( GetAddOnMetadata("Capslock", "Version") );

	CAPSLOCK_Echo(string.format("version %s by %s", GetAddOnMetadata("Capslock", "Version"), GetAddOnMetadata("Capslock", "Author")));
    this:RegisterEvent("ADDON_LOADED");
    this:RegisterEvent("CHAT_MSG_ADDON");   
    this:RegisterEvent("RAID_ROSTER_UPDATE")
end

