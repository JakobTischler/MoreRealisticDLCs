--[[
ExhaustFlap
adds exhaust flap movement based on motor rpm

@author: Jakob Tischler
@date: 17 May 2014
@version: 0.1
]]

ExhaustFlap = {};

function ExhaustFlap.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(RealisticVehicle, specializations) and SpecializationUtil.hasSpecialization(Steerable, specializations);
end;

local abs, deg, floor, rad, random = math.abs, math.deg, math.floor, math.rad, math.random;
function ExhaustFlap:load(xmlFile)
	self.exhaustFlap = {
		flap = Utils.indexToObject(self.components, getXMLString(xmlFile, 'vehicle.exhaustParticleSystems#flap')),
		maxRot = rad(getXMLFloat(xmlFile, 'vehicle.exhaustParticleSystems#maxRot') or 0)
	};
	local _,_,curRot = getRotation(self.exhaustFlap.flap);
	self.exhaustFlap.curRot = curRot;
	self.exhaustFlap.direction = Utils.sign(self.exhaustFlap.maxRot);
	self.exhaustFlap.randomExtraUp   = floor(deg(self.exhaustFlap.maxRot) / 5);
	self.exhaustFlap.randomExtraDown = self.exhaustFlap.direction / -18;
	if abs(self.exhaustFlap.randomExtraUp) <= abs(self.exhaustFlap.randomExtraDown) then
		print(('%s: ExhaustFlap WARNING: randomExtraUp needs to have a higher absolute value than randomExtraDown'):format(tostring(self.name)));
	end;
	self.exhaustFlap.flappityFlap = self.exhaustFlap.maxRot ~= 0;
end;

function ExhaustFlap:delete()
end;

function ExhaustFlap:mouseEvent(posX, posY, isDown, isUp, button)
end;

function ExhaustFlap:keyEvent(unicode, sym, modifier, isDown)
end;

function ExhaustFlap:updateTick(dt)
	if self.isServer and self.isActive and self.exhaustFlap.flappityFlap then
		local setRot;
		if self.isMotorStarted then
			local lastMotorRpm = RealisticUtils.linearFx(self.realLastMotorFx^0.5, 0.1, 1);
			local randomRot;
			if self.exhaustFlap.direction == 1 then
				randomRot = rad(random(self.exhaustFlap.randomExtraDown, self.exhaustFlap.randomExtraUp));
				setRot = Utils.clamp(self.exhaustFlap.maxRot * lastMotorRpm + randomRot, 0, self.exhaustFlap.maxRot);
			else
				randomRot = rad(random(self.exhaustFlap.randomExtraUp, self.exhaustFlap.randomExtraDown));
				setRot = Utils.clamp(self.exhaustFlap.maxRot * lastMotorRpm + randomRot, self.exhaustFlap.maxRot, 0);
			end;
		elseif self.exhaustFlap.curRot ~= 0 then
			setRot = 0;
		end;

		if setRot then
			setRotation(self.exhaustFlap.flap, 0, 0, setRot);
			self.exhaustFlap.curRot = setRot;
		end;
	end;
end;

function ExhaustFlap:update(dt)
end;

function ExhaustFlap:draw()
end;
