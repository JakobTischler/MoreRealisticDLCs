local modDir, modName = g_currentModDirectory, g_currentModName;

--------------------------------------------------

local prmGetXMLFn = {
	bool = getXMLBool,
	flt = getXMLFloat,
	int = getXMLInt,
	str = getXMLString
};

-- GET VEHICLE MR DATA
function MoreRealisticDLCs:getMrData(vehicleDataPath, dlcName)
	assert(fileExists(vehicleDataPath), ('ERROR: %q could not be found'):format(vehicleDataPath));
	local xmlFile = loadXMLFile('vehicleDataFile', vehicleDataPath);

	local get = function(prmType, key)
		return prmGetXMLFn[prmType](xmlFile, key);
	end;

	local has = function(key)
		return hasXMLProperty(xmlFile, key);
	end;

	--------------------------------------------------

	local i = 0;
	while true do
		local key = ('vehicles.vehicle(%d)'):format(i);
		if not has(key) then break; end;

		-- base
		local configFileName = get('str',  key .. '#configFileName');
		local vehicleTyp	 = get('str',  key .. '#mrVehicleType');
		local category		 = get('str',  key .. '#category');
		local subCategory	 = get('str',  key .. '#subCategory') or '';
		local doDebug		 = get('bool', key .. '#debug');
		assert(configFileName, ('ERROR: "configFileName" missing for %q'):format(key));
		assert(vehicleType, ('ERROR: "mrVehicleType" missing for %q'):format(configFileName));
		assert(category, ('ERROR: "category" missing for %q'):format(configFileName));


		-- general
		local general = {
			fuelCapacity 						  = get('flt',  key .. '.general#fuelCapacity');
			realMaxVehicleSpeed 				  = get('flt',  key .. '.general#realMaxVehicleSpeed');
			realBrakingDeceleration 			  = get('flt',  key .. '.general#realBrakingDeceleration');
			realCanLockWheelsWhenBraking		  = get('bool', key .. '.general#realCanLockWheelsWhenBraking');
			realRollingResistance 				  = get('flt',  key .. '.general#realRollingResistance');
			realWorkingPowerConsumption			  = get('flt',  key .. '.general#realWorkingPowerConsumption');
			realDisplaySlip						  = Utils.getNoNil(get('bool', key .. '.general#realDisplaySlip'), true);
			realMotorizedWheelsDriveLossFx		  = get('flt',  key .. '.general#realMotorizedWheelsDriveLossFx');
			realVehicleOnFieldRollingResistanceFx = get('flt',  key .. '.general#realVehicleOnFieldRollingResistanceFx');
			waitForTurnTime						  = get('flt',  key .. '.general#waitForTurnTime');
		};

		-- animation values
		general.animationValues = {};
		local p = 0;
		while true do
			local partKey = key .. ('.animationValues.part(%d)'):format(p);
			if not has(partKey) then break; end;

			local animIndex = get('int', partKey .. '#animIndex');
			local partIndex = get('int', partKey .. '#partIndex');
			if not animIndex or not partIndex then break; end;

			general.animationValues[#general.animationValues + 1] = {
				animIndex = animIndex;
				partIndex = partIndex;
				startRot		= get('str', partKey .. '#startRot');
				startRotLimit	= get('str', partKey .. '#startRotLimit');
				startTrans		= get('str', partKey .. '#startTrans');
				startTransLimit	= get('str', partKey .. '#startTransLimit');
				endRot			= get('str', partKey .. '#endRot');
				endRotLimit		= get('str', partKey .. '#endRotLimit');
				endTrans		= get('str', partKey .. '#endTrans');
				endTransLimit	= get('str', partKey .. '#endTransLimit');
			};
			general.hasAnimationValues = true;

			p = p + 1;
		end;

		-- animation speed scale
		general.animationSpeedScale = {};
		local animsStr = get('str', key .. '.general#animationSpeedScale');
		if animsStr then
			animsStr = Utils.splitString(',', animsStr);
			for i,data in pairs(animsStr) do
				local dataSplit = Utils.splitString(':', data);
				general.animationSpeedScale[dataSplit[1]] = tonumber(dataSplit[2]);
				general.hasAnimationsSpeedScale = true;
			end;
		end;

		-- animation time offset
		general.animationTimeOffset = {};
		local animsStr = get('str', key .. '.general#animationTimeOffset');
		if animsStr then
			animsStr = Utils.splitString(',', animsStr);
			for i,data in pairs(animsStr) do
				local dataSplit = Utils.splitString(':', data);
				general.animationTimeOffset[dataSplit[1]] = tonumber(dataSplit[2]);
				general.hasAnimationsTimeOffset = true;
			end;
		end;

		-- moving tool speed scale
		general.movingToolSpeedScale = {};
		local mtString = get('str', key .. '.general#movingToolSpeedScale');
		if mtString then
			general.movingToolSpeedScale = Utils.getVectorNFromString(mtString, nil);
		end;


		-- engine
		local engine = {
			kW 									= get('flt',  key .. '.engine#kW');
			accelerationSpeedMaxAcceleration	= get('flt',  key .. '.engine#accelerationSpeedMaxAcceleration') or 1;
			realMaxReverseSpeed 				= get('flt',  key .. '.engine#realMaxReverseSpeed');
			realMaxFuelUsage 					= get('flt',  key .. '.engine#realMaxFuelUsage');
			realSpeedBoost 						= get('flt',  key .. '.engine#realSpeedBoost');
			realSpeedBoostMinSpeed 				= get('flt',  key .. '.engine#realSpeedBoostMinSpeed');
			realImplementNeedsBoost 			= get('flt',  key .. '.engine#realImplementNeedsBoost');
			realImplementNeedsBoostMinPowerCons = get('flt',  key .. '.engine#realImplementNeedsBoostMinPowerCons');
			realMaxBoost 						= get('flt',  key .. '.engine#realMaxBoost');
			realTransmissionEfficiency 			= get('flt',  key .. '.engine#realTransmissionEfficiency');
			realPtoDriveEfficiency				= get('flt',  key .. '.engine#realPtoDriveEfficiency') or 0.92;
			realSpeedLevel						= get('str',  key .. '.engine#realSpeedLevel');
			realAiManeuverSpeed 				= get('flt',  key .. '.engine#realAiManeuverSpeed');
			realMaxPowerToTransmission 			= get('flt',  key .. '.engine#realMaxPowerToTransmission');
			realHydrostaticTransmission 		= get('bool', key .. '.engine#realHydrostaticTransmission');
			realMinSpeedForMaxPower 			= get('flt',  key .. '.engine#realMinSpeedForMaxPower');
			newExhaustPS						= get('bool', key .. '.engine#newExhaustPS');
			newExhaustMinAlpha					= get('flt',  key .. '.engine#newExhaustMinAlpha');
			newExhaustCapAxis					= get('str',  key .. '.engine#capAxis');
		};
		if engine.kW then
			engine.realPtoPowerKW 				= get('flt',  key .. '.engine#realPtoPowerKW') or engine.kW * engine.realPtoDriveEfficiency;
		end;


		-- dimensions
		local width  = get('flt', key .. '.dimensions#width') or 3;
		assert(width, ('ERROR: "dimensions#width" missing for %q'):format(configFileName));
		local height = get('flt', key .. '.dimensions#height') or 3;
		assert(height, ('ERROR: "dimensions#height" missing for %q'):format(configFileName));


		-- weights
		local weights = {};
		weights.weight					= get('flt', key .. '.weights#weight');
		assert(weights.weight, ('ERROR: "weights#weight" missing for %q'):format(configFileName));
		weights.maxWeight				= get('flt', key .. '.weights#maxWeight') or weights.weight * 1.55;
		weights.realBrakeMaxMovingMass	= get('flt', key .. '.weights#realBrakeMaxMovingMass'); -- or weights.maxWeight * 1.5;


		-- wheels
		local wheelStuff = {
			realTyreGripFx			  = get('flt',  key .. '.wheels#realTyreGripFx');
			realIsTracked			  = get('bool', key .. '.wheels#realIsTracked');
			realVehicleFlotationFx	  = get('flt',  key .. '.wheels#realVehicleFlotationFx');
			realNoSteeringAxleDamping = get('bool', key .. '.wheels#realNoSteeringAxleDamping');
			overwriteWheels			  = get('bool', key .. '.wheels#overwrite');
			crawlersRealWheel		  = {};
		};
		local crawlersRealWheelStr = get('str', key .. '.wheels#crawlersRealWheel');
		if crawlersRealWheelStr then
			wheelStuff.crawlersRealWheel = Utils.getVectorNFromString(crawlersRealWheelStr);
		end;


		local wheels = {};
		local w = 0;
		while true do
			local wheelKey = key .. ('.wheels.wheel(%d)'):format(w);
			if not has(wheelKey) then break; end;

			wheels[#wheels + 1] = {
				repr			   = get('str', wheelKey .. '#repr'),
				driveNode		   = get('str', wheelKey .. '#driveNode'),
				driveMode		   = get('int', wheelKey .. '#driveMode'),
				rotMax			   = get('flt', wheelKey .. '#rotMax'),
				rotMin			   = get('flt', wheelKey .. '#rotMin'),
				rotSpeed		   = get('flt', wheelKey .. '#rotSpeed'),
				radius			   = get('flt', wheelKey .. '#radius'),
				deltaY			   = get('flt', wheelKey .. '#deltaY'),
				suspTravel		   = get('flt', wheelKey .. '#suspTravel'),
				spring			   = get('flt', wheelKey .. '#spring'),
				damper			   = get('int', wheelKey .. '#damper') or 20,
				brakeRatio		   = get('flt', wheelKey .. '#brakeRatio') or 1,
				lateralStiffness   = get('flt', wheelKey .. '#lateralStiffness'),
				antiRollFx		   = get('flt', wheelKey .. '#antiRollFx'),
				realMaxMassAllowed = get('flt', wheelKey .. '#realMaxMassAllowed'),
				tirePressureFx	   = get('flt', wheelKey .. '#tirePressureFx')
				steeringAxleScale  = get('flt', wheelKey .. '#steeringAxleScale')
			};

			w = w + 1;
		end;

		-- additionalWheels
		local additionalWheels = {};
		w = 0;
		while true do
			local wheelKey = key .. ('.additionalWheels.wheel(%d)'):format(w);
			if not has(wheelKey) then break; end;

			additionalWheels[#additionalWheels + 1] = {
				repr							 = get('str', wheelKey .. '#repr'),
				radius							 = get('flt', wheelKey .. '#radius'),
				deltaY							 = get('flt', wheelKey .. '#deltaY'),
				suspTravel						 = get('flt', wheelKey .. '#suspTravel'),
				spring							 = get('flt', wheelKey .. '#spring'),
				damper							 = get('int', wheelKey .. '#damper') or 20,
				brakeRatio						 = get('flt', wheelKey .. '#brakeRatio') or 1,
				antiRollFx						 = get('flt', wheelKey .. '#antiRollFx'),
				lateralStiffness				 = get('flt', wheelKey .. '#lateralStiffness'),
				steeringAxleScale				 = get('flt', wheelKey .. '#steeringAxleScale'),
				continousBrakeForceWhenNotActive = get('flt', wheelKey .. '#continousBrakeForceWhenNotActive')
			};

			w = w + 1;
		end;


		-- attacherJoints
		local attacherJoints = {};
		local a = 0;
		while true do
			local ajKey = key .. ('.attacherJoints.attacherJoint(%d)'):format(a);
			if not has(ajKey) then break; end;

			local ajData = {};
			local jointType = get('str', ajKey .. '#jointType');
			if jointType and (jointType == 'implement' or jointType == 'cutter') then
				ajData.jointType = jointType;
				ajData.minRot				  = get('str', ajKey .. '#minRot');
				ajData.maxRot				  = get('str', ajKey .. '#maxRot');
				ajData.maxRot2				  = get('str', ajKey .. '#maxRot2');
				ajData.maxRotDistanceToGround = get('flt', ajKey .. '#maxRotDistanceToGround');
				ajData.minRotDistanceToGround = get('flt', ajKey .. '#minRotDistanceToGround');
				ajData.moveTime				  = get('flt', ajKey .. '#moveTime');

				-- cutter attacher joint
				ajData.lowerDistanceToGround 	   = get('flt', ajKey .. '#lowerDistanceToGround');
				ajData.upperDistanceToGround 	   = get('flt', ajKey .. '#upperDistanceToGround');
				ajData.realWantedLoweredTransLimit = get('str', ajKey .. '#realWantedLoweredTransLimit');
				ajData.realWantedLoweredRotLimit   = get('str', ajKey .. '#realWantedLoweredRotLimit');
				ajData.realWantedRaisedRotLimit	   = get('str', ajKey .. '#realWantedRaisedRotLimit');
				ajData.realWantedLoweredRot2 	   = get('flt', ajKey .. '#realWantedLoweredRot2');
				ajData.realWantedRaisedRotInc 	   = get('flt', ajKey .. '#realWantedRaisedRotInc');

			elseif jointType and (jointType == 'trailer' or jointType == 'trailerLow') then
				ajData.maxRotLimit				= get('str',  ajKey .. '#maxRotLimit');
				ajData.maxTransLimit			= get('str',  ajKey .. '#maxTransLimit');
				ajData.allowsJointLimitMovement = get('bool', ajKey .. '#allowsJointLimitMovement');
				ajData.allowsLowering			= get('bool', ajKey .. '#allowsLowering');
			end;

			attacherJoints[#attacherJoints + 1] = ajData;

			a = a + 1;
		end;


		-- trailerAttacherJoints
		local trailerAttacherJoints = {};
		a = 0;
		while true do
			local tajKey = key .. ('.trailerAttacherJoints.trailerAttacherJoint(%d)'):format(a);
			if not has(tajKey) then break; end;

			trailerAttacherJoints[#trailerAttacherJoints + 1] = {
				index 		  = get('str',  tajKey .. '#index');
				low 		  = get('bool', tajKey .. '#low');
				maxRotLimit	  = get('str',  tajKey .. '#maxRotLimit');
				ptoOutputNode = get('str',  tajKey .. '#ptoOutputNode');
				ptoFilename	  = get('str',  tajKey .. '#ptoFilename');
				schemaOverlay = {
					index	  = get('int',  tajKey .. '#schemaOverlayIndex');
					position  = get('str',  tajKey .. '#schemaOverlayPosition');
					invertX	  = get('bool', tajKey .. '#schemaOverlayInvertX');
				};
			};

			a = a + 1;
		end;


		-- components
		local components = {};
		local c = 1;
		while true do
			local compKey = key .. ('.components.component%d'):format(c);
			if not has(compKey) then break; end;

			components[#components + 1] = {
				centerOfMass		 = get('str', compKey .. '#centerOfMass'),
				realMassWanted		 = get('flt', compKey .. '#realMassWanted'),
				realTransWithMass	 = get('str', compKey .. '#realTransWithMass'),
				realTransWithMassMax = get('str', compKey .. '#realTransWithMassMax')
			};

			c = c + 1;
		end;


		-- workTool
		local workTool = {
			capacity								= get('int',  key .. '.workTool#capacity');
			realPowerConsumption					= get('flt',  key .. '.workTool#realPowerConsumption');
			realPowerConsumptionWhenWorking			= get('flt',  key .. '.workTool#realPowerConsumptionWhenWorking');
			realPowerConsumptionWhenWorkingInc		= get('flt',  key .. '.workTool#realPowerConsumptionWhenWorkingInc');
			realWorkingSpeedLimit					= get('flt',  key .. '.workTool#realWorkingSpeedLimit');
			realResistanceOnlyWhenActive			= get('bool', key .. '.workTool#realResistanceOnlyWhenActive');
			resistanceDecreaseFx					= get('flt',  key .. '.workTool#resistanceDecreaseFx');
			powerConsumptionWhenWorkingDecreaseFx	= get('flt',  key .. '.workTool#powerConsumptionWhenWorkingDecreaseFx');
			caRealTractionResistance				= get('flt',  key .. '.workTool#caRealTractionResistance');
			caRealTractionResistanceWithLoadMass	= get('flt',  key .. '.workTool#caRealTractionResistanceWithLoadMass') or 0;
			realAiWorkingSpeed						= get('int',  key .. '.workTool#realAiWorkingSpeed');
			groundReferenceNodeIndex				= get('str',  key .. '.workTool#groundReferenceNodeIndex');
			groundReferenceNodeThreshold			= get('flt',  key .. '.workTool#groundReferenceNodeThreshold');
		};

		-- capacity multipliers
		workTool.realCapacityMultipliers = {};
		local realCapacityMultipliers = get('str', key .. '.workTool#realCapacityMultipliers');
		if realCapacityMultipliers then
			realCapacityMultipliers = Utils.splitString(',', realCapacityMultipliers);
			for i=1, #realCapacityMultipliers do
				local data = Utils.splitString(':', Utils.trim(realCapacityMultipliers[i]));
				workTool.realCapacityMultipliers[i] = {
					fillType = data[1];
					multiplier = tonumber(data[2]);
				};
			end;
		end;

		-- trailer
		if subCategory == 'trailer' then
			workTool.realTippingPowerConsumption			 = get('flt', key .. '.workTool#realTippingPowerConsumption');
			workTool.realOverloaderUnloadingPowerConsumption = get('flt', key .. '.workTool#realOverloaderUnloadingPowerConsumption');
			workTool.pipeUnloadingCapacity					 = get('flt', key .. '.workTool#pipeUnloadingCapacity');

			-- tip animation discharge speed
			workTool.realMaxDischargeSpeeds = {};
			local tasStr = get('str', key .. '.workTool#realMaxDischargeSpeeds');
			if tasStr then
				workTool.realMaxDischargeSpeeds = Utils.getVectorNFromString(tasStr, nil);
			end;

		-- forageWagon
		elseif subCategory == 'forageWagon' then
			workTool.realForageWagonWorkingPowerConsumption	   = get('flt', key .. '.workTool#realForageWagonWorkingPowerConsumption');
			workTool.realForageWagonWorkingPowerConsumptionInc = get('flt', key .. '.workTool#realForageWagonWorkingPowerConsumptionInc');
			workTool.realForageWagonDischargePowerConsumption  = get('flt', key .. '.workTool#realForageWagonDischargePowerConsumption');
			workTool.realForageWagonCompressionRatio		   = get('flt', key .. '.workTool#realForageWagonCompressionRatio');

		-- cutter
		elseif subCategory == 'cutter' then
			workTool.realCutterPowerConsumption	   = get('flt', key .. '.workTool#realCutterPowerConsumption') or 25;
			workTool.realCutterPowerConsumptionInc = get('flt', key .. '.workTool#realCutterPowerConsumptionInc') or 2.5;
			workTool.realCutterSpeedLimit		   = get('flt', key .. '.workTool#realCutterSpeedLimit') or 14;

		-- rake
		elseif subCategory == 'rake' then
			workTool.realRakeWorkingPowerConsumption	= get('flt', key .. '.workTool#realRakeWorkingPowerConsumption');
			workTool.realRakeWorkingPowerConsumptionInc	= get('flt', key .. '.workTool#realRakeWorkingPowerConsumptionInc');

		-- baleWrapper
		elseif subCategory == 'baleWrapper' then
			workTool.wrappingTime = get('int', key .. '.workTool#wrappingTime');

		-- baleLoader
		elseif subCategory == 'baleLoader' then
			workTool.realAutoStackerWorkingPowerConsumption = get('flt', key .. '.workTool#realAutoStackerWorkingPowerConsumption');

		-- baler
		elseif subCategory == 'baler' then
			workTool.realBalerWorkingSpeedLimit			  = get('flt',  key .. '.workTool#realBalerWorkingSpeedLimit');
			workTool.realBalerPowerConsumption			  = get('flt',  key .. '.workTool#realBalerPowerConsumption');
			workTool.realBalerRoundingPowerConsumptionInc = get('flt',  key .. '.workTool#realBalerRoundingPowerConsumptionInc');
			workTool.realBalerRam = {
				strokePowerConsumption					  = get('flt',  key .. '.workTool#realBalerRamStrokePowerConsumption');
				strokePowerConsumptionInc				  = get('flt',  key .. '.workTool#realBalerRamStrokePowerConsumptionInc');
				strokeTimeOffset						  = get('flt',  key .. '.workTool#realBalerRamStrokeTimeOffset');
				strokePerMinute							  = get('flt',  key .. '.workTool#realBalerRamStrokePerMinute');
			};
			workTool.realBalerPickUpPowerConsumptionInc	  = get('flt',  key .. '.workTool#realBalerPickUpPowerConsumptionInc');
			workTool.realBalerOverFillingRatio			  = get('flt',  key .. '.workTool#realBalerOverFillingRatio');
			workTool.realBalerAddEjectVelZ				  = get('flt',  key .. '.workTool#realBalerAddEjectVelZ');
			workTool.realBalerUseEjectingVelocity		  = get('bool', key .. '.workTool#realBalerUseEjectingVelocity');

			workTool.realBalerLastBaleCol = {
				index = get('str', key .. '.workTool#realBalerLastBaleColIndex');
				maxBaleTimeBeforeNextBale = get('flt', key .. '.workTool#realBalerLastBaleColMaxBaleTimeBeforeNextBale');
				componentJoint = get('int', key .. '.workTool#realBalerLastBaleColComponentJoint');
			};

		-- sprayer
		elseif subCategory == 'sprayer' then
			workTool.realFillingPowerConsumption	 = get('flt', key .. '.workTool#realFillingPowerConsumption');
			workTool.realSprayingReferenceSpeed		 = get('int', key .. '.workTool#realSprayingReferenceSpeed');
			workTool.sprayUsageLitersPerSecond		 = get('flt', key .. '.workTool#sprayUsageLitersPerSecond');
			workTool.sprayUsageLitersPerSecondFolded = get('flt', key .. '.workTool#sprayUsageLitersPerSecondFolded');
			workTool.fillLitersPerSecond			 = get('int', key .. '.workTool#fillLitersPerSecond');

		-- shovel
		elseif subCategory == 'shovel' then
			workTool.replaceParticleSystem			 = get('bool', key .. '.workTool#replaceParticleSystem');
			workTool.addParticleSystemPos			 = get('str',  key .. '.workTool#addParticleSystemPos');
			if workTool.addParticleSystemPos then
				workTool.addParticleSystemPos = Utils.getVectorNFromString(workTool.addParticleSystemPos);
			end;
		end;

		-- combine
		local combine = {};
		if subCategory == 'combine' then
			combine.realAiWorkingSpeed = {
				baseSpeed									  = get('flt',  key .. '.combine#realAiWorkingBaseSpeed');
				minSpeed									  = get('flt',  key .. '.combine#realAiWorkingMinSpeed');
				maxSpeed									  = get('flt',  key .. '.combine#realAiWorkingMaxSpeed');
			};
			combine.realAiMinDistanceBeforeTurning 			  = get('flt',  key .. '.combine#realAiMinDistanceBeforeTurning');
			combine.realTurnStage1DistanceThreshold		 	  = get('flt',  key .. '.combine#realTurnStage1DistanceThreshold');
			combine.realTurnStage1AngleThreshold 			  = get('flt',  key .. '.combine#realTurnStage1AngleThreshold');
			combine.realTurnStage2MinDistanceBeforeTurnStage3 = get('flt',  key .. '.combine#realTurnStage2MinDistanceBeforeTurnStage3');
			combine.realUnloadingPowerBoost					  = get('flt',  key .. '.combine#realUnloadingPowerBoost');
			combine.realUnloadingPowerConsumption			  = get('flt',  key .. '.combine#realUnloadingPowerConsumption');
			combine.realThreshingPowerConsumption			  = get('flt',  key .. '.combine#realThreshingPowerConsumption');
			combine.realThreshingPowerConsumptionInc		  = get('flt',  key .. '.combine#realThreshingPowerConsumptionInc');
			combine.realThreshingPowerBoost					  = get('flt',  key .. '.combine#realThreshingPowerBoost');
			combine.realChopperPowerConsumption				  = get('flt',  key .. '.combine#realChopperPowerConsumption');
			combine.realChopperPowerConsumptionInc			  = get('flt',  key .. '.combine#realChopperPowerConsumptionInc');
			combine.realThreshingScale						  = get('flt',  key .. '.combine#realThreshingScale');
			combine.grainTankUnloadingCapacity				  = get('flt',  key .. '.combine#grainTankUnloadingCapacity');
			combine.realCombineLosses = {
				allowed								 		  = get('bool', key .. '.combine#realCombineLossesAllowed');
				maxSqmBeingThreshedBeforeLosses		 		  = get('flt',  key .. '.combine#realCombineLossesMaxSqmBeingThreshedBeforeLosses');
				displayLosses						 		  = get('bool', key .. '.combine#realCombineLossesDisplayLosses');
			};
			combine.realCombineCycleDuration		 		  = get('flt',  key .. '.combine#realCombineCycleDuration');
			combine.pipeRotationSpeeds				 		  = get('str',  key .. '.combine#pipeRotationSpeeds');
			combine.pipeState1Rotation				 		  = get('str',  key .. '.combine#pipeState1Rotation');
			combine.pipeState2Rotation				 		  = get('str',  key .. '.combine#pipeState2Rotation');
		end;


		-- create extra nodes
		local createExtraNodes = {};
		local n = 0;
		while true do
			local nodeKey = key .. ('.createExtraNodes.node(%d)'):format(n);
			if not has(nodeKey) then break; end;

			createExtraNodes[n + 1] = {
				index		= get('str', nodeKey .. '#index');
				translation	= Utils.getVectorNFromString(get('str', nodeKey .. '#translation') or '0 0 0');
				rotation	= Utils.getVectorNFromString(get('str', nodeKey .. '#rotation') or '0 0 0');
				scale		= Utils.getVectorNFromString(get('str', nodeKey .. '#scale') or '1 1 1');
			};

			n = n + 1;
		end;

		--------------------------------------------------

		-- STORE DATA
		local store = {
			price				= get('int', key .. '.store#price');
			dailyUpkeep			= get('int', key .. '.store#dailyUpkeep');
			powerKW				= get('int', key .. '.store#powerKW');
			requiredPowerKwMin	= get('int', key .. '.store#requiredPowerKwMin');
			requiredPowerKwMax	= get('int', key .. '.store#requiredPowerKwMax');
			maxSpeed			= get('int', key .. '.store#maxSpeed');
			weight				= get('int', key .. '.store#weight');
			workSpeedMin		= get('int', key .. '.store#workSpeedMin');
			workSpeedMax		= get('int', key .. '.store#workSpeedMax');
			workWidth			= get('flt', key .. '.store#workWidth');
			capacity			= get('flt', key .. '.store#capacity');
			compressedCapacity	= get('flt', key .. '.store#compressedCapacity');
			capacityUnit		= get('str', key .. '.store#capacityUnit');
			length				= get('flt', key .. '.store#length');
			fruits				= get('str', key .. '.store#fruits');
			author				= get('str', key .. '.store#author');
		};
		-- remove store spec per lang
		local removeSpecsPerLang = get('str', key .. '.store#removeSpecsPerLang');
		if removeSpecsPerLang then
			removeSpecsPerLang = Utils.splitString(',', removeSpecsPerLang);
			for _,langData in ipairs(removeSpecsPerLang) do
				local split = Utils.splitString(':', langData);
				local lang = split[1];
				if lang == g_languageShort then
					local specs = Utils.splitString(' ', split[2]);
					for _,specName in ipairs(specs) do
						store[specName] = nil;
					end;
					break;
				end;
			end;
		end;

		self:setStoreData(configFileName, dlcName, store, doDebug);

		--------------------------------------------------

		self.vehicleData[configFileName] = {
			dlcName = dlcName,
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
			components = components,
			createExtraNodes = createExtraNodes
		};

		--------------------------------------------------

		i = i + 1;
	end;

	delete(xmlFile);
end;


-- ##################################################
