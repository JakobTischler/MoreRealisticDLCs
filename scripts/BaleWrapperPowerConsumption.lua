--[[
BaleWrapperPowerConsumption
adds power consumption to bale wrappers

@author: Jakob Tischler
@date: 20 May 2014
@version: 0.1
]]

BaleWrapperPowerConsumption = {};

function BaleWrapperPowerConsumption.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(RealisticVehicle, specializations) and SpecializationUtil.hasSpecialization(Cylindered, specializations);
end;

function BaleWrapperPowerConsumption:load(xmlFile)
	self.realWorkingPowerConsumption = getXMLFloat(xmlFile, 'vehicle.realWorkingPowerConsumption');
	self.realCurrentPowerConsumption = 0;
end;

function BaleWrapperPowerConsumption:delete()
end;

function BaleWrapperPowerConsumption:mouseEvent(posX, posY, isDown, isUp, button)
end;

function BaleWrapperPowerConsumption:keyEvent(unicode, sym, modifier, isDown)
end;

function BaleWrapperPowerConsumption:updateTick(dt)
	if self.isServer and self.isActive and self.realWorkingPowerConsumption then
		self.realCurrentPowerConsumption = 0;

		if self.baleWrapperState == 3 then --BaleWrapper.STATE_WRAPPER_WRAPPING_BALE
			self.realCurrentPowerConsumption = self.realWorkingPowerConsumption;
			return;
		end;

		for _, anim in pairs(self.activeAnimations) do
			-- at least one animation playing
			self.realCurrentPowerConsumption = self.realWorkingPowerConsumption;
			break;
		end;
	end;
end;

function BaleWrapperPowerConsumption:update(dt)
end;

function BaleWrapperPowerConsumption:draw()
end;
