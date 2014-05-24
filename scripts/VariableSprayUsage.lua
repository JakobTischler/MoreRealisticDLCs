-- VariableSprayUsage
-- adjusts spray usage based on the sprayer's folded/unfolded state

-- @author: Jakob Tischler
-- @date: 24 May 2014
-- @version: 0.2
-- @history: 0.2 (24 May 2014) - spray consumption
--
-- Copyright (C) 2014 Jakob Tischler

VariableSprayUsage = {};

function VariableSprayUsage.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(RealisticVehicle, specializations) and SpecializationUtil.hasSpecialization(Sprayer, specializations) and SpecializationUtil.hasSpecialization(Foldable, specializations);
end;

function VariableSprayUsage:load(xmlFile)
	if not self.currentFillType or self.foldAnimTime == nil then return; end;

	self.setSprayLitersPerSecond = VariableSprayUsage.setSprayLitersPerSecond;

	self.sprayLitersPerSecondFolded = getXMLFloat(xmlFile, 'vehicle.sprayUsageLitersPerSecondFolded');
	assert(self.sprayLitersPerSecondFolded ~= nil, '"sprayUsageLitersPerSecondFolded" parameter missing!');
	local foldDir = self.foldAnimTime >= 0.001 and 1 or 0;
	self:setSprayLitersPerSecond(foldDir);
end;

function VariableSprayUsage:updateTick(dt)
	if not self.isActive or self.foldAnimTime == nil then return; end;

	local foldDir = self.foldAnimTime >= 0.001 and 1 or 0;
	if foldDir ~= self.prevSetFoldAnimTime then
		self:setSprayLitersPerSecond(foldDir);
	end;
end;

function VariableSprayUsage:setSprayLitersPerSecond(foldDir)
	local fillType = self.currentFillType;
	if not fillType or fillType == Fillable.FILLTYPE_UNKNOWN then
		fillType = Fillable.FILLTYPE_LIQUIDMANURE;
	end;

	if foldDir == 0 then -- default usage
		self.sprayLitersPerSecond[fillType] = self.defaultSprayLitersPerSecond;
	else -- alternate usage
		self.sprayLitersPerSecond[fillType] = self.sprayLitersPerSecondFolded;
	end;

	self.prevSetFoldAnimTime = foldDir;
end;

function VariableSprayUsage:delete() end;
function VariableSprayUsage:mouseEvent(posX, posY, isDown, isUp, button) end;
function VariableSprayUsage:keyEvent(unicode, sym, modifier, isDown) end;
function VariableSprayUsage:update(dt) end;
function VariableSprayUsage:draw() end;
