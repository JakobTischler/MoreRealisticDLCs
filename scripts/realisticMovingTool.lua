--[[
realisticMovingTool
adds power consumption to implements with movingTools

@author: Jakob Tischler (based on 'realisticPtoImplement.lua' by Michel Dorge)
@date: 29 Jan 2014
@version: 0.1
]]

realisticMovingTool = {};

function realisticMovingTool.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(RealisticVehicle, specializations) and SpecializationUtil.hasSpecialization(Cylindered, specializations);
end;

function realisticMovingTool:load(xmlFile)
	self.realWorkingPowerConsumption = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.realWorkingPowerConsumption"), 0);
	self.realCurrentPowerConsumption = 0;
end;

function realisticMovingTool:delete()
end;

function realisticMovingTool:mouseEvent(posX, posY, isDown, isUp, button)
end;

function realisticMovingTool:keyEvent(unicode, sym, modifier, isDown)
end;

function realisticMovingTool:updateTick(dt)
	if self.isServer and self.isActive and self.realWorkingPowerConsumption > 0 then
		self.realCurrentPowerConsumption = 0;

		for i,mt in pairs(self.movingTools) do
			if (mt.lastRotSpeed and math.abs(mt.lastRotSpeed) > 0) or (mt.lastTransSpeed and math.abs(mt.lastTransSpeed) > 0) then
				-- print(string.format('%s: movingTool %d: lastRotSpeed=%s -> realCurrentPowerConsumption=%d', tostring(self.name), i, tostring(mt.lastRotSpeed), self.realWorkingPowerConsumption));
				self.realCurrentPowerConsumption = self.realWorkingPowerConsumption;
				break;
			end;
		end;
	end;
end;

function realisticMovingTool:update(dt)
end;

function realisticMovingTool:draw()
end;
