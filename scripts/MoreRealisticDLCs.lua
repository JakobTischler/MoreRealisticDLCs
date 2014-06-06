--
-- MoreRealisticDLCs
--
-- @authors: modelleicher, Jakob Tischler, Satis
-- @contributors: dj, dural, Grisu118, Xentro
-- @version: 0.2b
-- @date: 06 Jun 2014
--
-- Copyright (C) 2014 Jakob Tischler

--[[
TODO:
* delete most prints before public release / convert to debug function
* increase min MoreRealisticVehicles version to 1.3.7
* add link to dural's Google Drive folder in min version print (?)
* decide between text vs. img 'converted by MoreRealisticDLC mod' in shop desc
]]


MoreRealisticDLCs = {};
local modDir, modName = g_currentModDirectory, g_currentModName;

source(Utils.getFilename('scripts/GetFilenameFix.lua', modDir));
source(Utils.getFilename('scripts/MoreRealisticDLCsGetData.lua', modDir));
source(Utils.getFilename('scripts/MoreRealisticDLCsSetData.lua', modDir));
source(Utils.getFilename('scripts/MoreRealisticDLCsUtils.lua', modDir));

-- ASSERT MOREREALISTIC MOD COMPATIBILITY
if not MoreRealisticDLCs:assertMrVersions() then
	return;
end;

-- ##################################################

function MoreRealisticDLCs:setGeneralData()
	self.dlcsData = {
		Lindner    = { dlcName = 'lindnerUnitracPack',	dataFile = 'vehicleDataLindner.xml',	minVersionStr = '1.0.0.1', minVersionFlt = 1.001 },
		Marshall   = { dlcName = 'marshallPack',		dataFile = 'vehicleDataMarshall.xml',	minVersionStr = '1.0.0.3', minVersionFlt = 1.003 },
		Titanium   = { dlcName = 'titaniumAddon',		dataFile = 'vehicleDataTitanium.xml',	minVersionStr = '1.0.0.5', minVersionFlt = 1.005 },
		Ursus	   = { dlcName = 'ursusAddon',		 	dataFile = 'vehicleDataUrsus.xml',		minVersionStr = '2.0.0.2', minVersionFlt = 2.002 },
		Vaederstad = { dlcName = 'vaderstadPack',		dataFile = 'vehicleDataVaederstad.xml',	minVersionStr = '1.0.0.3', minVersionFlt = 1.003 }
	};

	self.vehicleData = {};

	self.customSpecsRegistered = false;
	self.vehicleTypesPath = Utils.getFilename('vehicleTypes.xml', modDir);
	assert(fileExists(self.vehicleTypesPath), ('ERROR: %q could not be found'):format(self.vehicleTypesPath));
	self.vehicleTypesFile = loadXMLFile('vehicleTypesFile', self.vehicleTypesPath);

	self.exhaustPsNewPath = '$moddir$' .. modName .. '/_RES/exhaustPS/newRealParticles.i3d';
	self.exhaustPsOldPath = '$moddir$' .. modName .. '/_RES/exhaustPS/realParticles.i3d';

	self.shovelPS = {};
	if self.mrVehiclesPackInstalled then
		self.shovelPS = {
			manure	  = '$moddir$moreRealisticVehicles/_RES/particleSystems/shovelDpsManure.i3d',
			-- potato	  = '$moddir$moreRealisticVehicles/_RES/particleSystems/shovelDpsPotato.i3d',
			silage	  = '$moddir$moreRealisticVehicles/_RES/particleSystems/shovelDpsSilage.i3d',
			-- sugarBeet = '$moddir$moreRealisticVehicles/_RES/particleSystems/shovelDpsSugarBeet.i3d'
		};
	end;
end;

-- ##################################################

-- CHECK WHICH DLCs ARE INSTALLED -> only get MR data for installed and up-to-date ones
function MoreRealisticDLCs:checkDLCsAndGetData()
	for dlcNameClean, dlcData in pairs(self.dlcsData) do
		local dlcName = 'pdlc_' .. dlcData.dlcName;
		if g_modNameToDirectory[dlcName] ~= nil then
			local vStr, vFlt = self:getModVersion(dlcName);
			if vFlt < dlcData.minVersionFlt then
				print(('%s: DLC %q has a too low version number (v%s). Update to v%s or higher. Script will now be aborted!'):format(modName, dlcNameClean, vStr, dlcData.minVersionStr));
				delete(self.vehicleTypesFile);
				return false;
			end;

			dlcData.dir = g_modNameToDirectory[dlcName]; 
			dlcData.containingDir = dlcData.dir:sub(1, dlcData.dir:len() - dlcData.dlcName:len() - 1);
			-- print(('DLC %q: dlcName=%q, dir=%q, containingDir=%q'):format(dlcData.dlcName, dlcName, dlcData.dir, dlcData.containingDir));
			-- print(('\tmin DLC version: %s, existing DLC version: %s'):format(dlcData.minVersionStr, dlcVersionStr));
			if not self.customSpecsRegistered then
				self:registerCustomSpecs();
			end;


			local vehicleDataPath = Utils.getFilename(dlcData.dataFile, modDir);
			print(('%s: %q DLC v%s exists, -> get data from %q'):format(modName, dlcNameClean, vStr, dlcData.dataFile));
			self:registerVehicleTypes(dlcNameClean);
			self:getMrData(vehicleDataPath, dlcNameClean);
		end;
	end;

	delete(self.vehicleTypesFile);
	return true;
end;

-- ##################################################

-- REGISTER CUSTOM SPECIALIZATIONS
function MoreRealisticDLCs:registerCustomSpecs()
	if self.customSpecsRegistered then return; end;

	print(('%s: registerCustomSpecs()'):format(modName));
	local modDesc = loadXMLFile('modDesc', Utils.getFilename('modDesc.xml', modDir));
	local specsKey = 'modDesc.customSpecializations';
	local i = 0;
	while true do
		local key = ('%s.specialization(%d)'):format(specsKey, i);
		if not hasXMLProperty(modDesc, key) then break; end;

		local specName = getXMLString(modDesc, key .. '#name');
		local className = getXMLString(modDesc, key .. '#className');
		local fileName = getXMLString(modDesc, key .. '#filename');
		if specName and className and fileName then
			specName = modName .. '.' .. specName;
			className = modName .. '.' .. className;
			fileName = Utils.getFilename(fileName, modDir);
			print(('\tregisterSpecialization(): %s'):format(className));
			SpecializationUtil.registerSpecialization(specName, className, fileName, modName);
		end;
		i = i + 1;
	end;
	delete(modDesc);
	self.customSpecsRegistered = true;
end;

-- ##################################################

-- REGISTER CUSTOM VEHICLE TYPES
function MoreRealisticDLCs:registerVehicleTypes(dlcNameClean)
	-- print(('%s: registerVehicleTypes(%q)'):format(modName, dlcNameClean));
	local i = 0
	while true do
		local key = ('vehicleTypes.%s.type(%d)'):format(dlcNameClean, i);
		local typeName = getXMLString(self.vehicleTypesFile, key .. '#name');
		if typeName == nil then break; end;

		typeName = modName .. '.' .. typeName;
		assert(VehicleTypeUtil.vehicleTypes[typeName] == nil, ('vehicleType %q already exists'):format(typeName));

		local className = getXMLString(self.vehicleTypesFile, key .. '#className');
		local fileName = getXMLString(self.vehicleTypesFile, key .. '#filename');
		-- print(('\t%s\n\ttypeName=%q, className=%q, fileName=%q'):format(('-'):rep(50), typeName, tostring(className), tostring(fileName)));
		if className and fileName then
			fileName = Utils.getFilename(fileName, modDir);
			local specializationNames, j = {}, 0;
			while true do
				local specName = getXMLString(self.vehicleTypesFile, ('%s.specialization(%d)#name'):format(key, j));
				if specName == nil then break; end;
				if SpecializationUtil.specializations[specName] == nil then
					specName = modName .. '.' .. specName;
				end;
				if SpecializationUtil.specializations[specName] == nil then
					-- print(('\t\tspecName=%q: spec could not be found!'):format(tostring(specName)));
				else
					specializationNames[#specializationNames + 1] = specName;
				end;
				j = j + 1;
			end;
			-- print(('\t\tspecializationNames=%s'):format(table.concat(specializationNames, ', ')));
			-- print(('\tcall registerVehicleType(%q, %q, %q, %s, %q)'):format(tostring(typeName), tostring(className), tostring(fileName), tostring(specializationNames), tostring(customEnvironment)));
			VehicleTypeUtil.registerVehicleType(typeName, className, fileName, specializationNames, customEnvironment);
		end;
		i = i + 1;
	end;
end;

-- ##################################################


-- SET VEHICLE STORE DATA
function MoreRealisticDLCs:setStoreData(configFileNameShort, dlcNameClean, storeData, doDebug)
	if doDebug then print(('%s: setStoreData(%q, %q, ...)'):format(modName, configFileNameShort, dlcNameClean)); end;
	local pdlcDir = self.dlcsData[dlcNameClean].containingDir;
	local path = Utils.getFilename(configFileNameShort:sub(6, configFileNameShort:len()), pdlcDir);
	local storeItem = StoreItemsUtil.storeItemsByXMLFilename[path:lower()];
	if not storeItem then return; end;

	if not storeItem.nameMRized then
		storeItem.name = 'MR ' .. storeItem.name;
		storeItem.nameMRized = true;
		if doDebug then print(('\tchange store name to %q'):format(storeItem.name)); end;
	end;
	if storeData.price and storeItem.price ~= storeData.price and not storeItem.priceMRized then
		if doDebug then print(('\tchange store price to %s (old: %s)'):format(g_i18n:formatMoney(storeData.price), g_i18n:formatMoney(storeItem.price))); end;
		storeItem.price = storeData.price;
		storeItem.priceMRized = true;
	end;
	if storeData.dailyUpkeep and storeItem.dailyUpkeep ~= storeData.dailyUpkeep and not storeItem.dailyUpkeepMRized then
		if doDebug then print(('\tchange store dailyUpkeep to %s (old: %s)'):format(g_i18n:formatMoney(storeData.dailyUpkeep), g_i18n:formatMoney(storeItem.dailyUpkeep))); end;
		storeItem.dailyUpkeep = storeData.dailyUpkeep;
		storeItem.dailyUpkeepMRized = true;
	end;
	--[[ -- not needed, as the banner is displayed instead
	if not storeItem.descriptionMRized then
		storeItem.description = storeItem.description .. '\n\n' .. tostring(g_i18n:getText('DLC_MRIZED'));
		storeItem.descriptionMRized = true;
	end;
	]]
	if not storeItem.specsMRized then
		local specs = '';
		if storeData.powerKW then
			specs = specs .. g_i18n:getText('STORE_SPECS_MAXPOWER') .. ' ' .. g_i18n:getText('STORE_SPECS_POWER'):format(storeData.powerKW, storeData.powerKW * 1.35962162) .. '\n';
		end;
		if storeData.maxSpeed then
			specs = specs .. g_i18n:getText('STORE_SPECS_MAXSPEED'):format(self:formatNumber(g_i18n:getSpeed(storeData.maxSpeed), 1), g_i18n:getText('speedometer')) .. '\n';
		end;
		if storeData.requiredPowerKwMin then
			specs = specs .. g_i18n:getText('STORE_SPECS_POWERREQUIRED') .. ' ' .. g_i18n:getText('STORE_SPECS_POWER_HP'):format(storeData.requiredPowerKwMin * 1.35962162);
			if storeData.requiredPowerKwMax then
				specs = specs .. ' - ' .. g_i18n:getText('STORE_SPECS_POWER_HP'):format(storeData.requiredPowerKwMax * 1.35962162);
			end;
			specs = specs .. '\n';
		end;
		if storeData.weight then
			specs = specs .. g_i18n:getText('STORE_SPECS_WEIGHT'):format(self:formatNumber(storeData.weight)) .. '\n';
		end;
		if storeData.workWidth then
			specs = specs .. g_i18n:getText('STORE_SPECS_WORKWIDTH'):format(self:formatNumber(storeData.workWidth, 1)) .. '\n';
		end;
		if storeData.workSpeedMax then
			local speed = self:formatNumber(g_i18n:getSpeed(storeData.workSpeedMax), 1);
			if storeData.workSpeedMin then
				speed = self:formatNumber(g_i18n:getSpeed(storeData.workSpeedMin), 1) .. ' - ' .. speed;
			end;
			specs = specs .. g_i18n:getText('STORE_SPECS_WORKINGSPEED'):format(speed, g_i18n:getText('speedometer')) .. '\n';
		end;
		if storeData.capacity then
			local unit = storeData.capacityUnit or 'L';
			if unit == "M3COMP" then
				local compressed = storeData.compressedCapacity or storeData.capacity * 1.6;
				specs = specs .. g_i18n:getText('STORE_SPECS_CAPACITY_' .. unit):format(self:formatNumber(storeData.capacity, 1), self:formatNumber(compressed, 1)) .. '\n';
			else
				specs = specs .. g_i18n:getText('STORE_SPECS_CAPACITY_' .. unit):format(self:formatNumber(storeData.capacity, unit == 'M3' and 2 or 0)) .. '\n';
			end;
		end;
		if storeData.length then
			specs = specs .. g_i18n:getText('STORE_SPECS_LENGTH'):format(self:formatNumber(storeData.length, 2)) .. '\n';
		end;
		if storeData.fruits then
			local fruitNames = Utils.splitString(',', storeData.fruits);
			local fruitNamesI18n = {};
			for i=1,#fruitNames do
				local fruitName = fruitNames[i];
				if Fillable.fillTypeNameToDesc[fruitName] ~= nil then
					fruitNamesI18n[#fruitNamesI18n + 1] = tostring(Fillable.fillTypeNameToDesc[fruitName].nameI18N);
				else
					local fruitTypeDesc = FruitUtil.fruitTypes[fruitName];
					if fruitTypeDesc then
						local fillTypeDesc = FruitUtil.fruitTypeToFillType[fruitTypeDesc.index];
						if fillTypeDesc then
							fruitNamesI18n[#fruitNamesI18n + 1] = tostring(fillTypeDesc.nameI18n);
						end;
					end;
				end;
			end;

			specs = specs .. g_i18n:getText('STORE_SPECS_FRUITS'):format(table.concat(fruitNamesI18n, ', ')) .. '\n';
		end;

		specs = specs .. g_i18n:getText('STORE_SPECS_MAINTENANCE'):format(g_i18n:formatMoney(storeItem.dailyUpkeep));
		storeItem.specs = specs;
		if doDebug then print(('\tchange specs to\n%s'):format(specs)); end;
		storeItem.specsMRized = true;
	end;
end;

-- ##################################################

-- SET GENERAL DATA
MoreRealisticDLCs:setGeneralData();

-- HANDLE DLCs
if not MoreRealisticDLCs:checkDLCsAndGetData() then
	print(('%s: you don\'t have any DLCs installed. Script will now be aborted!'):format(modName));
	return;
end;

-- SET SHOP BANNER
MoreRealisticDLCs:setShopBanner();

-- ##################################################

local origVehicleLoad = Vehicle.load;
Vehicle.load = function(self, configFile, positionX, offsetY, positionZ, yRot, typeName, isVehicleSaved, asyncCallbackFunction, asyncCallbackObject, asyncCallbackArguments)
	local vehicleModName, baseDirectory = Utils.getModNameAndBaseDirectory(configFile);
 	self.configFileName = configFile;
	self.baseDirectory = baseDirectory;
	self.customEnvironment = vehicleModName;
	self.typeName = typeName;

	-- SET VEHICLE TYPE
	local addMrData = false;
	local cfnStart, _ = configFile:find('/pdlc/');
	if cfnStart then
		-- print(('\tmodName=%q, baseDirectory=%q'):format(tostring(vehicleModName), tostring(baseDirectory)));
		self.configFileNameShort = configFile:sub(cfnStart + 1, configFile:len());
		MoreRealisticDLCs.mrData = MoreRealisticDLCs.vehicleData[self.configFileNameShort];
		if MoreRealisticDLCs.mrData then
			self.typeName = MoreRealisticDLCs.mrData.vehicleType;
			self.isMoreRealisticDLC = true;
			self.moreRealisticDLCdebug = MoreRealisticDLCs.mrData.doDebug;
			self.dlcNameClean = MoreRealisticDLCs.mrData.dlcName;
			addMrData = true;
			print(('load(): typeName=%q, configFileName=%q'):format(tostring(self.typeName), tostring(self.configFileName)));
			print(('\tVehicleType changed to: %q'):format(tostring(self.typeName)));
		end;
	end;
	--

	self.isVehicleSaved = Utils.getNoNil(isVehicleSaved, true);

	local typeDef = VehicleTypeUtil.vehicleTypes[self.typeName];
	self.specializations = typeDef.specializations;

	local xmlFile = loadXMLFile('TempConfig', configFile);

	-- ADD MR DATA
	if addMrData then
		MoreRealisticDLCs:setMrData(self, xmlFile);
	end;
   
	for i=1, #self.specializations do
		if self.specializations[i].preLoad ~= nil then
			self.specializations[i].preLoad(self, xmlFile);
		end;
	end;   

	--** DURAL
	--** checking an additionnal y offset for vehicle which have their wheels under the '0' plane in Giants editor (avoid the vehicle to tip over when spawned)
	local additionnalOffsetY = Utils.getNoNil(getXMLFloat(xmlFile, 'vehicle.size#yOffset'), 0);
	offsetY = offsetY + additionnalOffsetY;

	if asyncCallbackFunction ~= nil then
		Utils.loadSharedI3DFile(getXMLString(xmlFile, 'vehicle.filename'), baseDirectory, true, true, self.loadFinished, self, {xmlFile, positionX, offsetY, positionZ, yRot, asyncCallbackFunction, asyncCallbackObject, asyncCallbackArguments});
	else
		local i3dNode = Utils.loadSharedI3DFile(getXMLString(xmlFile, 'vehicle.filename'), baseDirectory, true, true);
		self:loadFinished(i3dNode, {xmlFile, positionX, offsetY, positionZ, yRot, asyncCallbackFunction, asyncCallbackObject, asyncCallbackArguments});
	end;

	MoreRealisticDLCs.mrData = nil;
end;

-- ANGULAR + LINEAR DAMPING
function MoreRealisticDLCs.setMoreRealisticDamping(self, i3dNode, arguments)
	if self.isMoreRealisticDLC then
		-- set damping
		for i,comp in ipairs(self.components) do
			setAngularDamping(comp.node, 0);
			setLinearDamping(comp.node, 0);
			if self.moreRealisticDLCdebug then
				print(('%s: loadFinished(): component %d (%d/%q): angularDamping set to %s, linearDamping set to %s'):format(tostring(self.name), i, comp.node, tostring(getName(comp.node)), tostring(getAngularDamping(comp.node)), tostring(getLinearDamping(comp.node))));
			end;
		end;
	end;
end;
Vehicle.loadFinished = Utils.appendedFunction(Vehicle.loadFinished, MoreRealisticDLCs.setMoreRealisticDamping);

-- DEBUG PRINT WHEELS POSITION
function MoreRealisticDLCs.debugPrintWheelsPosition(self, i3dNode, arguments)
	if self.isMoreRealisticDLC then
		if self.wheels then
			local rx,ry,rz = getWorldTranslation(self.rootNode);
			print(('%s: wheels / rootNode: rx=%.1f, rz=%.1f'):format(tostring(self.name), rx, rz));
			for i,wheel in ipairs(self.wheels) do
				local wx,wy,wz = getWorldTranslation(wheel.driveNode);
				local dx,dy,dz = worldToLocal(self.rootNode, wx, wy, wz);
				local posX = dx > 0 and 'left' or 'right';
				local posZ = dz > 0 and 'front' or 'rear';
				print(('\twheel %d: wx=%.1f, wz=%.1f, dx=%.1f, dz=%.1f -> position = %s %s // rotMax=%s, rotMin=%s'):format(i, wx, wz, dx, dz, posX, posZ, tostring(wheel.rotMax), tostring(wheel.rotMin)));
			end;
		end;
	end;
end;
-- Vehicle.loadFinished = Utils.appendedFunction(Vehicle.loadFinished, MoreRealisticDLCs.debugPrintWheelsPosition);

-- BALES
function MoreRealisticDLCs.setBaleMrData(self, nodeId)
	if self.i3dFilename and self.i3dFilename:find('pdlc/ursusAddon') then
		setAngularDamping(self.nodeId, 0);
		setLinearDamping(self.nodeId, 0);
		setUserAttribute(self.nodeId, 'isRealistic', 'Boolean', true);
		setUserAttribute(self.nodeId, 'baleValueScale', 'Float', 1.6);
	end;
end;
Bale.setNodeId = Utils.appendedFunction(Bale.setNodeId, MoreRealisticDLCs.setBaleMrData);

-- RELOAD FROM XML
local origVehicleDevelopmentReloadFromXML = Vehicle.developmentReloadFromXML;
Vehicle.developmentReloadFromXML = function(self)
	if not self.isMoreRealisticDLC or not self.configFileNameShort or not self.dlcNameClean then
		return origVehicleDevelopmentReloadFromXML(self);
	end;

	local vehicleDataFileName = MoreRealisticDLCs.dlcsData[self.dlcNameClean].dataFile;
	local vehicleDataPath = Utils.getFilename(vehicleDataFileName, modDir);
	print(('%s (%q): reloadFromXML -> get data from %q'):format(tostring(self.name), tostring(self.configFileNameShort), vehicleDataFileName));
	-- print(('\tdlcNameClean=%q, vehicleDataPath=%q'):format(self.dlcNameClean, vehicleDataPath));
	getMoreRealisticData(vehicleDataPath, self.dlcNameClean);

	local xmlFile = loadXMLFile('configFileTmp', self.configFileName);
	-- print(('\ttypeName=%q, configFileNameShort=%q'):format(tostring(self.typeName), tostring(self.configFileNameShort)));
	MoreRealisticDLCs.mrData = MoreRealisticDLCs.vehicleData[self.configFileNameShort];
	if MoreRealisticDLCs.mrData then
		print('\tsetMrData()');
		MoreRealisticDLCs:setMrData(self, xmlFile);
	end;

	self.maxRotTime = 0;
	self.minRotTime = 0;
	self.autoRotateBackSpeed = getXMLFloat(xmlFile, 'vehicle.wheels#autoRotateBackSpeed') or 1;
	for i=1, #self.wheels do
		local wheel = self.wheels[i];
		local wheelKey = ('vehicle.wheels.wheel(%d)'):format(wheel.xmlIndex);
		self:loadDynamicWheelDataFromXML(xmlFile, wheelKey, wheel);
	end;
	for _, spec in pairs(self.specializations) do
		if spec.developmentReloadFromXML ~= nil then
			spec.developmentReloadFromXML(self, xmlFile);
		end;
	end;
	for _, spec in pairs(self.specializations) do
		if spec.developmentReloadFromXMLPost ~= nil then
			spec.developmentReloadFromXMLPost(self, xmlFile);
		end;
	end;
	delete(xmlFile);
end;

-- DEBUG DRAW COMPONENT POSITIONS / CENTER OF MASS
function MoreRealisticDLCs.drawComponents(self, dt)
	if not self.isActive or not self.moreRealisticDLCdebug then return; end;
	for i=1, #self.components do
		local node = self.components[i].node;
		local compX,compY,compZ = getWorldTranslation(node);
		drawDebugPoint(compX,compY,compZ, 0, 1, 0, 1);
		local x, y, z = getCenterOfMass(node);
		if x ~= 0 or y ~= 0 or z ~= 0 then
			local massX,massY,massZ = localToWorld(node, x, y, z);
			drawDebugPoint(massX,massY,massZ, 1, 1, 0, 1);
			drawDebugLine(compX,compY,compZ, 0, 1, 0, massX,massY,massZ, 1, 1, 0);
		end;
	end;
end;
Vehicle.update = Utils.appendedFunction(Vehicle.update, MoreRealisticDLCs.drawComponents);
