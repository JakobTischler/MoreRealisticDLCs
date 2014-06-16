local modDir, modName = g_currentModDirectory, g_currentModName;

--------------------------------------------------

local prmSetXMLFn = {
	bool = setXMLBool,
	flt = setXMLFloat,
	int = setXMLInt,
	str = setXMLString
};
-- ##################################################

-- SET VEHICLE MR DATA
function MoreRealisticDLCs:setMrData(vehicle, xmlFile)
	local mrData = MoreRealisticDLCs.mrData;
	if not mrData then return; end;

	local set = function(parameter, prmType, value, extraIndent)
		if value == nil then return; end;

		prmSetXMLFn[prmType](xmlFile, parameter, value);
		if MoreRealisticDLCs.mrData and MoreRealisticDLCs.mrData.doDebug then
			extraIndent = extraIndent or '';
			print(('\t%sset parameter %q (type %s) to %q'):format(extraIndent, parameter, prmType, tostring(value)));
		end;
	end;

	local removePrm = function(property, extraIndent)
		if getXMLString(xmlFile, property) ~= nil or hasXMLProperty(xmlFile, property) then
			removeXMLProperty(xmlFile, property);
			if MoreRealisticDLCs.mrData and MoreRealisticDLCs.mrData.doDebug then
				extraIndent = extraIndent or '';
				print(('\t%sremove property %q'):format(extraIndent, tostring(property)));
			end;
		end;
	end;

	-- ##################################################

	local returnData = {};

	removePrm('vehicle.motor');

	-- downForce, brakeForce
	set('vehicle.downForce',  'int', 0);
	set('vehicle.brakeForce', 'int', 0);

	-- relevant MR values
	set('vehicle.bunkerSiloCompactor#compactingScale',	 'flt',  mrData.weights.weight * 0.25);
	set('vehicle.realMaxVehicleSpeed', 					 'flt',  mrData.general.realMaxVehicleSpeed);
	set('vehicle.realMaxReverseSpeed', 					 'flt',  mrData.engine.realMaxReverseSpeed);
	set('vehicle.realBrakeMaxMovingMass', 				 'flt',  mrData.weights.realBrakeMaxMovingMass);
	set('vehicle.realSCX', 								 'flt',  mrData.width * mrData.height * 0.68);
	set('vehicle.realBrakingDeceleration', 				 'flt',  mrData.general.realBrakingDeceleration);
	set('vehicle.realCanLockWheelsWhenBraking', 		 'bool', mrData.general.realCanLockWheelsWhenBraking);
	set('vehicle.realRollingResistance',				 'flt',  mrData.general.realRollingResistance);
	set('vehicle.realWorkingPowerConsumption',			 'flt',  mrData.general.realWorkingPowerConsumption);
	set('vehicle.realMotorizedWheelsDriveLossFx',		 'flt',  mrData.general.realMotorizedWheelsDriveLossFx);
	set('vehicle.realVehicleOnFieldRollingResistanceFx', 'flt',  mrData.general.realVehicleOnFieldRollingResistanceFx);


	if mrData.category == 'steerable' then
		-- accelerationSpeed
		set('vehicle.accelerationSpeed#maxAcceleration', 'flt', mrData.engine.accelerationSpeedMaxAcceleration);
		set('vehicle.accelerationSpeed#deceleration',	 'int', 1);
		set('vehicle.accelerationSpeed#brakeSpeed',		 'int', 3);
		removePrm('vehicle.accelerationSpeed#backwardDeceleration');

		-- fuel usage
		set('vehicle.fuelUsage',  'int', 0);

		-- general
		set('vehicle.realDisplaySlip', 'bool', mrData.general.realDisplaySlip);
		set('vehicle.fuelCapacity',	   'int',  mrData.general.fuelCapacity);
		set('vehicle.waitForTurnTime', 'flt',  mrData.general.waitForTurnTime);

		-- wheels
		set('vehicle.realVehicleFlotationFx', 'flt', mrData.wheelStuff.realVehicleFlotationFx);

		-- crawlers
		if #mrData.wheelStuff.crawlersRealWheel > 0 then
			local i = 0;
			while true do
				local cKey = ('vehicle.crawlers.crawler(%d)'):format(i);
				if not hasXMLProperty(xmlFile, cKey) or not mrData.wheelStuff.crawlersRealWheel[i + 1] then break; end;
				set(cKey .. '#realWheel', 'int', mrData.wheelStuff.crawlersRealWheel[i + 1]);
				i = i + 1;
			end;
		end;

		-- engine
		set('vehicle.realSpeedLevel', 						'str',  mrData.engine.realSpeedLevel);
		set('vehicle.realAiManeuverSpeed', 					'flt',  mrData.engine.realAiManeuverSpeed);
		set('vehicle.realSpeedBoost',						'int',  mrData.engine.realSpeedBoost);
		set('vehicle.realSpeedBoost#minSpeed', 				'int',  mrData.engine.realSpeedBoostMinSpeed);
		set('vehicle.realImplementNeedsBoost',				'int',  mrData.engine.realImplementNeedsBoost);
		set('vehicle.realImplementNeedsBoost#minPowerCons',	'int',  mrData.engine.realImplementNeedsBoostMinPowerCons);
		set('vehicle.realMaxBoost', 						'int',  mrData.engine.realMaxBoost);
		set('vehicle.realPtoPowerKW',						'flt',  mrData.engine.realPtoPowerKW);
		set('vehicle.realPtoDriveEfficiency',				'flt',  mrData.engine.realPtoDriveEfficiency);
		set('vehicle.realMaxFuelUsage',						'flt',  mrData.engine.realMaxFuelUsage);
		set('vehicle.realTransmissionEfficiency', 			'flt',  mrData.engine.realTransmissionEfficiency);
		set('vehicle.realMaxPowerToTransmission', 			'flt',  mrData.engine.realMaxPowerToTransmission);
		set('vehicle.realHydrostaticTransmission',			'bool', mrData.engine.realHydrostaticTransmission);
		set('vehicle.realMinSpeedForMaxPower', 				'flt',  mrData.engine.realMinSpeedForMaxPower);

		-- combine
		if mrData.subCategory == 'combine' then
			set('vehicle.realAiWorkingSpeed#baseSpeed',	'int', mrData.combine.realAiWorkingSpeed.baseSpeed);
			set('vehicle.realAiWorkingSpeed#minSpeed',	'int', mrData.combine.realAiWorkingSpeed.minSpeed);
			set('vehicle.realAiWorkingSpeed#maxSpeed',	'int', mrData.combine.realAiWorkingSpeed.maxSpeed);

			set('vehicle.realAiMinDistanceBeforeTurning',			 'flt', mrData.combine.realAiMinDistanceBeforeTurning);
			set('vehicle.realTurnStage1DistanceThreshold',			 'flt', mrData.combine.realTurnStage1DistanceThreshold);
			set('vehicle.realTurnStage1AngleThreshold',				 'flt', mrData.combine.realTurnStage1AngleThreshold);
			set('vehicle.realTurnStage2MinDistanceBeforeTurnStage3', 'flt', mrData.combine.realTurnStage2MinDistanceBeforeTurnStage3);
			set('vehicle.realUnloadingPowerBoost', 					 'flt', mrData.combine.realUnloadingPowerBoost);
			set('vehicle.realUnloadingPowerConsumption', 			 'flt', mrData.combine.realUnloadingPowerConsumption);
			set('vehicle.realThreshingPowerConsumption', 			 'flt', mrData.combine.realThreshingPowerConsumption);
			set('vehicle.realThreshingPowerConsumptionInc',			 'flt', mrData.combine.realThreshingPowerConsumptionInc);
			set('vehicle.realThreshingPowerBoost',					 'flt', mrData.combine.realThreshingPowerBoost);
			set('vehicle.realChopperPowerConsumption', 				 'flt', mrData.combine.realChopperPowerConsumption);
			set('vehicle.realChopperPowerConsumptionInc',			 'flt', mrData.combine.realChopperPowerConsumptionInc);
			set('vehicle.realThreshingScale', 						 'flt', mrData.combine.realThreshingScale);
			set('vehicle.grainTankUnloadingCapacity', 				 'flt', mrData.combine.grainTankUnloadingCapacity);
			set('vehicle.realCombineCycleDuration', 				 'flt', mrData.combine.realCombineCycleDuration);

			set('vehicle.realCombineLosses#allowed', 						 'bool', mrData.combine.realCombineLosses.allowed);
			set('vehicle.realCombineLosses#maxSqmBeingThreshedBeforeLosses', 'flt',  mrData.combine.realCombineLosses.maxSqmBeingThreshedBeforeLosses);
			set('vehicle.realCombineLosses#displayLosses',					 'bool', mrData.combine.realCombineLosses.displayLosses);

			set('vehicle.pipe.node#rotationSpeeds',  'str', mrData.combine.pipeRotationSpeeds);
			set('vehicle.pipe.node.state1#rotation', 'str', mrData.combine.pipeState1Rotation);
			set('vehicle.pipe.node.state2#rotation', 'str', mrData.combine.pipeState2Rotation);
		end;

		-- exhaust PS
		if mrData.engine.newExhaustPS then
			local node = getXMLString(xmlFile, 'vehicle.exhaustParticleSystems.exhaustParticleSystem1#node');
			if node then
				-- remove old PS
				set('vehicle.exhaustParticleSystems.exhaustParticleSystem1#file', 'str', self.exhaustPsOldPath);
				-- set('vehicle.exhaustParticleSystems.exhaustParticleSystem1#file', 'str', self.exhaustPsNewPath);

				-- set new PS
				local desKey = 'vehicle.dynamicExhaustingSystem';
				local minAlpha = mrData.engine.newExhaustMinAlpha or 0.2;
				set(desKey .. '#minAlpha', 'flt', minAlpha); -- 0.05
				set(desKey .. '#maxAlpha', 'flt', 1); -- 0.4
				set(desKey .. '#param',	 'str', 'alphaScale');

				-- start sequence
				set(desKey .. '.startSequence.key(0)#time',  'flt', 0.0);
				set(desKey .. '.startSequence.key(0)#value', 'str', '0 0 0 0');
				set(desKey .. '.startSequence.key(1)#time',  'flt', 0.3);
				set(desKey .. '.startSequence.key(1)#value', 'str', '0 0 0 0.5');
				set(desKey .. '.startSequence.key(2)#time',  'flt', 0.6);
				set(desKey .. '.startSequence.key(2)#value', 'str', '0 0 0 0.8');
				set(desKey .. '.startSequence.key(3)#time',  'flt', 1);
				set(desKey .. '.startSequence.key(3)#value', 'str', '0 0 0 ' .. minAlpha);

				-- exhaust cap
				if mrData.engine.newExhaustCapAxis then
					local capNode	= getXMLString(xmlFile, 'vehicle.exhaustParticleSystems#flap');
					local capMaxRot	= getXMLString(xmlFile, 'vehicle.exhaustParticleSystems#maxRot');

					if capNode and capMaxRot then
						set(desKey .. '#cap',		'str', capNode);
						set(desKey .. '#capAxis',	'str', mrData.engine.newExhaustCapAxis);
						set(desKey .. '#maxRot',	'str', capMaxRot);
					end;
				end;

				-- second particleSystem
				--[[
				local spsKey = desKey .. '.secondParticleSystem';
				set(spsKey .. '#node', 'str', node);
				set(spsKey .. '#position', 'str', '0 0.02 0.02');
				set(spsKey .. '#rotation', 'str', '0 0 0');
				set(spsKey .. '#file', 'str', self.exhaustPsNewPath);
				set(spsKey .. '#minLoadActive', 'flt', 0.5);
				]]
			end;
		end;
	end;


	-- wheels
	set('vehicle.realTyreGripFx',									'flt',  mrData.wheelStuff.realTyreGripFx);
	set('vehicle.realIsTracked',									'bool', mrData.wheelStuff.realIsTracked);
	set('vehicle.steeringAxleAngleScale#realNoSteeringAxleDamping', 'bool', mrData.wheelStuff.realNoSteeringAxleDamping);
	if mrData.wheelStuff.overwriteWheels then
		removePrm('vehicle.wheels');
	end;

	local wheelI = 0;
	while true do
		local wheelKey = ('vehicle.wheels.wheel(%d)'):format(wheelI);
		if not mrData.wheelStuff.overwriteWheels then
			local repr = getXMLString(xmlFile, wheelKey .. '#repr');
			if not repr or repr == '' then break; end;
		end;
		local wheelMrData = mrData.wheels[wheelI + 1];
		if not wheelMrData then break; end;

		if wheelI == 0 then
			set('vehicle.wheels#autoRotateBackSpeed', 'flt', 1);
		end;

		if mrData.doDebug then print('\twheels: ' .. wheelI); end;

		removePrm(wheelKey .. '#lateralStiffness', '\t');
		removePrm(wheelKey .. '#longitudalStiffness', '\t');
		set(wheelKey .. '#repr',			   'str', wheelMrData.repr, '\t');
		set(wheelKey .. '#driveNode',		   'str', wheelMrData.driveNode, '\t');
		set(wheelKey .. '#driveMode',		   'int', wheelMrData.driveMode, '\t');
		set(wheelKey .. '#rotMax',			   'flt', wheelMrData.rotMax, '\t');
		set(wheelKey .. '#rotMin',			   'flt', wheelMrData.rotMin, '\t');
		set(wheelKey .. '#rotSpeed',		   'flt', wheelMrData.rotSpeed, '\t');
		set(wheelKey .. '#radius',			   'flt', wheelMrData.radius, '\t');
		set(wheelKey .. '#brakeRatio',		   'int', wheelMrData.brakeRatio, '\t');
		set(wheelKey .. '#damper',			   'int', wheelMrData.damper, '\t');
		set(wheelKey .. '#mass',			   'int', 1, '\t');
		set(wheelKey .. '#lateralStiffness',   'flt', wheelMrData.lateralStiffness, '\t');
		set(wheelKey .. '#antiRollFx',		   'flt', wheelMrData.antiRollFx, '\t');
		set(wheelKey .. '#realMaxMassAllowed', 'flt', wheelMrData.realMaxMassAllowed, '\t');
		set(wheelKey .. '#tirePressureFx',	   'flt', wheelMrData.tirePressureFx, '\t');

		local suspTravel = wheelMrData.suspTravel or getXMLFloat(xmlFile, wheelKey .. '#suspTravel');
		if not wheelMrData.realMaxMassAllowed and suspTravel < 0.05 then
			suspTravel = 0.05;
		end;
		set(wheelKey .. '#suspTravel', 'flt', suspTravel, '\t');

		-- MR 1.2: local spring = wheelMrData.spring or 278 * (mrData.weights.maxWeight / #mrData.wheels) / (suspTravel * 100 - 2);
		local spring = wheelMrData.spring or 3 * mrData.weights.maxWeight / #mrData.wheels / suspTravel;
		set(wheelKey .. '#spring', 'flt', spring, '\t');

		set(wheelKey .. '#deltaY', 'flt', wheelMrData.deltaY, '\t');

		wheelI = wheelI + 1;
	end;


	-- additionalWheels
	for w=1, #mrData.additionalWheels do
		local wheelMrData = mrData.additionalWheels[w];
		local wheelKey = ('vehicle.wheels.wheel(%d)'):format(wheelI);
		if mrData.doDebug then
			print(('\tadditionalWheels: %d (set as wheel %d'):format(w - 1, wheelI));
		end;

		set(wheelKey .. '#repr',							 'str', wheelMrData.repr, '\t');
		set(wheelKey .. '#deltaY',							 'flt', wheelMrData.deltaY, '\t');
		set(wheelKey .. '#radius',							 'flt', wheelMrData.radius, '\t');
		set(wheelKey .. '#suspTravel',						 'flt', wheelMrData.suspTravel, '\t');
		set(wheelKey .. '#spring',							 'flt', wheelMrData.spring, '\t');
		set(wheelKey .. '#damper',							 'flt', wheelMrData.damper, '\t');
		set(wheelKey .. '#brakeRatio',						 'flt', wheelMrData.brakeRatio, '\t');
		set(wheelKey .. '#antiRollFx',						 'flt', wheelMrData.antiRollFx, '\t');
		set(wheelKey .. '#lateralStiffness',				 'flt', wheelMrData.lateralStiffness, '\t');
		set(wheelKey .. '#continousBrakeForceWhenNotActive', 'flt', wheelMrData.continousBrakeForceWhenNotActive, '\t');

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
				removePrm(ajKey .. '#maxRotLimit');
				removePrm(ajKey .. '#minRot2');
				removePrm(ajKey .. '#minRotRotationOffset');
				removePrm(ajKey .. '#maxRotDistanceToGround');
				removePrm(ajKey .. '#maxTransLimit');

				set(ajKey .. '#minRot', 				'str', ajMrData.minRot);
				set(ajKey .. '#maxRot', 				'str', ajMrData.maxRot);
				set(ajKey .. '#maxRot2', 				'str', ajMrData.maxRot2);
				set(ajKey .. '#minRotDistanceToGround',	'flt', ajMrData.minRotDistanceToGround);
				set(ajKey .. '#maxRotDistanceToGround',	'flt', ajMrData.maxRotDistanceToGround);
				set(ajKey .. '#moveTime',				'flt', ajMrData.moveTime);

			elseif jointType and (jointType == 'trailer' or jointType == 'trailerLow') then
				set(ajKey .. '#maxRotLimit', 			  'str',  ajMrData.maxRotLimit);
				set(ajKey .. '#maxTransLimit', 			  'str',  ajMrData.maxTransLimit);
				set(ajKey .. '#allowsJointLimitMovement', 'bool', ajMrData.allowsJointLimitMovement);
				set(ajKey .. '#allowsLowering',			  'bool', ajMrData.allowsLowering);
			end;

			a = a + 1;
		end;

	elseif mrData.category == 'tool' and #mrData.attacherJoints == 1 then
		local ajMrData = mrData.attacherJoints[1];
		removePrm('vehicle.attacherJoint#upperDistanceToGround');
		set('vehicle.attacherJoint#lowerDistanceToGround',		 'flt', ajMrData.lowerDistanceToGround);
		set('vehicle.attacherJoint#upperDistanceToGround',		 'flt', ajMrData.upperDistanceToGround);
		set('vehicle.attacherJoint#realWantedLoweredTransLimit', 'str', ajMrData.realWantedLoweredTransLimit);
		set('vehicle.attacherJoint#realWantedLoweredRotLimit',	 'str', ajMrData.realWantedLoweredRotLimit);
		set('vehicle.attacherJoint#realWantedRaisedRotLimit',	 'str', ajMrData.realWantedRaisedRotLimit);
		set('vehicle.attacherJoint#realWantedLoweredRot2',		 'flt', ajMrData.realWantedLoweredRot2);
		set('vehicle.attacherJoint#realWantedRaisedRotInc',		 'flt', ajMrData.realWantedRaisedRotInc);
	end;


	-- trailerAttacherJoints
	local a = 0;
	while true do
		local tajKey = ('vehicle.trailerAttacherJoints.trailerAttacherJoint(%d)'):format(a);
		local isAdditional = false;
		if not hasXMLProperty(xmlFile, tajKey) then
			isAdditional = true;
		end;

		local tajData = mrData.trailerAttacherJoints[a + 1];
		if tajData then
			if mrData.doDebug then
				local index 		= tostring(getXMLString(xmlFile, tajKey .. '#index'));
				local low 			= tostring(getXMLString(xmlFile, tajKey .. '#low'));
				local ptoOutputNode = tostring(getXMLString(xmlFile, tajKey .. '#ptoOutputNode'));
				local ptoFilename 	= tostring(getXMLString(xmlFile, tajKey .. '#ptoFilename'));
				local printStr = ('\ttrailerAttacherJoints: %d'):format(a);
				if isAdditional then printStr = printStr .. ' (additional)'; end;
				printStr = ('%s\n\t\tindex=%q, low=%q, ptoOutputNode=%q, ptoFilename=%q'):format(printStr, index, low, ptoOutputNode, ptoFilename);
				print(printStr);
			end;
			set(tajKey .. '#maxRotLimit', 'str', tajData.maxRotLimit, '\t');
			if isAdditional then
				set(tajKey .. '#index',			'str',  tajData.index, '\t');
				set(tajKey .. '#low',			'bool', tajData.low, '\t');
				set(tajKey .. '#ptoOutputNode',	'str',  tajData.ptoOutputNode, '\t');
				set(tajKey .. '#ptoFilename',	'str',  tajData.ptoFilename, '\t');
				if tajData.schemaOverlay.index and tajData.schemaOverlay.position and tajData.schemaOverlay.invertX ~= nil then
					local soKey = ('vehicle.schemaOverlay.attacherJoint(%d)'):format(tajData.schemaOverlay.index);
					set(soKey .. '#position', 'str',  tajData.schemaOverlay.position, '\t');
					set(soKey .. '#rotation', 'int',  0, '\t');
					set(soKey .. '#invertX',  'bool', tajData.schemaOverlay.invertX, '\t');
				end;
			end;
		else
			break;
		end;

		a = a + 1;
	end;


	-- components
	for i=1, getXMLInt(xmlFile, 'vehicle.components#count') do
		if mrData.components[i] then
			local compKey = ('vehicle.components.component%d'):format(i);
			set(compKey .. '#centerOfMass',			'str', mrData.components[i].centerOfMass);
			set(compKey .. '#realMassWanted',		'flt', mrData.components[i].realMassWanted);
			set(compKey .. '#realTransWithMass',	'str', mrData.components[i].realTransWithMass);
			set(compKey .. '#realTransWithMassMax',	'str', mrData.components[i].realTransWithMassMax);
		end;
	end;


	-- workTool
	if mrData.category == 'tool' then
		set('vehicle.realAiWorkingSpeed', 'int', mrData.workTool.realAiWorkingSpeed);
		if mrData.workTool.groundReferenceNodeIndex and mrData.workTool.groundReferenceNodeThreshold then
			set('vehicle.groundReferenceNode#index',	 'str', mrData.workTool.groundReferenceNodeIndex);
			set('vehicle.groundReferenceNode#threshold', 'flt', mrData.workTool.groundReferenceNodeThreshold);
		end;

		-- cutter
		if mrData.subCategory == 'cutter' then
			set('vehicle.realCutterPowerConsumption',	 'flt', mrData.workTool.realCutterPowerConsumption);
			set('vehicle.realCutterPowerConsumptionInc', 'flt', mrData.workTool.realCutterPowerConsumptionInc);
			set('vehicle.realCutterSpeedLimit',			 'int', mrData.workTool.realCutterSpeedLimit);

		-- others
		else
			set('vehicle.realPowerConsumption',										   'flt',  mrData.workTool.realPowerConsumption);
			set('vehicle.realPowerConsumptionWhenWorking',							   'flt',  mrData.workTool.realPowerConsumptionWhenWorking);
			set('vehicle.realPowerConsumptionWhenWorkingInc',						   'flt',  mrData.workTool.realPowerConsumptionWhenWorkingInc);
			set('vehicle.realWorkingSpeedLimit',									   'flt',  mrData.workTool.realWorkingSpeedLimit);
			set('vehicle.realResistanceOnlyWhenActive',								   'bool', mrData.workTool.realResistanceOnlyWhenActive);
			set('vehicle.realTilledGroundBonus#resistanceDecreaseFx',				   'flt',  mrData.workTool.resistanceDecreaseFx);
			set('vehicle.realTilledGroundBonus#powerConsumptionWhenWorkingDecreaseFx', 'flt',  mrData.workTool.powerConsumptionWhenWorkingDecreaseFx);

			if mrData.workTool.caRealTractionResistance then
				local caCount = getXMLInt(xmlFile, 'vehicle.cuttingAreas#count');
				local tractionResistancePerCa = mrData.workTool.caRealTractionResistance / caCount;
				local tractionResistanceWithLoadMassPerCa = mrData.workTool.caRealTractionResistanceWithLoadMass / caCount;
				for i=1, caCount do
					local caKey = ('vehicle.cuttingAreas.cuttingArea%d'):format(i);
					set(caKey .. '#realTractionResistance', 			'flt', tractionResistancePerCa);
					set(caKey .. '#realTractionResistanceWithLoadMass',	'flt', tractionResistanceWithLoadMassPerCa);
				end;
			end;

			-- trailer
			if mrData.subCategory == 'trailer' then
				set('vehicle.realTippingPowerConsumption', 			   'flt', mrData.workTool.realTippingPowerConsumption);
				set('vehicle.realOverloaderUnloadingPowerConsumption', 'flt', mrData.workTool.realOverloaderUnloadingPowerConsumption);
				set('vehicle.pipe#unloadingCapacity', 				   'flt', mrData.workTool.pipeUnloadingCapacity);

				-- tip animation discharge speed
				local numEntries = #mrData.workTool.realMaxDischargeSpeeds;
				for ta=1, numEntries do
					local taKey = ('vehicle.tipAnimations.tipAnimation(%d)'):format(ta - 1);
					if not hasXMLProperty(xmlFile, taKey) then
						if numEntries == 1 and ta == 1 then
							taKey = 'vehicle.tipAnimation';
							if not hasXMLProperty(xmlFile, taKey) then break; end;
						else
							break;
						end;
					end;

					set(taKey .. '#realMaxDischargeSpeed', 'int', mrData.workTool.realMaxDischargeSpeeds[ta]);
				end;

			-- forageWagon
			elseif mrData.subCategory == 'forageWagon' then
				set('vehicle.realForageWagonWorkingPowerConsumption',	 'flt', mrData.workTool.realForageWagonWorkingPowerConsumption);
				set('vehicle.realForageWagonWorkingPowerConsumptionInc', 'flt', mrData.workTool.realForageWagonWorkingPowerConsumptionInc);
				set('vehicle.realForageWagonDischargePowerConsumption',	 'flt', mrData.workTool.realForageWagonDischargePowerConsumption);
				set('vehicle.realForageWagonCompressionRatio',			 'flt', mrData.workTool.realForageWagonCompressionRatio);

			-- rake
			elseif mrData.subCategory == 'rake' then
				set('vehicle.realRakeWorkingPowerConsumption',	  'flt', mrData.workTool.realRakeWorkingPowerConsumption);
				set('vehicle.realRakeWorkingPowerConsumptionInc', 'flt', mrData.workTool.realRakeWorkingPowerConsumptionInc);

			-- baleLoader
			elseif mrData.subCategory == 'baleLoader' then
				set('vehicle.realAutoStackerWorkingPowerConsumption', 'flt', mrData.workTool.realAutoStackerWorkingPowerConsumption);

			-- baleWrapper
			elseif mrData.subCategory == 'baleWrapper' then
				set('vehicle.wrapper#wrappingTime', 'int',  mrData.workTool.wrappingTime);

			-- baler
			elseif mrData.subCategory == 'baler' then
				set('vehicle.realBalerWorkingSpeedLimit',			  'flt',  mrData.workTool.realBalerWorkingSpeedLimit);
				set('vehicle.realBalerPowerConsumption',			  'flt',  mrData.workTool.realBalerPowerConsumption);
				set('vehicle.realBalerRoundingPowerConsumptionInc',	  'flt',  mrData.workTool.realBalerRoundingPowerConsumptionInc);
				set('vehicle.realBalerRam#strokePowerConsumption',	  'flt',  mrData.workTool.realBalerRam.strokePowerConsumption);
				set('vehicle.realBalerRam#strokePowerConsumptionInc', 'flt',  mrData.workTool.realBalerRam.strokePowerConsumptionInc);
				set('vehicle.realBalerRam#strokeTimeOffset',		  'flt',  mrData.workTool.realBalerRam.strokeTimeOffset);
				set('vehicle.realBalerRam#strokePerMinute',			  'flt',  mrData.workTool.realBalerRam.strokePerMinute);
				set('vehicle.realBalerPickUpPowerConsumptionInc',	  'flt',  mrData.workTool.realBalerPickUpPowerConsumptionInc);
				set('vehicle.realBalerOverFillingRatio',			  'flt',  mrData.workTool.realBalerOverFillingRatio);
				set('vehicle.realBalerAddEjectVelZ',				  'flt',  mrData.workTool.realBalerAddEjectVelZ);
				set('vehicle.realBalerUseEjectingVelocity',			  'bool', mrData.workTool.realBalerUseEjectingVelocity);
				if mrData.workTool.realBalerLastBaleCol.index then
					set('vehicle.realBalerLastBaleCol#index',					  'str', mrData.workTool.realBalerLastBaleCol.index);
					set('vehicle.realBalerLastBaleCol#maxBaleTimeBeforeNextBale', 'flt', mrData.workTool.realBalerLastBaleCol.maxBaleTimeBeforeNextBale);
					set('vehicle.realBalerLastBaleCol#componentJoint',			  'int', mrData.workTool.realBalerLastBaleCol.componentJoint);
				end;
				-- TODO: <realEnhancedBaler> section

				set('vehicle.realFillTypePowerFactors.fillTypeFx(0)#fillType', 'str', 'wheat_windrow');
				set('vehicle.realFillTypePowerFactors.fillTypeFx(0)#value',	   'int', 1);
				set('vehicle.realFillTypePowerFactors.fillTypeFx(1)#fillType', 'str', 'barley_windrow');
				set('vehicle.realFillTypePowerFactors.fillTypeFx(1)#value',	   'int', 1);
				set('vehicle.realFillTypePowerFactors.fillTypeFx(2)#fillType', 'str', 'dryGrass_windrow');
				set('vehicle.realFillTypePowerFactors.fillTypeFx(2)#value',	   'flt', 1.25);

			-- sprayer
			elseif mrData.subCategory == 'sprayer' then
				set('vehicle.realFillingPowerConsumption',			  'flt', mrData.workTool.realFillingPowerConsumption);
				set('vehicle.realSprayingReferenceSpeed',			  'int', mrData.workTool.realSprayingReferenceSpeed);
				set('vehicle.sprayUsages.sprayUsage#litersPerSecond', 'flt', mrData.workTool.sprayUsageLitersPerSecond);
				set('vehicle.sprayUsageLitersPerSecondFolded',		  'flt', mrData.workTool.sprayUsageLitersPerSecondFolded);
				set('vehicle.fillLitersPerSecond',					  'int', mrData.workTool.fillLitersPerSecond);

			-- shovel
			elseif mrData.subCategory == 'shovel' then
				if mrData.workTool.replaceParticleSystem and self.mrVehiclesPackInstalled then
					local i = 0;
					while true do
						local key = ('vehicle.emptyParticleSystems.emptyParticleSystem(%d)'):format(i);
						if not hasXMLProperty(xmlFile, key) then break; end;

						local fillType = getXMLString(xmlFile, key .. '#type');
						if fillType and self.shovelPS[fillType] then
							-- PS file
							set(key .. '#file', 'str', self.shovelPS[fillType]);

							-- position
							local posX, posY, posZ = unpack(mrData.workTool.addParticleSystemPos);
							local posStr = getXMLString(xmlFile, key .. '#position');
							if posStr then
								local x, y, z = Utils.getVectorFromString(posStr);
								posX, posY, posZ = posX + x, posY + y, posZ + z;
							end;
							set(key .. '#position', 'str', posX .. ' ' .. posY .. ' ' .. posZ);
						end;
						i = i + 1;
					end;
				end;
			end;

			-- fillable
			if SpecializationUtil.hasSpecialization(Fillable, vehicle.specializations) then
				set('vehicle.capacity', 'int', mrData.workTool.capacity);

				for i=1, #mrData.workTool.realCapacityMultipliers do
					local rcmKey = ('vehicle.realCapacityMultipliers.realCapacityMultiplier(%d)'):format(i-1);
					set(rcmKey .. '#fillType',   'str', mrData.workTool.realCapacityMultipliers[i].fillType);
					set(rcmKey .. '#multiplier', 'flt', mrData.workTool.realCapacityMultipliers[i].multiplier);
				end;
			end;
		end;
	end;


	-- animation speed scale / time offset
	if mrData.general.hasAnimationsSpeedScale or mrData.general.hasAnimationsTimeOffset then
		local a = 0;
		while true do
			local animKey = ('vehicle.animations.animation(%d)'):format(a);
			if not hasXMLProperty(xmlFile, animKey) then break; end;

			local animName = getXMLString(xmlFile, animKey .. '#name');
			local animScale = mrData.general.animationSpeedScale[animName];
			local animOffset = mrData.general.animationTimeOffset[animName];
			if animScale or animOffset then
				local p = 0;
				while true do
					local partKey = ('%s.part(%d)'):format(animKey, p);
					if not hasXMLProperty(xmlFile, partKey) then break; end;

					local startTime = getXMLFloat(xmlFile, partKey .. '#startTime');
					local endTime   = getXMLFloat(xmlFile, partKey .. '#endTime');
					local duration  = getXMLFloat(xmlFile, partKey .. '#duration');

					if startTime and (endTime or duration) then
						if animScale then
							startTime = startTime / animScale;
							if endTime then
								endTime = endTime / animScale;
							elseif duration then
								duration = duration / animScale;
							end;
						end;
						if animOffset then
							startTime = startTime + animOffset;
							if endTime then
								endTime = endTime + animOffset;
							end;
						end;

						set(partKey .. '#startTime', 'flt', startTime);
						if endTime then
							set(partKey .. '#endTime', 'flt', endTime);
						elseif duration then
							set(partKey .. '#duration', 'flt', duration);
						end;
					end;

					p = p + 1;
				end;

				if animOffset then
					-- add additional part with time 0 -> offset and no movement so the new anim duration will be correct
					local firstNode		  = getXMLString(xmlFile, animKey .. '.part(0)#node');
					local firstStartRot	  = getXMLString(xmlFile, animKey .. '.part(0)#startRot');
					local firstStartTrans = getXMLString(xmlFile, animKey .. '.part(0)#startTrans');

					local newPartKey = ('%s.part(%d)'):format(animKey, p);
					set(newPartKey .. '#node',		 'str', firstNode);
					set(newPartKey .. '#startRot',	 'str', firstStartRot);
					set(newPartKey .. '#endRot',	 'str', firstStartRot);
					set(newPartKey .. '#startTrans', 'str', firstStartTrans);
					set(newPartKey .. '#endTrans',	 'str', firstStartTrans);
					set(newPartKey .. '#startTime',	 'int', 0);
					set(newPartKey .. '#endTime',	 'flt', animOffset);
				end;
			end;
			a = a + 1;
		end;
	end;

	-- movingTool speed scale
	for mtNum, scale in ipairs(mrData.general.movingToolSpeedScale) do
		if scale ~= 1 then
			local mtKey = ('vehicle.movingTools.movingTool(%d)'):format(mtNum - 1);
			if not hasXMLProperty(xmlFile, mtKey) then break; end;

			local curRotSpeed = getXMLFloat(xmlFile, mtKey .. '#rotSpeed');
			if curRotSpeed then
				set(mtKey .. '#rotSpeed', 'flt', curRotSpeed * scale);
			end;
			local curTransSpeed = getXMLFloat(xmlFile, mtKey .. '#transSpeed');
			if curTransSpeed then
				set(mtKey .. '#transSpeed', 'flt', curTransSpeed * scale);
			end;
		end;
	end;

-- ##################################################

	if #mrData.createExtraNodes > 0 then
		return mrData.createExtraNodes;
	end;

	return;
end;
