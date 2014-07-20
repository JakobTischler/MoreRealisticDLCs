-- RealisticLastMotorRpm
-- sets lastMotorRpm to MoreRealistic value, so that the Titanium exhaust system actually works with MR

-- @author: Jakob Tischler
-- @date: 18 May 2014
-- @version: 0.1
-- @history: 0.1 (18 May 2014)
--
-- Copyright (C) 2014 Jakob Tischler

RealisticLastMotorRpm = {};

function RealisticLastMotorRpm.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(RealisticVehicle, specializations) and SpecializationUtil.hasSpecialization(Motorized, specializations);
end;

function RealisticLastMotorRpm:load(xmlFile)
	self.fuckTheEarth = self.exhaustParticleSystems ~= nil;
	if self.fuckTheEarth then
		self.exhaustParticleSystems.maxRpm = 1;
		if self.motor == nil then self.motor = {}; end;
		self.motor.lastMotorRpm = 0;
	end;
end;

function RealisticLastMotorRpm:update(dt)
	if self.isActive and self.fuckTheEarth then
		if not self.isMotorStarted and self.motor.lastMotorRpm ~= 0 then
			self.motor.lastMotorRpm = 0;
		else
			-- self.motor.lastMotorRpm = RealisticUtils.linearFx(self.realLastMotorFx^0.5, 0.1, 1);
			self.motor.lastMotorRpm = Utils.clamp(self.realSoundMotorFx, 0.1, 1);
		end;
	end;
end;

function RealisticLastMotorRpm:updateTick(dt) end;
function RealisticLastMotorRpm:draw() end;
function RealisticLastMotorRpm:delete() end;
function RealisticLastMotorRpm:mouseEvent(posX, posY, isDown, isUp, button) end;
function RealisticLastMotorRpm:keyEvent(unicode, sym, modifier, isDown) end;

