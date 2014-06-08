local modDir, modName = g_currentModDirectory, g_currentModName;

--------------------------------------------------

-- GET VEHICLE MR DATA
function MoreRealisticDLCs:getMrData(vehicleDataPath, dlcName)
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
			fuelCapacity 						  = getXMLFloat(xmlFile, key .. '.general#fuelCapacity');
			realMaxVehicleSpeed 				  = getXMLFloat(xmlFile, key .. '.general#realMaxVehicleSpeed');
			realBrakingDeceleration 			  = getXMLFloat(xmlFile, key .. '.general#realBrakingDeceleration');
			realCanLockWheelsWhenBraking		  =  getXMLBool(xmlFile, key .. '.general#realCanLockWheelsWhenBraking');
			realRollingResistance 				  = getXMLFloat(xmlFile, key .. '.general#realRollingResistance');
			realWorkingPowerConsumption			  = getXMLFloat(xmlFile, key .. '.general#realWorkingPowerConsumption');
			realDisplaySlip						  = Utils.getNoNil(getXMLBool(xmlFile, key .. '.general#realDisplaySlip'), true);
			realMotorizedWheelsDriveLossFx		  = getXMLFloat(xmlFile, key .. '.general#realMotorizedWheelsDriveLossFx');
			realVehicleOnFieldRollingResistanceFx = getXMLFloat(xmlFile, key .. '.general#realVehicleOnFieldRollingResistanceFx');
			waitForTurnTime						  = getXMLFloat(xmlFile, key .. '.general#waitForTurnTime');
		};


		-- animation speed scale
		general.animationSpeedScale = {};
		local animsStr = getXMLString(xmlFile, key .. '.general#animationSpeedScale');
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
		local animsStr = getXMLString(xmlFile, key .. '.general#animationTimeOffset');
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
		local mtString = getXMLString(xmlFile, key .. '.general#movingToolSpeedScale');
		if mtString then
			general.movingToolSpeedScale = Utils.getVectorNFromString(mtString, nil);
		end;


		-- engine
		local engine = {
			kW 									=  getXMLFloat(xmlFile, key .. '.engine#kW');
			accelerationSpeedMaxAcceleration	=  getXMLFloat(xmlFile, key .. '.engine#accelerationSpeedMaxAcceleration') or 1;
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
			realTyreGripFx			  = getXMLFloat(xmlFile, key .. '.wheels#realTyreGripFx');
			realIsTracked			  =  getXMLBool(xmlFile, key .. '.wheels#realIsTracked');
			realVehicleFlotationFx	  = getXMLFloat(xmlFile, key .. '.wheels#realVehicleFlotationFx');
			realNoSteeringAxleDamping =  getXMLBool(xmlFile, key .. '.wheels#realNoSteeringAxleDamping');
			overwriteWheels			  =  getXMLBool(xmlFile, key .. '.wheels#overwrite');
			crawlersRealWheel		  = {};
		};
		local crawlersRealWheelStr = getXMLString(xmlFile, key .. '.wheels#crawlersRealWheel');
		if crawlersRealWheelStr then
			wheelStuff.crawlersRealWheel = Utils.getVectorNFromString(crawlersRealWheelStr);
		end;


		local wheels = {};
		local w = 0;
		while true do
			local wheelKey = key .. ('.wheels.wheel(%d)'):format(w);
			if not hasXMLProperty(xmlFile, wheelKey) then break; end;

			wheels[#wheels + 1] = {
				repr	   		   = getXMLString(xmlFile, wheelKey .. '#repr'), 
				driveNode  		   = getXMLString(xmlFile, wheelKey .. '#driveNode'), 
				driveMode  		   =    getXMLInt(xmlFile, wheelKey .. '#driveMode'), 
				rotMax     		   =  getXMLFloat(xmlFile, wheelKey .. '#rotMax'),
				rotMin     		   =  getXMLFloat(xmlFile, wheelKey .. '#rotMin'),
				rotSpeed   		   =  getXMLFloat(xmlFile, wheelKey .. '#rotSpeed'),
				radius     		   =  getXMLFloat(xmlFile, wheelKey .. '#radius'),
				deltaY     		   =  getXMLFloat(xmlFile, wheelKey .. '#deltaY'),
				suspTravel 		   =  getXMLFloat(xmlFile, wheelKey .. '#suspTravel'),
				spring     		   =  getXMLFloat(xmlFile, wheelKey .. '#spring'),
				damper     		   =    getXMLInt(xmlFile, wheelKey .. '#damper') or 20,
				brakeRatio 		   =  getXMLFloat(xmlFile, wheelKey .. '#brakeRatio') or 1,
				lateralStiffness   =  getXMLFloat(xmlFile, wheelKey .. '#lateralStiffness'),
				antiRollFx		   =  getXMLFloat(xmlFile, wheelKey .. '#antiRollFx'),
				realMaxMassAllowed =  getXMLFloat(xmlFile, wheelKey .. '#realMaxMassAllowed'),
				tirePressureFx	   =  getXMLFloat(xmlFile, wheelKey .. '#tirePressureFx')
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
				ajData.maxRot2				  = getXMLString(xmlFile, ajKey .. '#maxRot2');
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
				index 		  = getXMLString(xmlFile, tajKey .. '#index');
				low 		  =   getXMLBool(xmlFile, tajKey .. '#low');
				maxRotLimit	  = getXMLString(xmlFile, tajKey .. '#maxRotLimit');
				ptoOutputNode = getXMLString(xmlFile, tajKey .. '#ptoOutputNode');
				ptoFilename	  = getXMLString(xmlFile, tajKey .. '#ptoFilename');
				schemaOverlay = {
					index	  =    getXMLInt(xmlFile, tajKey .. '#schemaOverlayIndex');
					position  = getXMLString(xmlFile, tajKey .. '#schemaOverlayPosition');
					invertX	  =   getXMLBool(xmlFile, tajKey .. '#schemaOverlayInvertX');
				};
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
				centerOfMass		 = getXMLString(xmlFile, compKey .. '#centerOfMass'),
				realMassWanted		 =  getXMLFloat(xmlFile, compKey .. '#realMassWanted'),
				realTransWithMass	 = getXMLString(xmlFile, compKey .. '#realTransWithMass'),
				realTransWithMassMax = getXMLString(xmlFile, compKey .. '#realTransWithMassMax')
			};

			c = c + 1;
		end;


		-- workTool
		local workTool = {
			capacity								=   getXMLInt(xmlFile, key .. '.workTool#capacity');
			realPowerConsumption					= getXMLFloat(xmlFile, key .. '.workTool#realPowerConsumption');
			realPowerConsumptionWhenWorking			= getXMLFloat(xmlFile, key .. '.workTool#realPowerConsumptionWhenWorking');
			realPowerConsumptionWhenWorkingInc		= getXMLFloat(xmlFile, key .. '.workTool#realPowerConsumptionWhenWorkingInc');
			realWorkingSpeedLimit					= getXMLFloat(xmlFile, key .. '.workTool#realWorkingSpeedLimit');
			realResistanceOnlyWhenActive			=  getXMLBool(xmlFile, key .. '.workTool#realResistanceOnlyWhenActive');
			resistanceDecreaseFx					= getXMLFloat(xmlFile, key .. '.workTool#resistanceDecreaseFx');
			powerConsumptionWhenWorkingDecreaseFx	= getXMLFloat(xmlFile, key .. '.workTool#powerConsumptionWhenWorkingDecreaseFx');
			caRealTractionResistance				= getXMLFloat(xmlFile, key .. '.workTool#caRealTractionResistance');
			caRealTractionResistanceWithLoadMass	= getXMLFloat(xmlFile, key .. '.workTool#caRealTractionResistanceWithLoadMass') or 0;
			realAiWorkingSpeed						=   getXMLInt(xmlFile, key .. '.workTool#realAiWorkingSpeed');
		};

		-- capacity multipliers
		workTool.realCapacityMultipliers = {};
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

			-- tip animation discharge speed
			workTool.realMaxDischargeSpeeds = {};
			local tasStr = getXMLString(xmlFile, key .. '.workTool#realMaxDischargeSpeeds');
			if tasStr then
				workTool.realMaxDischargeSpeeds = Utils.getVectorNFromString(tasStr, nil);
			end;

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

		-- baleWrapper
		elseif subCategory == 'baleWrapper' then
			workTool.wrappingTime = getXMLInt(xmlFile, key .. '.workTool#wrappingTime');

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
			workTool.realFillingPowerConsumption	 = getXMLFloat(xmlFile, key .. '.workTool#realFillingPowerConsumption');
			workTool.realSprayingReferenceSpeed		 =   getXMLInt(xmlFile, key .. '.workTool#realSprayingReferenceSpeed');
			workTool.sprayUsageLitersPerSecond		 = getXMLFloat(xmlFile, key .. '.workTool#sprayUsageLitersPerSecond');
			workTool.sprayUsageLitersPerSecondFolded = getXMLFloat(xmlFile, key .. '.workTool#sprayUsageLitersPerSecondFolded');
			workTool.fillLitersPerSecond			 =   getXMLInt(xmlFile, key .. '.workTool#fillLitersPerSecond');

		-- shovel
		elseif subCategory == 'shovel' then
			workTool.replaceParticleSystem			 =   getXMLBool(xmlFile, key .. '.workTool#replaceParticleSystem');
			workTool.addParticleSystemPos			 = getXMLString(xmlFile, key .. '.workTool#addParticleSystemPos');
			if workTool.addParticleSystemPos then
				workTool.addParticleSystemPos = Utils.getVectorNFromString(workTool.addParticleSystemPos);
			end;
		end;

		-- combine
		local combine = {};
		if subCategory == 'combine' then
			combine.realAiWorkingSpeed = {
				baseSpeed 							 =  getXMLFloat(xmlFile, key .. '.combine#realAiWorkingBaseSpeed');
				minSpeed 							 =  getXMLFloat(xmlFile, key .. '.combine#realAiWorkingMinSpeed');
				maxSpeed 							 =  getXMLFloat(xmlFile, key .. '.combine#realAiWorkingMaxSpeed');
			};
			combine.realAiMinDistanceBeforeTurning 			  =  getXMLFloat(xmlFile, key .. '.combine#realAiMinDistanceBeforeTurning');
			combine.realTurnStage1DistanceThreshold		 	  =  getXMLFloat(xmlFile, key .. '.combine#realTurnStage1DistanceThreshold');
			combine.realTurnStage1AngleThreshold 			  =  getXMLFloat(xmlFile, key .. '.combine#realTurnStage1AngleThreshold');
			combine.realTurnStage2MinDistanceBeforeTurnStage3 =  getXMLFloat(xmlFile, key .. '.combine#realTurnStage2MinDistanceBeforeTurnStage3');
			combine.realUnloadingPowerBoost					  =  getXMLFloat(xmlFile, key .. '.combine#realUnloadingPowerBoost');
			combine.realUnloadingPowerConsumption			  =  getXMLFloat(xmlFile, key .. '.combine#realUnloadingPowerConsumption');
			combine.realThreshingPowerConsumption			  =  getXMLFloat(xmlFile, key .. '.combine#realThreshingPowerConsumption');
			combine.realThreshingPowerConsumptionInc		  =  getXMLFloat(xmlFile, key .. '.combine#realThreshingPowerConsumptionInc');
			combine.realThreshingPowerBoost					  =  getXMLFloat(xmlFile, key .. '.combine#realThreshingPowerBoost');
			combine.realChopperPowerConsumption				  =  getXMLFloat(xmlFile, key .. '.combine#realChopperPowerConsumption');
			combine.realChopperPowerConsumptionInc			  =  getXMLFloat(xmlFile, key .. '.combine#realChopperPowerConsumptionInc');
			combine.realThreshingScale						  =  getXMLFloat(xmlFile, key .. '.combine#realThreshingScale');
			combine.grainTankUnloadingCapacity				  =  getXMLFloat(xmlFile, key .. '.combine#grainTankUnloadingCapacity');
			combine.realCombineLosses = {               
				allowed								 		  =   getXMLBool(xmlFile, key .. '.combine#realCombineLossesAllowed');
				maxSqmBeingThreshedBeforeLosses		 		  =  getXMLFloat(xmlFile, key .. '.combine#realCombineLossesMaxSqmBeingThreshedBeforeLosses');
				displayLosses						 		  =   getXMLBool(xmlFile, key .. '.combine#realCombineLossesDisplayLosses');
			};                                          
			combine.realCombineCycleDuration		 		  =  getXMLFloat(xmlFile, key .. '.combine#realCombineCycleDuration');
			combine.pipeRotationSpeeds				 		  = getXMLString(xmlFile, key .. '.combine#pipeRotationSpeeds');
			combine.pipeState1Rotation				 		  = getXMLString(xmlFile, key .. '.combine#pipeState1Rotation');
			combine.pipeState2Rotation				 		  = getXMLString(xmlFile, key .. '.combine#pipeState2Rotation');
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
			length				=  getXMLFloat(xmlFile, key .. '.store#length');
			fruits				= getXMLString(xmlFile, key .. '.store#fruits');
			author				= getXMLString(xmlFile, key .. '.store#author');
		};
		-- remove store spec per lang
		local removeSpecsPerLang = getXMLString(xmlFile, key .. '.store#removeSpecsPerLang');
		if removeSpecsPerLang then
			removeSpecsPerLang = Utils.splitString(',', removeSpecsPerLang);
			for i,langData in ipairs(removeSpecsPerLang) do
				local split = Utils.splitString(':', langData);
				local lang = split[1];
				if lang == g_languageShort then
					local specs = Utils.splitString(' ', split[2]);
					for i,specName in ipairs(specs) do
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
			components = components
		};

		--------------------------------------------------

		i = i + 1;
	end;

	delete(xmlFile);
end;


-- ##################################################
