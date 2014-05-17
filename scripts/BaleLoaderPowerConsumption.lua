--[[
BaleLoaderPowerConsumption
adds power consumption to the BaleLoader when there's any moving parts (playing animations)

@author: Jakob Tischler
@date: 17 May 2014
@version: 0.1
]]

BaleLoaderPowerConsumption = {};

function BaleLoaderPowerConsumption.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(RealisticVehicle, specializations);
end;

function BaleLoaderPowerConsumption:load(xmlFile)
	self.realWorkingPowerConsumption = getXMLFloat(xmlFile, 'vehicle.realWorkingPowerConsumption');
	self.realCurrentPowerConsumption = 0;

	self.powerConsumingAnimations = {};
	if self.realWorkingPowerConsumption then
		for animationName,animation in pairs(self.animations) do
			if #animation.parts > 0 and animationName ~= 'moveSupport' then
				self.powerConsumingAnimations[#self.powerConsumingAnimations + 1] = animationName;
			end;
		end;
	end;
	self.hasPowerConsumingAnimations = #self.powerConsumingAnimations > 0;
end;

function BaleLoaderPowerConsumption:delete()
end;

function BaleLoaderPowerConsumption:mouseEvent(posX, posY, isDown, isUp, button)
end;

function BaleLoaderPowerConsumption:keyEvent(unicode, sym, modifier, isDown)
end;

local getIsAnyAnimationPlaying = function(vehicle, animationNames)
	for i=1,#animationNames do
		if vehicle:getIsAnimationPlaying(animationNames[i]) then
			return true;
		end;
	end;
	return false;
end;

function BaleLoaderPowerConsumption:updateTick(dt)
	if self.isServer and self.isActive then
		self.realCurrentPowerConsumption = 0;
		if self.realWorkingPowerConsumption and self.hasPowerConsumingAnimations and getIsAnyAnimationPlaying(self, self.powerConsumingAnimations) then
			self.realCurrentPowerConsumption = self.realWorkingPowerConsumption;
		end;
	end;
end;

function BaleLoaderPowerConsumption:update(dt)
end;

function BaleLoaderPowerConsumption:draw()
end;
