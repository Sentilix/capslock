--[[
Author:			Mimma
Create Date:	2018-02-04

Holds integration to TitanPanel (optional)

--]]


--  *******************************************************
--
--	Titan Panel integration
--
--  *******************************************************
function TitanPanelCapslockButton_OnLoad()
	-- Hide CAPSLOCK icon for all but Warlocks:
	if not CAPSLOCK_IsWarlock() then
		return;
	end;

	CAPSLOCK_AND_TITAN_LOADED = CAPSLOCK_IsTitanDMLoaded();

	if CAPSLOCK_AND_TITAN_LOADED == 3 then	
		this.registry = {
			id = CAPSLOCK_TITAN_ID,
			category = "General",
			menuText = CAPSLOCK_TITAN_TITLE,
			buttonTextFunction = "TitanPanelCapslockButton_GetTooltipText",
			tooltipTitle = CAPSLOCK_TITAN_TITLE .. " Options",
			tooltipTextFunction = "TitanPanelCapslockButton_GetTooltipText",
			frequency = 0,
			icon = "Interface\\Icons\\Spell_Shadow_Twilight"
		};
	    
		TitanPanelButton_OnLoad();    
	end;
end

function TitanPanelCapslockButton_GetTooltipText()
    return "Click to toggle configuration panel";
end



--	0:	ADDON=0, TITAN=0
--	1:	ADDON=1, TITAN=0
--	2:	ADDON=0, TITAN=1
--	3:	ADDON=1, TITAN=1
function CAPSLOCK_IsTitanDMLoaded()
	local loadState = 0;
	local name, title, notes, addonEnabled, loadable, reason, security = GetAddOnInfo("Capslock")
	local _, _, _, titanEnabled, _, _, _ = GetAddOnInfo("Titan")

	if addonEnabled then 
		loadState = loadState + 1 
		CAPSLOCK_Echo("Addon Loaded OK.");
	else
		CAPSLOCK_Echo("Addon Not Loaded.");
	end 
	
	if titanEnabled then 
		loadState = loadState + 2 
		CAPSLOCK_Echo("Titan Loaded OK.");
	else
		CAPSLOCK_Echo("Titan Not Loaded.");
	end 
	
	return loadState;
end
