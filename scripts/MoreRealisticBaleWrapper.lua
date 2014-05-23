--[[
MoreRealisticBaleWrapper
adds power consumption to bale wrappers

@author: Jakob Tischler
@date: 20 May 2014
@version: 0.2
@history: 0.1 (20 May 2014) - power consumption
          0.2 (23 May 2014) - adjust silage bale fillLevel depending on wrapped bale fillType
]]

MoreRealisticBaleWrapper = {};

function MoreRealisticBaleWrapper.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(RealisticVehicle, specializations) and SpecializationUtil.hasSpecialization(Cylindered, specializations);
end;

local origGetBaleInRange;
function MoreRealisticBaleWrapper:load(xmlFile)
	self.realWorkingPowerConsumption = getXMLFloat(xmlFile, 'vehicle.realWorkingPowerConsumption');
	self.realCurrentPowerConsumption = 0;

	for i, spec in pairs(self.specializations) do
		if spec ~= MoreRealisticBaleWrapper and spec.getBaleInRange ~= nil then
			-- print(('spec %d has function "getBaleInRange" -> set as origGetBaleInRange, overwrite with own'):format(i));
			-- print(tableShow(spec.getBaleInRange, 'spec [before]'));
			origGetBaleInRange = spec.getBaleInRange;
			spec.getBaleInRange = MoreRealisticBaleWrapper.getBaleInRange;
			-- print(tableShow(spec.getBaleInRange, 'spec [after]'));
			break;
		end;
	end;

	-- fillType to silage ratio
	local _, grassWindrowDensity	 = RealisticUtils.getFillTypeInfosV2('grass_windrow');
	local _, dryGrassWindrowDensity = RealisticUtils.getFillTypeInfosV2('dryGrass_windrow');
	local _, silageDensity			 = RealisticUtils.getFillTypeInfosV2('silage');
	self.fillTypeRatio = {
		[ Fillable.fillTypeNameToInt.grass_windrow ]	= grassWindrowDensity / silageDensity;
		[ Fillable.fillTypeNameToInt.dryGrass_windrow ]	= dryGrassWindrowDensity / silageDensity;
	};
	-- print(tableShow(self.fillTypeRatio, 'self.fillTypeRatio'));
end;

function MoreRealisticBaleWrapper:delete()
end;

function MoreRealisticBaleWrapper:mouseEvent(posX, posY, isDown, isUp, button)
end;

function MoreRealisticBaleWrapper:keyEvent(unicode, sym, modifier, isDown)
end;

function MoreRealisticBaleWrapper:update(dt)
end;

function MoreRealisticBaleWrapper:updateTick(dt)
	if self.isServer and self.isActive and self.realWorkingPowerConsumption then
		self.realCurrentPowerConsumption = 0;

		if self.baleWrapperState == 3 then
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

function MoreRealisticBaleWrapper.getBaleInRange(self, node)
	local bale, silageBaleData = origGetBaleInRange(self, node);
	if bale then
		-- print(('getBaleInRange: bale=%s, silageBaleData=%s'):format(tostring(bale), tostring(silageBaleData)));
		-- print(('\tfillType=%d (%s), fillLevel=%.2f'):format(bale.fillType, Fillable.fillTypeIntToName[bale.fillType], bale.fillLevel));
		if silageBaleData and bale.fillLevel and bale.fillType then
			bale.fillLevel = bale.fillLevel * (self.fillTypeRatio[bale.fillType] or 1);
			-- print(('\tratio=%.5f -> set fillLevel to %.2f'):format(self.fillTypeRatio[bale.fillType], bale.fillLevel));
		end;
	end;

	return bale, silageBaleData;
end;

function MoreRealisticBaleWrapper:draw()
end;
