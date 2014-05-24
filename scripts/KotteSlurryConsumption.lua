-- KotteSlurryConsumption
-- adjusts spray usage based on the sprayer's folded/unfolded state

-- @author: Jakob Tischler
-- @date: 24 May 2014
-- @version: 0.1
-- @history: 0.1 (24 May 2014) - power consumption
--
-- Copyright (C) 2014 Jakob Tischler

KotteSlurryConsumption = {};

function KotteSlurryConsumption.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(RealisticVehicle, specializations) and SpecializationUtil.hasSpecialization(Sprayer, specializations);
end;

function KotteSlurryConsumption:load(xmlFile)
	if not self.particlePlanes or not self.currentFillType then return; end;

	self.setSprayLitersPerSecond = KotteSlurryConsumption.setSprayLitersPerSecond;

	self.sprayLitersPerSecondFolded = getXMLInt(xmlFile, 'vehicle.sprayUsageLitersPerSecondFolded') or (self.defaultSprayLitersPerSecond * 0.6);
	self:setSprayLitersPerSecond();
end;

function KotteSlurryConsumption:updateTick(dt)
	if not self.isActive then return; end;

	if self.particlePlanes.state ~= self.prevParticlePlaneState then
		self:setSprayLitersPerSecond();
	end;
end;

function KotteSlurryConsumption:setSprayLitersPerSecond()
	local fillType = self.currentFillType;
	if not fillType or fillType == Fillable.FILLTYPE_UNKNOWN then
		fillType = Fillable.FILLTYPE_LIQUIDMANURE;
	end;

	if self.particlePlanes.state == 0 then -- off -> default usage
		self.sprayLitersPerSecond[fillType] = self.defaultSprayLitersPerSecond;
	else -- on -> low usage
		self.sprayLitersPerSecond[fillType] = self.sprayLitersPerSecondFolded;
	end;
	print(('Kotte setSprayLitersPerSecond(): state=%d -> usage=%d'):format(self.particlePlanes.state, self.sprayLitersPerSecond[fillType]));

	self.prevParticlePlaneState = self.particlePlanes.state;
end;

function KotteSlurryConsumption:delete() end;
function KotteSlurryConsumption:mouseEvent(posX, posY, isDown, isUp, button) end;
function KotteSlurryConsumption:keyEvent(unicode, sym, modifier, isDown) end;
function KotteSlurryConsumption:update(dt) end;
function KotteSlurryConsumption:draw() end;
