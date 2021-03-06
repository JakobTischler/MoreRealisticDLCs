--
-- MoreRealisticDLCs
--
-- @authors: Jakob Tischler, dural
-- @contributors: dj, Grisu118, modelleicher, Satis, Xentro
-- @version: 1.0
-- @date: 06 Aug 2014
-- @history: 0.1 (15 May 2014): initial implementation
--           0.2 (06 Jun 2014): usage of main handler class instead of local functions
--           0.3 (07 Jul 2014): move main script execution to loadMap event, in order to prevent loading order errors in MP
--           1.0 (06 Aug 2014): finalize release version
--
-- Copyright (C) 2014 Jakob Tischler


-- ##################################################

MoreRealisticDLCs = {};
MoreRealisticDLCs.modDir = g_currentModDirectory;
MoreRealisticDLCs.modName = g_currentModName;
local modDir, modName = MoreRealisticDLCs.modDir, MoreRealisticDLCs.modName;

function MoreRealisticDLCs.addModEventListener(listener, index)
	listener.modEventListenerIndex = index or #g_modEventListeners + 1;
	table.insert(g_modEventListeners, listener.modEventListenerIndex, listener);
end;
addModEventListener = MoreRealisticDLCs.addModEventListener;

function removeModEventListener(listener)
	local index = listener.modEventListenerIndex;
	if not index then
		for i,class in ipairs(g_modEventListeners) do
			if class == listener then
				index = i;
				break;
			end;
		end;
	end;
	if index and g_modEventListeners[index] == listener then
		g_modEventListeners[index] = nil;
		if listener == MoreRealisticDLCs then
			print(('%s removed from game'):format(modName));
		end;
	end;
end;

addModEventListener(MoreRealisticDLCs, 1);
-- NOTE: MoreRealisticDLCs should be loaded first before other specs (other than MoreRealistic) are registered in loadMap, so that the newly created vehicleTypes are recognized by those specs' registering functions

function MoreRealisticDLCs:loadMap(name)
	if self.initialized then return; end;

	source(Utils.getFilename('scripts/MoreRealisticDLCsUtils.lua', modDir));

	local version, _ = self:getModVersion(modName);
	self:infoPrint(('v%s initializing'):format(version), '###');

	-- ASSERT MIN GAME VERSION (a.k.a. REALLY, REALLY MAKE SURE)
	if not self:assertGameVersion() then
		removeModEventListener(MoreRealisticDLCs);
		return;
	end;

	-- ASSERT MOREREALISTIC MOD COMPATIBILITY
	if not self:assertMrVersions() then
		removeModEventListener(MoreRealisticDLCs);
		return;
	end;

	source(Utils.getFilename('scripts/GetFilenameFix.lua', modDir));
	source(Utils.getFilename('scripts/MoreRealisticDLCsGetData.lua', modDir));
	source(Utils.getFilename('scripts/MoreRealisticDLCsSetData.lua', modDir));

	-- ##################################################

	-- SET GENERAL DATA
	self:setGeneralData();

	-- HANDLE DLCs
	if not self:checkDLCsAndGetData() then
		delete(self.vehicleTypesFile);
		removeModEventListener(MoreRealisticDLCs);
		return;
	end;

	-- SET SHOP BANNER
	self:setShopBanner();

	-- ##################################################

	-- OVERWRITE VEHICLE FUNCTIONS
	local origVehicleLoad = Vehicle.load;
	Vehicle.load = MoreRealisticDLCs.vehicleLoad; -- Vehicle.load = Utils.overwrittenFunction(Vehicle.load, MoreRealisticDLCs.vehicleLoad);
	Vehicle.loadFinished = Utils.prependedFunction(Vehicle.loadFinished, MoreRealisticDLCs.createExtraNodes);
	Vehicle.loadFinished = Utils.appendedFunction(Vehicle.loadFinished, MoreRealisticDLCs.setNodesProperties);
	Vehicle.loadFinished = Utils.appendedFunction(Vehicle.loadFinished, MoreRealisticDLCs.setMoreRealisticDamping);
	-- Vehicle.loadFinished = Utils.appendedFunction(Vehicle.loadFinished, MoreRealisticDLCs.debugPrintWheelsPosition);
	Vehicle.update = Utils.appendedFunction(Vehicle.update, MoreRealisticDLCs.drawComponents);
	Vehicle.developmentReloadFromXML = MoreRealisticDLCs.developmentReloadFromXML; -- Vehicle.developmentReloadFromXML = Utils.overwrittenFunction(Vehicle.developmentReloadFromXML, MoreRealisticDLCs.developmentReloadFromXML);
	Bale.setNodeId = Utils.appendedFunction(Bale.setNodeId, MoreRealisticDLCs.setBaleMrData);

	-- ##################################################

	-- prevent double execution on 2nd, 3rd, ... savegame load
	self.initialized = true;

	-- ##################################################

	self:infoPrint(('v%s loaded'):format(version), '###');
end;

function MoreRealisticDLCs:deleteMap() end;
function MoreRealisticDLCs:update(dt) end;
function MoreRealisticDLCs:draw() end;
function MoreRealisticDLCs:mouseEvent(posX, posY, isDown, isUp, button) end;
function MoreRealisticDLCs:keyEvent(unicode, sym, modifier, isDown) end;

-- ##################################################

function MoreRealisticDLCs:setGeneralData()
	self.dlcsData = {
		Lindner    = { dlcName = 'lindnerUnitracPack',	dataFile = 'vehicleDataLindner.xml',	minVersion = '1.0.0.1' },
		Marshall   = { dlcName = 'marshallPack',		dataFile = 'vehicleDataMarshall.xml',	minVersion = '1.0.0.3' },
		Titanium   = { dlcName = 'titaniumAddon',		dataFile = 'vehicleDataTitanium.xml',	minVersion = '1.0.0.5' },
		Ursus	   = { dlcName = 'ursusAddon',		 	dataFile = 'vehicleDataUrsus.xml',		minVersion = '2.0.0.2' },
		Vaederstad = { dlcName = 'vaderstadPack',		dataFile = 'vehicleDataVaederstad.xml',	minVersion = '1.0.0.3' }
	};

	self.vehicleData = {};

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
	local anyDlcExists = false;
	for dlcNameClean, dlcData in pairs(self.dlcsData) do
		local ingameDlcName = 'pdlc_' .. dlcData.dlcName;
		if g_modIsLoaded[ingameDlcName] then
			anyDlcExists = true;
			local dlcNameI18n = g_i18n:getText('MOREREALISTICDLCS_' .. dlcNameClean:upper());
			local vStr, vFlt = self:getModVersion(ingameDlcName);
			if vFlt < self:getFloatNumberFromString(dlcData.minVersion) then
				self:infoPrint(('%s (v%s) is not up to date. Update to v%s or higher. Script will now be aborted!'):format(dlcNameI18n, vStr, dlcData.minVersion));
				self:addIngameWarning(g_i18n:getText('MOREREALISTICDLCS_DLC_VERSION_OUTDATED'):format(dlcNameI18n, vStr, dlcData.minVersion));
				dlcData.upToDateVersionExists = false;
				return false;
			end;

			dlcData.upToDateVersionExists = true;

			dlcData.dir = g_modNameToDirectory[ingameDlcName]; 
			dlcData.containingDir = dlcData.dir:sub(1, dlcData.dir:len() - dlcData.dlcName:len() - 1);

			local vehicleDataPath = Utils.getFilename(dlcData.dataFile, modDir);
			self:infoPrint(('%s v%s exists --> get data from %q'):format(dlcNameI18n, vStr, dlcData.dataFile));
			self:registerVehicleTypes(dlcNameClean);
			self:getMrData(vehicleDataPath, dlcNameClean);
		end;
	end;

	if not anyDlcExists then
		self:infoPrint('you don\'t have any DLCs installed. Script will now be aborted!');
		self:addIngameWarning(g_i18n:getText('MOREREALISTICDLCS_NO_DLCS'));
		return false;
	end;

	self:infoPrint('all vehicle data gathered');
	return true;
end;

-- ##################################################

-- REGISTER CUSTOM SPECIALIZATIONS
function MoreRealisticDLCs:registerCustomSpecs()
	if self.customSpecsRegistered then return; end;

	-- self:infoPrint('registerCustomSpecs()');
	local modDesc = loadXMLFile('modDesc', Utils.getFilename('modDesc.xml', modDir));
	local i = 0;
	while true do
		local key = ('modDesc.customSpecializations.specialization(%d)'):format(i);
		if not hasXMLProperty(modDesc, key) then break; end;

		local specName	= getXMLString(modDesc, key .. '#name');
		local className	= getXMLString(modDesc, key .. '#className');
		local fileName	= getXMLString(modDesc, key .. '#filename');
		if specName and className and fileName then
			specName = modName .. '.' .. specName;
			className = modName .. '.' .. className;
			fileName = Utils.getFilename(fileName, modDir);
			-- print(('\tregisterSpecialization(): %s'):format(className));
			SpecializationUtil.registerSpecialization(specName, className, fileName, modName);
		end;
		i = i + 1;
	end;
	delete(modDesc);
	self.customSpecsRegistered = true;
end;

if not MoreRealisticDLCs.customSpecsRegistered then
	MoreRealisticDLCs:registerCustomSpecs();
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

	storeItem.isMoreRealisticDLC = true;

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
	if storeData.author and not storeItem.descriptionMRized then
		-- storeItem.description = storeItem.description .. '\n\n' .. tostring(g_i18n:getText('DLC_MRIZED')); -- not needed anymore, banner used instead

		-- check if conversion author line can be separated by empty line (depending on length of existing description)
		local numDescLines = self:getEffectiveNumberOfTextLines(storeItem.description, g_shopScreen.descText.textSize, g_shopScreen.descText.textWrapWidth);
		local authorLineSeparator = numDescLines < 8 and '\n' or '';

		local author = Utils.trim(storeData.author);
		local authorSplit = Utils.splitString(',', author);
		if #authorSplit > 1 then
			authorSplit = table.map(authorSplit, Utils.trim);
			if #authorSplit == 2 then
				author = g_i18n:getText('STORE_DESC_AND'):format(authorSplit[1], authorSplit[2]);
			else
				author = g_i18n:getText('STORE_DESC_AND'):format(table.concat(authorSplit, ', ', 1, #authorSplit - 1), authorSplit[#authorSplit]);
			end;
		end;
		if not Utils.endsWith(storeItem.description, '\n') then
			storeItem.description = storeItem.description .. '\n';
		end;
		storeItem.description = storeItem.description .. authorLineSeparator .. g_i18n:getText('STORE_DESC_AUTHOR'):format(author);
		storeItem.descriptionMRized = true;
		if doDebug then print(('\tauthor line %q added'):format(author)); end;
	end;
	if not storeItem.specsMRized then
		local specs = '';
		if storeData.powerKW then
			specs = specs .. g_i18n:getText('STORE_SPECS_MAXPOWER') .. ' ' .. g_i18n:getText('STORE_SPECS_POWER'):format(storeData.powerKW, self:kwToHp(storeData.powerKW)) .. '\n';
		end;
		if storeData.maxSpeed then
			specs = specs .. g_i18n:getText('STORE_SPECS_MAXSPEED'):format(self:formatNumber(g_i18n:getSpeed(storeData.maxSpeed), 1), g_i18n:getText('speedometer')) .. '\n';
		end;
		if storeData.requiredPowerKwMin then
			specs = specs .. g_i18n:getText('STORE_SPECS_POWERREQUIRED') .. ' ' .. g_i18n:getText('STORE_SPECS_POWER_HP'):format(self:kwToHp(storeData.requiredPowerKwMin));
			if storeData.requiredPowerKwMax then
				specs = specs .. ' - ' .. g_i18n:getText('STORE_SPECS_POWER_HP'):format(self:kwToHp(storeData.requiredPowerKwMax));
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
				local fruitName = Utils.trim(fruitNames[i]);
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

local origVehicleLoad = Vehicle.load;
function MoreRealisticDLCs.vehicleLoad(self, configFile, positionX, offsetY, positionZ, yRot, typeName, isVehicleSaved, asyncCallbackFunction, asyncCallbackObject, asyncCallbackArguments)
	local vehicleModName, baseDirectory = Utils.getModNameAndBaseDirectory(configFile);
 	self.configFileName = configFile;
	self.baseDirectory = baseDirectory;
	self.customEnvironment = vehicleModName;
	self.typeName = typeName;

	-- SET VEHICLE TYPE
	local mrData;
	local cfnStart, _ = configFile:find('/pdlc/');
	if cfnStart then
		-- print(('\tmodName=%q, baseDirectory=%q'):format(tostring(vehicleModName), tostring(baseDirectory)));
		self.configFileNameShort = configFile:sub(cfnStart + 1, configFile:len());
		mrData = MoreRealisticDLCs.vehicleData[self.configFileNameShort];
		if mrData then
			self.isMoreRealisticDLC = true;
			self.moreRealisticDLCdebug = mrData.doDebug;
			if self.moreRealisticDLCdebug then
				MoreRealisticDLCs:infoPrint(('load(): typeName=%q, configFileName=%q'):format(tostring(self.typeName), tostring(self.configFileName)));
			end;
			self.typeName = mrData.vehicleType;
			self.dlcNameClean = mrData.dlcName;
			if self.moreRealisticDLCdebug then
				print(('\tVehicleType changed to: %q'):format(tostring(self.typeName)));
			end;
		end;
	end;
	--

	self.isVehicleSaved = Utils.getNoNil(isVehicleSaved, true);

	local typeDef = VehicleTypeUtil.vehicleTypes[self.typeName];
	self.specializations = typeDef.specializations;

	local xmlFile = loadXMLFile('TempConfig', configFile);

	-- ADD MR DATA
	local createExtraNodes, nodeProperties;
	if mrData then
		createExtraNodes, nodeProperties = MoreRealisticDLCs:setMrData(self, xmlFile, mrData);
	end;
   
	for i=1, #self.specializations do
		if self.specializations[i].preLoad ~= nil then
			self.specializations[i].preLoad(self, xmlFile);
		end;
	end;   

	--** DURAL
	--** checking an additional y offset for vehicle which have their wheels under the '0' plane in Giants editor (avoid the vehicle to tip over when spawned)
	local additionnalOffsetY = Utils.getNoNil(getXMLFloat(xmlFile, 'vehicle.size#yOffset'), 0);
	offsetY = offsetY + additionnalOffsetY;

	if asyncCallbackFunction ~= nil then
		Utils.loadSharedI3DFile(getXMLString(xmlFile, 'vehicle.filename'), baseDirectory, true, true, self.loadFinished, self, {xmlFile, positionX, offsetY, positionZ, yRot, asyncCallbackFunction, asyncCallbackObject, asyncCallbackArguments, createExtraNodes, nodeProperties});
	else
		local i3dNode = Utils.loadSharedI3DFile(getXMLString(xmlFile, 'vehicle.filename'), baseDirectory, true, true);
		self:loadFinished(i3dNode, {xmlFile, positionX, offsetY, positionZ, yRot, asyncCallbackFunction, asyncCallbackObject, asyncCallbackArguments, createExtraNodes, nodeProperties});
	end;
end;

-- CREATE EXTRA NODES
function MoreRealisticDLCs.createExtraNodes(self, i3dNode, arguments)
	if not self.isMoreRealisticDLC then return; end;

	local createExtraNodes = arguments[9];
	if createExtraNodes and next(createExtraNodes) then
		for i,nodeData in ipairs(createExtraNodes) do
			if self.moreRealisticDLCdebug then
				print(('\ttrying to create node %q'):format(tostring(nodeData.name)));
			end;
			-- TODO: use parent instead of index, then use indexToObject()
			local componentIndex, childrenPath = MoreRealisticDLCs.nodeIndexToPath(nodeData.index);
			local component = getChildAt(i3dNode, componentIndex);
			local nodeParent = component;
			local validNodeParent = nodeParent ~= nil and nodeParent ~= 0;
			if not validNodeParent then break; end;
			if childrenPath and #childrenPath > 1 then
				for j,childIndex in ipairs(childrenPath) do
					if j < #childrenPath then
						nodeParent = getChildAt(nodeParent, childIndex);
						if not nodeParent or nodeParent == 0 then
							validNodeParent = false;
							break;
						end;
					end;
				end;
			end;
			if not validNodeParent then break; end;

			local node = createTransformGroup('extraNode_' .. i);
			link(nodeParent, node);
			if self.moreRealisticDLCdebug then
				print(('\t\tnode %q created -> id = %d'):format(tostring(nodeData.name), node));
			end;

			MoreRealisticDLCs.setNodeProperties(node, nodeData.name, nodeData.translation, nodeData.rotation, nodeData.scale);
		end;
	end;
end;

-- SET NODE PROPERTIES
function MoreRealisticDLCs.setNodesProperties(self, i3dNode, arguments)
	local nodeProperties = arguments[10];
	if nodeProperties and next(nodeProperties) then
		for i,nodeData in ipairs(nodeProperties) do
			local node = Utils.indexToObject(self.components, nodeData.index);
			if not node or node == 0 then break; end;

			MoreRealisticDLCs.setNodeProperties(node, nodeData.name, nodeData.translation, nodeData.rotation, nodeData.scale);
		end;
	end;
end;

-- ANGULAR + LINEAR DAMPING
function MoreRealisticDLCs.setMoreRealisticDamping(self, i3dNode, arguments)
	if not self.isMoreRealisticDLC then return; end;

	for i,comp in ipairs(self.components) do
		setAngularDamping(comp.node, 0);
		setLinearDamping(comp.node, 0);
		if self.moreRealisticDLCdebug then
			print(('%s: loadFinished(): component %d (%d/%q): angularDamping set to %s, linearDamping set to %s'):format(tostring(self.name), i, comp.node, tostring(getName(comp.node)), tostring(getAngularDamping(comp.node)), tostring(getLinearDamping(comp.node))));
		end;
	end;
end;

-- DEBUG PRINT WHEELS POSITION
function MoreRealisticDLCs.debugPrintWheelsPosition(self, i3dNode, arguments)
	if not self.isMoreRealisticDLC or not self.wheels or not self.moreRealisticDLCdebug then return; end;

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

-- BALES
function MoreRealisticDLCs.setBaleMrData(self, nodeId)
	if self.i3dFilename and self.i3dFilename:find('pdlc/ursusAddon') then
		setAngularDamping(self.nodeId, 0);
		setLinearDamping(self.nodeId, 0);
		setUserAttribute(self.nodeId, 'isRealistic', 'Boolean', true);
		setUserAttribute(self.nodeId, 'baleValueScale', 'Float', 1.6);
	end;
end;

-- RELOAD FROM XML
local origVehicleDevelopmentReloadFromXML = Vehicle.developmentReloadFromXML;
function MoreRealisticDLCs.developmentReloadFromXML(self)
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
	local mrData = MoreRealisticDLCs.vehicleData[self.configFileNameShort];
	if mrData then
		print('\tsetMrData()');
		MoreRealisticDLCs:setMrData(self, xmlFile, mrData);
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

