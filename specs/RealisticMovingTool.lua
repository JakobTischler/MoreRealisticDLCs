-- RealisticMovingTool
-- adds power consumption to implements with movingTools

-- @author: Jakob Tischler
-- @date: 17 May 2014
-- @version: 0.2
-- @history: 0.1 (Jan 2014)
--           0.2 (17 May 2014)
--
-- Copyright (C) 2014 Jakob Tischler


RealisticMovingTool = {};

function RealisticMovingTool.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(RealisticVehicle, specializations) and SpecializationUtil.hasSpecialization(Cylindered, specializations);
end;

function RealisticMovingTool:load(xmlFile)
	self.realWorkingPowerConsumption = Utils.getNoNil(getXMLFloat(xmlFile, 'vehicle.realWorkingPowerConsumption'), 0);
	self.realCurrentPowerConsumption = 0;
	self.powerConsumptionRequired = false;
end;

function RealisticMovingTool:delete()
end;

function RealisticMovingTool:mouseEvent(posX, posY, isDown, isUp, button)
end;

function RealisticMovingTool:keyEvent(unicode, sym, modifier, isDown)
end;

local abs = math.abs;
function RealisticMovingTool:updateTick(dt)
	if self.isServer and self.isActive and self.realWorkingPowerConsumption > 0 then
		self.realCurrentPowerConsumption = 0;

		if self.powerConsumptionRequired then
			self.realCurrentPowerConsumption = self.realWorkingPowerConsumption;
			self.powerConsumptionRequired = false;
		end;
	end;
end;

function RealisticMovingTool:update(dt)
end;

function RealisticMovingTool:draw()
end;

function RealisticMovingTool.setPowerConsumptionRequired(self, part, isInitialUpdate)
	if self.isServer and part.playSound then
		self.powerConsumptionRequired = true;
	end;
end;
Cylindered.updateMovingPart = Utils.appendedFunction(Cylindered.updateMovingPart, RealisticMovingTool.setPowerConsumptionRequired);

