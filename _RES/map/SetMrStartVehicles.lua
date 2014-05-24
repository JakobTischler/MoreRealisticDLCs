-- SetMrStartVehicles
-- replaces the default vehicles on the Titanium map with MR vehicles

-- @author: Jakob Tischler, dural
-- @date: 24 May 2014
-- @version: 0.1
--
-- Copyright (C) 2014 Jakob Tischler

SetMrStartVehicles = {}
SetMrStartVehicles.modDir = g_currentModDirectory;
addModEventListener(SetMrStartVehicles);

function SetMrStartVehicles:loadMap(name)
	-- MORE REALISTIC NOT INSTALLED -> ABORT
	if not RealisticUtils then
		return;
	end;

	-- NOT TITANIUM MAP -> ABORT
	if not Utils.endsWith(name, 'titaniumAddon/map/americanMap.i3d') then
		return;
	end;

	-- EXISTING SAVEGAME -> ABORT
	if g_currentMission.missionInfo.vehiclesXMLLoad:find('savegame') ~= nil then
		return;
	end;

	-- overwrite default vehicle xml path
	g_currentMission.missionInfo.vehiclesXMLLoad = Utils.getFilename('_RES/map/mrTitaniumMap_defaultVehicles.xml', SetMrStartVehicles.modDir);
end;

function SetMrStartVehicles:deleteMap() end;
function SetMrStartVehicles:keyEvent(unicode, sym, modifier, isDown) end;
function SetMrStartVehicles:mouseEvent(posX, posY, isDown, isUp, mouseButton) end;
function SetMrStartVehicles:update(dt) end;
function SetMrStartVehicles:updateTick(dt) end;
function SetMrStartVehicles:draw() end;
