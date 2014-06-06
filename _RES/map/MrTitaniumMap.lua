-- MrTitaniumMap
-- changes Titanium map name, replaces the default vehicles with MR vehicles, sets balancing values

-- @author: Jakob Tischler, dural
-- @date: 24 May 2014
-- @version: 0.1
--
-- Copyright (C) 2014 Jakob Tischler


-- MORE REALISTIC NOT INSTALLED -> ABORT
if not RealisticGlobalListener or not RealisticUtils then return; end;

MrTitaniumMap = {}
MrTitaniumMap.modDir = g_currentModDirectory;
addModEventListener(MrTitaniumMap);

function MrTitaniumMap:loadMap(name)
	-- NOT TITANIUM MAP -> ABORT
	if not Utils.endsWith(name, 'titaniumAddon/map/americanMap.i3d') then return; end;

	-- EXISTING SAVEGAME -> ABORT
	if g_currentMission.missionInfo.vehiclesXMLLoad:find('savegame') ~= nil then return; end;

	-- overwrite default vehicle xml path
	g_currentMission.missionInfo.vehiclesXMLLoad = Utils.getFilename('_RES/map/mrTitaniumMap_defaultVehicles.xml', MrTitaniumMap.modDir);
end;

function MrTitaniumMap:deleteMap() end;
function MrTitaniumMap:keyEvent(unicode, sym, modifier, isDown) end;
function MrTitaniumMap:mouseEvent(posX, posY, isDown, isUp, mouseButton) end;
function MrTitaniumMap:update(dt) end;
function MrTitaniumMap:updateTick(dt) end;
function MrTitaniumMap:draw() end;


-- SET MAP NAME (a.k.a. "too little, too late")
for i, mapItem in ipairs(MapsUtil.mapList) do
	if not mapItem.titleMRized and mapItem.title and mapItem.customEnvironment and mapItem.customEnvironment:find('pdlc_') then
		-- print(('mapItem %d: title=%q, customEnvironment=%q -> set title to %q'):format(i, tostring(mapItem.title), tostring(mapItem.customEnvironment), 'MR ' .. tostring(mapItem.title)));
		mapItem.title = 'MR ' .. mapItem.title;
		mapItem.titleMRized = true;
	end;
end;

-- SET BALANCING VALUES
local setTitaniumMapParameters = function(self, mapName)
	if mapName:find('/pdlc/titaniumAddon/map/americanMap.i3d') then

		--[[
		RealisticGlobalListener.priceBalancing = 1;
		RealisticGlobalListener.silagePriceBalancing = 1.3;
		RealisticGlobalListener.hiredWorkerWageBalancing = 0.1;	
		RealisticGlobalListener.seedPriceBalancing
		RealisticGlobalListener.balePriceBalancing
		RealisticGlobalListener.woolPriceBalancing
		RealisticGlobalListener.eggPriceBalancing
		RealisticGlobalListener.milkPriceBalancing
		RealisticGlobalListener.fuelPriceBalancing
		RealisticGlobalListener.fertilizerPriceBalancing
		RealisticGlobalListener.windrowPriceBalancing
		RealisticGlobalListener.startingSilosBaseAmount
		RealisticGlobalListener.startingMoney
		RealisticGlobalListener.realFieldTractionFx
		]]
	end;
end;
RealisticGlobalListener.loadMap = Utils.appendedFunction(RealisticGlobalListener.loadMap, setTitaniumMapParameters);
