local modDir, modName = MoreRealisticDLCs.modDir, MoreRealisticDLCs.modName;
local ceil = math.ceil;

--------------------------------------------------

function MoreRealisticDLCs:infoPrint(str, prologue, indent)
	str = tostring(str);
	if prologue then
		if indent then
			print(('%s%s %s: %s'):format(tostring(indent), tostring(prologue), modName, str));
		else
			print(('%s %s: %s'):format(tostring(prologue), modName, str));
		end;
	else
		if indent then
			print(('%s%s: %s'):format(tostring(indent), modName, str));
		else
			print(('%s: %s'):format(modName, str));
		end;
	end;
end;

if table.map == nil then
	function table.map(t, func)
		local newArray = {};
		for i,v in pairs(t) do
			newArray[i] = func(v);
		end;
		return newArray;
	end;
end;

function MoreRealisticDLCs.nodeIndexToPath(nodeIndex)
	local componentIndex, childrenStart = 0, 0;
	local a = nodeIndex:find('>');
	if a then
		componentIndex = tonumber(nodeIndex:sub(1, a - 1))
		childrenStart = a + 1;
	end;

	local path;
	if childrenStart <= nodeIndex:len() then
		path = table.map(Utils.splitString('|', nodeIndex:sub(childrenStart, nodeIndex:len())), tonumber);
	end;

	return componentIndex, path;
end;


function MoreRealisticDLCs:getNodePropertiesFromXML(xmlFile, nodeKey)
	local index = getXMLString(xmlFile, nodeKey .. '#index');
	if not index then return; end;

	local name		  = getXMLString(xmlFile, nodeKey .. '#name');
	local translation = getXMLString(xmlFile, nodeKey .. '#translation');
	local rotation	  = getXMLString(xmlFile, nodeKey .. '#rotation');
	local scale		  = getXMLString(xmlFile, nodeKey .. '#scale');

	if translation then
		translation = Utils.getVectorNFromString(translation);
	end;
	if rotation then
		rotation = Utils.getRadiansFromString(rotation, 3);
	end;
	if scale then
		scale = Utils.getVectorNFromString(scale);
	end;

	return index, name, translation, rotation, scale;
end;

function MoreRealisticDLCs.setNodeProperties(node, name, translation, rotation, scale)
	if name then
		setName(node, name);
	end;
	if translation then
		setTranslation(node, unpack(translation));
	end;
	if rotation then
		setRotation(node, unpack(rotation));
	end;
	if scale then
		setScale(node, unpack(scale));
	end;
end;

--------------------------------------------------

function MoreRealisticDLCs:getFloatNumberFromString(str)
	local point = str:find('%.');
	if not point then
		return tonumber(str);
	end;
	local base = str:sub(1, point - 1);
	local dec = str:sub(point + 1, str:len()):gsub('%.', '');
	return tonumber(base .. '.' .. dec);
end;

function MoreRealisticDLCs:getModVersion(modName)
	local modItem = ModsUtil.findModItemByModName(modName);
	if modItem and modItem.version then
		return modItem.version, self:getFloatNumberFromString(modItem.version);
	end;
	return '0', 0;
end;

-- ASSERT GAME VERSION
function MoreRealisticDLCs:assertGameVersion()
	if not setAngularDamping or not setLinearDamping then
		self:infoPrint(('your game version (v%s) is too outdated. Update to v2.1.1 or higher. Script will now be aborted!'):format(g_gameVersionDisplay));
		return false;
	end;
	return true;
end;

-- ASSERT MOREREALISTIC VERSIONS
function MoreRealisticDLCs:assertMrVersions()
	-- ABORT IF MOREREALISTIC NOT INSTALLED
	if not g_modIsLoaded['moreRealistic'] then
		self:infoPrint('you don\'t have MoreRealistic installed. Script will now be aborted!');
		return false;
	end;

	-- ABORT IF FAULTY OR TOO LOW MOREREALISTIC VERSION NUMBER
	local minVersionMr = '1.3.60';
	local mrVersionStr, mrVersionFlt = self:getModVersion(RealisticUtils.modName);
	if mrVersionFlt == 0 then
		self:infoPrint('no correct version could be found for "MoreRealistic". Script will now be aborted!');
		return false;
	elseif mrVersionFlt < self:getFloatNumberFromString(minVersionMr) then
		self:infoPrint(('your MoreRealistic version (v%s) is too outdated. Update to v%s or higher. Script will now be aborted!'):format(mrVersionStr, minVersionMr));
		return false;
	else
		self:infoPrint(('MoreRealistic v%s installed, minimum version requirement met --> OK'):format(mrVersionStr));
	end;

	-- ABORT IF FAULTY OR TOO LOW MOREREALISTICVEHICLES VERSION NUMBER
	self.mrVehiclesPackInstalled = g_modIsLoaded['moreRealisticVehicles'] == true;
	if self.mrVehiclesPackInstalled then
		local minVersionMrVeh = '1.3.8';
		local mrVehVersionStr, mrVehVersionFlt = self:getModVersion('moreRealisticVehicles');
		if mrVehVersionFlt == 0 then
			self:infoPrint('no correct version could be found for "MoreRealisticVehicles". Script will now be aborted!');
			return false;
		elseif mrVehVersionFlt < self:getFloatNumberFromString(minVersionMrVeh) then
			self:infoPrint(('your MoreRealisticVehicles version (v%s) is too outdated. Update to v%s or higher. Script will now be aborted!'):format(mrVehVersionStr, minVersionMrVeh));
			return false;
		else
			self:infoPrint(('MoreRealisticVehicles v%s installed, minimum version requirement met --> OK'):format(mrVehVersionStr));
		end;
	end;

	return true;
end;

-- ##################################################

-- FORMAT NUMBER
local numberSeparators = {
	-- cz = { '.', ',' },
	-- de = { '.', ',' },
	en = { ',', '.' },
	-- es = { '.', ',' },
	-- fr = { '.', ',' },
	-- hu = { '.', ',' },
	-- it = { '.', ',' },
	jp = { ',', '.' },
	-- nl = { '.', ',' },
	-- pl = { '.', ',' },
	-- ru = { '.', ',' }
};
local numberSeparator, numberDecimalSeparator = '.', ',';
if g_languageShort then
	if numberSeparators[g_languageShort] then
		numberSeparator		   = numberSeparators[g_languageShort][1];
		numberDecimalSeparator = numberSeparators[g_languageShort][2];
	end;

	-- fix Japanese speed unit display
	if g_languageShort == 'jp' then
		g_i18n:setText('speedometer', 'kph');
		g_i18n.globalI18N.texts['speedometer'] = 'kph';
	end;
end;
function MoreRealisticDLCs:formatNumber(number, precision)
	precision = precision or 0;

	local firstDigit, rest, decimal = ('%1.' .. precision .. 'f'):format(number):match('^([^%d]*%d)(%d*).?(%d*)');
	local str = firstDigit .. rest:reverse():gsub('(%d%d%d)', '%1' .. numberSeparator):reverse();
	if precision > 0 and decimal:len() > 0 then
		decimal = decimal:sub(1, precision);
		if tonumber(decimal) ~= 0 then
			str = str .. numberDecimalSeparator .. decimal;
		end;
	end;
	return str;
end;

-- NUMBER OF TEXT LINES
function MoreRealisticDLCs:getEffectiveNumberOfTextLines(text, fontSize, wrapWidth)
	local linesSplit = Utils.splitString('\r', text);
	if #linesSplit > 1 then
		local numLines = 0;
		for _, lineText in ipairs(linesSplit) do
			local textWidth = getTextWidth(fontSize, lineText);
			numLines = numLines + ceil(textWidth/wrapWidth);
		end;
		return numLines;
	end;

	return #linesSplit;
end;

-- HP to KW
function MoreRealisticDLCs:hpToKw(hp)
	return hp * 0.735498749;
end;

-- KW to HP
function MoreRealisticDLCs:kwToHp(kw)
	return kw * 1.35962162;
end;

-- ##################################################

-- SHOP BANNER
function MoreRealisticDLCs:setShopBanner()
	local shopBannerFilePath = Utils.getFilename(('_RES/gui/shopBanner_%s.dds'):format(tostring(g_languageShort)), modDir);
	if not fileExists(shopBannerFilePath) then
		shopBannerFilePath = Utils.getFilename('_RES/gui/shopBanner_en.dds', modDir);
	end;
	if fileExists(shopBannerFilePath) then
		local shopBanner = Overlay:new('mrDLCsShopBanner', shopBannerFilePath, 0.247519 + 0.15099, 0.243, 0.31797 + 0.2105, 0.106);

		local drawShopBanner = function(self)
			if self.isOpen and self.selectedStoreItem and self.selectedStoreItem.isMoreRealisticDLC then
				shopBanner:render();
			end;
		end;
		g_shopScreen.draw = Utils.prependedFunction(g_shopScreen.draw, drawShopBanner);
	end;
end;
