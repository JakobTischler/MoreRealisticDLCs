-- MrTitaniumMap
-- changes Titanium map name, replaces the default vehicles with MR vehicles, sets balancing values

-- @author: Jakob Tischler, dural
-- @date: 24 May 2014
-- @version: 0.1
--
-- Copyright (C) 2014 Jakob Tischler


MrTitaniumMap = {}
MrTitaniumMap.modDir = g_currentModDirectory;
MrTitaniumMap.modName = g_currentModName;
addModEventListener(MrTitaniumMap);

function MrTitaniumMap:loadMap(name)
	-- ONLY SERVER SIDE
	if g_server == nil then return; end;

	-- NOT TITANIUM MAP -> ABORT
	if not Utils.endsWith(name, 'titaniumAddon/map/americanMap.i3d') then return; end;

	-- ABORT IF MOREREALISTIC NOT INSTALLED
	if not g_modIsLoaded['moreRealistic'] then
		self:infoPrint('you don\'t have "moreRealistic" installed. The Titanium map will not be MRized.', '###');
		return;
	end;

	-- MOREREALISTICGENUINEMAP NOT INSTALLED
	if not g_modIsLoaded['moreRealisticGenuineMap'] then
		self:infoPrint('you don\'t have "moreRealisticGenuineMap" installed. The wool pallets will not work correctly!', '###');
	end;

	-- EXISTING SAVEGAME -> ABORT
	if g_currentMission.missionInfo.vehiclesXMLLoad:find('savegame') ~= nil then return; end;

	-- MOREREALISTICDLCS NOT FOUND -> ABORT
	if not MoreRealisticDLCs then return; end;

	-- ##################################################

	-- overwrite default vehicle xml path
	local vehFile = 'mrTitaniumMap_defaultVehicles.xml';
	if not MoreRealisticDLCs.mrVehiclesPackInstalled then
		vehFile = 'mrTitaniumMap_defaultVehicles_nonMrVehiclePack.xml';
		local startingMoney = 99837;

		if MoreRealisticDLCs.dlcsData and MoreRealisticDLCs.dlcsData.Ursus and MoreRealisticDLCs.dlcsData.Ursus.upToDateVersionExists then
			vehFile = 'mrTitaniumMap_defaultVehicles_nonMrVehiclePack_inclUrsus.xml';
			startingMoney = 89941;
		end;

		-- add extra money if vehicle pack isn't installed
		local setStartingMoney = function(self)
			g_currentMission.missionStats.money = startingMoney;
		end;
		RealisticGlobalListener.setMissionInfosForNewGame = Utils.appendedFunction(RealisticGlobalListener.setMissionInfosForNewGame, setStartingMoney);

		self:infoPrint('Warning: you don\'t have the "moreRealisticVehicles" pack installed. Many of the starting vehicles won\'t be available. As a compensation, your account will be credited with a bit of starting money.', '###');
	end;

	g_currentMission.missionInfo.vehiclesXMLLoad = Utils.getFilename('_RES/map/' .. vehFile, MrTitaniumMap.modDir);
end;

-- SET BALANCING VALUES
function MrTitaniumMap:setTitaniumMapParameters(mapName)
	if mapName:find('/pdlc/titaniumAddon/map/americanMap.i3d') then

		RealisticGlobalListener.priceBalancing = 1;
		RealisticGlobalListener.silagePriceBalancing = 1;
		RealisticGlobalListener.hiredWorkerWageBalancing = 0.05;
		--[[
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
if RealisticGlobalListener then
	RealisticGlobalListener.loadMap = Utils.appendedFunction(RealisticGlobalListener.loadMap, MrTitaniumMap.setTitaniumMapParameters);
end;


function MrTitaniumMap:infoPrint(str, prologue)
	if prologue then
		print(('%s %s: %s'):format(tostring(prologue), MrTitaniumMap.modName, tostring(str)));
	else
		print(('%s: %s'):format(MrTitaniumMap.modName, tostring(str)));
	end;
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
		break;
	end;
end;
