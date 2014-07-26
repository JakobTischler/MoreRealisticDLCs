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
	self.moveBy = 0.05;
	self:moveTestNode(0, 0, 0);
end;

function NodeTest:update(dt)
	if self.isClient and self:getIsActiveForInput() then
		if InputBinding.hasEvent(InputBinding.MOREREALISTICDLCS_NODETEST_MOVE_X_POS) then
			self:moveTestNode(self.moveBy, 0, 0);
		elseif InputBinding.hasEvent(InputBinding.MOREREALISTICDLCS_NODETEST_MOVE_X_NEG) then
			self:moveTestNode(-self.moveBy, 0, 0);
		elseif InputBinding.hasEvent(InputBinding.MOREREALISTICDLCS_NODETEST_MOVE_Y_POS) then
			self:moveTestNode(0, self.moveBy, 0);
		elseif InputBinding.hasEvent(InputBinding.MOREREALISTICDLCS_NODETEST_MOVE_Y_NEG) then
			self:moveTestNode(0, -self.moveBy, 0);
		elseif InputBinding.hasEvent(InputBinding.MOREREALISTICDLCS_NODETEST_MOVE_Z_POS) then
			self:moveTestNode(0, 0, self.moveBy);
		elseif InputBinding.hasEvent(InputBinding.MOREREALISTICDLCS_NODETEST_MOVE_Z_NEG) then
			self:moveTestNode(0, 0, -self.moveBy);
		end;
		local x,y,z = getWorldTranslation(self.nodeTestNode);
		drawDebugPoint(x, y, z, 1, 0, 1, 1);
		local x2,y2,z2 = localToWorld(self.nodeTestNode, 0, 0, -2);
		drawDebugLine(x,y,z, 1, 0, 1, x2,y2,z2, 1, 1, 1);
	end;
end;

function NodeTest:draw()
	g_currentMission:addExtraPrintText(('current trans: x=%.4f, y=%.4f, z=%.4f'):format(unpack(self.curNodeTrans)));
end;

function NodeTest:moveTestNode(dx, dy, dz)
	local x, y, z = getTranslation(self.nodeTestNode);
	local nx, ny, nz = x + dx, y + dy, z + dz;
	setTranslation(self.nodeTestNode, nx, ny, nz)
	self.curNodeTrans = { nx, ny, nz };
	print(('moveTestNode: x=%.4f, y=%.4f, z=%.4f'):format(nx, ny, nz));
end;

function NodeTest:delete() end;
function NodeTest:mouseEvent(posX, posY, isDown, isUp, button) end;
function NodeTest:keyEvent(unicode, sym, modifier, isDown) end;
function NodeTest:updateTick(dt) end;

