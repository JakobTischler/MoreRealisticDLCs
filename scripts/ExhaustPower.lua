--[[
ExhaustPower

@author: Jakob Tischler
@date: 18 May 2014
@version: 0.1
]]

ExhaustPower = {};

function ExhaustPower.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(RealisticVehicle, specializations) and SpecializationUtil.hasSpecialization(Motorized, specializations);
end;

function ExhaustPower:load(xmlFile)
	self.fuckTheEarth = self.exhaustParticleSystems ~= nil;
	if self.fuckTheEarth then
		self.exhaustParticleSystems.maxRpm = 1;
		if self.motor == nil then self.motor = {}; end;
		self.motor.lastMotorRpm = 0;
	end;
end;

function ExhaustPower:delete()
end;

function ExhaustPower:mouseEvent(posX, posY, isDown, isUp, button)
end;

function ExhaustPower:keyEvent(unicode, sym, modifier, isDown)
end;

function ExhaustPower:update(dt)
	if self.isServer and self.isActive and self.fuckTheEarth then
		if not self.isMotorStarted then
			self.motor.lastMotorRpm = 0;
		else
			self.motor.lastMotorRpm = RealisticUtils.linearFx(self.realLastMotorFx^0.5, 0.1, 1);
		end;
	end;
end;

function ExhaustPower:updateTick(dt)
end;

function ExhaustPower:draw()
end;
