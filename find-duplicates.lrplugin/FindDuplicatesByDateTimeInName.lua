--[[----------------------------------------------------------------------------

 Find Duplicates By Date/Time In Name
 Copyright 2019 Tapani Otala

--------------------------------------------------------------------------------

FindDuplicatesByDateTimeInName.lua

------------------------------------------------------------------------------]]

require "FindDuplicates.lua"

FindDuplicatesEngine(
	function( photo )
		local fileName = photo:getFormattedMetadata( "fileName" )
		if photo:getRawMetadata( "isVirtualCopy" ) then
			return fileName, nil, nil
		end

		local fileNameBase = fileName:sub( 1, 8 + 1 + 6 )
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
