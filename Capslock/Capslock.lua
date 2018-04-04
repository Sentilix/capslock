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
local WHISPER_CHANNEL				= "WHISPER"
local CHAT_END						= "|r"
local COLOUR_CHAT   				= "|c804060F0"
local COLOUR_INTRO  				= "|c8080A0F8"
local CAPSLOCK_PREFIX				= "Capslockv1"
local CTRA_PREFIX					= "CTRA"

-- To be configurable:
--	Update player status each <n> second:
CAPSLOCK_OPTION_PLAYER_UPDATE		= 2;

-- Globals:
CAPSLOCK_TITAN_ID					= "Capslock"
CAPSLOCK_TITAN_TITLE				= "CAPSLOCK"
CAPSLOCK_AND_TITAN_LOADED			= 0

local CAPSLOCK_CURRENT_VERSION		= 0
local CAPSLOCK_UPDATE_MESSAGE_SHOWN = false




-- List of people (in raid) requesting a summon.
-- Format is: { <playername>, <priority>, <playerstatus>, <location> }
-- Player status: 0=ready, 1=Offline, 2=Dead, 3=Not in Instance
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
		option = "OPEN"
	end
	option = string.upper(option);
		
		
	if (option == "SUM" or option == "SUMMON") then
		SlashCmdList["CAPSLOCK_SUMMON"]();
	elseif option == "OPEN" then
		SlashCmdList["CAPSLOCK_TOGGLE_SUMMON"]();
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
	Alternatives: /capssum, /summon
	If a playername is added, he/she will be added to summon queue.
	Added in: 0.0.1
]]
SLASH_CAPSLOCK_SUMMON1 = "/capslocksummon"
SLASH_CAPSLOCK_SUMMON2 = "/capssum"
SLASH_CAPSLOCK_SUMMON3 = "/summon"
SlashCmdList["CAPSLOCK_SUMMON"] = function(msg)
	if CAPSLOCK_IsWarlock() then
		
		local _, _, playername = string.find(msg, "(%S*)");
		if playername == "" then
			CAPSLOCK_SummonPriorityTarget();
		else
			-- If no zone, then this player is not in the party/raid.
			playername = CAPSLOCK_UCFirst(playername);
			local zone = CAPSLOCK_GetPlayerZone(playername);
			if zone then
				CAPSLOCK_AddToSummonQueue(playername, true);
			else
				CAPSLOCK_Echo(string.format("%s is not in the raid/party!", playername));
			end;		
		end;
	end;
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
	Open CAPSLOCK summon dialog
	Syntax: /capslock
	Alternative: /caps
	Added in: 0.0.1
]]
CAPSLOCK_TOGGLE_SUMMON1 = "/capslock"
CAPSLOCK_TOGGLE_SUMMON2 = "/caps"
SlashCmdList["CAPSLOCK_TOGGLE_SUMMON"] = function(msg)
	if CAPSLOCK_IsWarlock() then
		CAPSLOCK_ToggleConfigurationDialog();
	end;
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
	CAPSLOCK_Echo("    Open         (Default) Open/close the CAPSLOCK dialog");
	CAPSLOCK_Echo("    Summon       Summon next target.");
	CAPSLOCK_Echo("    Help         This help.");
	CAPSLOCK_Echo("    Version      Request version info from all clients.");
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

function CAPSLOCK_IsWarlock()
	return (UnitClass("player") == "Warlock");
end;


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
function CAPSLOCK_UCFirst(msg)
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
	playerName = CAPSLOCK_UCFirst(playerName);

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
local CAPSLOCK_TimerTick = 0;
local CAPSLOCK_LocationTimer = 0;

function CAPSLOCK_OnTimer(elapsed)
	CAPSLOCK_TimerTick = CAPSLOCK_TimerTick + elapsed

	if floor(CAPSLOCK_LocationTimer) < floor(CAPSLOCK_TimerTick) then
		CAPSLOCK_OnLocationTimer();
		CAPSLOCK_LocationTimer = CAPSLOCK_TimerTick + (CAPSLOCK_OPTION_PLAYER_UPDATE - 1);
	end
end

function CAPSLOCK_OnLocationTimer()
	if CAPSLOCK_SUMMON_ENABLED then
		CAPSLOCK_UpdateMessageList();
	end;
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
		
	if not CAPSLOCK_IsWarlock() then
		return;
	end;

	playername = CAPSLOCK_UCFirst(playername);
		
	local q = CAPSLOCK_GetFromQueueByName(playername);
	if q then
		if not silentMode then
			whisper(playername, "Patience, you are already queued for a summon!");
		end;
	else
		local id = 1 + table.getn(CAPSLOCK_SUMMON_QUEUE);
		-- Currently priority is always 10. Location is updated later.
		local priority = 10;
		CAPSLOCK_SUMMON_QUEUE[id] = { playername, priority, 0 , "" };
		
		if not silentMode then
			local lockInstance = "";
			if IsInInstance() then
				lockInstance = GetRealZoneText();
			end;
			local unitid = CAPSLOCK_GetUnitIDFromGroup(playername);
			local playerZone = CAPSLOCK_GetPlayerZone(UnitName(unitid))				
			local status = CAPSLOCK_GetPlayerStatus(lockInstance, playerZone, unitid);
		
			if status == 1 then
				-- Player is disconnected; don't send a message.
			elseif status == 2 then
				whisper(playername, string.format("Hi %s, you will be summoned when you are alive.", playername));
			elseif status == 3 then
				whisper(playername, string.format("Hi %s, you will be summoned when you are inside %s.", playername, lockInstance));
			else
				whisper(playername, string.format("Hi %s, you will be summoned shortly.", playername));
			end	
		end;
	end;	

	CAPSLOCK_UpdateMessageList();
		
	-- Debug: print out current queue:
	--[[
	for n=1, table.getn(CAPSLOCK_SUMMON_QUEUE), 1 do
		q = CAPSLOCK_SUMMON_QUEUE[n];
		echo(string.format("Queue: pos=%d, name=%s, prio=%d, status=%d, loc=%s", n, q[1], q[2], q[3], q[4]));
	end;
	]]	
end


--[[
	Get queue information for requested player.
	Added in: 0.0.2
--]]
function CAPSLOCK_GetFromQueueByName(playername)
	local target;
	for n=1, table.getn(CAPSLOCK_SUMMON_QUEUE), 1 do
		target = CAPSLOCK_SUMMON_QUEUE[n];
		if target[1] == playername then
			return target;
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
	local target;

	CAPSLOCK_UpdateQueueStatus();
	CAPSLOCK_SortTableAscending(CAPSLOCK_SUMMON_QUEUE, 1);
	
	for n=1, table.getn(CAPSLOCK_SUMMON_QUEUE), 1 do
		target = CAPSLOCK_SUMMON_QUEUE[n];			
		if target[3] == 0 then
			entry = target;
			break;
		end;	
	end;

	-- If we found a target we will remove it from the table:		
	if entry then
		CAPSLOCK_RemoveFromQueue(entry[1]);
	end;
	
	CAPSLOCK_UpdateMessageList();
	
	return entry;
end;


function CAPSLOCK_RemoveFromQueue(playername)
	local target
	local newTable = { }
	
	for n=1, table.getn(CAPSLOCK_SUMMON_QUEUE), 1 do
		target = CAPSLOCK_SUMMON_QUEUE[n];
		
		if target and not(target[1] == playername) then
			newTable[table.getn(newTable)+1] = CAPSLOCK_SUMMON_QUEUE[n];
		end;
	end;

	CAPSLOCK_SUMMON_QUEUE = newTable;
end;


--[[
	Return player status for one player: 
	0=ready, 1=Offline, 2=Dead, 3=Not in Instance
	Added in: 0.1.1
--]]
function CAPSLOCK_GetPlayerStatus(lockInstance, playerZone, unitid)
	-- Status 1: Unit is offline
	if not UnitIsConnected(unitid) then
		return 1;
	end;

	-- Status 2: Unit is dead!
	if UnitIsDeadOrGhost(unitid) then
		return 2;
	end;
	
	-- Status 3: lock is in an instance but target is not!
	if not(lockInstance == "") then
		if not(lockInstance == playerZone) then
			return 3;
		end;		
	end;
	
	return 0;
end


--[[
	Return player status for all players in queue:
	0=ready, 1=Offline, 2=Dead, 3=Not in Instance
	Added in: 0.1.1
--]]
function CAPSLOCK_UpdateQueueStatus()
	local lockInstance = "";	
	local status, unitid, playerZone;

	if IsInInstance() then
		lockInstance = GetRealZoneText();
	end;
	
	for n=1, table.getn(CAPSLOCK_SUMMON_QUEUE), 1 do
		target = CAPSLOCK_SUMMON_QUEUE[n];
		unitid = CAPSLOCK_GetUnitIDFromGroup(target[1]);
		
		playerZone = CAPSLOCK_GetPlayerZone(UnitName(unitid))				
		target[3] = CAPSLOCK_GetPlayerStatus(lockInstance, playerZone, unitid);
		target[4] = playerZone;
		
		CAPSLOCK_SUMMON_QUEUE[n] = target;
	end;
end;


function CAPSLOCK_AnnounceSummons()
	local location = GetRealZoneText();
	local message = string.format("<CAPSLOCK> Type \"!summon\" to be summoned to %s.", location);
	
	partyEcho(message);
end;



--  *******************************************************
--
--	Summon functions
--
--  *******************************************************

--[[
	Summon next target in priority.
	(optional) playername: set if specific player is to be summoned.
	Added in: 0.0.2
--]]
function CAPSLOCK_SummonPriorityTarget(playername)
	if not CAPSLOCK_IsInRaid() and not CAPSLOCK_IsInParty() then
		CAPSLOCK_Echo("You must be in a party or raid to summon!");
		return;
	end

	if UnitAffectingCombat("player") then
		CAPSLOCK_Echo("You cannot summon people while flagged for combat.");
		return;
	end

	local nearbyCount = CAPSLOCK_CountNearbyPlayers();
	if nearbyCount < 3 then
		CAPSLOCK_Echo("There are not enough clickers nearby, please wait with summons.");
		return;
	end;

	local target;
	if playername then
		target = { playername, 0, 0 };
		CAPSLOCK_RemoveFromQueue(target[1]);
		CAPSLOCK_UpdateMessageList();		
	else
		target = CAPSLOCK_GetFromQueueByPriority();
		if not target then
			if table.getn(CAPSLOCK_SUMMON_QUEUE) > 0 then
				CAPSLOCK_Echo("There are no eligible summon targets in queue!");
			else
				CAPSLOCK_Echo("The summon queue is empty!");
			end;
		
			return;
		end;
	end;

	local unitid = CAPSLOCK_GetUnitIDFromGroup(target[1]);
	if not unitid then
		CAPSLOCK_Echo(string.format("Oops, unable to find unitid for player %s", target[1]));
		return;
	end

	TargetUnit(unitid);
	CastSpellByName("Ritual of Summoning");

	if not SpellIsTargeting() then
		CAPSLOCK_SendAddonMessage("TX_SUMBEGIN#"..target[1].."#");
		CAPSLOCK_AnnounceSummoning(target[1]);
	else
		-- If summon did not succeed we must place player back in queue.	
		echo("*** Unsuccessful summon!!!");
		CAPSLOCK_AddToSummonQueue(target[1], true);
	end
end


--[[
	Summon specific target.
	Added in: 0.1.1
--]]
function CAPSLOCK_OnTargetClick(object, buttonname)
	currentObjectId = object:GetID();
	
	local frame = getglobal("CapslockFrameSummonQueueEntry"..currentObjectId);
	local playername = getglobal(frame:GetName().."Target"):GetText();

	if buttonname == "RightButton" then
		-- Right button: Remove player from queue
		CAPSLOCK_RemoveFromQueue(playername);
		CAPSLOCK_UpdateMessageList();				
	else
		-- Left button: Summon immediately (regardless of status)
		if not(playername == "") then
			CAPSLOCK_SummonPriorityTarget(playername);
		end;
	end


end;


--[[
	Announce summon instructions in party/raid.
	Will check if there are at least 3 persons within 100 yards range.
	Added in: 0.0.1
--]]
function CAPSLOCK_AnnounceSummoning(playername)
	local message = string.format("Summoning %s, please click the portal", playername);
--	partyEcho(message);	
--	SendChatMessage(message, SAY_CHANNEL)
	SendChatMessage(message, YELL_CHANNEL)

	whisper(playername, "You will be summoned in 10 seconds - be ready.");
end


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

	CAPSLOCK_UpdateQueueStatus();

	CAPSLOCK_SortTableAscending(summons, 2);
	
	local summon, playername, playerprio, playerstatus;
	for n=1, CAPSLOCK_SUMMON_MAXVISIBLE, 1 do
		local frame = getglobal("CapslockFrameSummonQueueEntry"..n);
		
		playername = "";
		playerzone = "";
		
		summon = summons[n + offset]
		if summon then
			playername = summon[1];
			playerprio = summon[2];
			playerstatus = summon[3];
			playerzone = summon[4];

			local clasColor = { 1.00, 1.00, 1.00 };
			local zoneColor = { 1.00, 0.80, 0.00 };

			-- Not in instance? Make zone color red
			if playerstatus == 3 then	
				zoneColor = { 1.00, 0.00,  0.00 }
			end;
			
			if playerstatus == 1 then		-- Offline
				clasColor = { 0.50, 0.50, 0.50 }
				zoneColor = { 0.50, 0.50, 0.50 }
			elseif playerstatus == 2 then	-- Dead
				clasColor = { 1.00, 0.00, 0.00 }			
			else
				-- Use class colour
				local unitid = CAPSLOCK_GetUnitIDFromGroup(playername);						
				local cls = UnitClass(unitid);
				if cls == "Druid" then
					clasColor = { 1.00, 0.49, 0.04 }
				elseif cls == "Hunter" then
					clasColor = { 0.67, 0.83, 0.45 }
				elseif cls == "Mage" then
					clasColor = { 0.41, 0.80, 0.94 }
				elseif cls == "Paladin" then
					clasColor = { 0.96, 0.55, 0.73 }
				elseif cls == "Priest" then
					clasColor = { 1.00, 1.00, 1.00 }
				elseif cls == "Rogue" then
					clasColor = { 1.00, 0.96, 0.41 }
				elseif cls == "Shaman" then
					clasColor = { 0.96, 0.55, 0.73 }
				elseif cls == "Warlock" then
					clasColor = { 0.58, 0.51, 0.79 }
				elseif cls == "Warrior" then
					clasColor = { 0.78, 0.61, 0.43 }
				end;			
			end;		
						
			getglobal(frame:GetName().."Target"):SetTextColor(clasColor[1], clasColor[2], clasColor[3]);			
			getglobal(frame:GetName().."Zone"):SetTextColor(zoneColor[1], zoneColor[2], zoneColor[3]);			
		end
		
		getglobal(frame:GetName().."Target"):SetText(playername);
		getglobal(frame:GetName().."Zone"):SetText(playerzone);
		frame:Show();			
	end
end



--  *******************************************************
--
--	Location functions
--
--  *******************************************************

--[[
	Return zonename where <playername> currently is.
	Returned value is nil if no zone was found (e.g. due to being offline).
	Added in: 0.1.0
--]]
function CAPSLOCK_GetPlayerZone(playername)
	if CAPSLOCK_IsInRaid() then
		for n=1, GetNumRaidMembers(), 1 do
			local name, _, _, _, _, _, zone = GetRaidRosterInfo(n);
			if name == playername then
				return zone;
			end
		end
	end;
	
	return nil;
end;


--[[
	Count how many players are within visible range (100 yards).
	Added in: 0.2.3
--]]
function CAPSLOCK_CountNearbyPlayers()
	local counter = 0;
	local unitid;

	if CAPSLOCK_IsInRaid() then
		for n=1, GetNumRaidMembers(), 1 do
			unitid = "raid"..n;
			if UnitIsVisible(unitid) and not UnitIsDeadOrGhost(unitid) then
				counter = counter + 1;
			end;
		end
	elseif CAPSLOCK_IsInParty() then
		for n=1, GetNumPartyMembers(), 1 do
			if UnitIsVisible(unitid) and not UnitIsDeadOrGhost(unitid) then
				counter = counter + 1;
			end;
		end
	end;

	return counter;
end;


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
	elseif (event == "CHAT_MSG_RAID" or 
			event == "CHAT_MSG_RAID_LEADER" or
			event == "CHAT_MSG_PARTY") then
		CAPSLOCK_HandleRaidChatMessage(event, arg1, arg2, arg3, arg4, arg5);
	end
end

function CAPSLOCK_OnLoad()
	CAPSLOCK_CURRENT_VERSION = CAPSLOCK_CalculateVersion( GetAddOnMetadata("Capslock", "Version") );

	CAPSLOCK_Echo(string.format("version %s by %s", GetAddOnMetadata("Capslock", "Version"), GetAddOnMetadata("Capslock", "Author")));
	
	if CAPSLOCK_IsWarlock() then	
		this:RegisterEvent("ADDON_LOADED");
		this:RegisterEvent("CHAT_MSG_ADDON");   
		this:RegisterEvent("RAID_ROSTER_UPDATE")    
		this:RegisterEvent("CHAT_MSG_WHISPER");
		this:RegisterEvent("CHAT_MSG_PARTY");
		this:RegisterEvent("CHAT_MSG_RAID");
		this:RegisterEvent("CHAT_MSG_RAID_LEADER");
		
		CAPSLOCK_InitializeListElements();		
	end
end

