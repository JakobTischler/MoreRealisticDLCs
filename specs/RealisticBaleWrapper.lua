-- RealisticBaleWrapper
-- adds power consumption and correct silage fill levels to the Ursus MR bale wrapper

-- @author: Jakob Tischler
-- @date: 20 May 2014
-- @version: 0.3
-- @history: 0.1 (20 May 2014) - power consumption
--           0.2 (23 May 2014) - adjust silage bale fillLevel depending on wrapped bale fillType
--           0.3 (19 June 2014) - adjust wrapper weight depending on the current bale being wrapped
--
-- Copyright (C) 2014 Jakob Tischler


if pdlc_ursusAddon == nil or pdlc_ursusAddon.BaleWrapper == nil or RealisticUtils == nil then return; end;

RealisticBaleWrapper = {};

function RealisticBaleWrapper.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(RealisticVehicle, specializations) and SpecializationUtil.hasSpecialization(Cylindered, specializations);
end;

function RealisticBaleWrapper:load(xmlFile)
	-- power consumption
	self.realWorkingPowerConsumption = getXMLFloat(xmlFile, 'vehicle.realWorkingPowerConsumption');
	self.realCurrentPowerConsumption = 0;

	self.updateLoadedBaleMass = RealisticBaleWrapper.updateLoadedBaleMass;
	self.realBaleWrapperLastBaleId = nil;

	-- fillType to silage ratio
	self.fillTypeRatio = {};
	local silageExists, silageDensity = RealisticUtils.getFillTypeInfosV2('silage');
	if not silageExists or not silageDensity or silageDensity == 0 then return; end;

	for fillType,_ in pairs(self.allowedBaleTypes) do
		local fillTypeName = Fillable.fillTypeIntToName[fillType];
		local exists, density = RealisticUtils.getFillTypeInfosV2(fillTypeName);
		if exists then
			self.fillTypeRatio[fillType] = density / silageDensity;
		end;
	end;
end;

function RealisticBaleWrapper:updateTick(dt)
	if self.isServer and self.isActive then
		if self.realWorkingPowerConsumption then
			self.realCurrentPowerConsumption = 0;
			if self.baleWrapperState == pdlc_ursusAddon.BaleWrapper.STATE_WRAPPER_WRAPPING_BALE then
				self.realCurrentPowerConsumption = self.realWorkingPowerConsumption;
			elseif next(self.activeAnimations) ~= nil then -- at least one animation playing
				self.realCurrentPowerConsumption = self.realWorkingPowerConsumption;
			end;
		end;

		local currentBaleId = self.wrapper.currentBale;
		if currentBaleId ~= self.realBaleWrapperLastBaleId then
			self:updateLoadedBaleMass(currentBaleid);
			self.realBaleWrapperLastBaleId = currentBaleId;
		end;
	end;
end;

function RealisticBaleWrapper:updateLoadedBaleMass(baleId) 
	local newBaleMass = 0;

	if baleId ~= nil then
		local baleObject = networkGetObject(self.wrapper.currentBale);
		if baleObject ~= nil and baleObject.realCurrentMass ~= nil then
			newBaleMass = baleObject.realCurrentMass;
		end;
	end;

	self.realFillableFillMass = newBaleMass;
end;

local origGetBaleInRange = pdlc_ursusAddon.BaleWrapper.getBaleInRange;
function RealisticBaleWrapper.getBaleInRange(self, node)
	local bale, silageBaleData = origGetBaleInRange(self, node);
	if self.isRealistic and bale and silageBaleData and bale.fillLevel and bale.fillType and (bale.isRealistic or bale.realSleepingMode1 ~= nil) then
		local fillType = bale.fillType;
		if bale.nodeId and bale.nodeId ~= 0 then
			local realFillType = getUserAttribute(bale.nodeId, 'realFillType');
			if realFillType then
				fillType = Fillable.fillTypeNameToInt[realFillType];
			end;
		end;

		bale.fillLevel = bale.fillLevel * (self.fillTypeRatio[fillType] or 1);
	end;

	return bale, silageBaleData;
end;
pdlc_ursusAddon.BaleWrapper.getBaleInRange = RealisticBaleWrapper.getBaleInRange;

function RealisticBaleWrapper:delete() end;
function RealisticBaleWrapper:mouseEvent(posX, posY, isDown, isUp, button) end;
function RealisticBaleWrapper:keyEvent(unicode, sym, modifier, isDown) end;
function RealisticBaleWrapper:update(dt) end;
function RealisticBaleWrapper:draw() end;
