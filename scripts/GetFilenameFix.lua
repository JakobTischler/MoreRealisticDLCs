--
-- Fix to use $pdlcdir$ in filenames of vehicle xml's
--
-- @author  Stefan Geiger
-- @date  28/04/14


-- Only apply this fix once, even if present in multiple mods. Use some variable, that is very unlikely to be used by any other script
if not Utils.unique198008912_getFilenameFixed then
    Utils.unique198008912_getFilenameFixed = true;

    local getFilenameOld = Utils.getFilename;

    function Utils.getFilename(filename, baseDir)
        if filename:sub(1,9) == "$pdlcdir$" or filename:sub(1,8) == "$moddir$" then
            return Utils.convertFromNetworkFilename(filename), true
        end
        return getFilenameOld(filename, baseDir);
    end;
end