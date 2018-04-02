--[[
Author:			Mimma
Create Date:	2018-02-04

The latest version of Capslock can always be found at:
https://armory.digam.dk/capslock

The source code can be found at Github:
https://github.com/Sentilix/capslock

Please see the ReadMe.txt for addon details.
]]


-- TODO: add 100 yards range check to see there are at least 3 people!
-- TODO: Check target is alive, online and not in combat.
-- TODO: Add party chat as well (is it covered by raid chat?)
-- TODO: Seems summons always ends up with "Invalid target"; something isnt working!


-- Channel settings:
local PARTY_CHANNEL					= "PARTY"
local RAID_CHANNEL					= "RAID"
local YELL_CHANNEL					= "YELL"
local SAY_CHANNEL					= "SAY"
local WARN_CHANNEL					= "RAID_WARNING"
local GUILD_CHANNEL					= "GUILD"
local WHISPER_CHANNEL				= "WHISPER"
local CHAT_END						= "|r"
local COLOUR_CHAT   				= "|c804060F0"
local COLOUR_INTRO  				= "|c8080A0F8"
local CAPSLOCK_NAME					= "Capslock"
local CAPSLOCK_PREFIX				= "Capslockv1"
local CTRA_PREFIX					= "CTRA"

local CAPSLOCK_CURRENT_VERSION		= 0
local CAPSLOCK_UPDATE_MESSAGE_SHOWN = false




-- List of people (in raid) requesting a summon.
-- Format is: { <playername>, <priority> }
local CAPSLOCK_SUMMON_QUEUE			= {}
local CAPSLOCK_SUMMON_KEYWORD		= "123"
local CAPSLOCK_SUMMON_MAXVISIBLE	= 6
local CAPSLOCK_SUMMON_MAXQUEUED		= 40
-- TRUE if client reacts on "!summon", FALSE if not.
-- This is triggered by the summoning UI being open or closed.
local CAPSLOCK_SUMMON_ENABLED		= false;



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


--[[
	Whisper specific target with a message.
]]
local function whisper(receiver, msg)
	if receiver == UnitName("player") then
		CAPSLOCK_Echo(msg);
	else
		SendChatMessage(msg, WHISPER_CHANNEL, nil, receiver);
	end
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
	CAPSLOCK_SummonPriorityTarget();
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
	CAPSLOCK_ToggleConfigurationDialog();
end

--[[
	Disable CAPSLOCK' messages
	Syntax: /capslock disable
	Added in: 0.0.1
]]
SLASH_CAPSLOCK_DISABLE1 = "/capslockdisable"
SlashCmdList["CAPSLOCK_DISABLE"] = function(msg)
	CAPSLOCK_ToggleConfigurationDialog();
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
function CAPSLOCK_ToggleConfigurationDialog()
	if CAPSLOCK_SUMMON_ENABLED then
		CAPSLOCK_CloseConfigurationDialog();
	else
		CAPSLOCK_OpenConfigurationDialog();
	end;
end;

function CAPSLOCK_OpenConfigurationDialog()
	CAPSLOCK_SUMMON_ENABLED = true;
	CAPSLOCK_UpdateMessageList();
	CapslockFrame:Show();
end;

function CAPSLOCK_CloseConfigurationDialog()
	CAPSLOCK_SUMMON_ENABLED = false;
	CapslockFrame:Hide();
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


--[[
	Convert a msg so first letter is uppercase, and rest as lower case.
]]
local function UCFirst(msg)
	if not msg then
		return ""
	end	

	local f = string.sub(msg, 1, 1)
	local r = string.sub(msg, 2)
	return string.upper(f) .. string.lower(r)
end


function CAPSLOCK_SortTableAscending(sourcetable, index)
	local doSort = true
	while doSort do
		doSort = false
		for n=table.getn(sourcetable), 2, -1 do
			local a = sourcetable[n - 1];
			local b = sourcetable[n];
			if (a[index]) > (b[index]) then
				sourcetable[n - 1] = b;
				sourcetable[n] = a;
				doSort = true;
			end
		end
	end
	return sourcetable;
end

function CAPSLOCK_SortTableDescending(sourcetable, index)
	local doSort = true
	while doSort do
		doSort = false
		for n=1,table.getn(sourcetable) - 1, 1 do
			local a = sourcetable[n]
			local b = sourcetable[n + 1]
			if (a[index]) < (b[index]) then
				sourcetable[n] = b
				sourcetable[n + 1] = a
				doSort = true
			end
		end
	end
	return sourcetable;
end

function CAPSLOCK_RenumberTable(sourcetable)
	local index = 1;
	local temptable = { };
	for key,value in ipairs(sourcetable) do
		if value and table.getn(value) > 0 then
			temptable[index] = value;
			index = index + 1
		end
	end
	return temptable;
end


function CAPSLOCK_GetUnitIDFromGroup(playerName)
	playerName = UCFirst(playerName);

	if CAPSLOCK_IsInRaid(false) then
		for n=1, GetNumRaidMembers(), 1 do
			if UnitName("raid"..n) == playerName then
				return "raid"..n;
			end
		end
	else
		for n=1, GetNumPartyMembers(), 1 do
			if UnitName("party"..n) == playerName then
				return "party"..n;
			end
		end				
	end
	
	return nil;	
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
--	Queue functions
--
--  *******************************************************

--[[
	Add a player to the summon queue.
	Added in: 0.0.2
--]]
function CAPSLOCK_AddToSummonQueue(playername, silentMode)
	playername = UCFirst(playername);
		
	if not CAPSLOCK_SUMMON_ENABLED then
		return;
	end;
	
	if not(UnitClass("player") == "Warlock") then
		return;
	end;
		
	local q = CAPSLOCK_GetFromQueueByName(playername);
	if q then
		if not silentMode then
			whisper(playername, "Patience, you are already queued for a summon!");
		end;
	else
		local id = 1 + table.getn(CAPSLOCK_SUMMON_QUEUE);
		-- Currently priority is always 10.
		local priority = 10;
		CAPSLOCK_SUMMON_QUEUE[id] = { playername, priority };
		
		if not silentMode then
			whisper(playername, string.format("Hi %s, you will be summoned shortly.", playername));
		end;
	end;	

	CAPSLOCK_UpdateMessageList();
		
	-- Debug: print out current queue:
	--[[
	for n=1, table.getn(CAPSLOCK_SUMMON_QUEUE), 1 do
		q = CAPSLOCK_SUMMON_QUEUE[n];
		echo(string.format("Queue: pos=%d, name=%s, prio=%d", n, q[1], q[2]));
	end;
	]]	
end


--[[
	Get queue information for requested player.
	Added in: 0.0.2
--]]
function CAPSLOCK_GetFromQueueByName(playername)
	local q;
	for n=1, table.getn(CAPSLOCK_SUMMON_QUEUE), 1 do
		q = CAPSLOCK_SUMMON_QUEUE[n];
		if q[1] == playername then
			return q;
		end
	end
	
	return nil;
end


--[[
	Get queue information for player with highest priority.
	Added in: 0.0.2
--]]
function CAPSLOCK_GetFromQueueByPriority()
	local entry = nil;
	
	if table.getn(CAPSLOCK_SUMMON_QUEUE) > 0 then	
		CAPSLOCK_SortTableAscending(CAPSLOCK_SUMMON_QUEUE, 1);
		
		entry = CAPSLOCK_SUMMON_QUEUE[1];
		
		local q
		local newTable = { }
		for n=1, table.getn(CAPSLOCK_SUMMON_QUEUE), 1 do
			q = CAPSLOCK_SUMMON_QUEUE[n];
			
			if q and not(q[1] == entry[1]) then
				newTable[table.getn(newTable)+1] = CAPSLOCK_SUMMON_QUEUE[n];
			end;
		end;
		
		CAPSLOCK_SUMMON_QUEUE = newTable;		
		CAPSLOCK_UpdateMessageList();
	end
	
	return entry;
end

function CAPSLOCK_AnnounceSummons()
	local location = GetRealZoneText();
	local message = string.format("<CAPSLOCK> Type \"!summon\" to be summoned to %s.", location);
	
	partyEcho(message);
--	SendChatMessage(message, SAY_CHANNEL)
end;



--  *******************************************************
--
--	Summon functions
--
--  *******************************************************
function CAPSLOCK_SummonPriorityTarget()
	if not CAPSLOCK_IsInRaid() and not CAPSLOCK_IsInParty() then
		CAPSLOCK_Echo("You must be in a party or raid to summon!");
		return;
	end

	if UnitAffectingCombat("player") then
		CAPSLOCK_Echo("You cannot summon people while flagged for combat.");
		return;
	end
	
	local target = CAPSLOCK_GetFromQueueByPriority();
	if not target then
		CAPSLOCK_Echo("The summon queue is empty!");
		return;
	end

	local unitid = CAPSLOCK_GetUnitIDFromGroup(target[1]);
	if not unitid then
		CAPSLOCK_Echo(string.format("Oops, unable to find unitid for player %s", target[1]));
		return;
	end

	CastSpellByName("Ritual of Summoning");
	SpellTargetUnit(unitid)

	if not SpellIsTargeting() then
		CAPSLOCK_SendAddonMessage("TX_SUMBEGIN#"..target[1].."#");
		CAPSLOCK_AnnounceResurrection(target[1]);
	else
		-- If summon did not succeed we must place player back in queue.	
		SpellStopTargeting();
		CAPSLOCK_AddToSummonQueue(target[1], true);
	end
end


function CAPSLOCK_AnnounceResurrection(playername)
	partyEcho(string.format("Summoning %s, please click the portal", playername));	
	whisper(playername, "You will be summoned in 10 seconds - be ready.");
end


function CAPSLOCK_OnTargetClick(object)
	local index = object:GetID();
	
	echo(format.string("Index=%d", index));
end;


function CAPSLOCK_UpdateMessageList()
	FauxScrollFrame_Update(CapslockFrameSummonQueue, CAPSLOCK_SUMMON_MAXQUEUED, 10, 20);
	local offset = FauxScrollFrame_GetOffset(CapslockFrameSummonQueue);
	
	CAPSLOCK_RefreshVisibleSummonQueue(offset);
end;


function CAPSLOCK_InitializeListElements()
	local entry = CreateFrame("Button", "$parentEntry1", CapslockFrameSummonQueue, "CAPSLOCK_CellTemplate");
	entry:SetID(1);
	entry:SetPoint("TOPLEFT", 4, -4);
	for n=2, CAPSLOCK_SUMMON_MAXQUEUED, 1 do
		local entry = CreateFrame("Button", "$parentEntry"..n, CapslockFrameSummonQueue, "CAPSLOCK_CellTemplate");
		entry:SetID(n);
		entry:SetPoint("TOP", "$parentEntry"..(n-1), "BOTTOM");
	end
end


function CAPSLOCK_RefreshVisibleSummonQueue(offset)
	local summons = CAPSLOCK_SUMMON_QUEUE;

	CAPSLOCK_SortTableAscending(summons, 2);
	
	local summon, playername
	for n=1, CAPSLOCK_SUMMON_MAXVISIBLE, 1 do
		local frame = getglobal("CapslockFrameSummonQueueEntry"..n);
		
		playername = "";
		
		summon = summons[n + offset]
		if summon then
			playername = summon[1];
					
			local unitid = CAPSLOCK_GetUnitIDFromGroup(playername);						
			local cls = UnitClass(unitid);
			local clsColor = { 1.00, 1.00,  1.00 }
			if cls == "Druid" then
				clsColor = { 1.00, 0.49, 0.04 }
			elseif cls == "Hunter" then
				clsColor = { 0.67, 0.83, 0.45 }
			elseif cls == "Mage" then
				clsColor = { 0.41, 0.80, 0.94 }
			elseif cls == "Paladin" then
				clsColor = { 0.96, 0.55, 0.73 }
			elseif cls == "Priest" then
				clsColor = { 1.00, 1.00, 1.00 }
			elseif cls == "Rogue" then
				clsColor = { 1.00, 0.96, 0.41 }
			elseif cls == "Shaman" then
				clsColor = { 0.96, 0.55, 0.73 }
			elseif cls == "Warlock" then
				clsColor = { 0.58, 0.51, 0.79 }
			elseif cls == "Warrior" then
				clsColor = { 0.78, 0.61, 0.43 }
			end;			
			
			getglobal(frame:GetName().."Target"):SetTextColor(clsColor[1], clsColor[2], clsColor[3]);			
		end
		
		getglobal(frame:GetName().."Target"):SetText(playername);
		frame:Show();			
	end
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



--[[
--	Handle incoming chat whisper.
--	"!" commands are redirected here too with the "raw" command line.
--	Since 0.0.2
--]]
function CAPSLOCK_OnChatWhisper(event, message, sender)	
	if not message then
		return
	end

	-- Skip messages from self:
	if sender == UnitName("player") then
		return;
	end;
	
	local _, _, cmd = string.find(message, "(%a+)");	
	if not cmd then
		return
	end
	cmd = string.lower(cmd);

	if cmd == "summon" then
		CAPSLOCK_AddToSummonQueue(sender);
	end;
end	


--[[
--	There's a message in the Party / Raid channel - investigate that!
--]]
function CAPSLOCK_HandleRaidChatMessage(event, message, sender)
	if not message or message == "" or not string.sub(message, 1, 1) == "!" then
		return;
	end

	local command = string.sub(message, 2)
	CAPSLOCK_OnChatWhisper(event, command, sender);
end



--  *******************************************************
--
--	Event handlers
--
--  *******************************************************
function CAPSLOCK_OnEvent(event)
--	if (event == "ADDON_LOADED") then
--		if arg1 == "Capslock" then
--		    CAPSLOCK_InitializeConfigSettings();
--		end		
--	else
	if (event == "CHAT_MSG_ADDON") then
		CAPSLOCK_OnChatMsgAddon(event, arg1, arg2, arg3, arg4, arg5)
--	elseif (event == "RAID_ROSTER_UPDATE") then
--		CAPSLOCK_OnRaidRosterUpdate()
	elseif (event == "CHAT_MSG_WHISPER") then
		CAPSLOCK_OnChatWhisper(event, arg1, arg2, arg3, arg4, arg5);
	elseif (event == "CHAT_MSG_RAID" or event == "CHAT_MSG_RAID_LEADER") then
		CAPSLOCK_HandleRaidChatMessage(event, arg1, arg2, arg3, arg4, arg5);
	end
end

function CAPSLOCK_OnLoad()
	CAPSLOCK_CURRENT_VERSION = CAPSLOCK_CalculateVersion( GetAddOnMetadata("Capslock", "Version") );

	CAPSLOCK_Echo(string.format("version %s by %s", GetAddOnMetadata("Capslock", "Version"), GetAddOnMetadata("Capslock", "Author")));
	
	if UnitClass("player") == "Warlock" then	
		this:RegisterEvent("ADDON_LOADED");
		this:RegisterEvent("CHAT_MSG_ADDON");   
		this:RegisterEvent("RAID_ROSTER_UPDATE")    
		this:RegisterEvent("CHAT_MSG_WHISPER");
		this:RegisterEvent("CHAT_MSG_RAID");
		this:RegisterEvent("CHAT_MSG_RAID_LEADER");
		
		CAPSLOCK_InitializeListElements();		
	end
end

