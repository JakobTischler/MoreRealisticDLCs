local modDir, modName = g_currentModDirectory, g_currentModName;

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

local minVersionMr	  = '1.3.42';
local minVersionMrVeh = '1.3.7';
function MoreRealisticDLCs:assertMrVersions()
	-- ABORT IF MOREREALISTIC NOT INSTALLED
	if not RealisticUtils then
		print(('%s: you don\'t have MoreRealistic installed. Script will now be aborted!'):format(modName));
		return false;
	end;

	-- ABORT IF FAULTY OR TOO LOW MOREREALISTIC VERSION NUMBER
	local mrVersionStr, mrVersionFlt = self:getModVersion(RealisticUtils.modName);
	if mrVersionFlt == 0 then
		print(('%s: no correct version could be found for "MoreRealistic". Script will now be aborted!'):format(modName));
		return false;
	elseif mrVersionFlt < self:getFloatNumberFromString(minVersionMr) then
		print(('%s: your MoreRealistic version (v%s) is too outdated. Update to v%s or higher. Script will now be aborted!'):format(modName, mrVersionStr, minVersionMr));
		return false;
	else
		print(('%s: MoreRealistic v%s installed, minimum version requirement met --> OK'):format(modName, mrVersionStr));
	end;

	-- ABORT IF FAULTY OR TOO LOW MOREREALISTICVEHICLES VERSION NUMBER
	self.mrVehiclesPackInstalled = ModsUtil.findModItemByModName('moreRealisticVehicles') ~= nil;
	if self.mrVehiclesPackInstalled then
		local mrVehVersionStr, mrVehVersionFlt = self:getModVersion('moreRealisticVehicles');
		if mrVehVersionFlt == 0 then
			print(('%s: no correct version could be found for "MoreRealisticVehicles". Script will now be aborted!'):format(modName));
			return false;
		elseif mrVehVersionFlt < self:getFloatNumberFromString(minVersionMrVeh) then
			print(('%s: your MoreRealisticVehicles version (v%s) is too outdated. Update to v%s or higher. Script will now be aborted!'):format(modName, mrVehVersionStr, minVersionMrVeh));
			return false;
		else
			print(('%s: MoreRealisticVehicles v%s installed, minimum version requirement met --> OK'):format(modName, mrVehVersionStr));
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
if g_languageShort and numberSeparators[g_languageShort] then
	numberSeparator		   = numberSeparators[g_languageShort][1];
	numberDecimalSeparator = numberSeparators[g_languageShort][2];
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
			if self.isOpen and self.selectedStoreItem and self.selectedStoreItem.nameMRized then
				shopBanner:render();
			end;
		end;
		g_shopScreen.draw = Utils.prependedFunction(g_shopScreen.draw, drawShopBanner);
	end;
end;
