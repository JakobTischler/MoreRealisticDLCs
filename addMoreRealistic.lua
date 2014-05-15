--[[
Case IH Puma 160 load: typeName="pdlc_titaniumAddon.tractor_wheelExtension", configFileName="C:/Users/JakobTischler/Documents/My Games/FarmingSimulator2013/pdlc/titaniumAddon/caseIH/caseIHPuma160.xml"
Case IH Magnum 340 load: typeName="pdlc_titaniumAddon.tractor_wheelExtension", configFileName="C:/Users/JakobTischler/Documents/My Games/FarmingSimulator2013/pdlc/titaniumAddon/caseIH/caseIHMagnum340.xml"
Case IH Magnum 340 load: typeName="pdlc_titaniumAddon.tractor_wheelExtension", configFileName="C:/Users/JakobTischler/Documents/My Games/FarmingSimulator2013/pdlc/titaniumAddon/caseIH/caseIHMagnum340TwinWheel.xml"
Case IH Axial Flow 7130 load: typeName="pdlc_titaniumAddon.combine_extended", configFileName="C:/Users/JakobTischler/Documents/My Games/FarmingSimulator2013/pdlc/titaniumAddon/caseIH/caseIH7130.xml"
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

		-- engine
		local hp = getXMLFloat(xmlFile, key .. '.engine#hp') or 100;
		local topSpeed = getXMLFloat(xmlFile, key .. '.engine#topSpeed') or 50;
		local reverseSpeed = getXMLFloat(xmlFile, key .. '.engine#reverseSpeed') or 20;
		local maxFuelUsage = getXMLFloat(xmlFile, key .. '.engine#maxFuelUsage');

		local braking = getXMLFloat(xmlFile, key .. '.engine#braking') or 4;


		-- dimensions
		local width = getXMLFloat(xmlFile, key .. '.dimensions#width') or 3;
		local height = getXMLFloat(xmlFile, key .. '.dimensions#height') or 3;


		-- weights
		local weight = getXMLFloat(xmlFile, key .. '.weights#weight');
		local maxWeight = getXMLFloat(xmlFile, key .. '.weights#maxWeight') or weight * 1.55;


		-- wheels
		local wheels = {};
		local w = 0;
		while true do
			local wheelKey = key .. ('.wheels.wheel(%d)'):format(w);
			if not hasXMLProperty(xmlFile, wheelKey) then break; end;

			wheels[#wheels + 1] = {
				driveMode = getXMLInt(xmlFile, wheelKey .. '#driveMode'), 
				deltaY = getXMLFloat(xmlFile, wheelKey .. '#deltaY'),
				brakeRatio = getXMLInt(xmlFile, wheelKey .. '#brakeRatio') or 1
			};

			w = w + 1;
		end;


		-- attacherJoints
		local attacherJoints = {};
		local a = 0;
		while true do
			local ajKey = key .. ('.attacherJoints.attacherJoint(%d)'):format(a);
			if not hasXMLProperty(xmlFile, ajKey) then break; end;

			attacherJoints[#attacherJoints + 1] = {
				maxRot = Utils.getNoNil(getXMLFloat(xmlFile, ajKey .. '#maxRot'), 0.2),
				maxRot2 = Utils.getNoNil(getXMLFloat(xmlFile, ajKey .. '#maxRot2'), -0.2),
				minRotDistanceToGround = Utils.getNoNil(getXMLFloat(xmlFile, ajKey .. '#minRotDistanceToGround'), 1);
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
				center = getXMLString(xmlFile, compKey .. '#center'),
				mass = getXMLFloat(xmlFile, compKey .. '#mass')
			};

			c = c + 1;
		end;


		-- workTool
		local workTool = {
			realPowerConsumption 	 = getXMLFloat(xmlFile, key .. '.workTool#realPowerConsumption');
			realWorkingSpeedLimit 	 = getXMLFloat(xmlFile, key .. '.workTool#realWorkingSpeedLimit');
			resistanceDecreaseFx 	 = getXMLFloat(xmlFile, key .. '.workTool#resistanceDecreaseFx');
			caRealTractionResistance = getXMLFloat(xmlFile, key .. '.workTool#caRealTractionResistance');
		};


		-- combine
		local combine = {
			realAiMinDistanceBeforeTurning 	 = getXMLFloat(xmlFile, key .. '.combine#realAiMinDistanceBeforeTurning');
			realAiManeuverSpeed 			 = getXMLFloat(xmlFile, key .. '.combine#realAiManeuverSpeed');
			realPtoPowerKW 					 = getXMLFloat(xmlFile, key .. '.combine#realPtoPowerKW');
			realTransmissionEfficiency 		 = getXMLFloat(xmlFile, key .. '.combine#realTransmissionEfficiency');
			realMaxPowerToTransmission 		 = getXMLFloat(xmlFile, key .. '.combine#realMaxPowerToTransmission');
			realHydrostaticTransmission 	 = getXMLBool( xmlFile, key .. '.combine#realHydrostaticTransmission');
			realUnloadingPowerBoost 		 = getXMLFloat(xmlFile, key .. '.combine#realUnloadingPowerBoost');
			realUnloadingPowerConsumption 	 = getXMLFloat(xmlFile, key .. '.combine#realUnloadingPowerConsumption');
			realThreshingPowerConsumption 	 = getXMLFloat(xmlFile, key .. '.combine#realThreshingPowerConsumption');
			realThreshingPowerConsumptionInc = getXMLFloat(xmlFile, key .. '.combine#realThreshingPowerConsumptionInc');
			realChopperPowerConsumption 	 = getXMLFloat(xmlFile, key .. '.combine#realChopperPowerConsumption');
			realChopperPowerConsumptionInc 	 = getXMLFloat(xmlFile, key .. '.combine#realChopperPowerConsumptionInc');
			realThreshingScale 				 = getXMLFloat(xmlFile, key .. '.combine#realThreshingScale');
		};

		--------------------------------------------------

		vehicleData[configFileName] = {
			category = category,
			configFileName = configFileName,
			vehicleType = modName .. '.' .. vehicleType,
			kW = hp * 0.745699872,
			topSpeed = topSpeed,
			reverseSpeed = reverseSpeed,
			braking = braking,
			maxFuelUsage = maxFuelUsage,
			width = width,
			height = height,
			weight = weight,
			maxWeight = maxWeight,
			wheels = wheels,
			attacherJoints = attacherJoints,
			workTool = workTool,
			components = components
		};

		--------------------------------------------------

		i = i + 1;
	end;

	delete(xmlFile);
end;

getData();

local prmSetXMLFn = {
	bool = setXMLBool,
	float = setXMLFloat,
	int = setXMLInt,
	str = setXMLString
};
local setValue = function(xmlFile, parameter, prmType, value)
	if value ~= nil then
		prmSetXMLFn[prmType](xmlFile, parameter, value);
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
	local mrData;
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

	local xmlFile = loadXMLFile("TempConfig", configFile);



	if addMrData then
		removeXMLProperty(xmlFile, 'vehicle.motor');

		if mrData.category == 'steerable' or mrData.category == 'combine' then
			-- accelerationSpeed
			setXMLInt(xmlFile, 'vehicle.accelerationSpeed#maxAcceleration', 1);
			setXMLInt(xmlFile, 'vehicle.accelerationSpeed#deceleration', 1);
			setXMLInt(xmlFile, 'vehicle.accelerationSpeed#brakeSpeed', 3);
			removeXMLProperty(xmlFile, 'vehicle.accelerationSpeed#backwardDeceleration');

			-- fuel usage, downforce
			setXMLInt(xmlFile, 'vehicle.fuelUsage', 0);
			setXMLInt(xmlFile, 'vehicle.downForce', 0);

			setXMLFloat(xmlFile, 'vehicle.realPtoPowerKW', mrData.kW * 0.92);
			setValue(xmlFile, 'vehicle.realMaxFuelUsage', 'flt', mrData.maxFuelUsage);
			setXMLBool(xmlFile, 'vehicle.realDisplaySlip', true);

			if mrData.category == 'combine' then
				setXMLString(xmlFile, 'vehicle.realSpeedLevel', '5 6 9');
				setXMLInt(xmlFile, 'vehicle.realAiWorkingSpeed#baseSpeed', 5);
				setXMLInt(xmlFile, 'vehicle.realAiWorkingSpeed#maxSpeed', mrData.workTool.realWorkingSpeedLimit or 12);
				setXMLInt(xmlFile, 'vehicle.realAiWorkingSpeed#minSpeed', 3);

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
		setXMLFloat(xmlFile, 'vehicle.bunkerSiloCompactor#compactingScale', 0.25 * mrData.weight);
		setXMLFloat(xmlFile, 'vehicle.realMaxVehicleSpeed', mrData.topSpeed);
		setXMLFloat(xmlFile, 'vehicle.realMaxReverseSpeed', mrData.reverseSpeed);
		setXMLFloat(xmlFile, 'vehicle.realBrakeMaxMovingMass', 1.5 * mrData.maxWeight);
		setXMLFloat(xmlFile, 'vehicle.realBrakingDeceleration', mrData.braking);
		setXMLFloat(xmlFile, 'vehicle.realSCX', mrData.width * mrData.height * 0.68);
	   
		-- wheels
		setXMLFloat(xmlFile, 'vehicle.wheels#autoRotateBackSpeed', 1);
		local wheelI = 0;
		while true do
			local wheelKey = ('vehicle.wheels.wheel(%d)'):format(wheelI);
			local repr = getXMLString(xmlFile, wheelKey .. '#repr');
			if not repr or repr == '' then break; end;
			print('wheels: ' .. wheelI);

			local wheelMrData = mrData.wheels[wheelI + 1];

			removeXMLProperty(xmlFile, wheelKey .. '#lateralStiffness');
			removeXMLProperty(xmlFile, wheelKey .. '#longitudalStiffness');
			setXMLInt(xmlFile, wheelKey .. '#driveMode', wheelMrData.driveMode);
			setXMLInt(xmlFile, wheelKey .. '#brakeRatio', wheelMrData.brakeRatio);
			setXMLInt(xmlFile, wheelKey .. '#damper', 20);
			setXMLInt(xmlFile, wheelKey .. '#mass', 1);

			local suspTravel = getXMLFloat(xmlFile, wheelKey .. '#suspTravel');
			local deltaY = getXMLFloat(xmlFile, wheelKey .. '#deltaY');
			if suspTravel == nil or suspTravel == '' or suspTravel < 0.05 then
				suspTravel = 0.08;
				setXMLFloat(xmlFile, wheelKey .. '#suspTravel', suspTravel);
			end;
			setXMLFloat(xmlFile, wheelKey .. '#spring', 278 * (mrData.maxWeight * 0.25) / (suspTravel * 100 - 2));
			if deltaY == nil or deltaY == '' or deltaY == 0 and not wheelMrData.deltaY then
				setXMLFloat(xmlFile, wheelKey .. '#deltaY', suspTravel * 0.9);
			else
				setValue(xmlFile, wheelKey .. '#deltaY', 'flt',  wheelMrData.deltaY);
			end;

			wheelI = wheelI + 1;
		end;

		-- attacherJoints
		if mrData.category == 'steerable' or mrData.category == 'combine' then
			local a = 0;
			while true do
				local ajKey = ('vehicle.attacherJoints.attacherJoint(%d)'):format(a);
				if not hasXMLProperty(xmlFile, ajKey) then break; end;

				removeXMLProperty(xmlFile, ajKey .. '#maxRotLimit');
				removeXMLProperty(xmlFile, ajKey .. '#minRot2');
				removeXMLProperty(xmlFile, ajKey .. '#minRotRotationOffset');
				removeXMLProperty(xmlFile, ajKey .. '#maxTransLimit');

				local ajMrData = mrData.attacherJoints[a + 1];
				setXMLFloat(xmlFile, ajKey .. '#maxRot', ajMrData.maxRot);
				setXMLFloat(xmlFile, ajKey .. '#maxRot2', ajMrData.maxRot2);
				setXMLFloat(xmlFile, ajKey .. '#minRotDistanceToGround', ajMrData.minRotDistanceToGround);

				a = a + 1;
			end;
		end;

		-- components
		for i=1, getXMLInt(xmlFile, 'vehicle.components#count') do
			setValue(xmlFile, ('vehicle.components.component%d#centerOfMass'):format(i), 'str', mrData.components[i].center);
			setValue(xmlFile, ('vehicle.components.component%d#realMassWanted'):format(i), 'flt', mrData.components[i].mass);
		end;

		-- workTool
		if mrData.category == 'tool' or mrData.category == 'combine' then
			setValue(xmlFile, 'vehicle.realPowerConsumption', 'flt', mrData.workTool.realPowerConsumption);
			setValue(xmlFile, 'vehicle.realWorkingSpeedLimit', 'flt', mrData.workTool.realWorkingSpeedLimit);
			setValue(xmlFile, 'vehicle.realTilledGroundBonus#resistanceDecreaseFx', 'flt', mrData.workTool.resistanceDecreaseFx);

			if mrData.workTool.caRealTractionResistance then
				local caCount = getXMLInt(xmlFile, 'vehicle.cuttingAreas#count');
				local resistanceDecreaseFxPerCa = mrData.workTool.caRealTractionResistance / caCount;
				for i=1, caCount do
					setXMLFloat(xmlFile, ('vehicle.cuttingAreas.cuttingArea%d#resistanceDecreaseFxPerCa'):format(i), resistanceDecreaseFxPerCa);
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
	--print('loading mod ' .. tostring(modName));
	local additionnalOffsetY = Utils.getNoNil(getXMLFloat(xmlFile, 'vehicle.size#yOffset'), 0);
	offsetY = offsetY + additionnalOffsetY;

	--Vehicle.springScale = 10000;
	--print('test Vehicle.springScale : ' .. tostring(Vehicle.springScale));
   
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