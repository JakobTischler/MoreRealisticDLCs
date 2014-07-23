-- RealisticMovingTool
-- adds power consumption to implements with movingTools

-- @author: Jakob Tischler, dural
-- @date: 20 Jul 2014
-- @version: 0.3
-- @history: 0.1 (Jan 2014)
--           0.2 (17 May 2014)
--           0.3 (20 Jul 2014): get moving parts via updateMovingPart() instead of looping through each movingTool [dural]
--
-- Copyright (C) 2014 Jakob Tischler


RealisticMovingTool = {};

function RealisticMovingTool.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(RealisticVehicle, specializations) and SpecializationUtil.hasSpecialization(Cylindered, specializations);
end;

function RealisticMovingTool:load(xmlFile)
	self.realWorkingPowerConsumption = getXMLFloat(xmlFile, 'vehicle.realWorkingPowerConsumption');
	self.realCurrentPowerConsumption = 0;
	self.powerConsumptionRequired = false;
end;

function RealisticMovingTool:updateTick(dt)
	if self.isServer and self.isActive and self.realWorkingPowerConsumption then
		self.realCurrentPowerConsumption = 0;

		if self.powerConsumptionRequired then
			self.realCurrentPowerConsumption = self.realWorkingPowerConsumption;
			self.powerConsumptionRequired = false;
		end;
	end;
end;

function RealisticMovingTool.setPowerConsumptionRequired(self, part, isInitialUpdate)
	if self.isServer and self.isRealistic and part.playSound then
		self.powerConsumptionRequired = true;
	end;
end;
Cylindered.updateMovingPart = Utils.appendedFunction(Cylindered.updateMovingPart, RealisticMovingTool.setPowerConsumptionRequired);

function RealisticMovingTool:delete() end;
function RealisticMovingTool:mouseEvent(posX, posY, isDown, isUp, button) end;
function RealisticMovingTool:keyEvent(unicode, sym, modifier, isDown) end;
function RealisticMovingTool:update(dt) end;
function RealisticMovingTool:draw() end;

