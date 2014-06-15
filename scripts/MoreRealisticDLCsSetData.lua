local modDir, modName = g_currentModDirectory, g_currentModName;

--------------------------------------------------

local prmSetXMLFn = {
	bool = setXMLBool,
	flt = setXMLFloat,
	int = setXMLInt,
	str = setXMLString
};
local setValue = function(xmlFile, parameter, prmType, value, extraIndent)
	if value == nil then return; end;

	prmSetXMLFn[prmType](xmlFile, parameter, value);
	if MoreRealisticDLCs.mrData and MoreRealisticDLCs.mrData.doDebug then
		extraIndent = extraIndent or '';
		print(('\t%sset parameter %q (type %s) to %q'):format(extraIndent, parameter, prmType, tostring(value)));
	end;
end;

local removeProperty = function(xmlFile, property, extraIndent)
	if getXMLString(xmlFile, property) ~= nil or hasXMLProperty(xmlFile, property) then
		removeXMLProperty(xmlFile, property);
		if MoreRealisticDLCs.mrData and MoreRealisticDLCs.mrData.doDebug then
			extraIndent = extraIndent or '';
			print(('\t%sremove property %q'):format(extraIndent, tostring(property)));
		end;
	end;
end;

-- ##################################################

-- SET VEHICLE MR DATA
function MoreRealisticDLCs:setMrData(vehicle, xmlFile)
	local mrData = MoreRealisticDLCs.mrData;
	if not mrData then return; end;

	local returnData = {};

	removeProperty(xmlFile, 'vehicle.motor');
	
	-- downForce, brakeForce
	setValue(xmlFile, 'vehicle.downForce',  'int', 0);
	setValue(xmlFile, 'vehicle.brakeForce', 'int', 0);


	-- relevant MR values
	setValue(xmlFile, 'vehicle.bunkerSiloCompactor#compactingScale',   'flt',  mrData.weights.weight * 0.25);
	setValue(xmlFile, 'vehicle.realMaxVehicleSpeed', 				   'flt',  mrData.general.realMaxVehicleSpeed);
	setValue(xmlFile, 'vehicle.realMaxReverseSpeed', 				   'flt',  mrData.engine.realMaxReverseSpeed);
	setValue(xmlFile, 'vehicle.realBrakeMaxMovingMass', 			   'flt',  mrData.weights.realBrakeMaxMovingMass);
	setValue(xmlFile, 'vehicle.realSCX', 							   'flt',  mrData.width * mrData.height * 0.68);
	setValue(xmlFile, 'vehicle.realBrakingDeceleration', 			   'flt',  mrData.general.realBrakingDeceleration);
	setValue(xmlFile, 'vehicle.realCanLockWheelsWhenBraking', 		   'bool', mrData.general.realCanLockWheelsWhenBraking);
	setValue(xmlFile, 'vehicle.realRollingResistance',				   'flt',  mrData.general.realRollingResistance);
	setValue(xmlFile, 'vehicle.realWorkingPowerConsumption',		   'flt',  mrData.general.realWorkingPowerConsumption);
	setValue(xmlFile, 'vehicle.realMotorizedWheelsDriveLossFx'		,  'flt',  mrData.general.realMotorizedWheelsDriveLossFx);
	setValue(xmlFile, 'vehicle.realVehicleOnFieldRollingResistanceFx', 'flt',  mrData.general.realVehicleOnFieldRollingResistanceFx);


	if mrData.category == 'steerable' then
		-- accelerationSpeed
		setValue(xmlFile, 'vehicle.accelerationSpeed#maxAcceleration',	'flt', mrData.engine.accelerationSpeedMaxAcceleration);
		setValue(xmlFile, 'vehicle.accelerationSpeed#deceleration',		'int', 1);
		setValue(xmlFile, 'vehicle.accelerationSpeed#brakeSpeed',		'int', 3);
		removeProperty(xmlFile, 'vehicle.accelerationSpeed#backwardDeceleration');

		-- fuel usage
		setValue(xmlFile, 'vehicle.fuelUsage',  'int', 0);

		-- general
		setValue(xmlFile, 'vehicle.realDisplaySlip', 'bool', mrData.general.realDisplaySlip);
		setValue(xmlFile, 'vehicle.fuelCapacity',	 'int',  mrData.general.fuelCapacity);
		setValue(xmlFile, 'vehicle.waitForTurnTime', 'flt',  mrData.general.waitForTurnTime);

		-- wheels
		setValue(xmlFile, 'vehicle.realVehicleFlotationFx', 'flt', mrData.wheelStuff.realVehicleFlotationFx);

		-- crawlers
		if #mrData.wheelStuff.crawlersRealWheel > 0 then
			local i = 0;
			while true do
				local cKey = ('vehicle.crawlers.crawler(%d)'):format(i);
				if not hasXMLProperty(xmlFile, cKey) or not mrData.wheelStuff.crawlersRealWheel[i + 1] then break; end;
				setValue(xmlFile, cKey .. '#realWheel', 'int', mrData.wheelStuff.crawlersRealWheel[i + 1]);
				i = i + 1;
			end;
		end;

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
			setValue(xmlFile, 'vehicle.realAiWorkingSpeed#baseSpeed', 	  'int',  mrData.combine.realAiWorkingSpeed.baseSpeed);
			setValue(xmlFile, 'vehicle.realAiWorkingSpeed#minSpeed', 	  'int',  mrData.combine.realAiWorkingSpeed.minSpeed);
			setValue(xmlFile, 'vehicle.realAiWorkingSpeed#maxSpeed', 	  'int',  mrData.combine.realAiWorkingSpeed.maxSpeed);

			setValue(xmlFile, 'vehicle.realAiMinDistanceBeforeTurning',			   'flt', mrData.combine.realAiMinDistanceBeforeTurning);
			setValue(xmlFile, 'vehicle.realTurnStage1DistanceThreshold',		   'flt', mrData.combine.realTurnStage1DistanceThreshold);
			setValue(xmlFile, 'vehicle.realTurnStage1AngleThreshold',			   'flt', mrData.combine.realTurnStage1AngleThreshold);
			setValue(xmlFile, 'vehicle.realTurnStage2MinDistanceBeforeTurnStage3', 'flt', mrData.combine.realTurnStage2MinDistanceBeforeTurnStage3);
			setValue(xmlFile, 'vehicle.realUnloadingPowerBoost', 				   'flt', mrData.combine.realUnloadingPowerBoost);
			setValue(xmlFile, 'vehicle.realUnloadingPowerConsumption', 			   'flt', mrData.combine.realUnloadingPowerConsumption);
			setValue(xmlFile, 'vehicle.realThreshingPowerConsumption', 			   'flt', mrData.combine.realThreshingPowerConsumption);
			setValue(xmlFile, 'vehicle.realThreshingPowerConsumptionInc',		   'flt', mrData.combine.realThreshingPowerConsumptionInc);
			setValue(xmlFile, 'vehicle.realThreshingPowerBoost',				   'flt', mrData.combine.realThreshingPowerBoost);
			setValue(xmlFile, 'vehicle.realChopperPowerConsumption', 			   'flt', mrData.combine.realChopperPowerConsumption);
			setValue(xmlFile, 'vehicle.realChopperPowerConsumptionInc',			   'flt', mrData.combine.realChopperPowerConsumptionInc);
			setValue(xmlFile, 'vehicle.realThreshingScale', 					   'flt', mrData.combine.realThreshingScale);
			setValue(xmlFile, 'vehicle.grainTankUnloadingCapacity', 			   'flt', mrData.combine.grainTankUnloadingCapacity);
			setValue(xmlFile, 'vehicle.realCombineCycleDuration', 				   'flt', mrData.combine.realCombineCycleDuration);

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
				setValue(xmlFile, 'vehicle.exhaustParticleSystems.exhaustParticleSystem1#file', 'str', self.exhaustPsOldPath);
				-- setValue(xmlFile, 'vehicle.exhaustParticleSystems.exhaustParticleSystem1#file', 'str', self.exhaustPsNewPath);

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
				setValue(xmlFile, spsKey .. '#file', 'str', self.exhaustPsNewPath);
				setValue(xmlFile, spsKey .. '#minLoadActive', 'flt', 0.5);
				]]
			end;
		end;
	end;


	-- wheels
	setValue(xmlFile, 'vehicle.realTyreGripFx',									  'flt',  mrData.wheelStuff.realTyreGripFx);
	setValue(xmlFile, 'vehicle.realIsTracked',									  'bool', mrData.wheelStuff.realIsTracked);
	setValue(xmlFile, 'vehicle.steeringAxleAngleScale#realNoSteeringAxleDamping', 'bool', mrData.wheelStuff.realNoSteeringAxleDamping);
	if mrData.wheelStuff.overwriteWheels then
		removeProperty(xmlFile, 'vehicle.wheels');
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
			setValue(xmlFile, 'vehicle.wheels#autoRotateBackSpeed', 'flt', 1);
		end;

		if mrData.doDebug then print('\twheels: ' .. wheelI); end;

		removeProperty(xmlFile, wheelKey .. '#lateralStiffness', '\t');
		removeProperty(xmlFile, wheelKey .. '#longitudalStiffness', '\t');
		setValue(xmlFile, wheelKey .. '#repr',				 'str', wheelMrData.repr, '\t');
		setValue(xmlFile, wheelKey .. '#driveNode',			 'str', wheelMrData.driveNode, '\t');
		setValue(xmlFile, wheelKey .. '#driveMode',			 'int', wheelMrData.driveMode, '\t');
		setValue(xmlFile, wheelKey .. '#rotMax',			 'flt', wheelMrData.rotMax, '\t');
		setValue(xmlFile, wheelKey .. '#rotMin',			 'flt', wheelMrData.rotMin, '\t');
		setValue(xmlFile, wheelKey .. '#rotSpeed',			 'flt', wheelMrData.rotSpeed, '\t');
		setValue(xmlFile, wheelKey .. '#radius',			 'flt', wheelMrData.radius, '\t');
		setValue(xmlFile, wheelKey .. '#brakeRatio',		 'int', wheelMrData.brakeRatio, '\t');
		setValue(xmlFile, wheelKey .. '#damper',			 'int', wheelMrData.damper, '\t');
		setValue(xmlFile, wheelKey .. '#mass',				 'int', 1, '\t');
		setValue(xmlFile, wheelKey .. '#lateralStiffness',	 'flt', wheelMrData.lateralStiffness, '\t');
		setValue(xmlFile, wheelKey .. '#antiRollFx',		 'flt', wheelMrData.antiRollFx, '\t');
		setValue(xmlFile, wheelKey .. '#realMaxMassAllowed', 'flt', wheelMrData.realMaxMassAllowed, '\t');
		setValue(xmlFile, wheelKey .. '#tirePressureFx',	 'flt', wheelMrData.tirePressureFx, '\t');

		local suspTravel = wheelMrData.suspTravel or getXMLFloat(xmlFile, wheelKey .. '#suspTravel');
		if not wheelMrData.realMaxMassAllowed and suspTravel < 0.05 then
			suspTravel = 0.05;
		end;
		setValue(xmlFile, wheelKey .. '#suspTravel', 'flt', suspTravel, '\t');

		-- MR 1.2: local spring = wheelMrData.spring or 278 * (mrData.weights.maxWeight / #mrData.wheels) / (suspTravel * 100 - 2);
		local spring = wheelMrData.spring or 3 * mrData.weights.maxWeight / #mrData.wheels / suspTravel;
		setValue(xmlFile, wheelKey .. '#spring', 'flt', spring, '\t');

		setValue(xmlFile, wheelKey .. '#deltaY', 'flt', wheelMrData.deltaY, '\t');

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
		setValue(xmlFile, 'vehicle.attacherJoint#upperDistanceToGround',	   'flt', ajMrData.upperDistanceToGround);
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
			setValue(xmlFile, tajKey .. '#maxRotLimit', 'str', tajData.maxRotLimit, '\t');
			if isAdditional then
				setValue(xmlFile, tajKey .. '#index',		  'str',  tajData.index, '\t');
				setValue(xmlFile, tajKey .. '#low',			  'bool', tajData.low, '\t');
				setValue(xmlFile, tajKey .. '#ptoOutputNode', 'str',  tajData.ptoOutputNode, '\t');
				setValue(xmlFile, tajKey .. '#ptoFilename',	  'str',  tajData.ptoFilename, '\t');
				if tajData.schemaOverlay.index and tajData.schemaOverlay.position and tajData.schemaOverlay.invertX ~= nil then
					local soKey = ('vehicle.schemaOverlay.attacherJoint(%d)'):format(tajData.schemaOverlay.index);
					setValue(xmlFile, soKey .. '#position', 'str',  tajData.schemaOverlay.position, '\t');
					setValue(xmlFile, soKey .. '#rotation', 'int',  0, '\t');
					setValue(xmlFile, soKey .. '#invertX',	'bool', tajData.schemaOverlay.invertX, '\t');
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
			setValue(xmlFile, compKey .. '#centerOfMass',		  'str', mrData.components[i].centerOfMass);
			setValue(xmlFile, compKey .. '#realMassWanted',		  'flt', mrData.components[i].realMassWanted);
			setValue(xmlFile, compKey .. '#realTransWithMass',	  'str', mrData.components[i].realTransWithMass);
			setValue(xmlFile, compKey .. '#realTransWithMassMax', 'str', mrData.components[i].realTransWithMassMax);
		end;
	end;


	-- workTool
	if mrData.category == 'tool' then
		setValue(xmlFile, 'vehicle.realAiWorkingSpeed', 'int', mrData.workTool.realAiWorkingSpeed);
		if mrData.workTool.groundReferenceNodeIndex and mrData.workTool.groundReferenceNodeThreshold then
			setValue(xmlFile, 'vehicle.groundReferenceNode#index',	   'str', mrData.workTool.groundReferenceNodeIndex);
			setValue(xmlFile, 'vehicle.groundReferenceNode#threshold', 'flt', mrData.workTool.groundReferenceNodeThreshold);
		end;

		-- cutter
		if mrData.subCategory == 'cutter' then
			setValue(xmlFile, 'vehicle.realCutterPowerConsumption',	   'flt', mrData.workTool.realCutterPowerConsumption);
			setValue(xmlFile, 'vehicle.realCutterPowerConsumptionInc', 'flt', mrData.workTool.realCutterPowerConsumptionInc);
			setValue(xmlFile, 'vehicle.realCutterSpeedLimit',		   'int', mrData.workTool.realCutterSpeedLimit);

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

					setValue(xmlFile, taKey .. '#realMaxDischargeSpeed', 'int', mrData.workTool.realMaxDischargeSpeeds[ta]);
				end;

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
				setValue(xmlFile, 'vehicle.wrapper#wrappingTime', 'int',  mrData.workTool.wrappingTime);

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
				setValue(xmlFile, 'vehicle.realSprayingReferenceSpeed',				'int', mrData.workTool.realSprayingReferenceSpeed);
				setValue(xmlFile, 'vehicle.sprayUsages.sprayUsage#litersPerSecond',	'flt', mrData.workTool.sprayUsageLitersPerSecond);
				setValue(xmlFile, 'vehicle.sprayUsageLitersPerSecondFolded',		'flt', mrData.workTool.sprayUsageLitersPerSecondFolded);
				setValue(xmlFile, 'vehicle.fillLitersPerSecond',					'int', mrData.workTool.fillLitersPerSecond);

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
							setValue(xmlFile, key .. '#file', 'str', self.shovelPS[fillType]);

							-- position
							local posX, posY, posZ = unpack(mrData.workTool.addParticleSystemPos);
							local posStr = getXMLString(xmlFile, key .. '#position');
							if posStr then
								local x, y, z = Utils.getVectorFromString(posStr);
								posX, posY, posZ = posX + x, posY + y, posZ + z;
							end;
							setValue(xmlFile, key .. '#position', 'str', posX .. ' ' .. posY .. ' ' .. posZ);
						end;
						i = i + 1;
					end;
				end;
			end;

			-- fillable
			if SpecializationUtil.hasSpecialization(Fillable, vehicle.specializations) then
				setValue(xmlFile, 'vehicle.capacity', 'int', mrData.workTool.capacity);

				for i=1, #mrData.workTool.realCapacityMultipliers do
					local rcmKey = ('vehicle.realCapacityMultipliers.realCapacityMultiplier(%d)'):format(i-1);
					setValue(xmlFile, rcmKey .. '#fillType',   'str', mrData.workTool.realCapacityMultipliers[i].fillType);
					setValue(xmlFile, rcmKey .. '#multiplier', 'flt', mrData.workTool.realCapacityMultipliers[i].multiplier);
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

						setValue(xmlFile, partKey .. '#startTime', 'flt', startTime);
						if endTime then
							setValue(xmlFile, partKey .. '#endTime', 'flt', endTime);
						elseif duration then
							setValue(xmlFile, partKey .. '#duration', 'flt', duration);
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
					setValue(xmlFile, newPartKey .. '#node',	   'str', firstNode);
					setValue(xmlFile, newPartKey .. '#startRot',   'str', firstStartRot);
					setValue(xmlFile, newPartKey .. '#endRot',	   'str', firstStartRot);
					setValue(xmlFile, newPartKey .. '#startTrans', 'str', firstStartTrans);
					setValue(xmlFile, newPartKey .. '#endTrans',   'str', firstStartTrans);
					setValue(xmlFile, newPartKey .. '#startTime',  'int', 0);
					setValue(xmlFile, newPartKey .. '#endTime',	   'flt', animOffset);
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
				setValue(xmlFile, mtKey .. '#rotSpeed', 'flt', curRotSpeed * scale);
			end;
			local curTransSpeed = getXMLFloat(xmlFile, mtKey .. '#transSpeed');
			if curTransSpeed then
				setValue(xmlFile, mtKey .. '#transSpeed', 'flt', curTransSpeed * scale);
			end;
		end;
	end;

-- ##################################################

	if #mrData.createExtraNodes > 0 then
		return mrData.createExtraNodes;
	end;

	return;
end;
