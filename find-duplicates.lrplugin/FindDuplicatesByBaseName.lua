--[[----------------------------------------------------------------------------

 Find Duplicates By Base Name
 Copyright 2019 Tapani Otala

--------------------------------------------------------------------------------

FindDuplicatesByBaseName.lua

------------------------------------------------------------------------------]]

local LrPathUtils = import "LrPathUtils"

require "FindDuplicates.lua"

FindDuplicatesEngine(
	function( photo )
		local fileName = photo:getFormattedMetadata( "fileName" )
		if photo:getRawMetadata( "isVirtualCopy" ) then
			return fileName, nil, nil
		end

		local fileNameBase = LrPathUtils.removeExtension( fileName )
		local criteria = {
			combine = "intersect",
			{
				criteria = "filename",
				operation = "beginsWith",
				value = fileNameBase,
			},
			{
				criteria = "pick",
				operation = "!=",
				value = -1,
			},
		}
		return fileName, fileNameBase, criteria
	end
)
