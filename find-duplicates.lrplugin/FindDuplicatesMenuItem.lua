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

local function findDuplicates()

	trace( "findDuplicates: enter" )

	LrTasks.startAsyncTask(
		function( )
			local catalog = LrApplication.activeCatalog()
			local collection = nil
			catalog:withWriteAccessDo( LOC "$$$/FindDuplicates/ActionName=Find Duplicates",
				function( context )
					-- Create the target collection, if it doesn't already exist
					collection = catalog:createCollection( LOC "$$$/FindDuplicates/CollectionName=Found Duplicates", nil, true )
				end
			)

			if collection == nil then
				return
			end

			catalog:withWriteAccessDo( LOC "$$$/FindDuplicates/ActionName=Find Duplicates",
				function( context )
					local progressScope = LrProgressScope {
						title = LOC "$$$/FindDuplicates/ProgressScopeTitle=Finding Duplicates",
						functionContext = context,
					}
					progressScope:setCancelable( true )

					-- Clear the collection first
					collection:removeAllPhotos()

					-- Enumerate through all selected photos in the catalog, searching for other photos with matching names
					local photos = catalog:getTargetPhotos()
					trace( "searching %d photos", #photos )
					for i, photo in ipairs(photos) do
						if progressScope:isCanceled() then
							break
						end

						-- Update the progress bar
						local fileName = photo:getFormattedMetadata( "fileName" )
						progressScope:setCaption( fileName )
						progressScope:setPortionComplete( i, #photos )

						trace( "photo %d of %d: %s", i, #photos, fileName )

						-- Find all the dupes of this photo
						local foundPhotos = catalog:findPhotos {
							searchDesc = {
								criteria = "filename",
								operation = "==",
								value = fileName,
							}
						}

						if #foundPhotos > 1 then
							trace( "found %d matching photos", #foundPhotos )
							collection:addPhotos( foundPhotos )
						end

						LrTasks.yield()
					end

					progressScope:done()
					catalog:setActiveSources { collection }

				end
			)
		end
	)
	trace( "findDuplicates: exit" )
	
end

--------------------------------------------------------------------------------
-- Begin the search
findDuplicates()


