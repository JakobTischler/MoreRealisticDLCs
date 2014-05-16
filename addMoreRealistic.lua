--
--MoreRealisticDLCs
--
--@authors: modelleicher, Jakob Tischler, Satissis
--@version: 0.1b
--


-- ABORT IF MOREREALISTIC NOT INSTALLED
if not RealisticUtils then
	print('MoreRealisticDLCs: you don\'t have MoreRealistic installed. Script will now be aborted!');
	return;
end;

-- ABORT IF TOO LOW MOREREALISTIC VERSION NUMBER
local mrModItem = ModsUtil.findModItemByModName(RealisticUtils.modName);
if mrModItem and mrModItem.version then
	local version = tonumber(mrModItem.version:sub(1, 3));
	if version < 1.3 then
		print(('MoreRealisticDLCs: your MoreRealistic version (%s) is too low. Install v1.3 or higher. Script will now be aborted!'):format(mrModItem.version));
		return;
	end;
end;

-- ##################################################

local modDir, modName = g_currentModDirectory, g_currentModName;

local dlcTest = {
	Lindner    = { '/lindnerUnitracPack/lindner/lindnerUnitrac92.xml', 'vehicleDataLindner.xml' },
	Titanium   = { '/titaniumAddon/lizard/americanTruck.xml', 		   'vehicleDataTitanium.xml' },
	Ursus	   = { '/ursusAddon/ursus/ursus15014.xml', 				   'vehicleDataUrsus.xml' },
	Vaederstad = { '/vaderstadPack/vaderstad/vaderstadTopDown500.xml', 'vehicleDataVaederstad.xml' }
};

-- ##################################################

-- REGISTER CUSTOM SPECIALIZATIONS
local customSpecsRegistered = false;
local registerCustomSpecs = function()
	print('MoreRealisticDLCs registerCustomSpecs()');
	local modDesc = loadXMLFile('modDesc', Utils.getFilename('modDesc.xml', modDir));
	local specsKey = 'modDesc.customSpecializations';
	local numCustomSpecs = getXMLInt(modDesc, specsKey .. '#num') or 0;
	if numCustomSpecs > 0 then
		for i=0, numCustomSpecs-1 do
			local key = ('%s.specialization(%d)'):format(specsKey, i);
			local specName = getXMLString(modDesc, key .. '#name');
			local className = getXMLString(modDesc, key .. '#className');
			local fileName = getXMLString(modDesc, key .. '#filename');
			if specName and className and fileName then
				specName = modName .. '.' .. specName;
				className = modName .. '.' .. className;
				fileName = Utils.getFilename(fileName, modDir);
				print(('\tregisterSpecialization(): specName=%q, className=%q, fileName=%q'):format(specName, className, fileName));
				SpecializationUtil.registerSpecialization(specName, className, fileName, modName);
			end;
		end;
	end;
	delete(modDesc);
	customSpecsRegistered = true;
end;

-- ##################################################

-- REGISTER CUSTOM VEHICLE TYPES
local vehicleTypesPath = Utils.getFilename('vehicleTypes.xml', modDir);
assert(fileExists(vehicleTypesPath), ('ERROR: %q could not be found'):format(vehicleTypesPath));
local vehicleTypesFile = loadXMLFile('vehicleTypesFile', vehicleTypesPath);
local registerVehicleTypes = function(dlcName)
	print(('registerVehicleTypes(%q)'):format(dlcName));

	local i = 0
	while true do
		local key = ('vehicleTypes.%s.type(%d)'):format(dlcName, i);
		local typeName = getXMLString(vehicleTypesFile, key .. '#name');
		if typeName == nil then break; end;

		typeName = modName .. '.' .. typeName;
		local className = getXMLString(vehicleTypesFile, key .. '#className');
		local fileName = getXMLString(vehicleTypesFile, key .. '#filename');
		print(('\t%s\n\ttypeName=%q, className=%q, fileName=%q'):format(('-'):rep(50), typeName, tostring(className), tostring(fileName)));
		if className and fileName then
			fileName = Utils.getFilename(fileName, modDir);
			local specializationNames, j = {}, 0;
			while true do
				local specName = getXMLString(vehicleTypesFile, ('%s.specialization(%d)#name'):format(key, j));
				if specName == nil then break; end;
				if SpecializationUtil.specializations[specName] == nil then
					specName = modName .. '.' .. specName;
				end;
				if SpecializationUtil.specializations[specName] == nil then
					print(('\t\tspecName=%q: spec could not be found!'):format(tostring(specName)));
				else
					specializationNames[#specializationNames + 1] = specName;
				end;
				j = j + 1;
			end;
			print(('\t\tspecializationNames=%s'):format(table.concat(specializationNames, ', ')));
			print(('\tcall registerVehicleType(%q, %q, %q, %s, %q)'):format(tostring(typeName), tostring(className), tostring(fileName), tostring(specializationNames), tostring(customEnvironment)));
			VehicleTypeUtil.registerVehicleType(typeName, className, fileName, specializationNames, customEnvironment);
		end;
		i = i + 1;
	end;
end;

-- ##################################################

-- SET VEHICLE STORE DATA
local setStoreData = function(configFileNameShort, dlcName, storeData)
	print(('MoreRealisticDLCs: setStoreData(%q, %q, ...)'):format(configFileNameShort, dlcName));
	local dlcDir = dlcTest[dlcName][3];
	local path = Utils.getFilename('/' .. configFileNameShort:sub(6, 200), dlcDir);
	local storeItem = StoreItemsUtil.storeItemsByXMLFilename[path:lower()];
	-- print(('\tdlcDir=%q'):format(tostring(dlcDir)));
	-- print(('\tpath=%q'):format(tostring(path)));
	if storeItem then
		if not storeItem.nameMRized then
			storeItem.name = 'MR ' .. storeItem.name;
			storeItem.nameMRized = true;
			print(('\tchange store name to %s'):format(storeItem.name));
		end;
		if storeData.price and not storeItem.priceMRized then
			print(('\tchange store price to %d (old: %d)'):format(storeData.price, storeItem.price));
			storeItem.price = storeData.price;
			storeItem.priceMRized = true;
		end;
		if storeData.dailyUpkeep and not storeItem.dailyUpkeepMRized then
			print(('\tchange store dailyUpkeep to %d (old: %d)'):format(storeData.dailyUpkeep, storeItem.dailyUpkeep));
			storeItem.dailyUpkeep = storeData.dailyUpkeep;
			storeItem.dailyUpkeepMRized = true;
		end;
	end;
end;

-- ##################################################

-- GET VEHICLE MR DATA
local vehicleData = {};
local getMoreRealisticData = function(vehicleDataPath, dlcName)
	registerVehicleTypes(dlcName);

	assert(fileExists(vehicleDataPath), ('ERROR: %q could not be found'):format(vehicleDataPath));
	local xmlFile = loadXMLFile('vehicleDataFile', vehicleDataPath);

	local i = 0;
	while true do
		local key = ('vehicles.vehicle(%d)'):format(i);
		if not hasXMLProperty(xmlFile, key) then break; end;

		-- base
		local configFileName = getXMLString(xmlFile, key .. '#configFileName');
		assert(configFileName, ('ERROR: "configFileName" missing for %q'):format(key));
		local vehicleType = getXMLString(xmlFile, key .. '#mrVehicleType');
		assert(vehicleType, ('ERROR: "mrVehicleType" missing for %q'):format(configFileName));
		local category = getXMLString(xmlFile, key .. '#category');
		assert(category, ('ERROR: "category" missing for %q'):format(configFileName));
		local subCategory = getXMLString(xmlFile, key .. '#subCategory') or '';
		local doDebug = getXMLBool(xmlFile, key .. '#debug');
		local store = {
			price = getXMLInt(xmlFile, key .. '#price');
			dailyUpkeep = getXMLInt(xmlFile, key .. '#dailyUpkeep');
		};
		setStoreData(configFileName, dlcName, store);

		-- engine
		local engine = {
			kW 									= getXMLFloat(xmlFile, key .. '.engine#kW') or 100;
			realMaxVehicleSpeed 				= getXMLFloat(xmlFile, key .. '.engine#realMaxVehicleSpeed') or 50;
			realMaxReverseSpeed 				= getXMLFloat(xmlFile, key .. '.engine#realMaxReverseSpeed') or 20;
			realMaxFuelUsage 					= getXMLFloat(xmlFile, key .. '.engine#realMaxFuelUsage');
			realSpeedBoost 						= getXMLFloat(xmlFile, key .. '.engine#realSpeedBoost');
			realSpeedBoostMinSpeed 				= getXMLFloat(xmlFile, key .. '.engine#realSpeedBoostMinSpeed');
			realImplementNeedsBoost 			= getXMLFloat(xmlFile, key .. '.engine#realImplementNeedsBoost');
			realImplementNeedsBoostMinPowerCons = getXMLFloat(xmlFile, key .. '.engine#realImplementNeedsBoostMinPowerCons');
			realMaxBoost 						= getXMLFloat(xmlFile, key .. '.engine#realMaxBoost');
			realTransmissionEfficiency 			= getXMLFloat(xmlFile, key .. '.engine#realTransmissionEfficiency');
			realPtoDriveEfficiency				= getXMLFloat(xmlFile, key .. '.engine#realPtoDriveEfficiency') or 0.92;
		};
		engine.realPtoPowerKW 					= getXMLFloat(xmlFile, key .. '.engine#realPtoPowerKW') or engine.kW * engine.realPtoDriveEfficiency;

		local realBrakingDeceleration = getXMLFloat(xmlFile, key .. '.engine#realBrakingDeceleration') or 4;
		local fuelCapacity = getXMLFloat(xmlFile, key .. '.engine#fuelCapacity');


		-- dimensions
		local width  = getXMLFloat(xmlFile, key .. '.dimensions#width') or 3;
		assert(width, ('ERROR: "dimensions#width" missing for %q'):format(configFileName));
		local height = getXMLFloat(xmlFile, key .. '.dimensions#height') or 3;
		assert(height, ('ERROR: "dimensions#height" missing for %q'):format(configFileName));


		-- weights
		local weights = {};
		weights.weight					= getXMLFloat(xmlFile, key .. '.weights#weight');
		assert(weights.weight, ('ERROR: "weights#weight" missing for %q'):format(configFileName));
		weights.maxWeight				= getXMLFloat(xmlFile, key .. '.weights#maxWeight') or weights.weight * 1.55;
		weights.realBrakeMaxMovingMass	= getXMLFloat(xmlFile, key .. '.weights#realBrakeMaxMovingMass') or weights.maxWeight * 1.5;


		-- wheels
		local realNoSteeringAxleDamping = getXMLBool(xmlFile, key .. '.wheels#realNoSteeringAxleDamping');
		local wheels = {};
		local w = 0;
		while true do
			local wheelKey = key .. ('.wheels.wheel(%d)'):format(w);
			if not hasXMLProperty(xmlFile, wheelKey) then break; end;

			wheels[#wheels + 1] = {
				driveMode  =   getXMLInt(xmlFile, wheelKey .. '#driveMode'), 
				rotMax     = getXMLFloat(xmlFile, wheelKey .. '#rotMax'),
				rotMin     = getXMLFloat(xmlFile, wheelKey .. '#rotMin'),
				rotSpeed   = getXMLFloat(xmlFile, wheelKey .. '#rotSpeed'),
				radius     = getXMLFloat(xmlFile, wheelKey .. '#radius'),
				deltaY     = getXMLFloat(xmlFile, wheelKey .. '#deltaY'),
				suspTravel = getXMLFloat(xmlFile, wheelKey .. '#suspTravel'),
				spring     = getXMLFloat(xmlFile, wheelKey .. '#spring'),
				damper     =   getXMLInt(xmlFile, wheelKey .. '#damper') or 20,
				brakeRatio =   getXMLInt(xmlFile, wheelKey .. '#brakeRatio') or 1
			};

			w = w + 1;
		end;


		-- attacherJoints
		local attacherJoints = {};
		local a = 0;
		while true do
			local ajKey = key .. ('.attacherJoints.attacherJoint(%d)'):format(a);
			if not hasXMLProperty(xmlFile, ajKey) then break; end;

			local ajData = {};
			local jointType = getXMLString(xmlFile, ajKey .. '#jointType');
			if jointType and jointType == 'implement' or jointType == 'cutter' then
				ajData.jointType = jointType;
				ajData.maxRot				  = getXMLString(xmlFile, ajKey .. '#maxRot');
				ajData.maxRot2				  = getXMLString(xmlFile, ajKey .. '#maxRot2'); --TODO: always maxRot * -1 ?
				ajData.maxRotDistanceToGround =  getXMLFloat(xmlFile, ajKey .. '#maxRotDistanceToGround');
				ajData.minRotDistanceToGround =  getXMLFloat(xmlFile, ajKey .. '#minRotDistanceToGround');

				-- cutter attacher joint
				ajData.lowerDistanceToGround 	 =  getXMLFloat(xmlFile, ajKey .. '#lowerDistanceToGround');
				ajData.realWantedLoweredRotLimit = getXMLString(xmlFile, ajKey .. '#realWantedLoweredRotLimit');
				ajData.realWantedRaisedRotLimit  = getXMLString(xmlFile, ajKey .. '#realWantedRaisedRotLimit');
				ajData.realWantedLoweredRot2 	 =  getXMLFloat(xmlFile, ajKey .. '#realWantedLoweredRot2');
				ajData.realWantedRaisedRotInc 	 =  getXMLFloat(xmlFile, ajKey .. '#realWantedRaisedRotInc');
			end;

			attacherJoints[#attacherJoints + 1] = ajData;

			a = a + 1;
		end;


		-- components
		local components = {};
		local c = 1;
		while true do
			local compKey = key .. ('.components.component%d'):format(c);
			if not hasXMLProperty(xmlFile, compKey) then break; end;

			components[#components + 1] = {
				centerOfMass = getXMLString(xmlFile, compKey .. '#centerOfMass'),
				realMassWanted = getXMLFloat(xmlFile, compKey .. '#realMassWanted'),
				realTransWithMass = getXMLString(xmlFile, compKey .. '#realTransWithMass'),
				realTransWithMassMax = getXMLString(xmlFile, compKey .. '#realTransWithMassMax')
			};

			c = c + 1;
		end;


		-- workTool
		local workTool = {
			realPowerConsumption 					= getXMLFloat(xmlFile, key .. '.workTool#realPowerConsumption');
			realPowerConsumptionWhenWorking			= getXMLFloat(xmlFile, key .. '.workTool#realPowerConsumptionWhenWorking');
			realPowerConsumptionWhenWorkingInc		= getXMLFloat(xmlFile, key .. '.workTool#realPowerConsumptionWhenWorkingInc');
			realWorkingPowerConsumption				= getXMLFloat(xmlFile, key .. '.workTool#realWorkingPowerConsumption');
			realOverloaderUnloadingPowerConsumption = getXMLFloat(xmlFile, key .. '.workTool#realOverloaderUnloadingPowerConsumption');
			realWorkingSpeedLimit 					= getXMLFloat(xmlFile, key .. '.workTool#realWorkingSpeedLimit');
			realRollingResistance					= getXMLFloat(xmlFile, key .. '.workTool#realRollingResistance') or 0;
			realResistanceOnlyWhenActive			= Utils.getNoNil(getXMLBool(xmlFile, key .. '.workTool#realResistanceOnlyWhenActive'), false);
			resistanceDecreaseFx 					= getXMLFloat(xmlFile, key .. '.workTool#resistanceDecreaseFx');
			caRealTractionResistance				= getXMLFloat(xmlFile, key .. '.workTool#caRealTractionResistance');
			caRealTractionResistanceWithLoadMass	= getXMLFloat(xmlFile, key .. '.workTool#caRealTractionResistanceWithLoadMass') or 0;

			-- cutter
			realCutterPowerConsumption	  = getXMLFloat(xmlFile, key .. '.workTool#realCutterPowerConsumption') or 25;
			realCutterPowerConsumptionInc = getXMLFloat(xmlFile, key .. '.workTool#realCutterPowerConsumptionInc') or 2.5;
			realCutterSpeedLimit		  = getXMLFloat(xmlFile, key .. '.workTool#realCutterSpeedLimit') or 14;

			-- windrower
			realRakeWorkingPowerConsumption    = getXMLFloat(xmlFile, key .. '.workTool#realRakeWorkingPowerConsumption');
			realRakeWorkingPowerConsumptionInc = getXMLFloat(xmlFile, key .. '.workTool#realRakeWorkingPowerConsumptionInc');
		};


		-- combine
		local combine = {
			realSpeedLevel					 = getXMLString(xmlFile, key .. '.combine#realSpeedLevel') or '5 6 9';
			baseSpeed 						 =  getXMLFloat(xmlFile, key .. '.combine#baseSpeed') or 5;
			minSpeed 						 =  getXMLFloat(xmlFile, key .. '.combine#minSpeed') or 3;
			maxSpeed 						 =  getXMLFloat(xmlFile, key .. '.combine#maxSpeed') or 12;
			realAiMinDistanceBeforeTurning 	 =  getXMLFloat(xmlFile, key .. '.combine#realAiMinDistanceBeforeTurning');
			realAiManeuverSpeed 			 =  getXMLFloat(xmlFile, key .. '.combine#realAiManeuverSpeed');
			realMaxPowerToTransmission 		 =  getXMLFloat(xmlFile, key .. '.combine#realMaxPowerToTransmission');
			realHydrostaticTransmission 	 =   getXMLBool(xmlFile, key .. '.combine#realHydrostaticTransmission');
			realUnloadingPowerBoost 		 =  getXMLFloat(xmlFile, key .. '.combine#realUnloadingPowerBoost');
			realUnloadingPowerConsumption 	 =  getXMLFloat(xmlFile, key .. '.combine#realUnloadingPowerConsumption');
			realThreshingPowerConsumption 	 =  getXMLFloat(xmlFile, key .. '.combine#realThreshingPowerConsumption');
			realThreshingPowerConsumptionInc =  getXMLFloat(xmlFile, key .. '.combine#realThreshingPowerConsumptionInc');
			realChopperPowerConsumption 	 =  getXMLFloat(xmlFile, key .. '.combine#realChopperPowerConsumption');
			realChopperPowerConsumptionInc 	 =  getXMLFloat(xmlFile, key .. '.combine#realChopperPowerConsumptionInc');
			realThreshingScale 				 =  getXMLFloat(xmlFile, key .. '.combine#realThreshingScale');
		};

		--------------------------------------------------

		vehicleData[configFileName] = {
			category = category,
			subCategory = subCategory,
			configFileName = configFileName,
			vehicleType = Utils.startsWith(vehicleType, 'mr_') and modName .. '.' .. vehicleType or vehicleType,
			doDebug = doDebug,
			engine = engine,
			realBrakingDeceleration = realBrakingDeceleration,
			fuelCapacity = fuelCapacity,
			width = width,
			height = height,
			weights = weights,
			wheels = wheels,
			realNoSteeringAxleDamping = realNoSteeringAxleDamping,
			attacherJoints = attacherJoints,
			workTool = workTool,
			combine = combine,
			components = components
		};

		--------------------------------------------------

		i = i + 1;
	end;

	delete(xmlFile);
end;

-- ##################################################

-- CHECK WHICH DLCs ARE INSTALLED -> only get MR data for installed ones
local dlcExists = false;
for name, data in pairs(dlcTest) do
	for _, dir in ipairs(g_dlcsDirectories) do
		if dir.isLoaded then
			local path = Utils.getFilename(data[1], dir.path);
			if fileExists(path) then
				if not customSpecsRegistered then
					registerCustomSpecs();
				end;
				data[3] = dir.path;
				local vehicleDataPath = Utils.getFilename(data[2], modDir);
				print(('MoreRealisticDLCs: %q DLC exists -> call getMoreRealisticData(%q)'):format(name, vehicleDataPath));
				getMoreRealisticData(vehicleDataPath, name);
				dlcExists = true;
				break;
			end;
		end;
	end;
end;
delete(vehicleTypesFile);

-- ABORT IF THERE ARE NO DLCs
if not dlcExists then
	print('MoreRealisticDLCs: you don\'t have any DLCs installed. Script will now be aborted!');
	return;
end;

-- ##################################################

local mrData;

local prmSetXMLFn = {
	bool = setXMLBool,
	flt = setXMLFloat,
	int = setXMLInt,
	str = setXMLString
};
local setValue = function(xmlFile, parameter, prmType, value)
	if value == nil then return; end;

	prmSetXMLFn[prmType](xmlFile, parameter, value);
	if mrData and mrData.doDebug then
		print(('\tset parameter %q (type %s) to %q'):format(parameter, prmType, tostring(value)));
	end;
end;

local removeProperty = function(xmlFile, property)
	if getXMLString(xmlFile, property) ~= nil or hasXMLProperty(xmlFile, property) then
		removeXMLProperty(xmlFile, property);
		if mrData and mrData.doDebug then
			print(('\tremove property %q'):format(tostring(property)));
		end;
	end;
end;

-- ##################################################

local origVehicleLoad = Vehicle.load;
Vehicle.load = function(self, configFile, positionX, offsetY, positionZ, yRot, typeName, isVehicleSaved, asyncCallbackFunction, asyncCallbackObject, asyncCallbackArguments)
	local vehicleModName, baseDirectory = Utils.getModNameAndBaseDirectory(configFile);
 	self.configFileName = configFile;
	self.baseDirectory = baseDirectory;
	self.customEnvironment = vehicleModName;
	self.typeName = typeName;

	-- 
	local addMrData = false;
	local cfnStart, _ = configFile:find('/pdlc/');
	if cfnStart then
		print(('load(): typeName=%q, configFileName=%q'):format(tostring(self.typeName), tostring(self.configFileName)));
		-- print(('\tmodName=%q, baseDirectory=%q'):format(tostring(vehicleModName), tostring(baseDirectory)));
		local cfnShort = configFile:sub(cfnStart + 1, 1000);
		mrData = vehicleData[cfnShort];
		if mrData then
			self.typeName = mrData.vehicleType;
			self.isMoreRealisticDLC = true;
			addMrData = true;
			print(('\tVehicleType changed to: %q'):format(tostring(self.typeName)));
		end;
	end;
	--

	self.isVehicleSaved = Utils.getNoNil(isVehicleSaved, true);

	local typeDef = VehicleTypeUtil.vehicleTypes[self.typeName];
	self.specializations = typeDef.specializations;

	local xmlFile = loadXMLFile('TempConfig', configFile);



	if addMrData then
		removeProperty(xmlFile, 'vehicle.motor');


		-- relevant MR values
		setValue(xmlFile, 'vehicle.bunkerSiloCompactor#compactingScale',  'flt', mrData.weights.weight * 0.25);
		setValue(xmlFile, 'vehicle.realMaxVehicleSpeed', 				  'flt', mrData.engine.realMaxVehicleSpeed);
		setValue(xmlFile, 'vehicle.realMaxReverseSpeed', 				  'flt', mrData.engine.realMaxReverseSpeed);
		setValue(xmlFile, 'vehicle.realBrakeMaxMovingMass', 			  'flt', mrData.weights.realBrakeMaxMovingMass);
		setValue(xmlFile, 'vehicle.realBrakingDeceleration', 			  'flt', mrData.realBrakingDeceleration);
		setValue(xmlFile, 'vehicle.realSCX', 							  'flt', mrData.width * mrData.height * 0.68);


		if mrData.category == 'steerable' then
			-- accelerationSpeed
			setValue(xmlFile, 'vehicle.accelerationSpeed#maxAcceleration',	'int', 1);
			setValue(xmlFile, 'vehicle.accelerationSpeed#deceleration',		'int', 1);
			setValue(xmlFile, 'vehicle.accelerationSpeed#brakeSpeed',		'int', 3);
			removeProperty(xmlFile, 'vehicle.accelerationSpeed#backwardDeceleration');

			-- fuel usage, downforce
			setValue(xmlFile, 'vehicle.fuelUsage', 'int', 0);
			setValue(xmlFile, 'vehicle.downForce', 'int', 0);

			setValue(xmlFile, 'vehicle.realSpeedBoost',						  'int',  mrData.engine.realSpeedBoost);
			setValue(xmlFile, 'vehicle.realSpeedBoost#minSpeed', 			  'int',  mrData.engine.realSpeedBoostMinSpeed);
			setValue(xmlFile, 'vehicle.realImplementNeedsBoost',			  'int',  mrData.engine.realImplementNeedsBoost);
			setValue(xmlFile, 'vehicle.realImplementNeedsBoost#minPowerCons', 'int',  mrData.engine.realImplementNeedsBoostMinPowerCons);
			setValue(xmlFile, 'vehicle.realMaxBoost', 						  'int',  mrData.engine.realMaxBoost);
			setValue(xmlFile, 'vehicle.realPtoPowerKW',						  'flt',  mrData.engine.realPtoPowerKW);
			setValue(xmlFile, 'vehicle.realPtoDriveEfficiency',				  'flt',  mrData.engine.realPtoDriveEfficiency);
			setValue(xmlFile, 'vehicle.realMaxFuelUsage',					  'flt',  mrData.engine.realMaxFuelUsage);
			setValue(xmlFile, 'vehicle.realTransmissionEfficiency', 		  'flt',  mrData.engine.realTransmissionEfficiency);

			setValue(xmlFile, 'vehicle.realDisplaySlip',					  'bool', true);
			setValue(xmlFile, 'vehicle.fuelCapacity',						  'int',  mrData.fuelCapacity);

			-- combine
			if mrData.subCategory == 'combine' then
				setValue(xmlFile, 'vehicle.realSpeedLevel', 				  'str',  mrData.combine.realSpeedLevel);
				setValue(xmlFile, 'vehicle.realAiWorkingSpeed#baseSpeed', 	  'int',  mrData.combine.baseSpeed);
				setValue(xmlFile, 'vehicle.realAiWorkingSpeed#minSpeed', 	  'int',  mrData.combine.minSpeed);
				setValue(xmlFile, 'vehicle.realAiWorkingSpeed#maxSpeed', 	  'int',  mrData.combine.maxSpeed);

				setValue(xmlFile, 'vehicle.realAiMinDistanceBeforeTurning',   'flt',  mrData.combine.realAiMinDistanceBeforeTurning);
				setValue(xmlFile, 'vehicle.realAiManeuverSpeed', 			  'flt',  mrData.combine.realAiManeuverSpeed);
				setValue(xmlFile, 'vehicle.realMaxPowerToTransmission', 	  'flt',  mrData.combine.realMaxPowerToTransmission);
				setValue(xmlFile, 'vehicle.realHydrostaticTransmission', 	  'bool', mrData.combine.realHydrostaticTransmission);
				setValue(xmlFile, 'vehicle.realUnloadingPowerBoost', 		  'flt',  mrData.combine.realUnloadingPowerBoost);
				setValue(xmlFile, 'vehicle.realUnloadingPowerConsumption', 	  'flt',  mrData.combine.realUnloadingPowerConsumption);
				setValue(xmlFile, 'vehicle.realThreshingPowerConsumption', 	  'flt',  mrData.combine.realThreshingPowerConsumption);
				setValue(xmlFile, 'vehicle.realThreshingPowerConsumptionInc', 'flt',  mrData.combine.realThreshingPowerConsumptionInc);
				setValue(xmlFile, 'vehicle.realChopperPowerConsumption', 	  'flt',  mrData.combine.realChopperPowerConsumption);
				setValue(xmlFile, 'vehicle.realChopperPowerConsumptionInc',   'flt',  mrData.combine.realChopperPowerConsumptionInc);
				setValue(xmlFile, 'vehicle.realThreshingScale', 			  'flt',  mrData.combine.realThreshingScale);
			end;
		end;


		-- wheels
		setValue(xmlFile, 'vehicle.steeringAxleAngleScale#realNoSteeringAxleDamping',  'bool', mrData.realNoSteeringAxleDamping);
		local wheelI = 0;
		while true do
			local wheelKey = ('vehicle.wheels.wheel(%d)'):format(wheelI);
			local repr = getXMLString(xmlFile, wheelKey .. '#repr');
			if not repr or repr == '' then break; end;
			if wheelI == 0 then
				setValue(xmlFile, 'vehicle.wheels#autoRotateBackSpeed', 'flt', 1);
			end;
			print('wheels: ' .. wheelI);

			local wheelMrData = mrData.wheels[wheelI + 1];

			removeProperty(xmlFile, wheelKey .. '#lateralStiffness');
			removeProperty(xmlFile, wheelKey .. '#longitudalStiffness');
			setValue(xmlFile, wheelKey .. '#driveMode',  'int', wheelMrData.driveMode);
			setValue(xmlFile, wheelKey .. '#rotMax',     'flt', wheelMrData.rotMax);
			setValue(xmlFile, wheelKey .. '#rotMin',     'flt', wheelMrData.rotMin);
			setValue(xmlFile, wheelKey .. '#rotSpeed',   'flt', wheelMrData.rotSpeed);
			setValue(xmlFile, wheelKey .. '#radius',     'flt', wheelMrData.radius);
			setValue(xmlFile, wheelKey .. '#brakeRatio', 'int', wheelMrData.brakeRatio);
			setValue(xmlFile, wheelKey .. '#damper',     'int', wheelMrData.damper);
			setValue(xmlFile, wheelKey .. '#mass',       'int', 1);

			local suspTravel = wheelMrData.suspTravel or getXMLFloat(xmlFile, wheelKey .. '#suspTravel');
			if suspTravel == nil or suspTravel == '' or suspTravel < 0.05 then
				suspTravel = 0.08;
			end;
			setValue(xmlFile, wheelKey .. '#suspTravel', 'flt', suspTravel);

			-- MR 1.2: setValue(xmlFile, wheelKey .. '#spring', 'flt', wheelMrData.spring or 278 * (mrData.weights.maxWeight * 0.25) / (suspTravel * 100 - 2));
			setValue(xmlFile, wheelKey .. '#spring', 'flt', wheelMrData.spring or mrData.weights.maxWeight * 0.25 * 3 / suspTravel); -- TODO: 0.25 -> num of wheels

			local deltaY = wheelMrData.deltaY or getXMLFloat(xmlFile, wheelKey .. '#deltaY');
			if deltaY == nil or deltaY == '' or deltaY == 0 then
				deltaY = suspTravel * 0.9;
			end;
			setValue(xmlFile, wheelKey .. '#deltaY', 'flt', deltaY);

			wheelI = wheelI + 1;
		end;


		-- attacherJoints
		if mrData.category == 'steerable' then
			local a = 0;
			while true do
				local ajKey = ('vehicle.attacherJoints.attacherJoint(%d)'):format(a);
				if not hasXMLProperty(xmlFile, ajKey) then break; end;

				local jointType = getXMLString(xmlFile, ajKey .. '#jointType');
				if jointType and jointType == 'implement' or jointType == 'cutter' then
					removeProperty(xmlFile, ajKey .. '#maxRotLimit');
					removeProperty(xmlFile, ajKey .. '#minRot2');
					removeProperty(xmlFile, ajKey .. '#minRotRotationOffset');
					removeProperty(xmlFile, ajKey .. '#maxRotDistanceToGround');
					removeProperty(xmlFile, ajKey .. '#maxTransLimit');

					local ajMrData = mrData.attacherJoints[a + 1];
					setValue(xmlFile, ajKey .. '#maxRot', 				  'str', ajMrData.maxRot);
					setValue(xmlFile, ajKey .. '#maxRot2', 				  'str', ajMrData.maxRot2);
					setValue(xmlFile, ajKey .. '#minRotDistanceToGround', 'flt', ajMrData.minRotDistanceToGround);
					setValue(xmlFile, ajKey .. '#maxRotDistanceToGround', 'flt', ajMrData.maxRotDistanceToGround);
				end;

				a = a + 1;
			end;

		elseif mrData.category == 'tool' and #mrData.attacherJoints == 1 then
			local ajMrData = mrData.attacherJoints[1];
			removeProperty(xmlFile, 'vehicle.attacherJoint#upperDistanceToGround');
			setValue(xmlFile, 'vehicle.attacherJoint#lowerDistanceToGround',     'flt', ajMrData.lowerDistanceToGround);
			setValue(xmlFile, 'vehicle.attacherJoint#realWantedLoweredRotLimit', 'str', ajMrData.realWantedLoweredRotLimit);
			setValue(xmlFile, 'vehicle.attacherJoint#realWantedRaisedRotLimit',  'str', ajMrData.realWantedRaisedRotLimit);
			setValue(xmlFile, 'vehicle.attacherJoint#realWantedLoweredRot2',     'flt', ajMrData.realWantedLoweredRot2);
			setValue(xmlFile, 'vehicle.attacherJoint#realWantedRaisedRotInc',    'flt', ajMrData.realWantedRaisedRotInc);
		end;


		-- components
		for i=1, getXMLInt(xmlFile, 'vehicle.components#count') do
			local compKey = ('vehicle.components.component%d'):format(i);
			setValue(xmlFile, compKey .. '#centerOfMass',		  'str', mrData.components[i].centerOfMass);
			setValue(xmlFile, compKey .. '#realMassWanted',		  'flt', mrData.components[i].realMassWanted);
			setValue(xmlFile, compKey .. '#realTransWithMass',	  'str', mrData.components[i].realTransWithMass);
			setValue(xmlFile, compKey .. '#realTransWithMassMax', 'str', mrData.components[i].realTransWithMassMax);
		end;


		-- workTool
		if mrData.category == 'tool' then
			-- cutter
			if mrData.subCategory == 'cutter' then
				setValue(xmlFile, 'vehicle.realCutterPowerConsumption', 'flt', mrData.workTool.realCutterPowerConsumption);
				setValue(xmlFile, 'vehicle.realCutterPowerConsumptionInc', 'flt', mrData.workTool.realCutterPowerConsumptionInc);
				setValue(xmlFile, 'vehicle.realCutterSpeedLimit', 'int', mrData.workTool.realCutterSpeedLimit);

			-- others
			else
				setValue(xmlFile, 'vehicle.realPowerConsumption',						'flt',  mrData.workTool.realPowerConsumption);
				setValue(xmlFile, 'vehicle.realWorkingPowerConsumption',				'flt',  mrData.workTool.realWorkingPowerConsumption);
				setValue(xmlFile, 'vehicle.realOverloaderUnloadingPowerConsumption',	'flt',  mrData.workTool.realOverloaderUnloadingPowerConsumption);
				setValue(xmlFile, 'vehicle.realWorkingSpeedLimit',						'flt',  mrData.workTool.realWorkingSpeedLimit);
				setValue(xmlFile, 'vehicle.realRollingResistance',						'flt',  mrData.workTool.realRollingResistance);
				setValue(xmlFile, 'vehicle.realResistanceOnlyWhenActive',				'bool', mrData.workTool.realResistanceOnlyWhenActive);
				setValue(xmlFile, 'vehicle.realTilledGroundBonus#resistanceDecreaseFx', 'flt',  mrData.workTool.resistanceDecreaseFx);

				if mrData.workTool.caRealTractionResistance then
					local caCount = getXMLInt(xmlFile, 'vehicle.cuttingAreas#count');
					local tractionResistancePerCa = mrData.workTool.caRealTractionResistance / caCount;
					local tractionResistanceWithLoadMassPerCa = mrData.workTool.caRealTractionResistanceWithLoadMass / caCount;
					for i=1, caCount do
						local caKey = ('vehicle.cuttingAreas.cuttingArea%d'):format(i);
						setValue(xmlFile, caKey .. '#realTractionResistance', 			  'flt', tractionResistancePerCa);
						setValue(xmlFile, caKey .. '#realTractionResistanceWithLoadMass', 'flt', tractionResistanceWithLoadMassPerCa);
					end;
				end;

				-- windrower
				setValue(xmlFile, 'vehicle.realRakeWorkingPowerConsumption',    'flt',  mrData.workTool.realRakeWorkingPowerConsumption);
				setValue(xmlFile, 'vehicle.realRakeWorkingPowerConsumptionInc', 'flt',  mrData.workTool.realRakeWorkingPowerConsumptionInc);
			end;
		end;
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
end;

local setMoreRealisticDamping = function(self, i3dNode, arguments)
	if self.isMoreRealisticDLC then
		for i,comp in ipairs(self.components) do
			setAngularDamping(comp.node, 0);
			setLinearDamping(comp.node, 0);
			print(('%s: loadFinished(): component %d (%d/%q): angularDamping set to %s, linearDamping set to %s'):format(tostring(self.name), i, comp.node, tostring(getName(comp.node)), tostring(getAngularDamping(comp.node)), tostring(getLinearDamping(comp.node))));
		end;
	end;
end;
Vehicle.loadFinished = Utils.appendedFunction(Vehicle.loadFinished, setMoreRealisticDamping);