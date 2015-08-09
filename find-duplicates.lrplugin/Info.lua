--[[----------------------------------------------------------------------------

 Find Duplicates
 Copyright 2015 Tapani Otala

--------------------------------------------------------------------------------

Info.lua
Summary information for the plug-in.

Adds menu items to Lightroom.

------------------------------------------------------------------------------]]

return {
	
	LrSdkVersion = 5.0,
	LrSdkMinimumVersion = 5.0, -- minimum SDK version required by this plug-in

	LrToolkitIdentifier = "com.tjotala.lightroom.find-duplicates",

	LrPluginName = LOC "$$$/FindDuplicates/PluginName=Find Duplicates",
	
	-- Add the menu item to the File menu.
	
	LrExportMenuItems = {
	    {
		    title = LOC "$$$/FindDuplicates/LibraryMenuItem=Find Duplicates",
		    file = "FindDuplicatesMenuItem.lua",
		},
	},

	-- Add the menu item to the Library menu.
	
	LrLibraryMenuItems = {
	    {
		    title = LOC "$$$/FindDuplicates/LibraryMenuItem=Find Duplicates",
		    file = "FindDuplicatesMenuItem.lua",
		},
	},

	VERSION = { major=1, minor=0, revision=0, build=1, },

}


	