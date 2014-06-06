-- AugerWagonPowerConsumption
-- adds power consumption to the AugerWagon when the pipe is (un)folding / when it's unloading

-- @author: Jakob Tischler
-- @date: 16 May 2014
-- @version: 0.1
-- @history: 0.1 (16 May 2014)
--
-- Copyright (C) 2014 Jakob Tischler

AugerWagonPowerConsumption = {};

function AugerWagonPowerConsumption.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(RealisticVehicle, specializations) and SpecializationUtil.hasSpecialization(Cylindered, specializations);
end;

function AugerWagonPowerConsumption:load(xmlFile)
	self.realOverloaderUnloadingPowerConsumption = getXMLFloat(xmlFile, 'vehicle.realOverloaderUnloadingPowerConsumption');
	self.realWorkingPowerConsumption = getXMLFloat(xmlFile, 'vehicle.realWorkingPowerConsumption');
	self.realCurrentPowerConsumption = 0;
end;

function AugerWagonPowerConsumption:delete()
end;

function AugerWagonPowerConsumption:mouseEvent(posX, posY, isDown, isUp, button)
end;

function AugerWagonPowerConsumption:keyEvent(unicode, sym, modifier, isDown)
end;

function AugerWagonPowerConsumption:updateTick(dt)
	if self.isServer and self.isActive then
		self.realCurrentPowerConsumption = 0;
		if self.realOverloaderUnloadingPowerConsumption and self.pipeIsUnloading then
			self.realCurrentPowerConsumption = self.realOverloaderUnloadingPowerConsumption;
		elseif self.realWorkingPowerConsumption and self:getIsAnimationPlaying('foldingPipe') then
			self.realCurrentPowerConsumption = self.realWorkingPowerConsumption;
		end;
	end;
end;

function AugerWagonPowerConsumption:update(dt)
end;

function AugerWagonPowerConsumption:draw()
end;
