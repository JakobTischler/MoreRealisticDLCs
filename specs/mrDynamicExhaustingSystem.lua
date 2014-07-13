--
-- DynamicExhaustingSystem
-- Specialization for a dynamic exhausting system
--
-- @author  	Manuel Leithner (SFM-Modding)
-- @version 	v2.3
-- @date  		15/10/10
-- @history:	v1.0 - Initial version
--				v2.0 - converted to 2011 and some bugfixes
--				v2.1 - [dural] MoreRealistic compatibility
--				v2.2 - [Jakob Tischler, 20 May 2014] MoreRealisticDLCs compatibility
--				v2.3 - [dural, 9 July 2014] "self.realMotorLoadS" only "streamed" when needed


DynamicExhaustingSystem = {};

local abs, deg, min, max, rad, random = math.abs, math.deg, math.min, math.max, math.rad, math.random;

function DynamicExhaustingSystem.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(Motorized, specializations);
end;

function DynamicExhaustingSystem:load(xmlFile)

	self.exhaustingSystem = {};

	self.exhaustingSystem.cap = Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.dynamicExhaustingSystem#cap"));
	self.exhaustingSystem.capAxis = getXMLString(xmlFile, "vehicle.dynamicExhaustingSystem#capAxis") or 'x';
	self.exhaustingSystem.maxRot = Utils.degToRad(Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.dynamicExhaustingSystem#maxRot"), 0));
	self.setCapRotation = DynamicExhaustingSystem.setCapRotation;
	self:setCapRotation(self.exhaustingSystem.capAxis, 0, 0, 0);


	local startSequence = AnimCurve:new(linearInterpolator4);
	local i=0;
	while true do
		local path = string.format("vehicle.dynamicExhaustingSystem.startSequence.key(%d)", i);
		local timeStamp = getXMLFloat(xmlFile, path .. "#time");
		if timeStamp == nil then
			break;
		end;
		local r,g,b,alpha = Utils.getVectorFromString(getXMLString(xmlFile, path .. "#value"));
		startSequence:addKeyframe({x=r, y=g, z=b, w=alpha, time=timeStamp})
		i = i + 1;
	end;
	self.exhaustingSystem.minAlpha = min(abs(Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.dynamicExhaustingSystem#minAlpha"),0)),1);
	self.exhaustingSystem.maxAlpha = min(abs(Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.dynamicExhaustingSystem#maxAlpha"),1)),1);
	local x1,y1,z1,w1 = startSequence:get(1.0);
	self.exhaustingSystem.startSequence = startSequence;
	self.exhaustingSystem.lastValue = {x=x1,y=y1,z=z1,w=w1};
	self.exhaustingSystem.param = getXMLString(xmlFile, "vehicle.dynamicExhaustingSystem#param");
	self.exhaustingSystem.offset = 0;
	self.exhaustingSystem.deltaTime = 0;

	-- <secondParticleSystem node="0>5|7" position="0 0.02 0.02" rotation="0 0 0" file="newRealParticles.i3d" parameter="alphaScale" minAlpha="0.07" maxAlpha="1.0" minLoadActive="0.5" />
	self.sPS = {};
	local sNode = Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.dynamicExhaustingSystem.secondParticleSystem#node"));
	if sNode ~= nil then
		self.sPS.node = sNode;
		self.sPS.ps = {};
		Utils.loadParticleSystem(xmlFile, self.sPS.ps, string.format("vehicle.dynamicExhaustingSystem.secondParticleSystem"), self.components, false, nil, self.baseDirectory);
		--self.sPS.parameter = getXMLString(xmlFile, "vehicle.dynamicExhaustingSystem.secondParticleSystem#parameter");
		--self.sPS.minAlpha = getXMLString(xmlFile, "vehicle.dynamicExhaustingSystem.secondParticleSystem#minAlpha");
		--self.sPS.maxAlpha = getXMLString(xmlFile, "vehicle.dynamicExhaustingSystem.secondParticleSystem#maxAlpha");
		self.sPS.minLoadActive = getXMLFloat(xmlFile, "vehicle.dynamicExhaustingSystem.secondParticleSystem#minLoadActive");
		self.sPS.a = false;
		self.sPS.lastLoad = 0;
	end;
	
	self.exhaustingSystemDirtyFlag = self:getNextDirtyFlag();

end;

function DynamicExhaustingSystem:delete()
	if self.sPS ~= nil and self.sPS.ps ~= nil then
		Utils.deleteParticleSystem(self.sPS.ps);
	end;
end;

function DynamicExhaustingSystem:mouseEvent(posX, posY, isDown, isUp, button)
end;

function DynamicExhaustingSystem:keyEvent(unicode, sym, modifier, isDown)
end;

function DynamicExhaustingSystem:readUpdateStream(streamId, timestamp, connection)
	if connection:getIsServer() then
		if streamReadBool(streamId) then
			self.realMotorLoadS = streamReadUIntN(streamId, 8)/255;
		end;
	end;
end;

function DynamicExhaustingSystem:writeUpdateStream(streamId, connection, dirtyMask)
	if not connection:getIsServer() then
		if streamWriteBool(streamId, bitAND(dirtyMask, self.exhaustingSystemDirtyFlag) ~= 0) then
			streamWriteUIntN(streamId, min(255, tonumber(self.realMotorLoadS*255)), 8);
		end;
	end;
end;

function DynamicExhaustingSystem:update(dt)
end;

function DynamicExhaustingSystem:setCapRotation(axis, minRandom, maxRandom, alpha)
	local angle = Utils.clamp(rad(random(minRandom, maxRandom)) + self.exhaustingSystem.maxRot * alpha, self.exhaustingSystem.maxRot, 0);
	if self.exhaustingSystem.curRot == angle then return; end;

	if axis == 'x' then
		setRotation(self.exhaustingSystem.cap, angle, 0, 0);
	elseif axis == 'y' then
		setRotation(self.exhaustingSystem.cap, 0, angle, 0);
	else
		setRotation(self.exhaustingSystem.cap, 0, 0, angle);
	end;
	self.exhaustingSystem.curRot = angle;
end;

function DynamicExhaustingSystem:updateTick(dt)
	if self:getIsActive() and self.isClient then
	
		self:raiseDirtyFlags(self.exhaustingSystemDirtyFlag);

		if self.time <= self.motorStartTime then
			local time = (self.exhaustingSystem.deltaTime - (self.motorStartTime - self.time)) / self.exhaustingSystem.deltaTime;
			local x1,y1,z1,w1 = self.exhaustingSystem.startSequence:get(time);
			local values = self.exhaustingSystem.lastValue;
			if abs(values.x - x1) > 0.01 or abs(values.y - y1) > 0.01 or abs(values.z - z1) > 0.01 or abs(values.w - w1) > 0.01 then
				setShaderParameter(self.exhaustParticleSystems[1].shape, self.exhaustingSystem.param, x1, y1, z1, w1, false);
				self.exhaustingSystem.lastValue = {x=x1, y=y1, z=z1, w=w1};
			end;

			if self.exhaustingSystem.cap ~= nil then
				if self.isMotorStarted then
					self:setCapRotation(self.exhaustingSystem.capAxis, -35, 0, w1);
				elseif self.exhaustingSystem.curRot ~= 0 then
					self:setCapRotation(self.exhaustingSystem.capAxis, 0, 0, 0);
				end;
			end;

		else
			-- alpha function of engine load on moreRealistic vehicles
			local alpha = Utils.lerp(self.exhaustingSystem.minAlpha, self.exhaustingSystem.maxAlpha, self.realMotorLoadS);

			if abs(self.exhaustingSystem.lastValue.w - alpha) > 0.01 then
				local values = self.exhaustingSystem.lastValue;
				setShaderParameter(self.exhaustParticleSystems[1].shape, self.exhaustingSystem.param, values.x, values.y, values.z, alpha, false);
				self.exhaustingSystem.lastValue.w = alpha;
			end;

			if self.exhaustingSystem.cap ~= nil then
				if self.realIsMotorStarted then
					self:setCapRotation(self.exhaustingSystem.capAxis, -20, 5, self.realSoundMotorFx);
				elseif self.exhaustingSystem.curRot ~= 0 then
					self:setCapRotation(self.exhaustingSystem.capAxis, 0, 0, 0);
				end;
			end;

			if self.sPS.ps ~= nil then
				if abs( self.sPS.lastLoad - self.realMotorLoadS) > 0.01 and self.sPS.a == false then --self.sPS.minLoadActive < self.realMotorLoadS and self.sPS.a == false then
					Utils.setEmittingState(self.sPS.ps, true);
					self.sPS.a = true;
				elseif self.sPS.a == true then --self.sPS.minLoadActive > self.realMotorLoadS and self.sPS.a == true then
					self.sPS.a = false;
					Utils.setEmittingState(self.sPS.ps, false);
				end;

				self.sPS.lastLoad = self.realMotorLoadS;
			end;
		end;
	end;
end;

function DynamicExhaustingSystem:draw()
end;

function DynamicExhaustingSystem:startMotor()
	self.exhaustingSystem.deltaTime = self.motorStartTime - self.time - self.exhaustingSystem.offset;
end;

function DynamicExhaustingSystem:onLeave()
	if self.exhaustingSystem.cap ~= nil then
		self:setCapRotation(self.exhaustingSystem.capAxis, 0, 0, 0);
	end;
end;
