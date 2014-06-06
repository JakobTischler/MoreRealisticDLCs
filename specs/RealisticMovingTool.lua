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

		for i=1,#self.movingTools do
			local mt = self.movingTools[i];
			if (mt.lastRotSpeed and abs(mt.lastRotSpeed) > 0) or (mt.lastTransSpeed and abs(mt.lastTransSpeed) > 0) then
				-- print(('%s: movingTool %d: lastRotSpeed=%s -> realCurrentPowerConsumption=%d':format(tostring(self.name), i, tostring(mt.lastRotSpeed), self.realWorkingPowerConsumption));
				self.realCurrentPowerConsumption = self.realWorkingPowerConsumption;
				break;
			end;
		end;
	end;
end;

function RealisticMovingTool:update(dt)
end;

function RealisticMovingTool:draw()
end;
