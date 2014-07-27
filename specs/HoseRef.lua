--
--
local moddir = g_currentModDirectory;

HoseRef = {};

function HoseRef.prerequisitesPresent(specializations)
    return true;
end;


function HoseRef:printTable( _tbl, _str, _dpth, _mdpth )
	if _dpth >= _mdpth then
		return;
	end;
	for i,j in pairs( _tbl ) do
		print(_dpth.._str.." "..tostring(i).." "..tostring(j));
		if string.match( type(j), "table" ) then
			self:printTable(j, _str.." >", _dpth+1, _mdpth);
		end
	end
end;


function HoseRef:load(xmlFile)
	self.printTable = HoseRef.printTable;

	self.setRefState = HoseRef.setRefState;

	self.hoseRef = {};

	self.isTrailer = not SpecializationUtil.hasSpecialization(Steerable, self.specializations);

	--#
	self.hoseRef.refs = {};
	local i = 0;
	while true do
		local str = getXMLString(xmlFile, string.format("vehicle.hoseRef.ref(%d)#index",i));
		if str == nil then
			break;
		end;
		local rt = getXMLString(xmlFile, string.format("vehicle.hoseRef.ref(%d)#type",i));
		local compIdx = getXMLFloat(xmlFile, string.format("vehicle.hoseRef.ref(%d)#compIdx",i));
		local id = i + 1;
		local node = Utils.indexToObject(self.components, str);
		local node2 = Utils.indexToObject(self.components, getXMLString(xmlFile, string.format("vehicle.hoseRef.ref(%d)#index2",i)));
		local delta = getXMLString(xmlFile, string.format("vehicle.hoseRef.ref(%d)#deltaFill",i));
		local isUsed = false;
		local hose = 0;
		local anim = {};
		if getXMLString(xmlFile, string.format("vehicle.hoseRef.ref(%d)#animIndex",i)) ~= nil then
			anim.idx = Utils.indexToObject(self.components, getXMLString(xmlFile, string.format("vehicle.hoseRef.ref(%d)#animIndex",i)));
			anim.charset = getAnimCharacterSet(anim.idx);
			anim.clipIdx = getAnimClipIndex(anim.charset, getXMLString(xmlFile, string.format("vehicle.hoseRef.ref(%d)#animClip",i)));
			assignAnimTrackClip(anim.charset, 0, anim.clipIdx);
			setAnimTrackLoopState(anim.charset, 0, false);
			anim.duration = getAnimClipDuration(anim.charset, anim.clipIdx);
			setAnimTrackTime(anim.charset, 0, anim.duration, true);
		end;
		local animOpen = {};
		if getXMLString(xmlFile, string.format("vehicle.hoseRef.ref(%d)#animOpenIndex",i)) ~= nil then
			animOpen.idx = Utils.indexToObject(self.components, getXMLString(xmlFile, string.format("vehicle.hoseRef.ref(%d)#animOpenIndex",i)));
			animOpen.charset = getAnimCharacterSet(animOpen.idx);
			animOpen.clipIdx = getAnimClipIndex(animOpen.charset, getXMLString(xmlFile, string.format("vehicle.hoseRef.ref(%d)#animOpenClip",i)));
			assignAnimTrackClip(animOpen.charset, 0, animOpen.clipIdx);
			setAnimTrackLoopState(animOpen.charset, 0, false);
			animOpen.duration = getAnimClipDuration(animOpen.charset, animOpen.clipIdx);
			setAnimTrackTime(animOpen.charset, 0, 0, true);
		end;
		table.insert( self.hoseRef.refs, {rt=rt, compIdx=compIdx, id=id, node=node, node2=node2, delta=delta, isUsed=isUsed, hose=hose, anim=anim, animOpen=animOpen} );
		i = i + 1;
	end

	--#
	self.hoseRef.odc = {};
	self.hoseRef.odc.trigger = Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.hoseRef.outDoorControl#trigger"));
	self.playerCallback = SpecializationUtil.callSpecializationsFunction("playerCallback");

	if self.hoseRef.odc.trigger ~= nil then
		addTrigger(self.hoseRef.odc.trigger, "playerCallback", self);
		self.hoseRef.odc.pit = false;
		self.hoseRef.odc.dir = {};
		self.hoseRef.odc.dir.node = Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.hoseRef.outDoorControl#dirNode"));
		self.hoseRef.odc.dir.rMin = Utils.getVectorNFromString( getXMLString(xmlFile, "vehicle.hoseRef.outDoorControl#dirMin"), 3 );
		self.hoseRef.odc.dir.rMax = Utils.getVectorNFromString( getXMLString(xmlFile, "vehicle.hoseRef.outDoorControl#dirMax"), 3 );
		self.hoseRef.odc.dir.rNeut = Utils.getVectorNFromString( getXMLString(xmlFile, "vehicle.hoseRef.outDoorControl#dirNeut"), 3 );
		self.hoseRef.odc.enable = {};
		self.hoseRef.odc.enable.node = Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.hoseRef.outDoorControl#enableNode"));
		self.hoseRef.odc.enable.rMin = Utils.getVectorNFromString( getXMLString(xmlFile, "vehicle.hoseRef.outDoorControl#enableOff"), 3 );
		self.hoseRef.odc.enable.rMax = Utils.getVectorNFromString( getXMLString(xmlFile, "vehicle.hoseRef.outDoorControl#enableOn"), 3 );
		for i=1,3 do
			self.hoseRef.odc.dir.rMin[i] = math.rad( self.hoseRef.odc.dir.rMin[i] );
			self.hoseRef.odc.dir.rMax[i] = math.rad( self.hoseRef.odc.dir.rMax[i] );
			self.hoseRef.odc.dir.rNeut[i] = math.rad( self.hoseRef.odc.dir.rNeut[i] );
			self.hoseRef.odc.enable.rMin[i] = math.rad( self.hoseRef.odc.enable.rMin[i] );
			self.hoseRef.odc.enable.rMax[i] = math.rad( self.hoseRef.odc.enable.rMax[i] );
		end;
	end;

	--#
	self.pumpDir = 0;
	self.setPumpDir = SpecializationUtil.callSpecializationsFunction("setPumpDir");
	self.hasPump = Utils.getNoNil( getXMLBool(xmlFile, "vehicle.hoseRef#hasPump"), false );
	self.pumpSpeed = Utils.getNoNil( getXMLFloat(xmlFile, "vehicle.hoseRef#pumpSpeed"), 0.25);
	self.fillSpeed = Utils.getNoNil( getXMLFloat(xmlFile, "vehicle.hoseRef#fillSpeed"), 0.25);
	self.emptySpeed = Utils.getNoNil( getXMLFloat(xmlFile, "vehicle.hoseRef#emptySpeed"), 0.25);

	--###
	self.setVehicleIncreaseRpm = SpecializationUtil.callSpecializationsFunction("setVehicleIncreaseRpm");
    self.saveMinimumRpm = 0;
	self.rpmInc = {};
	self.rpmInc.drawbar = 0;
	self.rpmInc.turnOn = 0;
	self.rpmInc.turnOnDefault = 1000;
	self.rpmInc.fillarm = 0;
	self.attacherVehicleMinRpm = 0;

	self.doLoadCheck = -1;
end;

function HoseRef:delete()
end;

function HoseRef:readStream(streamId, connection)
	--print("function HoseRef:readStream(streamId, connection)")
	for i,ref in pairs(self.hoseRef.refs) do
		ref.isUsed = streamReadBool(streamId);
		local v = streamReadInt32(streamId);
		if v ~= 0 then
			ref.hoseToLoad = v;
		else
			ref.hose = 0;
		end;
	end;
end;

function HoseRef:writeStream(streamId, connection)
	--print("function HoseRef:writeStream(streamId, connection)");
	for i,ref in pairs(self.hoseRef.refs) do
		streamWriteBool(streamId, ref.isUsed);
		if ref.hose ~= 0 then
			streamWriteInt32(streamId, networkGetObjectId(ref.hose));
		else
			streamWriteInt32(streamId, 0);
		end
	end;
end;


function HoseRef:loadFromAttributesAndNodes(xmlFile, key, resetVehicles)
	if not resetVehicles then
	end;
	self.doLoadCheck = self.time + 1000;
	return BaseMission.VEHICLE_LOAD_OK;
end;

function HoseRef:getSaveAttributesAndNodes(nodeIdent)
	return nil, nil;
end;

function HoseRef:mouseEvent(posX, posY, isDown, isUp, button)
end;

function HoseRef:keyEvent(unicode, sym, modifier, isDown)
end;

function HoseRef:update(dt)

	--###
	if self.attVeh ~= nil and self.doLoadCheck > self.time then
		while self.attVeh.attacherVehicle ~= nil do
			self.attVeh = self.attVeh.attacherVehicle;
		end;
	end;

	--###
	for i,ref in pairs(self.hoseRef.refs) do
		if ref.hoseToLoad ~= nil then
			ref.hose = networkGetObject(ref.hoseToLoad);
			ref.hoseToLoad = nil;
		end;
	end;

	local act = true;
	if self.isTrailer then
		act = self.attacherVehicleSteer ~= nil and self.attacherVehicleSteer.isMotorStarted;
	else
		act = self.isMotorStarted;
	end

	if self.isClient and self:getIsActiveForInput(true) and not self:hasInputConflictWithSelection() then
		if self.conToFillable then
			if InputBinding.hasEvent(InputBinding.HOSEREF_FILL) then
				if self.attacherVehicleCopy ~= nil then
					self.attacherVehicleSteer = self.attacherVehicleCopy;
					while self.attacherVehicleSteer.attacherVehicle ~= nil do
						self.attacherVehicleSteer = self.attacherVehicleSteer.attacherVehicle;
					end;
				end;
				if self.attacherVehicleSteer ~= nil and self.attacherVehicleSteer.isMotorStarted then
					if self.pumpDir ~= 1 then
						self:setPumpDir(1);
					else
						self:setPumpDir(0);
					end;
				end;
			elseif InputBinding.hasEvent(InputBinding.HOSEREF_EMPTY) then
				if self.attacherVehicleCopy ~= nil then
					self.attacherVehicleSteer = self.attacherVehicleCopy;
					while self.attacherVehicleSteer.attacherVehicle ~= nil do
						self.attacherVehicleSteer = self.attacherVehicleSteer.attacherVehicle;
					end;
				end;
				if self.attacherVehicleSteer ~= nil and self.attacherVehicleSteer.isMotorStarted then
					if self.pumpDir ~= -1 then
						self:setPumpDir(-1);
					else
						self:setPumpDir(0);
					end;
				end;
			end;
		end;
	end;

	if self.pumpDir ~= 0 then
		if self.attVeh == nil then
			self:setPumpDir(0);
		else
			if not self.attVeh.isMotorStarted then
				self:setPumpDir(0);
			end;
		end;
	end;

	--###
    if self.hasPump and self.hoseRef.odc.trigger ~= nil then
		if self.hoseRef.odc.pit then
			if self.conToFillable then
				g_currentMission:addHelpButtonText(g_i18n:getText("HOSEREF_FILL"), InputBinding.HOSEREF_FILL);
				g_currentMission:addHelpButtonText(g_i18n:getText("HOSEREF_EMPTY"), InputBinding.HOSEREF_EMPTY);
				if InputBinding.hasEvent(InputBinding.HOSEREF_FILL) then
					if self.pumpDir ~= 1 then
						self:setPumpDir(1);
					else
						self:setPumpDir(0);
					end;
				elseif InputBinding.hasEvent(InputBinding.HOSEREF_EMPTY) then
					if self.pumpDir ~= -1 then
						self:setPumpDir(-1);
					else
						self:setPumpDir(0);
					end;
				end;
			end;
		end;
	end;


end;

function HoseRef:updateTick(dt)

	--#
	if self.attacherVehicleCopy ~= nil then
		self.attacherVehicleSteer = self.attacherVehicleCopy;
		while self.attacherVehicleSteer.attacherVehicle ~= nil do
			self.attacherVehicleSteer = self.attacherVehicleSteer.attacherVehicle;
		end;
	end;

	--###
	for i,ref in pairs(self.hoseRef.refs) do
		if ref.anim ~= nil then
			if ref.anim.charset ~= nil then
				local ct = getAnimTrackTime(ref.anim.charset, 0);
				if ct < 0 then
					setAnimTrackTime(ref.anim.charset, 0, 0, true);
					disableAnimTrack(ref.anim.charset, 0);
				elseif ct > ref.anim.duration then
					setAnimTrackTime(ref.anim.charset, 0, ref.anim.duration, true);
					disableAnimTrack(ref.anim.charset, 0);
				end
			end;
		end
		if ref.animOpen ~= nil then
			if ref.animOpen.charset ~= nil then
				local ct = getAnimTrackTime(ref.animOpen.charset, 0);
				if ct < 0 then
					setAnimTrackTime(ref.animOpen.charset, 0, 0, true);
					disableAnimTrack(ref.animOpen.charset, 0);
				elseif ct > ref.animOpen.duration then
					setAnimTrackTime(ref.animOpen.charset, 0, ref.animOpen.duration, true);
					disableAnimTrack(ref.animOpen.charset, 0);
				end
			end;
		end
	end

	--###
	if self.hasPump then

		self.conToFillable = false;

		local sId;
		local sId2;
		local refId;
		--print("--------------------------- " .. tostring(self));
		for i,ref in pairs(self.hoseRef.refs) do
			--print("ref.isUsed="..tostring(ref.isUsed).."  ref.hose="..tostring(ref.hose));
			if ref.isUsed and ref.hose ~= 0 and string.match( ref.rt, 'conn' ) then
				if ref.hose.ctors[1].isAttached and ref.hose.ctors[2].isAttached then
					if ref.hose.ctors[1].veh == self then
						sId = 1;
						sId2 = 2;
						refId = i;
						break;
					elseif ref.hose.ctors[2].veh == self then
						sId = 2;
						sId2 = 1;
						refId = i;
						break;
					end;
				end;
			end;
		end;
		--print("sId = " ..tostring(sId).." <-?! ");

		if sId ~= nil then
			local veh2;
			veh2 = self.hoseRef.refs[refId].hose.ctors[sId2].veh;
			if veh2 ~= nil then
				if veh2 ~= 0 then
					if not SpecializationUtil.hasSpecialization(Fillable, veh2.specializations) then
						veh2 = 0;
					end;
				end
			end;

			local pa = true;
			if veh2 ~= nil then
				if veh2 ~= 0 then
					if veh2.hoseRef ~= nil then
						if veh2.hasPump == true then
							if veh2.pumpDir ~= 0 then
								pa = false;
							end;
						end;
					end;
				end;
			end;
			--print("pa="..tostring(pa));
			local isTrigger = false;
			if veh2 ~= 0 then
				self.conToFillable = pa;
			else
				--check station
				if self.hoseRef.refs[refId].hose.ctors[sId2].station ~= nil and self.hoseRef.refs[refId].hose.ctors[sId2].station ~= 0 then
					if self.hoseRef.refs[refId].hose.ctors[sId2].station.manureTriggerRef ~= nil then
						self.conToFillable = true;
						veh2 = self.hoseRef.refs[refId].hose.ctors[sId2].station.manureTriggerRef;
						isTrigger = true;
					end;
				end;
			end;

			if (veh2 == nil or veh2 == 0) and self.pumpDir ~= 0 then
				self:setPumpDir(0);
				--print("!! STOP_PUMP (ZU)HoseRef:updateTick() veh2="..tostring(veh2));
				return;
			end;

			if self.pumpDir ~= 0 and self.isServer then
				local delta = dt*self.pumpSpeed;
				local fillType = Fillable.FILLTYPE_LIQUIDMANURE;
				if self.pumpDir == -1 then
					delta = dt*self.emptySpeed;
					delta = -math.min(delta, math.min(veh2.capacity-veh2.fillLevel, self.fillLevel));
					--fillType = self.currentFillType;
				else
					delta = dt*self.fillSpeed;
					delta = math.min(delta, math.min(veh2.fillLevel, self.capacity-self.fillLevel));
					--fillType = veh2.currentFillType;
				end;
				--print("delta="..tostring(delta).." fillType="..tostring(fillType).." self.fillLevel="..tostring(self.fillLevel).." veh2.fillLevel="..tostring(veh2.fillLevel));
				if delta == 0 then
					self:setPumpDir(0);
					--print("!! STOP_PUMP (ZU)HoseRef:updateTick() delta="..tostring(delta));
				end;
				self:setFillLevel( self.fillLevel+delta, fillType );
				if isTrigger then
					veh2:setFillLevel( veh2.fillLevel-delta );
				else
					veh2:setFillLevel( veh2.fillLevel-delta, fillType );
				end;
			end;

		elseif self.pumpDir ~= 0 then
			--for i,ref in pairs(self.hoseRef.refs) do
			--	if ref.hose ~= 0 then
			--		print(i.."   ref.hose.ctors[1].isAttached = "..tostring(ref.hose.ctors[1].isAttached));
			--		print(i.."   ref.hose.ctors[2].isAttached = "..tostring(ref.hose.ctors[2].isAttached));
			--		print(i.."   ref.hose.ctors[1].station = "..tostring(ref.hose.ctors[1].station));
			--		print(i.."   ref.hose.ctors[2].station = "..tostring(ref.hose.ctors[2].station));
			--		print(i.."   ref.hose.ctors[1].veh = "..tostring(ref.hose.ctors[1].veh));
			--		print(i.."   ref.hose.ctors[2].veh = "..tostring(ref.hose.ctors[2].veh));
			--		print(i.."   self = "..tostring(self));
			--	end;
			--end;
			self:setPumpDir(0);
		end

	end;


	--### moved to zunhammer18500.lua
	--if self.pumpDir ~= 0 then
	--	self:setVehicleIncreaseRpm(dt, 800, true);
	--else
	--	self:setVehicleIncreaseRpm(dt, 0, false);
	--end

	-- MoreRealistic pump power consumption [Jakob Tischler, 26 Jul 2014]
	if self.isServer and self.realFillingPowerConsumption and self.realFillingPowerConsumption > 0 and self.attacherVehicle and not self.isSprayerFilling and self.pumpDir ~= 0 then
		self.realCurrentPowerConsumption = self.realCurrentPowerConsumption + self.realFillingPowerConsumption;
	end;
end;

function HoseRef:draw()
	if self.hasPump and not self:hasInputConflictWithSelection() then
		if self.attacherVehicleSteer ~= nil and self.attacherVehicleSteer.isMotorStarted then
			if self.conToFillable then
				g_currentMission:addHelpButtonText(g_i18n:getText("HOSEREF_FILL"), InputBinding.HOSEREF_FILL);
				g_currentMission:addHelpButtonText(g_i18n:getText("HOSEREF_EMPTY"), InputBinding.HOSEREF_EMPTY);
			end;
		end;
	end;
end;


function HoseRef:onAttach(attacherVehicle)
	self.attVeh = attacherVehicle;
	while self.attVeh.attacherVehicle ~= nil do
		self.attVeh = self.attVeh.attacherVehicle;
	end;
	if self.attVeh.motor ~= nil then
		self.saveMinimumRpm = self.attVeh.motor.minRpm;
		self.attacherVehicleMinRpm = self.attVeh.motor.minRpm;
	else
		if self.attVeh.saveMinRpm ~= nil then
			self.saveMinimumRpm = self.attVeh.saveMinimumRpm;
		else
			self.attVeh.saveMinimumRpm  = 100;
		end;
	end;
	self.attacherVehicleSteer = attacherVehicle;
	while self.attacherVehicleSteer.attacherVehicle ~= nil do
		self.attacherVehicleSteer = self.attacherVehicleSteer.attacherVehicle;
	end;
end;

function HoseRef:onDetach()
	for k, steerable in pairs(g_currentMission.steerables) do
		if self.attVeh == steerable then
			steerable.motor.minRpm = self.saveMinimumRpm;
			if steerable.motor.rpmIncByImplement ~= nil then
				if steerable.motor.rpmIncByImplement[self] ~= nil then
					steerable.motor.rpmIncByImplement[self] = 0;
				end;
			end;
		end;
	end;
	self.attVeh = nil;
	self.attacherVehicleSteer = nil;
end;

function HoseRef:updateMesh()
end;

--###
function HoseRef:setRefState(refId, state, hose, noEventSend)
--print("function HoseRef:setRefState("..tostring(refId)..", "..tostring(state)..", "..tostring(noEventSend));
	SetRefStateEvent.sendEvent(self, refId, state, hose, noEventSend);
	if self.hoseRef.refs[refId] ~= nil then
		self.hoseRef.refs[refId].isUsed = state;
		self.hoseRef.refs[refId].hose = hose;
		if self.hoseRef.refs[refId].anim ~= nil then
			if self.hoseRef.refs[refId].anim.charset ~= nil then
				--print("play anim!");
				enableAnimTrack(self.hoseRef.refs[refId].anim.charset, 0);
				if state then
					setAnimTrackSpeedScale(self.hoseRef.refs[refId].anim.charset, 0, -2);
				else
					setAnimTrackSpeedScale(self.hoseRef.refs[refId].anim.charset, 0, 2);
				end;
			end;
		end;
		if self.hoseRef.refs[refId].animOpen ~= nil then
			if self.hoseRef.refs[refId].animOpen.charset ~= nil then
				--print("play animOpen!");
				enableAnimTrack(self.hoseRef.refs[refId].animOpen.charset, 0);
				if state then
					setAnimTrackSpeedScale(self.hoseRef.refs[refId].animOpen.charset, 0, 1);
				else
					setAnimTrackSpeedScale(self.hoseRef.refs[refId].animOpen.charset, 0, -1);
				end;
			end;
		end;
	end;

end;


--###
function HoseRef:setPumpDir(dir, noEventSend)
--print("function HoseRef:setPumpDir("..tostring(dir)..", "..tostring(noEventSend));
	SetPumpDirEvent.sendEvent(self, dir, noEventSend);
	self.pumpDir = dir;

	if self.hoseRef.odc.trigger ~= nil then
		if self.hoseRef.odc.enable ~= nil and self.hoseRef.odc.dir ~= nil then

			if dir ~= 0 then
				setRotation(self.hoseRef.odc.enable.node, self.hoseRef.odc.enable.rMax[1], self.hoseRef.odc.enable.rMax[2], self.hoseRef.odc.enable.rMax[3]);
			else
				setRotation(self.hoseRef.odc.enable.node, self.hoseRef.odc.enable.rMin[1], self.hoseRef.odc.enable.rMin[2], self.hoseRef.odc.enable.rMin[3]);
			end;

			if dir == -1 then
				setRotation(self.hoseRef.odc.dir.node, self.hoseRef.odc.dir.rMax[1], self.hoseRef.odc.dir.rMax[2], self.hoseRef.odc.dir.rMax[3]);
			elseif dir == 1 then
				setRotation(self.hoseRef.odc.dir.node, self.hoseRef.odc.dir.rMin[1], self.hoseRef.odc.dir.rMin[2], self.hoseRef.odc.dir.rMin[3]);
			elseif dir == 0 then
				setRotation(self.hoseRef.odc.dir.node, self.hoseRef.odc.dir.rNeut[1], self.hoseRef.odc.dir.rNeut[2], self.hoseRef.odc.dir.rNeut[3]);
			end;

		end;
	end;

	-- and re-check for attacherVehicle due to 'trailer in between'-situation
	self.attVeh = self.attacherVehicleSteer;
	while self.attVeh.attacherVehicle ~= nil do
		self.attVeh = self.attVeh.attacherVehicle;
	end;
	--[[
	if self.attVeh.motor ~= nil then
		self.saveMinimumRpm = self.attVeh.motor.minRpm;
		self.attacherVehicleMinRpm = self.attVeh.motor.minRpm;
	else
		if self.attVeh.saveMinRpm ~= nil then
			self.saveMinimumRpm = self.attVeh.saveMinimumRpm;
		else
			self.attVeh.saveMinimumRpm  = 100;
		end;
	end;
	]]--

end;


--###
function HoseRef:playerCallback(triggerId, otherId, onEnter, onLeave, onStay)
--print("function HoseRef:playerCallback("..tostring(triggerId)..", "..tostring(otherId)..", "..tostring(onEnter)..", "..tostring(onLeave)..", "..tostring(onStay));
--print("g_currentMission.controlPlayer="..tostring(g_currentMission.controlPlayer));
--print("g_currentMission.player="..tostring(g_currentMission.player));
--print("g_currentMission.player.rootNode="..tostring(g_currentMission.player.rootNode));

	if onEnter and g_currentMission.controlPlayer and g_currentMission.player ~= nil and otherId == g_currentMission.player.rootNode then
		self.hoseRef.odc.pit = true;
	elseif onLeave then
		self.hoseRef.odc.pit = false;
	end;
end;

--###
function HoseRef:setVehicleIncreaseRpm(dt, increase, isActive)
--print("function HoseRef:setVehicleIncreaseRpm("..tostring(dt)..", "..tostring(increase)..", "..tostring(isActive));

	if self.attVeh ~= nil and self.saveMinimumRpm ~= 0 and self.attVeh.motor ~= nil then

		if dt ~= nil then
			if isActive == true then
				--self.attacherVehicle.motor.minRpm = math.max(self.attacherVehicle.motor.minRpm-(dt*2), -increase);
				self.attacherVehicleMinRpm = math.max(self.attacherVehicleMinRpm-(dt*2), -increase);
			else
				--self.attacherVehicle.motor.minRpm = math.min(self.attacherVehicle.motor.minRpm+(dt*5), self.saveMinimumRpm);
				self.attacherVehicleMinRpm = math.min(self.attacherVehicleMinRpm+(dt*4), self.saveMinimumRpm);
			end;
		else
			--self.attacherVehicle.motor.minRpm = self.saveMinimumRpm;
			self.attacherVehicleMinRpm = self.saveMinimumRpm;
		end;
		self.attVeh.motor.minRpm = self.attacherVehicleMinRpm;
		--print("self.attacherVehicle.motor.minRpm="..tostring(self.attacherVehicle.motor.minRpm));

		if self.attVeh.motor.rpmIncByImplement == nil then
			self.attVeh.motor.rpmIncByImplement = {};
			self.attVeh.motor.rpmIncByImplement[self] = 2*math.abs(self.attVeh.motor.minRpm);
		else
			self.attVeh.motor.rpmIncByImplement[self] = 2*math.abs(self.attVeh.motor.minRpm);
		end;

		if self.attVeh.isMotorStarted then
			local fuelUsed = 0.0000012*math.abs(self.attVeh.motor.minRpm);
			self.attVeh:setFuelFillLevel(self.attVeh.fuelFillLevel-fuelUsed);
			g_currentMission.missionStats.fuelUsageTotal = g_currentMission.missionStats.fuelUsageTotal + fuelUsed;
			g_currentMission.missionStats.fuelUsageSession = g_currentMission.missionStats.fuelUsageSession + fuelUsed;
		end;
	end;
end;

--
--
--
--
--
SetRefStateEvent = {};
SetRefStateEvent_mt = Class(SetRefStateEvent, Event);

InitEventClass(SetRefStateEvent, "SetRefStateEvent");

function SetRefStateEvent:emptyNew()
    local self = Event:new(SetRefStateEvent_mt);
    self.className="SetRefStateEvent";
    return self;
end;

function SetRefStateEvent:new(vehicle, refId, state, hose)
    local self = SetRefStateEvent:emptyNew()
    self.vehicle = vehicle;
	self.refId = refId;
	self.state = state;
	self.hose = hose;
	return self;
end;

function SetRefStateEvent:readStream(streamId, connection)
    local id = streamReadInt32(streamId);
    self.vehicle = networkGetObject(id);
	self.refId = streamReadInt8(streamId);
	self.state = streamReadBool(streamId);
    local id = streamReadInt32(streamId);
    self.hose = networkGetObject(id);
    self:run(connection);
end;

function SetRefStateEvent:writeStream(streamId, connection)
    streamWriteInt32(streamId, networkGetObjectId(self.vehicle));
	streamWriteInt8(streamId, self.refId);
	streamWriteBool(streamId, self.state);
	streamWriteInt32(streamId, networkGetObjectId(self.hose));
end;

function SetRefStateEvent:run(connection)
	self.vehicle:setRefState(self.refId, self.state, self.hose, true);
	if not connection:getIsServer() then
		g_server:broadcastEvent(SetRefStateEvent:new(self.vehicle, self.refId, self.state, self.hose), nil, connection, self.vehicle);
	end;
end;


function SetRefStateEvent.sendEvent(vehicle, refId, state, hose, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			g_server:broadcastEvent(SetRefStateEvent:new(vehicle, refId, state, hose), nil, nil, vehicle);
		else
			g_client:getServerConnection():sendEvent(SetRefStateEvent:new(vehicle, refId, state, hose));
		end;
	end;
end;

--
--
--
--
--
SetPumpDirEvent = {};
SetPumpDirEvent_mt = Class(SetPumpDirEvent, Event);

InitEventClass(SetPumpDirEvent, "SetPumpDirEvent");

function SetPumpDirEvent:emptyNew()
    local self = Event:new(SetPumpDirEvent_mt);
    self.className="SetPumpDirEvent";
    return self;
end;

function SetPumpDirEvent:new(vehicle, state)
    local self = SetPumpDirEvent:emptyNew()
    self.vehicle = vehicle;
	self.state = state;
	return self;
end;

function SetPumpDirEvent:readStream(streamId, connection)
    local id = streamReadInt32(streamId);
    self.vehicle = networkGetObject(id);
	self.state = streamReadInt32(streamId);
    self:run(connection);
end;

function SetPumpDirEvent:writeStream(streamId, connection)
    streamWriteInt32(streamId, networkGetObjectId(self.vehicle));
	streamWriteInt32(streamId, self.state);
end;

function SetPumpDirEvent:run(connection)
	self.vehicle:setPumpDir(self.state, true);
	if not connection:getIsServer() then
		g_server:broadcastEvent(SetPumpDirEvent:new(self.vehicle, self.state), nil, connection, self.vehicle);
	end;
end;


function SetPumpDirEvent.sendEvent(vehicle, state, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			g_server:broadcastEvent(SetPumpDirEvent:new(vehicle, state), nil, nil, vehicle);
		else
			g_client:getServerConnection():sendEvent(SetPumpDirEvent:new(vehicle, state));
		end;
	end;
end;