﻿--[[
Case IH Axial Flow 9230 load: typeName="pdlc_titaniumAddon.combine_extended", configFileName="C:/Users/JakobTischler/Documents/My Games/FarmingSimulator2013/pdlc/titaniumAddon/caseIH/caseIH9230.xml"
Case IH Axial Flow 9230 Quadtrac load: typeName="pdlc_titaniumAddon.combine_extended_crawler", configFileName="C:/Users/JakobTischler/Documents/My Games/FarmingSimulator2013/pdlc/titaniumAddon/caseIH/caseIH9230Crawler.xml"
Krone BigX 1100 load: typeName="pdlc_titaniumAddon.combine_extended", configFileName="C:/Users/JakobTischler/Documents/My Games/FarmingSimulator2013/pdlc/titaniumAddon/krone/kroneBigX1100.xml"
Lizard Truck load: typeName="pdlc_titaniumAddon.truck", configFileName="C:/Users/JakobTischler/Documents/My Games/FarmingSimulator2013/pdlc/titaniumAddon/lizard/americanTruck.xml"
--]]

local modDir, modName = g_currentModDirectory, g_currentModName;
local vehicleData = {};

local getData = function()
	local vehicleDataPath = Utils.getFilename('vehicleData.xml', modDir);
	assert(fileExists(vehicleDataPath), 'ERROR: "vehicleData.xml" could not be found');
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

		-- engine
		local kW = getXMLFloat(xmlFile, key .. '.engine#kW') or 100;
		local realMaxVehicleSpeed = getXMLFloat(xmlFile, key .. '.engine#realMaxVehicleSpeed') or 50;
		local realMaxReverseSpeed = getXMLFloat(xmlFile, key .. '.engine#realMaxReverseSpeed') or 20;
		local realMaxFuelUsage = getXMLFloat(xmlFile, key .. '.engine#realMaxFuelUsage');

		local realBrakingDeceleration = getXMLFloat(xmlFile, key .. '.engine#realBrakingDeceleration') or 4;


		-- dimensions
		local width = getXMLFloat(xmlFile, key .. '.dimensions#width') or 3;
		assert(width, ('ERROR: "dimensions#width" missing for %q'):format(configFileName));
		local height = getXMLFloat(xmlFile, key .. '.dimensions#height') or 3;
		assert(height, ('ERROR: "dimensions#height" missing for %q'):format(configFileName));


		-- weights
		local weight = getXMLFloat(xmlFile, key .. '.weights#weight');
		assert(weight, ('ERROR: "weights#weight" missing for %q'):format(configFileName));
		local maxWeight = getXMLFloat(xmlFile, key .. '.weights#maxWeight') or weight * 1.55;


		-- wheels
		local wheels = {};
		local w = 0;
		while true do
			local wheelKey = key .. ('.wheels.wheel(%d)'):format(w);
			if not hasXMLProperty(xmlFile, wheelKey) then break; end;

			wheels[#wheels + 1] = {
				driveMode  =   getXMLInt(xmlFile, wheelKey .. '#driveMode'), 
				rotMax     = getXMLFloat(xmlFile, wheelKey .. '#rotMax'),
				rotMin     = getXMLFloat(xmlFile, wheelKey .. '#rotMin'),
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
			realPowerConsumption 				 = getXMLFloat(xmlFile, key .. '.workTool#realPowerConsumption');
			realPowerConsumptionWhenWorking		 = getXMLFloat(xmlFile, key .. '.workTool#realPowerConsumptionWhenWorking');
			realPowerConsumptionWhenWorkingInc	 = getXMLFloat(xmlFile, key .. '.workTool#realPowerConsumptionWhenWorkingInc');
			realWorkingSpeedLimit 				 = getXMLFloat(xmlFile, key .. '.workTool#realWorkingSpeedLimit');
			realRollingResistance				 = getXMLFloat(xmlFile, key .. '.workTool#realRollingResistance') or 0;
			realResistanceOnlyWhenActive		 = Utils.getNoNil(getXMLBool(xmlFile, key .. '.workTool#realResistanceOnlyWhenActive'), false);
			resistanceDecreaseFx 				 = getXMLFloat(xmlFile, key .. '.workTool#resistanceDecreaseFx');
			caRealTractionResistance			 = getXMLFloat(xmlFile, key .. '.workTool#caRealTractionResistance');
			caRealTractionResistanceWithLoadMass = getXMLFloat(xmlFile, key .. '.workTool#caRealTractionResistanceWithLoadMass') or 0;

			-- cutter
			realCutterPowerConsumption	  = getXMLFloat(xmlFile, key .. '.workTool#realCutterPowerConsumption') or 25;
			realCutterPowerConsumptionInc = getXMLFloat(xmlFile, key .. '.workTool#realCutterPowerConsumptionInc') or 2.5;
			realCutterSpeedLimit		  = getXMLFloat(xmlFile, key .. '.workTool#realCutterSpeedLimit') or 14;
		};


		-- combine
		local combine = {
			realSpeedLevel					 = getXMLString(xmlFile, key .. '.combine#realSpeedLevel') or '5 6 9';
			baseSpeed 						 =  getXMLFloat(xmlFile, key .. '.combine#baseSpeed') or 5;
			minSpeed 						 =  getXMLFloat(xmlFile, key .. '.combine#minSpeed') or 3;
			maxSpeed 						 =  getXMLFloat(xmlFile, key .. '.combine#maxSpeed') or 12;
			realAiMinDistanceBeforeTurning 	 =  getXMLFloat(xmlFile, key .. '.combine#realAiMinDistanceBeforeTurning');
			realAiManeuverSpeed 			 =  getXMLFloat(xmlFile, key .. '.combine#realAiManeuverSpeed');
			realPtoPowerKW 					 =  getXMLFloat(xmlFile, key .. '.combine#realPtoPowerKW');
			realTransmissionEfficiency 		 =  getXMLFloat(xmlFile, key .. '.combine#realTransmissionEfficiency');
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
			doDebug = doDebug,
			kW = kW,
			realMaxVehicleSpeed = realMaxVehicleSpeed,
			realMaxReverseSpeed = realMaxReverseSpeed,
			realBrakingDeceleration = realBrakingDeceleration,
			realMaxFuelUsage = realMaxFuelUsage,
			width = width,
			height = height,
			weight = weight,
			maxWeight = maxWeight,
			wheels = wheels,
			attacherJoints = attacherJoints,
			workTool = workTool,
			combine = combine,
			components = components
		};

		if Utils.startsWith(vehicleType, 'mr_') then
			vehicleData[configFileName].vehicleType = modName .. '.' .. vehicleType;
		else
			vehicleData[configFileName].vehicleType = vehicleType;
		end;

		--------------------------------------------------

		i = i + 1;
	end;

	delete(xmlFile);
end;

getData();
local mrData;

local prmSetXMLFn = {
	bool = setXMLBool,
	flt = setXMLFloat,
	int = setXMLInt,
	str = setXMLString
};
local setValue = function(xmlFile, parameter, prmType, value)
	if value ~= nil then
		prmSetXMLFn[prmType](xmlFile, parameter, value);
		if mrData and mrData.doDebug then
			print(('\tset parameter %q (type %s) to %q'):format(parameter, prmType, tostring(value)));
		end;
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

local origVehicleLoad = Vehicle.load;
Vehicle.load = function(self, configFile, positionX, offsetY, positionZ, yRot, typeName, isVehicleSaved, asyncCallbackFunction, asyncCallbackObject, asyncCallbackArguments)
	local modName, baseDirectory = Utils.getModNameAndBaseDirectory(configFile);
 	self.configFileName = configFile;
	self.baseDirectory = baseDirectory;
	self.customEnvironment = modName;
	self.typeName = typeName;

	-- 
	local addMrData = false;
	local cfnStart, _ = configFile:find('/pdlc/');
	if cfnStart then
		print(('%s load: typeName=%q, configFileName=%q'):format(tostring(self.name), tostring(self.typeName), tostring(self.configFileName)));
		print(('\tmodName=%q, baseDirectory=%q'):format(tostring(modName), tostring(baseDirectory)));
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

		if mrData.category == 'steerable' then
			-- accelerationSpeed
			setValue(xmlFile, 'vehicle.accelerationSpeed#maxAcceleration', 'int', 1);
			setValue(xmlFile, 'vehicle.accelerationSpeed#deceleration', 'int', 1);
			setValue(xmlFile, 'vehicle.accelerationSpeed#brakeSpeed', 'int', 3);
			removeProperty(xmlFile, 'vehicle.accelerationSpeed#backwardDeceleration');

			-- fuel usage, downforce
			setValue(xmlFile, 'vehicle.fuelUsage', 'int', 0);
			setValue(xmlFile, 'vehicle.downForce', 'int', 0);

			setValue(xmlFile, 'vehicle.realPtoPowerKW', 'flt', mrData.kW * 0.92);
			setValue(xmlFile, 'vehicle.realMaxFuelUsage', 'flt', mrData.realMaxFuelUsage);
			setValue(xmlFile, 'vehicle.realDisplaySlip', 'bool', true);

			-- combine
			if mrData.subCategory == 'combine' then
				setValue(xmlFile, 'vehicle.realSpeedLevel', 				  'str',  mrData.combine.realSpeedLevel);
				setValue(xmlFile, 'vehicle.realAiWorkingSpeed#baseSpeed', 	  'int',  mrData.combine.baseSpeed);
				setValue(xmlFile, 'vehicle.realAiWorkingSpeed#minSpeed', 	  'int',  mrData.combine.minSpeed);
				setValue(xmlFile, 'vehicle.realAiWorkingSpeed#maxSpeed', 	  'int',  mrData.combine.maxSpeed);

				setValue(xmlFile, 'vehicle.realAiMinDistanceBeforeTurning',   'flt',  mrData.combine.realAiMinDistanceBeforeTurning);
				setValue(xmlFile, 'vehicle.realAiManeuverSpeed', 			  'flt',  mrData.combine.realAiManeuverSpeed);
				setValue(xmlFile, 'vehicle.realTransmissionEfficiency', 	  'flt',  mrData.combine.realTransmissionEfficiency);
				setValue(xmlFile, 'vehicle.realMaxPowerToTransmission', 	  'flt',  mrData.combine.realMaxPowerToTransmission);
				setValue(xmlFile, 'vehicle.realHydrostaticTransmission', 	  'bool', mrData.combine.realHydrostaticTransmission);
				setValue(xmlFile, 'vehicle.realUnloadingPowerBoost', 		  'flt',  mrData.combine.realUnloadingPowerBoost);
				setValue(xmlFile, 'vehicle.realUnloadingPowerConsumption', 	  'flt',  mrData.combine.realUnloadingPowerConsumption);
				setValue(xmlFile, 'vehicle.realThreshingPowerConsumption', 	  'flt',  mrData.combine.realThreshingPowerConsumption);
				setValue(xmlFile, 'vehicle.realThreshingPowerConsumptionInc', 'flt',  mrData.combine.realThreshingPowerConsumptionInc);
				setValue(xmlFile, 'vehicle.realChopperPowerConsumption', 	  'flt',  mrData.combine.realChopperPowerConsumption);
				setValue(xmlFile, 'vehicle.realChopperPowerConsumptionInc',   'flt',  mrData.combine.realChopperPowerConsumptionInc);
				setValue(xmlFile, 'vehicle.realThreshingScale', 			  'flt',  mrData.combine.realThreshingScale);
				setValue(xmlFile, 'vehicle.realPtoPowerKW', 				  'flt',  mrData.combine.realPtoPowerKW);
			end;
		end;


		-- relevant MR values
		setValue(xmlFile, 'vehicle.bunkerSiloCompactor#compactingScale', 'flt', mrData.weight * 0.25);
		setValue(xmlFile, 'vehicle.realMaxVehicleSpeed', 				 'flt', mrData.realMaxVehicleSpeed);
		setValue(xmlFile, 'vehicle.realMaxReverseSpeed', 				 'flt', mrData.realMaxReverseSpeed);
		setValue(xmlFile, 'vehicle.realBrakeMaxMovingMass', 			 'flt', mrData.maxWeight * 1.5);
		setValue(xmlFile, 'vehicle.realBrakingDeceleration', 			 'flt', mrData.realBrakingDeceleration);
		setValue(xmlFile, 'vehicle.realSCX', 							 'flt', mrData.width * mrData.height * 0.68);


		-- wheels
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
			setValue(xmlFile, wheelKey .. '#brakeRatio', 'int', wheelMrData.brakeRatio);
			setValue(xmlFile, wheelKey .. '#damper',     'int', wheelMrData.damper);
			setValue(xmlFile, wheelKey .. '#mass',       'int', 1);

			local suspTravel = wheelMrData.suspTravel or getXMLFloat(xmlFile, wheelKey .. '#suspTravel');
			if suspTravel == nil or suspTravel == '' or suspTravel < 0.05 then
				suspTravel = 0.08;
			end;
			setValue(xmlFile, wheelKey .. '#suspTravel', 'flt', suspTravel);

			-- MR 1.2: setValue(xmlFile, wheelKey .. '#spring', 'flt', wheelMrData.spring or 278 * (mrData.maxWeight * 0.25) / (suspTravel * 100 - 2));
			setValue(xmlFile, wheelKey .. '#spring', 'flt', wheelMrData.spring or mrData.maxWeight * 0.25 * 3 / suspTravel);

			local deltaY = getXMLFloat(xmlFile, wheelKey .. '#deltaY');
			if deltaY == nil or deltaY == '' or deltaY == 0 and not wheelMrData.deltaY then
				setValue(xmlFile, wheelKey .. '#deltaY', 'flt', suspTravel * 0.9);
			else
				setValue(xmlFile, wheelKey .. '#deltaY', 'flt', wheelMrData.deltaY);
			end;

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
				setValue(xmlFile, 'vehicle.realPowerConsumption', 'flt', mrData.workTool.realPowerConsumption);
				setValue(xmlFile, 'vehicle.realWorkingSpeedLimit', 'flt', mrData.workTool.realWorkingSpeedLimit);
				setValue(xmlFile, 'vehicle.realRollingResistance', 'flt', mrData.workTool.realRollingResistance);
				setValue(xmlFile, 'vehicle.realResistanceOnlyWhenActive', 'bool', mrData.workTool.realResistanceOnlyWhenActive);
				setValue(xmlFile, 'vehicle.realTilledGroundBonus#resistanceDecreaseFx', 'flt', mrData.workTool.resistanceDecreaseFx);

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
			end;
		end;

		-- edit store item
		local storeItem = StoreItemsUtil.storeItemsByXMLFilename[self.configFileName:lower()];
		storeItem.name = 'MR ' .. storeItem.name;
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