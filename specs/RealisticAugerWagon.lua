-- RealisticAugerWagon
-- adds power consumption to the AugerWagon when the pipe is (un)folding / when it's unloading

-- @author: Jakob Tischler
-- @date: 16 May 2014
-- @version: 0.1
-- @history: 0.1 (16 May 2014)
--
-- Copyright (C) 2014 Jakob Tischler

RealisticAugerWagon = {};

function RealisticAugerWagon.prerequisitesPresent(specializations)
	if RealisticVehicle and pdlc_titaniumAddon and pdlc_titaniumAddon.AugerWagon then
		return SpecializationUtil.hasSpecialization(RealisticVehicle, specializations) and SpecializationUtil.hasSpecialization(Cylindered, specializations) and SpecializationUtil.hasSpecialization(pdlc_titaniumAddon.AugerWagon, specializations);
	end;
	return false;
end;

function RealisticAugerWagon:load(xmlFile)
	self.realOverloaderUnloadingPowerConsumption = getXMLFloat(xmlFile, 'vehicle.realOverloaderUnloadingPowerConsumption');
	self.realWorkingPowerConsumption = getXMLFloat(xmlFile, 'vehicle.realWorkingPowerConsumption');
	self.realCurrentPowerConsumption = 0;
end;

function RealisticAugerWagon:updateTick(dt)
	if self.isServer and self.isActive then
		self.realCurrentPowerConsumption = 0;
		if self.realOverloaderUnloadingPowerConsumption and self.pipeIsUnloading then
			self.realCurrentPowerConsumption = self.realOverloaderUnloadingPowerConsumption;
		elseif self.realWorkingPowerConsumption and self:getIsAnimationPlaying('foldingPipe') then
			self.realCurrentPowerConsumption = self.realWorkingPowerConsumption;
		end;
	end;
end;

function RealisticAugerWagon:update(dt) end;
function RealisticAugerWagon:draw() end;
function RealisticAugerWagon:delete() end;
function RealisticAugerWagon:mouseEvent(posX, posY, isDown, isUp, button) end;
function RealisticAugerWagon:keyEvent(unicode, sym, modifier, isDown) end;
