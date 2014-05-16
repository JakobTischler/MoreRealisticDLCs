--[[
AugerWagonPowerConsumption
adds power consumption to implements with movingTools

@author: Jakob Tischler
@date: 16 May 2014
@version: 0.1
]]

AugerWagonPowerConsumption = {};

function AugerWagonPowerConsumption.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(RealisticVehicle, specializations) and SpecializationUtil.hasSpecialization(Cylindered, specializations);
end;

function AugerWagonPowerConsumption:load(xmlFile)
	self.realOverloaderUnloadingPowerConsumption = Utils.getNoNil(getXMLFloat(xmlFile, 'vehicle.realOverloaderUnloadingPowerConsumption'), 0);
	self.realCurrentPowerConsumption = 0;
end;

function AugerWagonPowerConsumption:delete()
end;

function AugerWagonPowerConsumption:mouseEvent(posX, posY, isDown, isUp, button)
end;

function AugerWagonPowerConsumption:keyEvent(unicode, sym, modifier, isDown)
end;

function AugerWagonPowerConsumption:updateTick(dt)
	if self.isServer and self.isActive and self.realOverloaderUnloadingPowerConsumption > 0 then
		self.realCurrentPowerConsumption = 0;
		if self.pipeIsUnloading then
			self.realCurrentPowerConsumption = self.realOverloaderUnloadingPowerConsumption;
		end;
	end;
end;

function AugerWagonPowerConsumption:update(dt)
end;

function AugerWagonPowerConsumption:draw()
end;
