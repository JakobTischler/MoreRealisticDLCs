--
--MoreRealisticDLCs
--
--@authors: modelleicher, Jakob Tischler, Satis
--@contributors: dj, dural, Grisu118, Xentro
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

local dlcs = {
	Lindner    = { dlcName = 'lindnerUnitracPack',	dataFile = 'vehicleDataLindner.xml',	minVersionStr = '1.0.0.1', minVersionFlt = 1.001 },
	Marshall   = { dlcName = 'marshallPack',		dataFile = 'vehicleDataMarshall.xml',	minVersionStr = '1.0.0.3', minVersionFlt = 1.003 },
	Titanium   = { dlcName = 'titaniumAddon',		dataFile = 'vehicleDataTitanium.xml',	minVersionStr = '1.0.0.5', minVersionFlt = 1.005 },
	Ursus	   = { dlcName = 'ursusAddon',		 	dataFile = 'vehicleDataUrsus.xml',		minVersionStr = '2.0.0.2', minVersionFlt = 2.002 },
	Vaederstad = { dlcName = 'vaderstadPack',		dataFile = 'vehicleDataVaederstad.xml',	minVersionStr = '1.0.0.3', minVersionFlt = 1.003 }
};

-- ##################################################

-- REGISTER CUSTOM SPECIALIZATIONS
local customSpecsRegistered = false;
local registerCustomSpecs = function()
	print('MoreRealisticDLCs: registerCustomSpecs()');
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
				print(('\tregisterSpecialization(): %s'):format(className));
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
	-- print(('MoreRealisticDLCs: registerVehicleTypes(%q)'):format(dlcName));

	local i = 0
	while true do
		local key = ('vehicleTypes.%s.type(%d)'):format(dlcName, i);
		local typeName = getXMLString(vehicleTypesFile, key .. '#name');
		if typeName == nil then break; end;

		typeName = modName .. '.' .. typeName;
		local className = getXMLString(vehicleTypesFile, key .. '#className');
		local fileName = getXMLString(vehicleTypesFile, key .. '#filename');
		-- print(('\t%s\n\ttypeName=%q, className=%q, fileName=%q'):format(('-'):rep(50), typeName, tostring(className), tostring(fileName)));
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

local numberSeparators = {
	cz = { '.', ',' },
	de = { '.', ',' },
	en = { ',', '.' },
	es = { '.', ',' },
	fr = { '.', ',' },
	hu = { '.', ',' },
	it = { '.', ',' },
	jp = { ',', '.' },
	nl = { '.', ',' },
	pl = { '.', ',' },
	ru = { '.', ',' }
};
local numberSeparator, numberDecimalSeparator = '.', ',';
if g_languageShort and numberSeparators[g_languageShort] then
	numberSeparator		   = numberSeparators[g_languageShort][1];
	numberDecimalSeparator = numberSeparators[g_languageShort][2];
end;
local formatNumber = function(number, precision)
	precision = precision or 0;

	local str = '';
	local firstDigit, rest, decimal = ('%1.' .. precision .. 'f'):format(number):match('^([^%d]*%d)(%d*).?(%d*)');
	str = firstDigit .. rest:reverse():gsub('(%d%d%d)', '%1' .. numberSeparator):reverse();
	if precision > 0 and decimal:len() > 0 then
		decimal = decimal:sub(1, precision);
		if tonumber(decimal) ~= 0 then
			str = str .. numberDecimalSeparator .. decimal:sub(1, precision);
		end;
	end;
	return str;
end;

-- SET VEHICLE STORE DATA
local setStoreData = function(configFileNameShort, dlcName, storeData, doDebug)
	if doDebug then print(('MoreRealisticDLCs: setStoreData(%q, %q, ...)'):format(configFileNameShort, dlcName)); end;
	local pdlcDir = dlcs[dlcName].containingDir;
	local path = Utils.getFilename(configFileNameShort:sub(6, 200), pdlcDir);
	local storeItem = StoreItemsUtil.storeItemsByXMLFilename[path:lower()];
	if doDebug then 
		-- print(('\tpdlcDir=%q'):format(tostring(pdlcDir)));
		-- print(('\tpath=%q'):format(tostring(path)));
	end;
	if storeItem then
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
		if not storeItem.descriptionMRized then
			storeItem.description = storeItem.description .. '\n\n' .. tostring(g_i18n:getText('DLC_MRIZED'));
			storeItem.descriptionMRized = true;
		end;
		if not storeItem.specsMRized then
			local specs = '';
			if storeData.powerKW then
				specs = specs .. g_i18n:getText('STORE_SPECS_MAXPOWER') .. ' ' .. g_i18n:getText('STORE_SPECS_POWER'):format(storeData.powerKW, storeData.powerKW * 1.35962162) .. '\n';
			end;
			if storeData.maxSpeed then
				specs = specs .. g_i18n:getText('STORE_SPECS_MAXSPEED'):format(formatNumber(g_i18n:getSpeed(storeData.maxSpeed), 1), g_i18n:getText('speedometer')) .. '\n';
			end;
			if storeData.requiredPowerKwMin then
				specs = specs .. g_i18n:getText('STORE_SPECS_POWERREQUIRED') .. ' ' .. g_i18n:getText('STORE_SPECS_POWER_HP'):format(storeData.requiredPowerKwMin * 1.35962162);
				if storeData.requiredPowerKwMax then
					specs = specs .. ' - ' .. g_i18n:getText('STORE_SPECS_POWER_HP'):format(storeData.requiredPowerKwMax * 1.35962162);
				end;
				specs = specs .. '\n';
			end;
			if storeData.weight then
				specs = specs .. g_i18n:getText('STORE_SPECS_WEIGHT'):format(formatNumber(storeData.weight)) .. '\n';
			end;
			if storeData.workWidth then
				specs = specs .. g_i18n:getText('STORE_SPECS_WORKWIDTH'):format(formatNumber(storeData.workWidth, 1)) .. '\n';
			end;
			if storeData.workSpeedMax then
				local speed = formatNumber(g_i18n:getSpeed(storeData.workSpeedMax), 1);
				if storeData.workSpeedMin then
					speed = formatNumber(g_i18n:getSpeed(storeData.workSpeedMin), 1) .. ' - ' .. speed;
				end;
				specs = specs .. g_i18n:getText('STORE_SPECS_WORKINGSPEED'):format(speed, g_i18n:getText('speedometer')) .. '\n';
			end;
			if storeData.capacity then -- TODO: use g_i18n:getText('fluid_unit_short') for liters
				local unit = storeData.capacityUnit or 'L';
				if unit == "M3COMP" then
					local compressed = storeData.compressedCapacity or storeData.capacity * 1.6;
					specs = specs .. g_i18n:getText('STORE_SPECS_CAPACITY_' .. unit):format(formatNumber(storeData.capacity, 1), formatNumber(compressed, 1)) .. '\n';
				else
					specs = specs .. g_i18n:getText('STORE_SPECS_CAPACITY_' .. unit):format(formatNumber(storeData.capacity, unit == 'M3' and 1 or 0)) .. '\n';
				end;
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


		-- general
		local general = {
			fuelCapacity 				 = getXMLFloat(xmlFile, key .. '.general#fuelCapacity');
			realMaxVehicleSpeed 		 = getXMLFloat(xmlFile, key .. '.general#realMaxVehicleSpeed');
			realBrakingDeceleration 	 = getXMLFloat(xmlFile, key .. '.general#realBrakingDeceleration');
			realCanLockWheelsWhenBraking =  getXMLBool(xmlFile, key .. '.general#realCanLockWheelsWhenBraking');
			realRollingResistance 		 = getXMLFloat(xmlFile, key .. '.general#realRollingResistance');
			realWorkingPowerConsumption  = getXMLFloat(xmlFile, key .. '.general#realWorkingPowerConsumption');
			realDisplaySlip				 = Utils.getNoNil(getXMLBool(xmlFile, key .. '.general#realDisplaySlip'), true);
		};


		-- animation speed scale
		general.animationSpeedScale = {};
		local animsStr = getXMLString(xmlFile, key .. '.general#animationSpeedScale');
		if animsStr then
			animsStr = Utils.splitString(',', animsStr);
			for i,data in pairs(animsStr) do
				dataSplit = Utils.splitString(':', data);
				general.animationSpeedScale[dataSplit[1]] = tonumber(dataSplit[2]);
				general.hasAnimationsSpeedScale = true;
			end;
		end;


		-- engine
		local engine = {
			kW 									=  getXMLFloat(xmlFile, key .. '.engine#kW');
			realMaxReverseSpeed 				=  getXMLFloat(xmlFile, key .. '.engine#realMaxReverseSpeed');
			realMaxFuelUsage 					=  getXMLFloat(xmlFile, key .. '.engine#realMaxFuelUsage');
			realSpeedBoost 						=  getXMLFloat(xmlFile, key .. '.engine#realSpeedBoost');
			realSpeedBoostMinSpeed 				=  getXMLFloat(xmlFile, key .. '.engine#realSpeedBoostMinSpeed');
			realImplementNeedsBoost 			=  getXMLFloat(xmlFile, key .. '.engine#realImplementNeedsBoost');
			realImplementNeedsBoostMinPowerCons =  getXMLFloat(xmlFile, key .. '.engine#realImplementNeedsBoostMinPowerCons');
			realMaxBoost 						=  getXMLFloat(xmlFile, key .. '.engine#realMaxBoost');
			realTransmissionEfficiency 			=  getXMLFloat(xmlFile, key .. '.engine#realTransmissionEfficiency');
			realPtoDriveEfficiency				=  getXMLFloat(xmlFile, key .. '.engine#realPtoDriveEfficiency') or 0.92;
			realSpeedLevel						= getXMLString(xmlFile, key .. '.engine#realSpeedLevel');
			realAiManeuverSpeed 				=  getXMLFloat(xmlFile, key .. '.engine#realAiManeuverSpeed');
			realMaxPowerToTransmission 			=  getXMLFloat(xmlFile, key .. '.engine#realMaxPowerToTransmission');
			realHydrostaticTransmission 		=   getXMLBool(xmlFile, key .. '.engine#realHydrostaticTransmission');
			realMinSpeedForMaxPower 			=  getXMLFloat(xmlFile, key .. '.engine#realMinSpeedForMaxPower');
			newExhaustPS						=   getXMLBool(xmlFile, key .. '.engine#newExhaustPS');
			newExhaustMinAlpha					=  getXMLFloat(xmlFile, key .. '.engine#newExhaustMinAlpha');
			newExhaustCapAxis					= getXMLString(xmlFile, key .. '.engine#capAxis');
		};
		if engine.kW then
			engine.realPtoPowerKW 				=  getXMLFloat(xmlFile, key .. '.engine#realPtoPowerKW') or engine.kW * engine.realPtoDriveEfficiency;
		end;


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
		weights.realBrakeMaxMovingMass	= getXMLFloat(xmlFile, key .. '.weights#realBrakeMaxMovingMass'); -- or weights.maxWeight * 1.5;


		-- wheels
		local wheelStuff = {
			realVehicleFlotationFx    = getXMLFloat(xmlFile, key .. '.wheels#realVehicleFlotationFx');
			realNoSteeringAxleDamping =  getXMLBool(xmlFile, key .. '.wheels#realNoSteeringAxleDamping');
		};
		local wheels = {};
		local w = 0;
		while true do
			local wheelKey = key .. ('.wheels.wheel(%d)'):format(w);
			if not hasXMLProperty(xmlFile, wheelKey) then break; end;

			wheels[#wheels + 1] = {
				driveMode  		   =   getXMLInt(xmlFile, wheelKey .. '#driveMode'), 
				rotMax     		   = getXMLFloat(xmlFile, wheelKey .. '#rotMax'),
				rotMin     		   = getXMLFloat(xmlFile, wheelKey .. '#rotMin'),
				rotSpeed   		   = getXMLFloat(xmlFile, wheelKey .. '#rotSpeed'),
				radius     		   = getXMLFloat(xmlFile, wheelKey .. '#radius'),
				deltaY     		   = getXMLFloat(xmlFile, wheelKey .. '#deltaY'),
				suspTravel 		   = getXMLFloat(xmlFile, wheelKey .. '#suspTravel'),
				spring     		   = getXMLFloat(xmlFile, wheelKey .. '#spring'),
				damper     		   =   getXMLInt(xmlFile, wheelKey .. '#damper') or 20,
				brakeRatio 		   = getXMLFloat(xmlFile, wheelKey .. '#brakeRatio') or 1,
				antiRollFx		   = getXMLFloat(xmlFile, wheelKey .. '#antiRollFx'),
				realMaxMassAllowed = getXMLFloat(xmlFile, wheelKey .. '#realMaxMassAllowed')
			};

			w = w + 1;
		end;

		-- additionalWheels
		local additionalWheels = {};
		w = 0;
		while true do
			local wheelKey = key .. ('.additionalWheels.wheel(%d)'):format(w);
			if not hasXMLProperty(xmlFile, wheelKey) then break; end;

			additionalWheels[#additionalWheels + 1] = {
				repr	   						 = getXMLString(xmlFile, wheelKey .. '#repr'), 
				radius	   						 =  getXMLFloat(xmlFile, wheelKey .. '#radius'),
				deltaY	   						 =  getXMLFloat(xmlFile, wheelKey .. '#deltaY'),
				suspTravel 						 =  getXMLFloat(xmlFile, wheelKey .. '#suspTravel'),
				spring	   						 =  getXMLFloat(xmlFile, wheelKey .. '#spring'),
				damper	   						 =    getXMLInt(xmlFile, wheelKey .. '#damper') or 20,
				brakeRatio 						 =  getXMLFloat(xmlFile, wheelKey .. '#brakeRatio') or 1,
				antiRollFx						 =  getXMLFloat(xmlFile, wheelKey .. '#antiRollFx'),
				lateralStiffness 				 =  getXMLFloat(xmlFile, wheelKey .. '#lateralStiffness'),
				continousBrakeForceWhenNotActive =  getXMLFloat(xmlFile, wheelKey .. '#continousBrakeForceWhenNotActive')
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
			if jointType and (jointType == 'implement' or jointType == 'cutter') then
				ajData.jointType = jointType;
				ajData.minRot				  = getXMLString(xmlFile, ajKey .. '#minRot');
				ajData.maxRot				  = getXMLString(xmlFile, ajKey .. '#maxRot');
				ajData.maxRot2				  = getXMLString(xmlFile, ajKey .. '#maxRot2'); --TODO: always maxRot * -1 ?
				ajData.maxRotDistanceToGround =  getXMLFloat(xmlFile, ajKey .. '#maxRotDistanceToGround');
				ajData.minRotDistanceToGround =  getXMLFloat(xmlFile, ajKey .. '#minRotDistanceToGround');
				ajData.moveTime				  =  getXMLFloat(xmlFile, ajKey .. '#moveTime');

				-- cutter attacher joint
				ajData.lowerDistanceToGround 	   =  getXMLFloat(xmlFile, ajKey .. '#lowerDistanceToGround');
				ajData.realWantedLoweredTransLimit = getXMLString(xmlFile, ajKey .. '#realWantedLoweredTransLimit');
				ajData.realWantedLoweredRotLimit   = getXMLString(xmlFile, ajKey .. '#realWantedLoweredRotLimit');
				ajData.realWantedRaisedRotLimit	   = getXMLString(xmlFile, ajKey .. '#realWantedRaisedRotLimit');
				ajData.realWantedLoweredRot2 	   =  getXMLFloat(xmlFile, ajKey .. '#realWantedLoweredRot2');
				ajData.realWantedRaisedRotInc 	   =  getXMLFloat(xmlFile, ajKey .. '#realWantedRaisedRotInc');

			elseif jointType and (jointType == 'trailer' or jointType == 'trailerLow') then
				ajData.maxRotLimit				= getXMLString(xmlFile, ajKey .. '#maxRotLimit');
				ajData.maxTransLimit			= getXMLString(xmlFile, ajKey .. '#maxTransLimit');
				ajData.allowsJointLimitMovement =   getXMLBool(xmlFile, ajKey .. '#allowsJointLimitMovement');
				ajData.allowsLowering			=   getXMLBool(xmlFile, ajKey .. '#allowsLowering');
			end;

			attacherJoints[#attacherJoints + 1] = ajData;

			a = a + 1;
		end;


		-- trailerAttacherJoints
		local trailerAttacherJoints = {};
		a = 0;
		while true do
			local tajKey = key .. ('.trailerAttacherJoints.trailerAttacherJoint(%d)'):format(a);
			if not hasXMLProperty(xmlFile, tajKey) then break; end;

			trailerAttacherJoints[#trailerAttacherJoints + 1] = {
				maxRotLimit = getXMLString(xmlFile, tajKey .. '#maxRotLimit');
			};

			a = a + 1;
		end;


		-- components
		local components = {};
		local c = 1;
		while true do
			local compKey = key .. ('.components.component%d'):format(c);
			if not hasXMLProperty(xmlFile, compKey) then break; end;

			components[#components + 1] = {
				centerOfMass 		 = getXMLString(xmlFile, compKey .. '#centerOfMass'),
				realMassWanted 		 =  getXMLFloat(xmlFile, compKey .. '#realMassWanted'),
				realTransWithMass 	 = getXMLString(xmlFile, compKey .. '#realTransWithMass'),
				realTransWithMassMax = getXMLString(xmlFile, compKey .. '#realTransWithMassMax')
			};

			c = c + 1;
		end;


		-- workTool
		local workTool = {
			capacity								=   getXMLInt(xmlFile, key .. '.workTool#capacity');
			realPowerConsumption 					= getXMLFloat(xmlFile, key .. '.workTool#realPowerConsumption');
			realPowerConsumptionWhenWorking			= getXMLFloat(xmlFile, key .. '.workTool#realPowerConsumptionWhenWorking');
			realPowerConsumptionWhenWorkingInc		= getXMLFloat(xmlFile, key .. '.workTool#realPowerConsumptionWhenWorkingInc');
			realWorkingSpeedLimit 					= getXMLFloat(xmlFile, key .. '.workTool#realWorkingSpeedLimit');
			realResistanceOnlyWhenActive			=  getXMLBool(xmlFile, key .. '.workTool#realResistanceOnlyWhenActive');
			resistanceDecreaseFx 					= getXMLFloat(xmlFile, key .. '.workTool#resistanceDecreaseFx');
			powerConsumptionWhenWorkingDecreaseFx	= getXMLFloat(xmlFile, key .. '.workTool#powerConsumptionWhenWorkingDecreaseFx');
			caRealTractionResistance				= getXMLFloat(xmlFile, key .. '.workTool#caRealTractionResistance');
			caRealTractionResistanceWithLoadMass	= getXMLFloat(xmlFile, key .. '.workTool#caRealTractionResistanceWithLoadMass') or 0;
			realCapacityMultipliers					= {};
		};

		-- capacity multipliers
		local realCapacityMultipliers = getXMLString(xmlFile, key .. '.workTool#realCapacityMultipliers');
		if realCapacityMultipliers then
			realCapacityMultipliers = Utils.splitString(',', realCapacityMultipliers);
			for i=1, #realCapacityMultipliers do
				local data = Utils.splitString(':', realCapacityMultipliers[i]);
				workTool.realCapacityMultipliers[i] = {
					fillType = data[1];
					multiplier = tonumber(data[2]);
				};
			end;
		end;

		-- trailer
		if subCategory == 'trailer' then
			workTool.realTippingPowerConsumption			 = getXMLFloat(xmlFile, key .. '.workTool#realTippingPowerConsumption');
			workTool.realOverloaderUnloadingPowerConsumption = getXMLFloat(xmlFile, key .. '.workTool#realOverloaderUnloadingPowerConsumption');
			workTool.pipeUnloadingCapacity					 = getXMLFloat(xmlFile, key .. '.workTool#pipeUnloadingCapacity');

		-- forageWagon
		elseif subCategory == 'forageWagon' then
			workTool.realForageWagonWorkingPowerConsumption	   = getXMLFloat(xmlFile, key .. '.workTool#realForageWagonWorkingPowerConsumption');
			workTool.realForageWagonWorkingPowerConsumptionInc = getXMLFloat(xmlFile, key .. '.workTool#realForageWagonWorkingPowerConsumptionInc');
			workTool.realForageWagonDischargePowerConsumption  = getXMLFloat(xmlFile, key .. '.workTool#realForageWagonDischargePowerConsumption');
			workTool.realForageWagonCompressionRatio		   = getXMLFloat(xmlFile, key .. '.workTool#realForageWagonCompressionRatio');

		-- cutter
		elseif subCategory == 'cutter' then
			workTool.realCutterPowerConsumption	   = getXMLFloat(xmlFile, key .. '.workTool#realCutterPowerConsumption') or 25;
			workTool.realCutterPowerConsumptionInc = getXMLFloat(xmlFile, key .. '.workTool#realCutterPowerConsumptionInc') or 2.5;
			workTool.realCutterSpeedLimit		   = getXMLFloat(xmlFile, key .. '.workTool#realCutterSpeedLimit') or 14;

		-- rake
		elseif subCategory == 'rake' then
			workTool.realRakeWorkingPowerConsumption	= getXMLFloat(xmlFile, key .. '.workTool#realRakeWorkingPowerConsumption');
			workTool.realRakeWorkingPowerConsumptionInc	= getXMLFloat(xmlFile, key .. '.workTool#realRakeWorkingPowerConsumptionInc');

		-- baleLoader
		elseif subCategory == 'baleLoader' then
			workTool.realAutoStackerWorkingPowerConsumption = getXMLFloat(xmlFile, key .. '.workTool#realAutoStackerWorkingPowerConsumption');

		-- baler
		elseif subCategory == 'baler' then
			workTool.realBalerWorkingSpeedLimit			  = getXMLFloat(xmlFile, key .. '.workTool#realBalerWorkingSpeedLimit');
			workTool.realBalerPowerConsumption			  = getXMLFloat(xmlFile, key .. '.workTool#realBalerPowerConsumption');
			workTool.realBalerRoundingPowerConsumptionInc = getXMLFloat(xmlFile, key .. '.workTool#realBalerRoundingPowerConsumptionInc');
			workTool.realBalerRam = {
				strokePowerConsumption					  = getXMLFloat(xmlFile, key .. '.workTool#realBalerRamStrokePowerConsumption');
				strokePowerConsumptionInc				  = getXMLFloat(xmlFile, key .. '.workTool#realBalerRamStrokePowerConsumptionInc');
				strokeTimeOffset						  = getXMLFloat(xmlFile, key .. '.workTool#realBalerRamStrokeTimeOffset');
				strokePerMinute							  = getXMLFloat(xmlFile, key .. '.workTool#realBalerRamStrokePerMinute');
			};
			workTool.realBalerPickUpPowerConsumptionInc	  = getXMLFloat(xmlFile, key .. '.workTool#realBalerPickUpPowerConsumptionInc');
			workTool.realBalerOverFillingRatio			  = getXMLFloat(xmlFile, key .. '.workTool#realBalerOverFillingRatio');
			workTool.realBalerAddEjectVelZ				  = getXMLFloat(xmlFile, key .. '.workTool#realBalerAddEjectVelZ');
			workTool.realBalerUseEjectingVelocity		  =  getXMLBool(xmlFile, key .. '.workTool#realBalerUseEjectingVelocity');

			workTool.realBalerLastBaleCol = {
				index = getXMLString(xmlFile, key .. '.workTool#realBalerLastBaleColIndex');
				maxBaleTimeBeforeNextBale = getXMLFloat(xmlFile, key .. '.workTool#realBalerLastBaleColMaxBaleTimeBeforeNextBale');
				componentJoint = getXMLInt(xmlFile, key .. '.workTool#realBalerLastBaleColComponentJoint');
			};

		-- sprayer
		elseif subCategory == 'sprayer' then
			workTool.realFillingPowerConsumption	= getXMLFloat(xmlFile, key .. '.workTool#realFillingPowerConsumption');
			workTool.realSprayingReferenceSpeed		= getXMLFloat(xmlFile, key .. '.workTool#realSprayingReferenceSpeed');
			workTool.sprayUsageLitersPerSecond		= getXMLFloat(xmlFile, key .. '.workTool#sprayUsageLitersPerSecond');
			workTool.fillLitersPerSecond			= getXMLFloat(xmlFile, key .. '.workTool#fillLitersPerSecond');
		end;

		-- combine
		local combine = {};
		if subCategory == 'combine' then
			combine.baseSpeed 						 =  getXMLFloat(xmlFile, key .. '.combine#baseSpeed') or 5;
			combine.minSpeed 						 =  getXMLFloat(xmlFile, key .. '.combine#minSpeed') or 3;
			combine.maxSpeed 						 =  getXMLFloat(xmlFile, key .. '.combine#maxSpeed') or 12;
			combine.realAiMinDistanceBeforeTurning 	 =  getXMLFloat(xmlFile, key .. '.combine#realAiMinDistanceBeforeTurning');
			combine.realUnloadingPowerBoost 		 =  getXMLFloat(xmlFile, key .. '.combine#realUnloadingPowerBoost');
			combine.realUnloadingPowerConsumption 	 =  getXMLFloat(xmlFile, key .. '.combine#realUnloadingPowerConsumption');
			combine.realThreshingPowerConsumption 	 =  getXMLFloat(xmlFile, key .. '.combine#realThreshingPowerConsumption');
			combine.realThreshingPowerConsumptionInc =  getXMLFloat(xmlFile, key .. '.combine#realThreshingPowerConsumptionInc');
			combine.realThreshingPowerBoost			 =  getXMLFloat(xmlFile, key .. '.combine#realThreshingPowerBoost');
			combine.realChopperPowerConsumption 	 =  getXMLFloat(xmlFile, key .. '.combine#realChopperPowerConsumption');
			combine.realChopperPowerConsumptionInc 	 =  getXMLFloat(xmlFile, key .. '.combine#realChopperPowerConsumptionInc');
			combine.realThreshingScale 				 =  getXMLFloat(xmlFile, key .. '.combine#realThreshingScale');
			combine.grainTankUnloadingCapacity 		 =  getXMLFloat(xmlFile, key .. '.combine#grainTankUnloadingCapacity');
			combine.realCombineLosses = {               
				allowed								 =   getXMLBool(xmlFile, key .. '.combine#realCombineLossesAllowed');
				maxSqmBeingThreshedBeforeLosses		 =  getXMLFloat(xmlFile, key .. '.combine#realCombineLossesMaxSqmBeingThreshedBeforeLosses');
				displayLosses						 =   getXMLBool(xmlFile, key .. '.combine#realCombineLossesDisplayLosses');
			};                                          
			combine.realCombineCycleDuration		 =  getXMLFloat(xmlFile, key .. '.combine#realCombineCycleDuration');
			combine.pipeRotationSpeeds				 = getXMLString(xmlFile, key .. '.combine#pipeRotationSpeeds');
			combine.pipeState1Rotation				 = getXMLString(xmlFile, key .. '.combine#pipeState1Rotation');
			combine.pipeState2Rotation				 = getXMLString(xmlFile, key .. '.combine#pipeState2Rotation');
		end;

		--------------------------------------------------

		-- STORE DATA
		local store = {
			price				=    getXMLInt(xmlFile, key .. '.store#price');
			dailyUpkeep			=    getXMLInt(xmlFile, key .. '.store#dailyUpkeep');
			powerKW				=    getXMLInt(xmlFile, key .. '.store#powerKW');
			requiredPowerKwMin	=    getXMLInt(xmlFile, key .. '.store#requiredPowerKwMin');
			requiredPowerKwMax	=    getXMLInt(xmlFile, key .. '.store#requiredPowerKwMax');
			maxSpeed			=    getXMLInt(xmlFile, key .. '.store#maxSpeed');
			weight				=    getXMLInt(xmlFile, key .. '.store#weight');
			workSpeedMin		=    getXMLInt(xmlFile, key .. '.store#workSpeedMin');
			workSpeedMax		=    getXMLInt(xmlFile, key .. '.store#workSpeedMax');
			workWidth			=  getXMLFloat(xmlFile, key .. '.store#workWidth');
			capacity			=  getXMLFloat(xmlFile, key .. '.store#capacity');
			compressedCapacity	=  getXMLFloat(xmlFile, key .. '.store#compressedCapacity');
			capacityUnit		= getXMLString(xmlFile, key .. '.store#capacityUnit');
			fruits				= getXMLString(xmlFile, key .. '.store#fruits');
		};
		setStoreData(configFileName, dlcName, store, doDebug);

		--------------------------------------------------

		vehicleData[configFileName] = {
			category = category,
			subCategory = subCategory,
			configFileName = configFileName,
			vehicleType = Utils.startsWith(vehicleType, 'mr_') and modName .. '.' .. vehicleType or vehicleType,
			doDebug = doDebug,

			general = general,
			engine = engine,
			width = width,
			height = height,
			weights = weights,
			wheels = wheels,
			wheelStuff = wheelStuff,
			additionalWheels = additionalWheels,
			attacherJoints = attacherJoints,
			trailerAttacherJoints = trailerAttacherJoints,
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

-- CHECK WHICH DLCs ARE INSTALLED -> only get MR data for installed and up-to-date ones
local getDlcVersion = function(modName)
	local dlcModItem = ModsUtil.findModItemByModName(modName);
	if dlcModItem and dlcModItem.version then
		local versionSplit = Utils.splitString('.', dlcModItem.version);
		local versionFlt = tonumber(('%d.%d%d%d'):format(versionSplit[1], versionSplit[2], versionSplit[3], versionSplit[4]));
		return versionFlt, dlcModItem.version;
	end;

	return 0, '0';
end;

local dlcExists = false;
for name, dlcData in pairs(dlcs) do
	local modName = 'pdlc_' .. dlcData.dlcName;
	if g_modNameToDirectory[modName] ~= nil then
		local dlcVersion, dlcVersionStr = getDlcVersion(modName);
		if dlcVersion < dlcData.minVersionFlt then
			print(('MoreRealisticDLCs: DLC %q has a too low version number (v%s). Update to v%s or higher. Script will now be aborted!'):format(name, dlcVersionStr, dlcData.minVersionStr));
			delete(vehicleTypesFile);
			return;
		end;

		dlcData.dir = g_modNameToDirectory[modName]; 
		dlcData.containingDir = dlcData.dir:sub(1, dlcData.dir:len() - dlcData.dlcName:len() - 1);
		-- print(('DLC %q: modName=%q, dir=%q, containingDir=%q'):format(dlcData.dlcName, modName, dlcData.dir, dlcData.containingDir));
		-- print(('\tmin DLC version: %s, existing DLC version: %s'):format(dlcData.minVersionStr, dlcVersionStr));
		if not customSpecsRegistered then
			registerCustomSpecs();
		end;
		local vehicleDataPath = Utils.getFilename(dlcData.dataFile, modDir);
		print(('MoreRealisticDLCs: %q DLC v%s exists, -> call getMoreRealisticData("...%s")'):format(name, dlcVersionStr, dlcData.dataFile));
		getMoreRealisticData(vehicleDataPath, name);
		dlcExists = true;
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
local setValue = function(xmlFile, parameter, prmType, value, extraIndent)
	if value == nil then return; end;

	prmSetXMLFn[prmType](xmlFile, parameter, value);
	if mrData and mrData.doDebug then
		extraIndent = extraIndent or '';
		print(('\t%sset parameter %q (type %s) to %q'):format(extraIndent, parameter, prmType, tostring(value)));
	end;
end;

local removeProperty = function(xmlFile, property, extraIndent)
	if getXMLString(xmlFile, property) ~= nil or hasXMLProperty(xmlFile, property) then
		removeXMLProperty(xmlFile, property);
		if mrData and mrData.doDebug then
			extraIndent = extraIndent or '';
			print(('\t%sremove property %q'):format(extraIndent, tostring(property)));
		end;
	end;
end;

-- ##################################################

local exhaustPsNewPath = '$moddir$' .. modName .. '/_RES/newRealParticles.i3d';
local exhaustPsOldPath = '$moddir$' .. modName .. '/_RES/realParticles.i3d';

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
		setValue(xmlFile, 'vehicle.bunkerSiloCompactor#compactingScale',  'flt',  mrData.weights.weight * 0.25);
		setValue(xmlFile, 'vehicle.realMaxVehicleSpeed', 				  'flt',  mrData.general.realMaxVehicleSpeed);
		setValue(xmlFile, 'vehicle.realMaxReverseSpeed', 				  'flt',  mrData.engine.realMaxReverseSpeed);
		setValue(xmlFile, 'vehicle.realBrakeMaxMovingMass', 			  'flt',  mrData.weights.realBrakeMaxMovingMass);
		setValue(xmlFile, 'vehicle.realSCX', 							  'flt',  mrData.width * mrData.height * 0.68);
		setValue(xmlFile, 'vehicle.realBrakingDeceleration', 			  'flt',  mrData.general.realBrakingDeceleration);
		setValue(xmlFile, 'vehicle.realCanLockWheelsWhenBraking', 		  'bool', mrData.general.realCanLockWheelsWhenBraking);
		setValue(xmlFile, 'vehicle.realRollingResistance',				  'flt',  mrData.general.realRollingResistance);
		setValue(xmlFile, 'vehicle.realWorkingPowerConsumption',		  'flt',  mrData.general.realWorkingPowerConsumption);


		if mrData.category == 'steerable' then
			-- accelerationSpeed
			setValue(xmlFile, 'vehicle.accelerationSpeed#maxAcceleration',	'int', 1);
			setValue(xmlFile, 'vehicle.accelerationSpeed#deceleration',		'int', 1);
			setValue(xmlFile, 'vehicle.accelerationSpeed#brakeSpeed',		'int', 3);
			removeProperty(xmlFile, 'vehicle.accelerationSpeed#backwardDeceleration');

			-- fuel usage, downforce
			setValue(xmlFile, 'vehicle.fuelUsage', 'int', 0);
			setValue(xmlFile, 'vehicle.downForce', 'int', 0);

			-- general
			setValue(xmlFile, 'vehicle.realDisplaySlip',					  'bool', mrData.general.realDisplaySlip);
			setValue(xmlFile, 'vehicle.fuelCapacity',						  'int',  mrData.general.fuelCapacity);

			-- wheels
			setValue(xmlFile, 'vehicle.realVehicleFlotationFx',				  'flt',  mrData.wheelStuff.realVehicleFlotationFx);

			-- engine
			setValue(xmlFile, 'vehicle.realSpeedLevel', 					  'str',  mrData.engine.realSpeedLevel);
			setValue(xmlFile, 'vehicle.realAiManeuverSpeed', 				  'flt',  mrData.engine.realAiManeuverSpeed);
			setValue(xmlFile, 'vehicle.realSpeedBoost',						  'int',  mrData.engine.realSpeedBoost);
			setValue(xmlFile, 'vehicle.realSpeedBoost#minSpeed', 			  'int',  mrData.engine.realSpeedBoostMinSpeed);
			setValue(xmlFile, 'vehicle.realImplementNeedsBoost',			  'int',  mrData.engine.realImplementNeedsBoost);
			setValue(xmlFile, 'vehicle.realImplementNeedsBoost#minPowerCons', 'int',  mrData.engine.realImplementNeedsBoostMinPowerCons);
			setValue(xmlFile, 'vehicle.realMaxBoost', 						  'int',  mrData.engine.realMaxBoost);
			setValue(xmlFile, 'vehicle.realPtoPowerKW',						  'flt',  mrData.engine.realPtoPowerKW);
			setValue(xmlFile, 'vehicle.realPtoDriveEfficiency',				  'flt',  mrData.engine.realPtoDriveEfficiency);
			setValue(xmlFile, 'vehicle.realMaxFuelUsage',					  'flt',  mrData.engine.realMaxFuelUsage);
			setValue(xmlFile, 'vehicle.realTransmissionEfficiency', 		  'flt',  mrData.engine.realTransmissionEfficiency);
			setValue(xmlFile, 'vehicle.realMaxPowerToTransmission', 		  'flt',  mrData.engine.realMaxPowerToTransmission);
			setValue(xmlFile, 'vehicle.realHydrostaticTransmission',		  'bool', mrData.engine.realHydrostaticTransmission);
			setValue(xmlFile, 'vehicle.realMinSpeedForMaxPower', 			  'flt',  mrData.engine.realMinSpeedForMaxPower);

			-- combine
			if mrData.subCategory == 'combine' then
				setValue(xmlFile, 'vehicle.realAiWorkingSpeed#baseSpeed', 	  'int',  mrData.combine.baseSpeed);
				setValue(xmlFile, 'vehicle.realAiWorkingSpeed#minSpeed', 	  'int',  mrData.combine.minSpeed);
				setValue(xmlFile, 'vehicle.realAiWorkingSpeed#maxSpeed', 	  'int',  mrData.combine.maxSpeed);

				setValue(xmlFile, 'vehicle.realAiMinDistanceBeforeTurning',   'flt',  mrData.combine.realAiMinDistanceBeforeTurning);
				setValue(xmlFile, 'vehicle.realUnloadingPowerBoost', 		  'flt',  mrData.combine.realUnloadingPowerBoost);
				setValue(xmlFile, 'vehicle.realUnloadingPowerConsumption', 	  'flt',  mrData.combine.realUnloadingPowerConsumption);
				setValue(xmlFile, 'vehicle.realThreshingPowerConsumption', 	  'flt',  mrData.combine.realThreshingPowerConsumption);
				setValue(xmlFile, 'vehicle.realThreshingPowerConsumptionInc', 'flt',  mrData.combine.realThreshingPowerConsumptionInc);
				setValue(xmlFile, 'vehicle.realThreshingPowerBoost',		  'flt',  mrData.combine.realThreshingPowerBoost);
				setValue(xmlFile, 'vehicle.realChopperPowerConsumption', 	  'flt',  mrData.combine.realChopperPowerConsumption);
				setValue(xmlFile, 'vehicle.realChopperPowerConsumptionInc',   'flt',  mrData.combine.realChopperPowerConsumptionInc);
				setValue(xmlFile, 'vehicle.realThreshingScale', 			  'flt',  mrData.combine.realThreshingScale);
				setValue(xmlFile, 'vehicle.grainTankUnloadingCapacity', 	  'flt',  mrData.combine.grainTankUnloadingCapacity);
				setValue(xmlFile, 'vehicle.realCombineCycleDuration', 		  'flt',  mrData.combine.realCombineCycleDuration);

				setValue(xmlFile, 'vehicle.realCombineLosses#allowed', 						   'bool', mrData.combine.realCombineLosses.allowed);
				setValue(xmlFile, 'vehicle.realCombineLosses#maxSqmBeingThreshedBeforeLosses', 'flt',  mrData.combine.realCombineLosses.maxSqmBeingThreshedBeforeLosses);
				setValue(xmlFile, 'vehicle.realCombineLosses#displayLosses',				   'bool', mrData.combine.realCombineLosses.displayLosses);

				setValue(xmlFile, 'vehicle.pipe.node#rotationSpeeds',  'str', mrData.combine.pipeRotationSpeeds);
				setValue(xmlFile, 'vehicle.pipe.node.state1#rotation', 'str', mrData.combine.pipeState1Rotation);
				setValue(xmlFile, 'vehicle.pipe.node.state2#rotation', 'str', mrData.combine.pipeState2Rotation);
			end;

			-- exhaust PS
			if mrData.engine.newExhaustPS then
				local node = getXMLString(xmlFile, 'vehicle.exhaustParticleSystems.exhaustParticleSystem1#node');
				if node then
					-- remove old PS
					setValue(xmlFile, 'vehicle.exhaustParticleSystems.exhaustParticleSystem1#file', 'str', exhaustPsOldPath);
					-- setValue(xmlFile, 'vehicle.exhaustParticleSystems.exhaustParticleSystem1#file', 'str', exhaustPsNewPath);

					-- set new PS
					local desKey = 'vehicle.dynamicExhaustingSystem';
					local minAlpha = mrData.engine.newExhaustMinAlpha or 0.2;
					setValue(xmlFile, desKey .. '#minAlpha', 'flt', minAlpha); -- 0.05
					setValue(xmlFile, desKey .. '#maxAlpha', 'flt', 1); -- 0.4
					setValue(xmlFile, desKey .. '#param',	 'str', 'alphaScale');

					-- start sequence
					setValue(xmlFile, desKey .. '.startSequence.key(0)#time',  'flt', 0.0);
					setValue(xmlFile, desKey .. '.startSequence.key(0)#value', 'str', '0 0 0 0');
					setValue(xmlFile, desKey .. '.startSequence.key(1)#time',  'flt', 0.3);
					setValue(xmlFile, desKey .. '.startSequence.key(1)#value', 'str', '0 0 0 0.5');
					setValue(xmlFile, desKey .. '.startSequence.key(2)#time',  'flt', 0.6);
					setValue(xmlFile, desKey .. '.startSequence.key(2)#value', 'str', '0 0 0 0.8');
					setValue(xmlFile, desKey .. '.startSequence.key(3)#time',  'flt', 1);
					setValue(xmlFile, desKey .. '.startSequence.key(3)#value', 'str', '0 0 0 ' .. minAlpha);

					-- exhaust cap
					if mrData.engine.newExhaustCapAxis then
						local capNode	= getXMLString(xmlFile, 'vehicle.exhaustParticleSystems#flap');
						local capMaxRot	= getXMLString(xmlFile, 'vehicle.exhaustParticleSystems#maxRot');

						if capNode and capMaxRot then
							setValue(xmlFile, desKey .. '#cap',		'str', capNode);
							setValue(xmlFile, desKey .. '#capAxis',	'str', mrData.engine.newExhaustCapAxis);
							setValue(xmlFile, desKey .. '#maxRot',	'str', capMaxRot);
						end;
					end;

					-- second particleSystem
					--[[
					local spsKey = desKey .. '.secondParticleSystem';
					setValue(xmlFile, spsKey .. '#node', 'str', node);
					setValue(xmlFile, spsKey .. '#position', 'str', '0 0.02 0.02');
					setValue(xmlFile, spsKey .. '#rotation', 'str', '0 0 0');
					setValue(xmlFile, spsKey .. '#file', 'str', exhaustPsNewPath);
					setValue(xmlFile, spsKey .. '#minLoadActive', 'flt', 0.5);
					]]
				end;
			end;
		end;


		-- wheels
		setValue(xmlFile, 'vehicle.steeringAxleAngleScale#realNoSteeringAxleDamping', 'bool', mrData.wheelStuff.realNoSteeringAxleDamping);
		local wheelI = 0;
		while true do
			local wheelKey = ('vehicle.wheels.wheel(%d)'):format(wheelI);
			local repr = getXMLString(xmlFile, wheelKey .. '#repr');
			if not repr or repr == '' then break; end;
			if wheelI == 0 then
				setValue(xmlFile, 'vehicle.wheels#autoRotateBackSpeed', 'flt', 1);
			end;
			if mrData.doDebug then
				print('\twheels: ' .. wheelI);
			end;

			local wheelMrData = mrData.wheels[wheelI + 1];

			removeProperty(xmlFile, wheelKey .. '#lateralStiffness', '\t');
			removeProperty(xmlFile, wheelKey .. '#longitudalStiffness', '\t');
			setValue(xmlFile, wheelKey .. '#driveMode',			 'int', wheelMrData.driveMode, '\t');
			setValue(xmlFile, wheelKey .. '#rotMax',			 'flt', wheelMrData.rotMax, '\t');
			setValue(xmlFile, wheelKey .. '#rotMin',			 'flt', wheelMrData.rotMin, '\t');
			setValue(xmlFile, wheelKey .. '#rotSpeed',			 'flt', wheelMrData.rotSpeed, '\t');
			setValue(xmlFile, wheelKey .. '#radius',			 'flt', wheelMrData.radius, '\t');
			setValue(xmlFile, wheelKey .. '#brakeRatio',		 'int', wheelMrData.brakeRatio, '\t');
			setValue(xmlFile, wheelKey .. '#damper',			 'int', wheelMrData.damper, '\t');
			setValue(xmlFile, wheelKey .. '#mass',				 'int', 1, '\t');
			setValue(xmlFile, wheelKey .. '#antiRollFx',		 'flt', wheelMrData.antiRollFx, '\t');
			setValue(xmlFile, wheelKey .. '#realMaxMassAllowed', 'flt', wheelMrData.realMaxMassAllowed, '\t');

			local suspTravel = wheelMrData.suspTravel or getXMLFloat(xmlFile, wheelKey .. '#suspTravel');
			if suspTravel == nil or suspTravel == '' or suspTravel < 0.05 then
				suspTravel = 0.08;
			end;
			setValue(xmlFile, wheelKey .. '#suspTravel', 'flt', suspTravel, '\t');

			-- MR 1.2: local spring = wheelMrData.spring or 278 * (mrData.weights.maxWeight / #mrData.wheels) / (suspTravel * 100 - 2);
			local spring = wheelMrData.spring or 3 * mrData.weights.maxWeight / #mrData.wheels / suspTravel;
			setValue(xmlFile, wheelKey .. '#spring', 'flt', spring, '\t');

			local deltaY = wheelMrData.deltaY or getXMLFloat(xmlFile, wheelKey .. '#deltaY');
			if deltaY == nil or deltaY == '' or deltaY == 0 then
				deltaY = suspTravel * 0.9;
			end;
			setValue(xmlFile, wheelKey .. '#deltaY', 'flt', deltaY, '\t');

			wheelI = wheelI + 1;
		end;


		-- additionalWheels
		for w=1, #mrData.additionalWheels do
			local wheelMrData = mrData.additionalWheels[w];
			local wheelKey = ('vehicle.wheels.wheel(%d)'):format(wheelI);
			if mrData.doDebug then
				print(('\tadditionalWheels: %d (set as wheel %d'):format(w - 1, wheelI));
			end;

			setValue(xmlFile, wheelKey .. '#repr',							   'str', wheelMrData.repr, '\t');
			setValue(xmlFile, wheelKey .. '#deltaY',						   'flt', wheelMrData.deltaY, '\t');
			setValue(xmlFile, wheelKey .. '#radius',						   'flt', wheelMrData.radius, '\t');
			setValue(xmlFile, wheelKey .. '#suspTravel',					   'flt', wheelMrData.suspTravel, '\t');
			setValue(xmlFile, wheelKey .. '#spring',						   'flt', wheelMrData.spring, '\t');
			setValue(xmlFile, wheelKey .. '#damper',						   'flt', wheelMrData.damper, '\t');
			setValue(xmlFile, wheelKey .. '#brakeRatio',					   'flt', wheelMrData.brakeRatio, '\t');
			setValue(xmlFile, wheelKey .. '#antiRollFx',					   'flt', wheelMrData.antiRollFx, '\t');
			setValue(xmlFile, wheelKey .. '#lateralStiffness',				   'flt', wheelMrData.lateralStiffness, '\t');
			setValue(xmlFile, wheelKey .. '#continousBrakeForceWhenNotActive', 'flt', wheelMrData.continousBrakeForceWhenNotActive, '\t');

			wheelI = wheelI + 1;
		end;


		-- attacherJoints
		if mrData.category == 'steerable' then
			local a = 0;
			while true do
				local ajKey = ('vehicle.attacherJoints.attacherJoint(%d)'):format(a);
				if not hasXMLProperty(xmlFile, ajKey) then break; end;

				local ajMrData = mrData.attacherJoints[a + 1];
				local jointType = getXMLString(xmlFile, ajKey .. '#jointType');
				-- if jointType and (jointType == 'implement' or jointType == 'cutter') then
				local rotationNode = getXMLString(xmlFile, ajKey .. '#rotationNode');
				if rotationNode then
					removeProperty(xmlFile, ajKey .. '#maxRotLimit');
					removeProperty(xmlFile, ajKey .. '#minRot2');
					removeProperty(xmlFile, ajKey .. '#minRotRotationOffset');
					removeProperty(xmlFile, ajKey .. '#maxRotDistanceToGround');
					removeProperty(xmlFile, ajKey .. '#maxTransLimit');

					setValue(xmlFile, ajKey .. '#minRot', 				  'str', ajMrData.minRot);
					setValue(xmlFile, ajKey .. '#maxRot', 				  'str', ajMrData.maxRot);
					setValue(xmlFile, ajKey .. '#maxRot2', 				  'str', ajMrData.maxRot2);
					setValue(xmlFile, ajKey .. '#minRotDistanceToGround', 'flt', ajMrData.minRotDistanceToGround);
					setValue(xmlFile, ajKey .. '#maxRotDistanceToGround', 'flt', ajMrData.maxRotDistanceToGround);
					setValue(xmlFile, ajKey .. '#moveTime',				  'flt', ajMrData.moveTime);

				elseif jointType and (jointType == 'trailer' or jointType == 'trailerLow') then
					setValue(xmlFile, ajKey .. '#maxRotLimit', 				'str',  ajMrData.maxRotLimit);
					setValue(xmlFile, ajKey .. '#maxTransLimit', 			'str',  ajMrData.maxTransLimit);
					setValue(xmlFile, ajKey .. '#allowsJointLimitMovement',	'bool', ajMrData.allowsJointLimitMovement);
					setValue(xmlFile, ajKey .. '#allowsLowering',			'bool', ajMrData.allowsLowering);
				end;

				a = a + 1;
			end;

		elseif mrData.category == 'tool' and #mrData.attacherJoints == 1 then
			local ajMrData = mrData.attacherJoints[1];
			removeProperty(xmlFile, 'vehicle.attacherJoint#upperDistanceToGround');
			setValue(xmlFile, 'vehicle.attacherJoint#lowerDistanceToGround',	   'flt', ajMrData.lowerDistanceToGround);
			setValue(xmlFile, 'vehicle.attacherJoint#realWantedLoweredTransLimit', 'str', ajMrData.realWantedLoweredTransLimit);
			setValue(xmlFile, 'vehicle.attacherJoint#realWantedLoweredRotLimit',   'str', ajMrData.realWantedLoweredRotLimit);
			setValue(xmlFile, 'vehicle.attacherJoint#realWantedRaisedRotLimit',	   'str', ajMrData.realWantedRaisedRotLimit);
			setValue(xmlFile, 'vehicle.attacherJoint#realWantedLoweredRot2',	   'flt', ajMrData.realWantedLoweredRot2);
			setValue(xmlFile, 'vehicle.attacherJoint#realWantedRaisedRotInc',	   'flt', ajMrData.realWantedRaisedRotInc);
		end;


		-- trailerAttacherJoints
		local a = 0;
		while true do
			local tajKey = ('vehicle.trailerAttacherJoints.trailerAttacherJoint(%d)'):format(a);
			if not hasXMLProperty(xmlFile, tajKey) then break; end;

			if mrData.trailerAttacherJoints[a + 1] then
				setValue(xmlFile, tajKey .. '#maxRotLimit', 'str', mrData.trailerAttacherJoints[a + 1].maxRotLimit);
			end;

			a = a + 1;
		end;


		-- components
		for i=1, getXMLInt(xmlFile, 'vehicle.components#count') do
			if mrData.components[i] then
				local compKey = ('vehicle.components.component%d'):format(i);
				setValue(xmlFile, compKey .. '#centerOfMass',		  'str', mrData.components[i].centerOfMass);
				setValue(xmlFile, compKey .. '#realMassWanted',		  'flt', mrData.components[i].realMassWanted);
				setValue(xmlFile, compKey .. '#realTransWithMass',	  'str', mrData.components[i].realTransWithMass);
				setValue(xmlFile, compKey .. '#realTransWithMassMax', 'str', mrData.components[i].realTransWithMassMax);
			end;
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
				setValue(xmlFile, 'vehicle.realPowerConsumption',										 'flt',  mrData.workTool.realPowerConsumption);
				setValue(xmlFile, 'vehicle.realPowerConsumptionWhenWorking',							 'flt',  mrData.workTool.realPowerConsumptionWhenWorking);
				setValue(xmlFile, 'vehicle.realPowerConsumptionWhenWorkingInc',							 'flt',  mrData.workTool.realPowerConsumptionWhenWorkingInc);
				setValue(xmlFile, 'vehicle.realWorkingSpeedLimit',										 'flt',  mrData.workTool.realWorkingSpeedLimit);
				setValue(xmlFile, 'vehicle.realResistanceOnlyWhenActive',								 'bool', mrData.workTool.realResistanceOnlyWhenActive);
				setValue(xmlFile, 'vehicle.realTilledGroundBonus#resistanceDecreaseFx',					 'flt',  mrData.workTool.resistanceDecreaseFx);
				setValue(xmlFile, 'vehicle.realTilledGroundBonus#powerConsumptionWhenWorkingDecreaseFx', 'flt',  mrData.workTool.powerConsumptionWhenWorkingDecreaseFx);

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

				-- trailer
				if mrData.subCategory == 'trailer' then
					setValue(xmlFile, 'vehicle.realTippingPowerConsumption', 			 'flt', mrData.workTool.realTippingPowerConsumption);
					setValue(xmlFile, 'vehicle.realOverloaderUnloadingPowerConsumption', 'flt', mrData.workTool.realOverloaderUnloadingPowerConsumption);
					setValue(xmlFile, 'vehicle.pipe#unloadingCapacity', 				 'flt', mrData.workTool.pipeUnloadingCapacity);

				-- forageWagon
				elseif mrData.subCategory == 'forageWagon' then
					setValue(xmlFile, 'vehicle.realForageWagonWorkingPowerConsumption',	   'flt', mrData.workTool.realForageWagonWorkingPowerConsumption);
					setValue(xmlFile, 'vehicle.realForageWagonWorkingPowerConsumptionInc', 'flt', mrData.workTool.realForageWagonWorkingPowerConsumptionInc);
					setValue(xmlFile, 'vehicle.realForageWagonDischargePowerConsumption',  'flt', mrData.workTool.realForageWagonDischargePowerConsumption);
					setValue(xmlFile, 'vehicle.realForageWagonCompressionRatio',		   'flt', mrData.workTool.realForageWagonCompressionRatio);

				-- rake
				elseif mrData.subCategory == 'rake' then
					setValue(xmlFile, 'vehicle.realRakeWorkingPowerConsumption',	'flt',  mrData.workTool.realRakeWorkingPowerConsumption);
					setValue(xmlFile, 'vehicle.realRakeWorkingPowerConsumptionInc',	'flt',  mrData.workTool.realRakeWorkingPowerConsumptionInc);

				-- baleLoader
				elseif mrData.subCategory == 'baleLoader' then
					setValue(xmlFile, 'vehicle.realAutoStackerWorkingPowerConsumption', 'flt',  mrData.workTool.realAutoStackerWorkingPowerConsumption);

				-- baleWrapper
				elseif mrData.subCategory == 'baleWrapper' then

				-- baler
				elseif mrData.subCategory == 'baler' then
					setValue(xmlFile, 'vehicle.realBalerWorkingSpeedLimit',				'flt',  mrData.workTool.realBalerWorkingSpeedLimit);
					setValue(xmlFile, 'vehicle.realBalerPowerConsumption',				'flt',  mrData.workTool.realBalerPowerConsumption);
					setValue(xmlFile, 'vehicle.realBalerRoundingPowerConsumptionInc',	'flt',  mrData.workTool.realBalerRoundingPowerConsumptionInc);
					setValue(xmlFile, 'vehicle.realBalerRam#strokePowerConsumption',	'flt',  mrData.workTool.realBalerRam.strokePowerConsumption);
					setValue(xmlFile, 'vehicle.realBalerRam#strokePowerConsumptionInc',	'flt',  mrData.workTool.realBalerRam.strokePowerConsumptionInc);
					setValue(xmlFile, 'vehicle.realBalerRam#strokeTimeOffset',			'flt',  mrData.workTool.realBalerRam.strokeTimeOffset);
					setValue(xmlFile, 'vehicle.realBalerRam#strokePerMinute',			'flt',  mrData.workTool.realBalerRam.strokePerMinute);
					setValue(xmlFile, 'vehicle.realBalerPickUpPowerConsumptionInc',		'flt',  mrData.workTool.realBalerPickUpPowerConsumptionInc);
					setValue(xmlFile, 'vehicle.realBalerOverFillingRatio',				'flt',  mrData.workTool.realBalerOverFillingRatio);
					setValue(xmlFile, 'vehicle.realBalerAddEjectVelZ',					'flt',  mrData.workTool.realBalerAddEjectVelZ);
					setValue(xmlFile, 'vehicle.realBalerUseEjectingVelocity',			'bool', mrData.workTool.realBalerUseEjectingVelocity);
					if mrData.workTool.realBalerLastBaleCol.index then
						setValue(xmlFile, 'vehicle.realBalerLastBaleCol#index',						'str',	mrData.workTool.realBalerLastBaleCol.index);
						setValue(xmlFile, 'vehicle.realBalerLastBaleCol#maxBaleTimeBeforeNextBale',	'flt',	mrData.workTool.realBalerLastBaleCol.maxBaleTimeBeforeNextBale);
						setValue(xmlFile, 'vehicle.realBalerLastBaleCol#componentJoint',			'int',	mrData.workTool.realBalerLastBaleCol.componentJoint);
					end;
					-- TODO: <realEnhancedBaler> section

					setValue(xmlFile, 'vehicle.realFillTypePowerFactors.fillTypeFx(0)#fillType', 'str', 'wheat_windrow');
					setValue(xmlFile, 'vehicle.realFillTypePowerFactors.fillTypeFx(0)#value',	 'int', 1);
					setValue(xmlFile, 'vehicle.realFillTypePowerFactors.fillTypeFx(1)#fillType', 'str', 'barley_windrow');
					setValue(xmlFile, 'vehicle.realFillTypePowerFactors.fillTypeFx(1)#value',	 'int', 1);
					setValue(xmlFile, 'vehicle.realFillTypePowerFactors.fillTypeFx(2)#fillType', 'str', 'dryGrass_windrow');
					setValue(xmlFile, 'vehicle.realFillTypePowerFactors.fillTypeFx(2)#value',	 'flt', 1.25);

				-- sprayer
				elseif mrData.subCategory == 'sprayer' then
					setValue(xmlFile, 'vehicle.realFillingPowerConsumption',			'flt', mrData.workTool.realFillingPowerConsumption);
					setValue(xmlFile, 'vehicle.realSprayingReferenceSpeed',				'flt', mrData.workTool.realSprayingReferenceSpeed);
					setValue(xmlFile, 'vehicle.sprayUsages.sprayUsage#litersPerSecond', 'flt', mrData.workTool.sprayUsageLitersPerSecond);
					setValue(xmlFile, 'vehicle.fillLitersPerSecond',					'flt', mrData.workTool.fillLitersPerSecond);
				end;

				-- fillable
				if SpecializationUtil.hasSpecialization(Fillable, self.specializations) then
					setValue(xmlFile, 'vehicle.capacity', 'int', mrData.workTool.capacity);
					
					for i=1, #mrData.workTool.realCapacityMultipliers do
						local rcmKey = ('vehicle.realCapacityMultipliers.realCapacityMultiplier(%d)'):format(i-1);
						setValue(xmlFile, rcmKey .. '#fillType',   'str', mrData.workTool.realCapacityMultipliers[i].fillType);
						setValue(xmlFile, rcmKey .. '#multiplier', 'flt', mrData.workTool.realCapacityMultipliers[i].multiplier);
					end;
				end;
			end;
		end;


		-- animation speed scale
		if mrData.general.hasAnimationsSpeedScale then
			local a = 0;
			while true do
				local animKey = ('vehicle.animations.animation(%d)'):format(a);
				if not hasXMLProperty(xmlFile, animKey) then break; end;

				local animName = getXMLString(xmlFile, animKey .. '#name');
				local animScale = mrData.general.animationSpeedScale[animName];
				if animScale then
					local p = 0;
					while true do
						local partKey = ('%s.part(%d)'):format(animKey, p);
						if not hasXMLProperty(xmlFile, partKey) then break; end;

						local startTime = getXMLFloat(xmlFile, partKey .. '#startTime');
						local endTime   = getXMLFloat(xmlFile, partKey .. '#endTime');
						setValue(xmlFile, partKey .. '#startTime', 'flt', startTime / animScale);
						setValue(xmlFile, partKey .. '#endTime',   'flt', endTime / animScale);

						p = p + 1;
					end;
				end;
				a = a + 1;
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

-- ANGULAR + LINEAR DAMPING
local setMoreRealisticDamping = function(self, i3dNode, arguments)
	if self.isMoreRealisticDLC then
		for i,comp in ipairs(self.components) do
			setAngularDamping(comp.node, 0);
			setLinearDamping(comp.node, 0);
			-- print(('%s: loadFinished(): component %d (%d/%q): angularDamping set to %s, linearDamping set to %s'):format(tostring(self.name), i, comp.node, tostring(getName(comp.node)), tostring(getAngularDamping(comp.node)), tostring(getLinearDamping(comp.node))));
		end;
	end;
end;
Vehicle.loadFinished = Utils.appendedFunction(Vehicle.loadFinished, setMoreRealisticDamping);

-- BALES
local setBaleMrData = function(self, nodeId)
	if self.i3dFilename and self.i3dFilename:find('pdlc/ursusAddon') then
		setAngularDamping(self.nodeId, 0);
		setLinearDamping(self.nodeId, 0);
		setUserAttribute(self.nodeId, 'isRealistic', 'Boolean', true);
		setUserAttribute(self.nodeId, 'baleValueScale', 'Float', 1.6);
	end;
end;
Bale.setNodeId = Utils.appendedFunction(Bale.setNodeId, setBaleMrData);


local drawComponents = function(self, dt)
	if not self.isActive --[[or not self.isSelected]] then return; end;
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
-- Vehicle.update = Utils.appendedFunction(Vehicle.update, drawComponents);