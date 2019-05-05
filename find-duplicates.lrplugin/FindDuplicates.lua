--[[----------------------------------------------------------------------------

 Find Duplicates
 Copyright 2015 Tapani Otala

--------------------------------------------------------------------------------

FindDuplicatesMenuItem.lua

------------------------------------------------------------------------------]]

-- Access the Lightroom SDK namespaces.
local LrLogger = import "LrLogger"
local LrApplication = import "LrApplication"
local LrTasks = import "LrTasks"
local LrProgressScope = import "LrProgressScope"

-- Create the logger and enable the print function.
local myLogger = LrLogger( "com.tjotala.lightroom.find-duplicates" )
myLogger:enable( "logfile" ) -- Pass either a string or a table of actions.

--------------------------------------------------------------------------------
-- Write trace information to the logger.

local function trace( message, ... )
	myLogger:tracef( message, unpack( arg ) )
end

--------------------------------------------------------------------------------
-- Launch a background task to go find all duplicates in the active catalog
-- The duplicates are added to a collection named "Found Duplicates"

local function getTargetCollection( catalog )
	local collection = nil
	catalog:withWriteAccessDo( LOC( "$$$/FindDuplicates/GetTargetCollection=Creating Target Collection" ),
		function( context )
			-- Create the target collection, if it doesn't already exist
			collection = catalog:createCollection( LOC( "$$$/FindDuplicates/CollectionName=Found Duplicates by Name" ), nil, true )

			-- Clear the collection, if it isn't empty already
			collection:removeAllPhotos()
		end
	)

	return collection
end

local function findDuplicates()
	LrTasks.startAsyncTask(
		function( )
			trace( "findDuplicates: enter" )
			local catalog = LrApplication.activeCatalog()
			local collection = getTargetCollection(catalog)

			catalog:withWriteAccessDo( LOC( "$$$/FindDuplicates/ActionName=Find Duplicates by Name" ),
				function( context )
					local progressScope = LrProgressScope {
						title = LOC( "$$$/FindDuplicates/ProgressScopeTitle=Finding Duplicates by Name" ),
						functionContext = context,
					}
					progressScope:setCancelable( true )

					-- Enumerate through all selected photos in the catalog, searching for other photos with matching names
					local photos = catalog:getTargetPhotos()
					trace( "searching %d photos", #photos )
					for i, photo in ipairs(photos) do
						if progressScope:isCanceled() then
							break
						end

						if not photo:getRawMetadata( "isVirtualCopy" ) then
							-- Update the progress bar
							local fileName = photo:getFormattedMetadata( "fileName" )
							progressScope:setCaption( LOC( "$$$/FindDuplicates/ProgressCaption=^1 (^2 of ^3)", fileName, i, #photos ) )
							progressScope:setPortionComplete( i, #photos )

							trace( "photo %d of %d: %s", i, #photos, fileName )

							-- Find all the dupes of this photo
							local foundPhotos = catalog:findPhotos {
								ascending = true,
								searchDesc = {
									criteria = "filename",
									operation = "all",
									value = fileName
								}
							}

							if #foundPhotos > 1 then
								trace( "found %d matching photos of %s", #foundPhotos, fileName )
								for i, found in ipairs(foundPhotos) do
									trace( "  matched: %s from %s", found:getFormattedMetadata( "fileName" ), found:getFormattedMetadata( "folderName" ) )
								end
								collection:addPhotos( foundPhotos )
							end

						end

						LrTasks.yield()
					end

					progressScope:done()
					catalog:setActiveSources { collection }
				end
			)
			trace( "findDuplicates: exit" )
		end
	)
end

--------------------------------------------------------------------------------
-- Begin the search
findDuplicates()
