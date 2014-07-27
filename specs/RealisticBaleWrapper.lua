-- RealisticBaleWrapper
-- adds power consumption and correct silage fill levels to the Ursus MR bale wrapper

-- @author: Jakob Tischler
-- @date: 27 Jul 2014
-- @version: 0.4
-- @history: 0.1 (20 May 2014) - power consumption
--           0.2 (23 May 2014) - adjust silage bale fillLevel depending on wrapped bale fillType
--           0.3 (19 Jun 2014) - adjust wrapper weight depending on the current bale being wrapped
--           0.4 (27 Jul 2014) - make sure Ursus DLC exists when overwriting getBaleInRange function
--
-- Copyright (C) 2014 Jakob Tischler


RealisticBaleWrapper = {};

function RealisticBaleWrapper.prerequisitesPresent(specializations)
	if RealisticVehicle and pdlc_ursusAddon and pdlc_ursusAddon.BaleWrapper then
		return SpecializationUtil.hasSpecialization(RealisticVehicle, specializations) and SpecializationUtil.hasSpecialization(pdlc_ursusAddon.BaleWrapper, specializations);
	end;
	return false;
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

	if pdlc_ursusAddon.BaleWrapper.origGetBaleInRange == nil then
		pdlc_ursusAddon.BaleWrapper.origGetBaleInRange = pdlc_ursusAddon.BaleWrapper.getBaleInRange;
		pdlc_ursusAddon.BaleWrapper.getBaleInRange = RealisticBaleWrapper.getBaleInRange;
	end;
end;

function RealisticBaleWrapper.getBaleInRange(self, node)
	local bale, silageBaleData = pdlc_ursusAddon.BaleWrapper.origGetBaleInRange(self, node);
	if self.isRealistic and bale and silageBaleData and bale.fillLevel and bale.fillType and (bale.isRealistic or bale.realSleepingMode1 ~= nil) then
		local fillType = bale:getFillType();
		if bale.nodeId and bale.nodeId ~= 0 then
			local realFillType = getUserAttribute(bale.nodeId, 'realFillType');
			if realFillType then
				fillType = Fillable.fillTypeNameToInt[realFillType];
			end;
		end;

		bale:setFillLevel(bale:getFillLevel() * (self.fillTypeRatio[fillType] or 1)); --TODO: MP? fillLevel event?
	end;

	return bale, silageBaleData;
end;

function RealisticBaleWrapper:updateTick(dt)
	if self.isServer and self.isActive then
		if self.realWorkingPowerConsumption then
			self.realCurrentPowerConsumption = 0;
			-- wrapping power consumption
			if self.baleWrapperState == pdlc_ursusAddon.BaleWrapper.STATE_WRAPPER_WRAPPING_BALE then
				self.realCurrentPowerConsumption = self.realWorkingPowerConsumption;

			-- at least one animation playing
			elseif next(self.activeAnimations) ~= nil then
				self.realCurrentPowerConsumption = self.realWorkingPowerConsumption * 0.5;
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

function RealisticBaleWrapper:delete() end;
function RealisticBaleWrapper:mouseEvent(posX, posY, isDown, isUp, button) end;
function RealisticBaleWrapper:keyEvent(unicode, sym, modifier, isDown) end;
function RealisticBaleWrapper:update(dt) end;
function RealisticBaleWrapper:draw() end;
