--[[----------------------------------------------------------------------------

 Find Duplicates
 Copyright 2015 Tapani Otala

--------------------------------------------------------------------------------

FindDuplicates.lua

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
			collection = catalog:createCollection( LOC( "$$$/FindDuplicates/CollectionName=Found Duplicates" ), nil, true )
			collection:removeAllPhotos()
		end
	)
	return collection
end

function FindDuplicatesEngine( getSearchCriteria )
	LrTasks.startAsyncTask(
		function( )
			trace( "FindDuplicatesEngine enter" )
			local catalog = LrApplication.activeCatalog()
			local collection = getTargetCollection( catalog )

			catalog:withWriteAccessDo( LOC( "$$$/FindDuplicates/ActionName=Find Duplicates" ),
				function( context )
					local progressScope = LrProgressScope {
						title = LOC( "$$$/FindDuplicates/ProgressScopeTitle=Finding Duplicates" ),
						functionContext = context,
					}
					progressScope:setCancelable( true )

					-- Enumerate through all selected photos in the catalog, searching for other photos with matching names
					local photos = catalog:getTargetPhotos()
					trace( "searching %d photos", #photos )
					for i, photo in ipairs(photos) do
						if progressScope:isCanceled() then
							trace( "operation canceled" )
							break
						end

						-- Update the progress bar
						local fileName, label, criteria = getSearchCriteria( photo )
						progressScope:setCaption( LOC( "$$$/FindDuplicates/ProgressCaption=^1 (^2 of ^3)", fileName, i, #photos ) )
						progressScope:setPortionComplete( i, #photos )

						if criteria then
							trace( "find %d of %d '%s' by '%s'", i, #photos, fileName, label )

							-- Find all the dupes of this photo
							local foundPhotos = catalog:findPhotos {
								sort = "fileName",
								ascending = true,
								searchDesc = criteria,
							}

							if #foundPhotos > 1 then
								trace( "found %d matches of %s", #foundPhotos, fileName )
								for i, found in ipairs(foundPhotos) do
									if progressScope:isCanceled() then
										trace( "operation canceled" )
										break
									end
									trace( "  matched %s", found:getRawMetadata( "path" ) )
								end
								if not progressScope:isCanceled() then
									collection:addPhotos( foundPhotos )
								end
							end

						end

						if i % 10 == 0 then
							LrTasks.yield()
						end
					end

					progressScope:done()
					catalog:setActiveSources { collection }
				end
			)
			trace( "FindDuplicatesEngine exit" )
		end
	)
end
