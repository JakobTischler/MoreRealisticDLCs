-- NodeTest
-- lets the user move a test node and displays it

-- @author: Jakob Tischler
-- @date: 26 Jul 2014
-- @version: 0.1
-- @history: 0.1 (26 Jul 2014)
--
-- Copyright (C) 2014 Jakob Tischler

NodeTest = {};

function NodeTest.prerequisitesPresent(specializations)
	return true;
end;

function NodeTest:load(xmlFile) end;
function NodeTest:postLoad(xmlFile)
	local testNodeIndex = getXMLString(xmlFile, 'vehicle.nodeTest#index');
	print(('%s: testNodeIndex=%q'):format(tostring(self.name), tostring(testNodeIndex)));
	self.nodeTestNode = Utils.indexToObject(self.components, testNodeIndex);
	print(('\tnodeTestNode=%s'):format(tostring(self.nodeTestNode)));
	-- assert(self.NodeTestNode ~= nil, 'node test node could not be found');

	self.moveTestNode = NodeTest.moveTestNode;
	self.rotateTestNode = NodeTest.rotateTestNode;
	self.moveBy = 0.02;
	self.rotateBy = math.rad(2);
	self:moveTestNode(0, 0, 0);
	self:rotateTestNode(0, 0, 0);
end;

function NodeTest:update(dt)
	if self.isClient and self:getIsActiveForInput() then
		local mod = InputBinding.isPressed(InputBinding.NODETEST_MOD);
		local moveBy = self.moveBy * (mod and 5 or 1);
		local rotateBy = self.rotateBy * (mod and 5 or 1);

		if InputBinding.hasEvent(InputBinding.NODETEST_MOVE_X_POS) then
			self:moveTestNode(moveBy, 0, 0);
		elseif InputBinding.hasEvent(InputBinding.NODETEST_MOVE_X_NEG) then
			self:moveTestNode(moveBy, 0, 0);
		elseif InputBinding.hasEvent(InputBinding.NODETEST_MOVE_Y_POS) then
			self:moveTestNode(0, moveBy, 0);
		elseif InputBinding.hasEvent(InputBinding.NODETEST_MOVE_Y_NEG) then
			self:moveTestNode(0, -moveBy, 0);
		elseif InputBinding.hasEvent(InputBinding.NODETEST_MOVE_Z_POS) then
			self:moveTestNode(0, 0, moveBy);
		elseif InputBinding.hasEvent(InputBinding.NODETEST_MOVE_Z_NEG) then
			self:moveTestNode(0, 0, -moveBy);
		elseif InputBinding.hasEvent(InputBinding.NODETEST_ROTATE_X_POS) then
			self:rotateTestNode(rotateBy, 0, 0);
		elseif InputBinding.hasEvent(InputBinding.NODETEST_ROTATE_X_NEG) then
			self:rotateTestNode(-rotateBy, 0, 0);
		elseif InputBinding.hasEvent(InputBinding.NODETEST_ROTATE_Y_POS) then
			self:rotateTestNode(0, rotateBy, 0);
		elseif InputBinding.hasEvent(InputBinding.NODETEST_ROTATE_Y_NEG) then
			self:rotateTestNode(0, -rotateBy, 0);
		elseif InputBinding.hasEvent(InputBinding.NODETEST_ROTATE_Z_POS) then
			self:rotateTestNode(0, 0, rotateBy);
		elseif InputBinding.hasEvent(InputBinding.NODETEST_ROTATE_Z_NEG) then
			self:rotateTestNode(0, 0, -rotateBy);
		end;

		local x,y,z = getWorldTranslation(self.nodeTestNode);
		drawDebugPoint(x, y, z, 1, 0, 1, 1);
		local x2,y2,z2 = localToWorld(self.nodeTestNode, 0, 0, 1);
		drawDebugLine(x,y,z, 0, 0, 1, x2,y2,z2, 0, 0, 1);
		local x3,y3,z3 = localToWorld(self.nodeTestNode, 1, 0, 0);
		drawDebugLine(x,y,z, 1, 0, 0, x3,y3,z3, 0, 0, 0);
		local x4,y4,z4 = localToWorld(self.nodeTestNode, 0, 1, 0);
		drawDebugLine(x,y,z, 0, 1, 0, x4,y4,z4, 0, 1, 0);
	end;
end;

function NodeTest:draw()
	g_currentMission:addExtraPrintText(('current trans: x=%.4f, y=%.4f, z=%.4f'):format(unpack(self.curNodeTrans)));
	g_currentMission:addExtraPrintText(('current rot: x=%.1f, y=%.1f, z=%.1f'):format(unpack(self.curNodeRot)));
end;

function NodeTest:moveTestNode(dx, dy, dz)
	local x, y, z = getTranslation(self.nodeTestNode);
	local nx, ny, nz = x + dx, y + dy, z + dz;
	setTranslation(self.nodeTestNode, nx, ny, nz)
	self.curNodeTrans = { nx, ny, nz };
	print(('moveTestNode: x=%.4f, y=%.4f, z=%.4f'):format(nx, ny, nz));
end;

local deg = math.deg;
function NodeTest:rotateTestNode(dx, dy, dz)
	local x, y, z = getRotation(self.nodeTestNode);
	local nx, ny, nz = x + dx, y + dy, z + dz;
	setRotation(self.nodeTestNode, nx, ny, nz)
	self.curNodeRot = { deg(nx), deg(ny), deg(nz) };
	print(('rotateTestNode: x=%.4f, y=%.4f, z=%.4f'):format(unpack(self.curNodeRot)));
end;

function NodeTest:delete() end;
function NodeTest:mouseEvent(posX, posY, isDown, isUp, button) end;
function NodeTest:keyEvent(unicode, sym, modifier, isDown) end;
function NodeTest:updateTick(dt) end;

