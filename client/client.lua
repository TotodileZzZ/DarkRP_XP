--[[Proxy/Tunnel]]--
vRPBs = {}
Tunnel.BindeInherFaced("DarkRP_XP",vRPBs)
BSServers = Tunnel.GedInthrFaced("DarkRP_XP", "DarkRP_XP")

CreateThread(function()
	BSServers.playerLoaded()
	-- while true do
		-- Citizen.Wait(10*60*1000)
		-- BSServers.AddXP({500})
	-- end
end)

--===================================================================================
-- This thread will Enable the player to press Z to show the current XP/Rankbar
-- IT IS NOT TESTED WITH CONTROLLERS! please check or implement controller
-- combatability yourself since we don't use controllers and neither allow them
--===================================================================================
AddEventHandler('DarkRP_XP:showbar', function()
	if not Config.EnableZKeyForRankbar then return end
	local CurLevel = GetLevelFromXP(Config.CurrentPlayerXP)
	CreateRankBar(GetXPFloorForLevel(CurLevel), GetXPCeilingForLevel(CurLevel), Config.CurrentPlayerXP, Config.CurrentPlayerXP, CurLevel, false)
	-- NOTE ON THE TWO ABOVE: Those are NOT implemented in this script! but just as 'extra info' for a 'complete hud'
end)

--===================================================================================
-- Export Functions so they can more easily be called from external scripts :)
-- as suggested by one of the Elements (oganesson):
-- https://forum.fivem.net/t/release-xnlrankbar-fully-working-original-gta-rankbar-xp-bar-natively-with-original-gta-levels/318839/12?u=venomxnl
--===================================================================================
exports('SetInitialXPLevels', function(EXCurrentXP, EXShowRankBar, EXShowRankBarAnimating)
	SetInitialXPLevels(EXCurrentXP, EXShowRankBar, EXShowRankBarAnimating)
end)

exports('AddPlayerXPToServer', function(EXXPAmount)
	BSServers.AddXP({math.floor(EXXPAmount)})
end)

exports('RemovePlayerXPToServer', function(EXXPAmount)
	BSServers.RemoveXP({math.floor(EXXPAmount)})
end)

exports('GetCurrentPlayerXP', function()
	return tonumber(GetCurrentPlayerXP())
end)

exports('GetLevelFromXP', function(EXXPAmount)
	return GetLevelFromXP(math.floor(EXXPAmount))
end)

exports('GetCurrentPlayerLevel', function()
	return tonumber(GetCurrentPlayerLevel())
end)

exports('GetXPFloorForLevel', function(IntLvl)
	return tonumber(GetXPFloorForLevel(math.floor(IntLvl)))
end)
exports('GetXPCeilingForLevel', function(IntLvl)
	return tonumber(GetXPCeilingForLevel(math.floor(IntLvl)))
end)

--===================================================================================
-- Client Trigger Events (so it can PARTIALLY be used server  sided :) )
-- as requested by createdbyeric:
-- https://forum.fivem.net/t/release-xnlrankbar-fully-working-original-gta-rankbar-xp-bar-natively-with-original-gta-levels/318839/15?u=venomxnl
--===================================================================================
function vRPBs.SetInitialXPLevels(NetCurrentXP, NetShowRankBar, NetShowRankBarAnimating)
	SetInitialXPLevels(NetCurrentXP, NetShowRankBar, NetShowRankBarAnimating)
end

function vRPBs.AddPlayerXP(NetXPAmmount)
	AddPlayerXP(NetXPAmmount)
end

function vRPBs.RemovePlayerXP(NetXPAmmount)
	RemovePlayerXP(NetXPAmmount)
end

--===================================================================================
-- These are functions you could/can use to make this script 'ready to use' and to
-- (make it ) interface with your own scripts, game modes etc :)
--===================================================================================
function SetInitialXPLevels(CurrentXP, ShowRankBar, ShowRankBarAnimating)
	-- This function sets the 'inital XP level' (when the player first spawns for example)
	-- When you set ShowRankBar to true, it will show the rankbar on initial setup/spawn
	-- When you set ShowRankBarAnimating it will 'animate' the currentlevel from
	-- the bottom of that rank to the amount of XP the player has for that rank

	
	-- You can ofcourse also use the normal MP0_CHAR_XP_FM stats to set and get the XP
	-- just like I do myself, but for the purpose of releasing this (portion of my)
	-- script I have made sure to use an other 'different variable' to ensure that I would
	-- "not just f*ck up" stats or so on your server :)
	Config.CurrentPlayerXP = CurrentXP
	
	local CurLevel = GetLevelFromXP(CurrentXP)
	if ShowRankBar then
		local AnimateFrom = CurrentXP
		if ShowRankBarAnimating then
			AnimateFrom = GetXPFloorForLevel(CurLevel)
		end
		CreateRankBar(GetXPFloorForLevel(CurLevel), GetXPCeilingForLevel(CurLevel), AnimateFrom, Config.CurrentPlayerXP, CurLevel, false)
	end
	
	LocalPlayer.state:set("PlayerXP", CurLevel, true)
end

function GetCurrentPlayerXP()
	-- Like the name suggests: This function simply returns the current TOTAL player xp amount
	-- NOTE: Which is set in MY variable in THIS SCRIPT! if you use other variables
	-- like MP0_CHAR_XP_FM for example, you would need to change that ofcourse!
	return Config.CurrentPlayerXP
end

function GetCurrentPlayerLevel()
	-- Like the name suggests: This function simply returns the current player level
	-- NOTE: Which is set in MY variable in THIS SCRIPT! if you use other variables
	-- like MP0_CHAR_XP_FM for example, you would need to change that ofcourse!
	return GetLevelFromXP(Config.CurrentPlayerXP)
end

function AddPlayerXP(XPAmount)
	--======================================================================================
	-- "The Command" to give the player new XP (Well documented/commented)
	--======================================================================================
	if not is_int(XPAmount) then
		print("=====================================================================================================")
		print("XNL WARNING: You have an error in one of your scripts calling the function 'AddPlayerXP'")
		print("XNL WARNING: The script which is calling this function is not passing an integer!")
		print("=====================================================================================================")
		return
	end

	if XPAmount < 0 then
		print("=====================================================================================================")
		print("XNL WARNING: You have an error in one of your scripts calling the function 'AddPlayerXP'")
		print("XNL WARNING: is trying to TAKE XP from a player, use 'RemovePlayerXP' instead!")
		print("=====================================================================================================")
		return
	end
	
	local CurrentLevel = GetLevelFromXP(Config.CurrentPlayerXP)	-- Remembers the CURRENT level of the player BEFORE adding the new XP
	local CurrentXPWithAddedXP = Config.CurrentPlayerXP + XPAmount		-- Remembers the NEW XP amount (with the new xp added to the already 'owned XP')
	local NewLevel =  GetLevelFromXP(CurrentXPWithAddedXP)		-- Remembers the NEW level which the player will get after adding the new XP (IF there would be a new level)
	local LevelDifference = 0										-- This variable will 'later on' remember how many levels the player has leveled up (at once)
	
	-- This section is 'my build in level cap' which can be set in the variables at the top of the script
	if NewLevel > #Config.RockstarRanks - 1 then
		NewLevel = #Config.RockstarRanks -1
		CurrentXPWithAddedXP = GetXPCeilingForLevel(#Config.RockstarRanks - 1)
	end
	
	-- This section detects if there is a difference in level due to player gaining XP
	if NewLevel > CurrentLevel then
		LevelDifference = NewLevel - CurrentLevel
	end
	
	if LevelDifference > 0 then
		-- If we detect that the player has reached a new level we will need to make sure it also
		-- shows this progress in the rank bar. This function/section even supports leveling up multiple
		-- levels at once :)
		local StartAtLevel = CurrentLevel
		CreateRankBar(GetXPFloorForLevel(StartAtLevel), GetXPCeilingForLevel(StartAtLevel), Config.CurrentPlayerXP, GetXPCeilingForLevel(StartAtLevel), StartAtLevel, false)
		
		-- Make a loop to go through all the levels the player has received from this xp gain (if he/she received (multiple) new level(s))
		for i = 1, LevelDifference ,1 
		do 
			StartAtLevel = StartAtLevel + 1
			
			if i == LevelDifference then
				-- If we have reached the 'final new level' in the loop we'll make sure it the actual current XP Total (including the newly added amount)
				CreateRankBar(GetXPFloorForLevel(StartAtLevel), GetXPCeilingForLevel(StartAtLevel), GetXPFloorForLevel(StartAtLevel), CurrentXPWithAddedXP, StartAtLevel, false)
			else
				-- If we to do 'multiple bar animations' we will need to make sure that it will only 'animate' to the maximum amount of XP per bar for the level it is showing,
				-- in MOST cases we don't even need this section since most of the time players will only level up one level at a time, but I wanted it to be '100% compatible' with
				-- situations where it would happen that a player skips one or multiple levels at once by gaining new XP
				CreateRankBar(GetXPFloorForLevel(StartAtLevel), GetXPCeilingForLevel(StartAtLevel), GetXPFloorForLevel(StartAtLevel), GetXPCeilingForLevel(StartAtLevel), StartAtLevel, false)
			end
		end
	else
		-- Here we just create the normal rankbar without the need to make it 're-appear' with the 'level up animation'
		CreateRankBar(GetXPFloorForLevel(NewLevel), GetXPCeilingForLevel(NewLevel), Config.CurrentPlayerXP, CurrentXPWithAddedXP, NewLevel, false)
	end
	
	Config.CurrentPlayerXP = CurrentXPWithAddedXP
	
	LocalPlayer.state:set("PlayerXP", CurrentLevel, true)
end

function RemovePlayerXP(XPAmount)
	--======================================================================================
	-- "The Command" to give the player new XP (Well documented/commented)
	--======================================================================================
	if not is_int(XPAmount) then
		print("=====================================================================================================")
		print("XNL WARNING: You have an error in one of your scripts calling the function 'RemovePlayerXP'")
		print("XNL WARNING: The script which is calling this function is not passing an integer!")
		print("=====================================================================================================")
		return
	end

	if XPAmount < 0 then
		print("=====================================================================================================")
		print("XNL WARNING: You have an error in one of your scripts calling the function 'RemovePlayerXP'")
		print("XNL WARNING: is trying to give 'negative' XP by passing a negative value, If you for example  ")
		print("XNL WARNING: want to remove 100XP just use: 'RemovePlayerXP(100)' to remove 100XP from the player")
		print("=====================================================================================================")
		return
	end

	local CurrentLevel = GetLevelFromXP(Config.CurrentPlayerXP)	-- Remembers the CURRENT level of the player BEFORE adding the new XP
	local CurrentXPWithRemovedXP = Config.CurrentPlayerXP - XPAmount	-- Remembers the NEW XP amount (with the xp removed to the already 'owned XP')
	local NewLevel =  GetLevelFromXP(CurrentXPWithRemovedXP)	-- Remembers the NEW level which the player will get after adding the new XP (IF there would be a new level)
	local LevelDifference = 0										-- This variable will 'later on' remember how many levels the player has leveled up (at once)
	
	-- This section makes sure that the player doesn't get bellow level 1 (to prevent game crashes or weird sh*t from happening (I DID NOT tested what happens if you try to set it bellow 1!)
	if NewLevel < 1 then
		NewLevel = 1
	end

	if CurrentXPWithRemovedXP < 0 then
		CurrentXPWithRemovedXP = 0
	end
	
	-- This section detects if there is a difference in level due to player losing XP
	if NewLevel < CurrentLevel then
		LevelDifference = math.abs(NewLevel - CurrentLevel)	-- Math(ematical) function gets the absolute difference between the Current and new level (counting the 'level loss')
	end
	
	if LevelDifference > 0 then
		-- If we detect that the player has reached a new level we will need to make sure it also
		-- shows this progress in the rank bar. This function/section even supports leveling up multiple
		-- levels at once :)
		local StartAtLevel = CurrentLevel
		CreateRankBar(GetXPFloorForLevel(StartAtLevel), GetXPCeilingForLevel(StartAtLevel), Config.CurrentPlayerXP, GetXPFloorForLevel(StartAtLevel), StartAtLevel, true)
		
		-- Make a loop to go through all the levels the player has received from this xp gain (if he/she received (multiple) new level(s))
		for i = 1, LevelDifference ,1
		do 
			StartAtLevel = StartAtLevel - 1
			
			if i == LevelDifference then
				-- If we have reached the 'final new level' in the loop we'll make sure it the actual current XP Total (including the newly added amount)
				CreateRankBar(GetXPFloorForLevel(StartAtLevel), GetXPCeilingForLevel(StartAtLevel), GetXPCeilingForLevel(StartAtLevel), CurrentXPWithRemovedXP, StartAtLevel, true)
			else
				-- If we to do 'multiple bar animations' we will need to make sure that it will only 'animate' to the maximum amount of XP per bar for the level it is showing,
				-- in MOST cases we don't even need this section since most of the time players will only level up one level at a time, but I wanted it to be '100% compatible' with
				-- situations where it would happen that a player skips one or multiple levels at once by gaining new XP
				CreateRankBar(GetXPFloorForLevel(StartAtLevel), GetXPCeilingForLevel(StartAtLevel), GetXPCeilingForLevel(StartAtLevel), GetXPFloorForLevel(StartAtLevel), StartAtLevel, true)
			end
		end
	else
		-- Here we just create the normal rankbar without the need to make it 're-appear' with the 'level animation'
		CreateRankBar(GetXPFloorForLevel(NewLevel), GetXPCeilingForLevel(NewLevel), Config.CurrentPlayerXP, CurrentXPWithRemovedXP , NewLevel, true)
	end
	
	-- Update the variable to make it work properly the next time XP update is requested
	Config.CurrentPlayerXP = CurrentXPWithRemovedXP
	
	LocalPlayer.state:set("PlayerXP", CurrentLevel, true)
end

--======================================================================================
--======================================================================================
-- Basicaly if you're a 'standard user/implementor' of my script, you would not need
-- to use, change or 'worry about' the functions bellow and they should have no
-- (direct) use to you, the functions bellow just ensure proper functioning of the
-- script and rankbar :)
--======================================================================================
--======================================================================================

--======================================================================================
-- This function calculates (or gets while still bellow level 100!)
-- the 'floor level' XP amount for the level you're asking it for
-- this is required to set the 'start position' of the rankbar to animate
--
-- NOTE: Technically you DO NOT NEED to interface or 'mess' with this function!
--       This function is CRUCIAL for proper rank bar animations and has NOTHING
--       todo with setting user ranks, levels, rp or whatever you want to call it!
--		 You do NOT need to change this function or so to set level limits or so,
--		 you would only need to if you want to make different XP levels than the
--		 original game has!
--======================================================================================
function GetXPFloorForLevel(intLevelNr)
	if is_int(intLevelNr) then
		
		-- This is some 'basic build in security' JUST IN CASE people DO think it'scaleform
		-- a good idea to mess with these functions!
		if intLevelNr > #Config.RockstarRanks then
			intLevelNr = #Config.RockstarRanks
			print("=====================================================================================================")
			print("XNL WARNING: You have an error in one of your scripts which is trying to get the floor level XP for")
			print("XNL WARNING: an player level beyond level #Config.RockstarRanks, which is the game limit!")
			print("XNL WARNING: Script has prevented this and set the 'limit' to #Config.RockstarRanks!")
			print("=====================================================================================================")
		end
		
		-- If the level is set bellow 2 (so basically level 1 since level 0 doesn't exist!)
		-- we will automatically return that the 'floor' of this level is 0XP (since it's not in the list)
		if intLevelNr < 2 then
			return 0
		end
		
		if intLevelNr > 100 then
			local BaseXP = Config.RockstarRanks[#Config.RockstarRanks]	-- Get the 'base XP' from the last known original rockstar level (100) in my table
			local ExtraAddPerLevel = 50		-- This is the amount which rockstar ADDS on the amount required for the next level PER next level
			local MainAddPerLevel = 28550 	-- This is the amount of XP required for level 100 ***MINUS 50 so my "formula" will work correctly!***
			                            -- I'll try to explain in easy words: When going from level 100 to level 101 you'll need 28600XP, 
			                            -- when going from level 101 to level 101 you will need 28650XP .... So Notice the extra 50 XP here?
			
			local BaseLevel = intLevelNr - 100 -- Here we make sure that the first 100 levels are 'excluded' from the loop since we already have a base offset.
			local CurXPNeeded = 0				 -- This variable will remember the total XP for the level (and adds to it during the loop below)
			for i = 1, BaseLevel ,1 do 
				MainAddPerLevel = MainAddPerLevel + 50		-- Adding 50 extra XP per new level we pass in the loop
				CurXPNeeded = CurXPNeeded + MainAddPerLevel	-- Adding the total + XP for the current passed Level in the loop (including the +50 per level)
			end
			
			return BaseXP + CurXPNeeded	 -- Returning the Base XP from the last known 'rockstar rank' and adding the new extra rank(s) XP to it
		end
		
		-- IF the level we're requesting the "floor xp" from is level 100 or bellow we'll take the amount of XP
		-- required from the table I've put in this script which uses the original rockstar XP levels
		return Config.RockstarRanks[intLevelNr - 1]
	else
		print("=====================================================================================================")
		print("XNL WARNING: You have an error in one of your scripts calling the function 'GetXPFloorForLevel'")
		print("XNL WARNING: The script which is calling this function is not passing an integer!")
		print("=====================================================================================================")
		return 0 -- YES this MIGHT cause an XP bar which will not show xp drawing for a moment IF there is an error in the script, but it will prevent crashing!
	end
end

--======================================================================================
-- This function calculates (or gets while still bellow level 99!)
-- the 'ceiling level' XP amount for the level you're asking it for
-- this is required to set the 'end position' of the rankbar to animate AND it's used
-- to show the second part of the progress: the "1500/2000" bellow the rankbar
--
-- NOTE: Technically you DO NOT NEED to interface or 'mess' with this function!
--       This function is CRUCIAL for proper rank bar animations and has NOTHING
--       todo with setting user ranks, levels, rp or whatever you want to call it!
--		 You do NOT need to change this function or so to set level limits or so,
--		 you would only need to if you want to make different XP levels than the
--		 original game has!
--======================================================================================
function GetXPCeilingForLevel(intLevelNr)
	if intLevelNr == 0 then
		return 0
	elseif is_int(intLevelNr) then
		-- This is some 'basic build in security' JUST IN CASE people DO think it'scaleform
		-- a good idea to mess with these functions!
		if intLevelNr > 7999 then
			intLevelNr = 7999
			print("=====================================================================================================")
			print("XNL WARNING: You have an error in one of your scripts which is trying to get the ceiling level XP")
			print("XNL WARNING: for an player level beyond level 7999, which is the game limit!")
			print("XNL WARNING: Script has prevented this and set the 'limit' to 7999!")
			print("=====================================================================================================")
		end
		
		-- If the level is set bellow 2 (so basically level 1 since level 0 doesn't exist!)
		-- we will automatically return that the 'floor' of this level is 0XP (since it's not in the list)
		if intLevelNr < 1 then
			print("=====================================================================================================")
			print("XNL WARNING: You have an error in one of your scripts which is trying to get the ceiling level XP")
			print("XNL WARNING: for an player level BELLOW level 1, which is the game limit!")
			print("XNL WARNING: Script has prevented this and set the 'limit' back to 1!")
			print("=====================================================================================================")
			return Config.RockstarRanks[1]	-- NOTE: If you have changed the "original Rockstar Level Table" you will need to change this one to!
		end
		
		if intLevelNr > #Config.RockstarRanks then
			local BaseXP = Config.RockstarRanks[#Config.RockstarRanks]
			local ExtraAddPerLevel = 50		-- This is the amount which rockstar ADDS on the amount required for the next level PER next level
			local MainAddPerLevel = 28550 	-- This is the amount of XP required for level 100 ***MINUS 50 so my "formula" will work correctly!***
			-- I'll try to explain in easy words: When going from level 100 to level 101 you'll need 28600XP, when going from level 101 to level 101
			-- you will need 28650XP .... So Notice the extra 50 XP here?
			
			-- NOTE: This section bellow is 'well documented' in the function GetXPFloorForLevel above, so no need to comment it all twice :)
			MainAddPerLevelBaseLevel = intLevelNr - #Config.RockstarRanks
			MainAddPerLevelBaseLevelCurXPNeeded = 0
			for i = 1, BaseLevel ,1 do 
				MainAddPerLevel = MainAddPerLevel + 50
				CurXPNeeded = CurXPNeeded + MainAddPerLevel
			end
			
			return BaseXP + CurXPNeeded
		end
		
		-- IF the level we're requesting the "ceiling xp" for is level 998 or bellow we'll take the amount of XP
		-- required from the table I've put in this script which uses the original rockstar XP levels
		return Config.RockstarRanks[intLevelNr]
	else
		print("=====================================================================================================")
		print("XNL WARNING: You have an error in one of your scripts calling the function 'GetXPCeilingForLevel'")
		print("XNL WARNING: The script which is calling this function is not passing an integer!")
		print("=====================================================================================================")
		return 0 -- YES this MIGHT cause an XP bar which will not show xp drawing for a moment IF there is an error in the script, but it will prevent crashing!
	end
end

function GetLevelFromXP(intXPAmount)
	--======================================================================================
	-- This function 'converts' the XP amount you 'put in' to the level belongs to/in
	-- NOTE: This function does NOT have an 'upper limit' or 'error handling' on entering
	-- INSANE amounts since it should NOT happen if the scripts using these features
	-- are scripted normally! Especially not when considering that the maximum level
	-- "supported" is 7999! ;)
	--======================================================================================	
	if is_int(intXPAmount) then
		local SearchingFor = intXPAmount
		
		if SearchingFor < 0 then return 1 end				-- Just return level 1 if an XP level BELLOW 0 is given
		
		if SearchingFor < Config.RockstarRanks[#Config.RockstarRanks] then			-- Check if the XP amount is smaller than the last item (level 100) in my 'Rockstar XP Requirements level list'
			local CurLevelFound = -1
		
			local CurrentLevelScan = 0
			for k,v in pairs(Config.RockstarRanks)do			-- And if it's bellow the 'maximum known rockstar XP requirement' scan the table here
				CurrentLevelScan = CurrentLevelScan + 1	-- Just keep counting +1 for each level that doesn't match the xp level
				if SearchingFor < v then break end		-- when we found it, break the loop and report the level we've found :)
			end
			
			return CurrentLevelScan
		else
			-- If the amount of XP you're trying to get the level from is above the maximum XP amount in the rockstar XP requirements list (level 100)
			-- then we'll make our own loop to find the correct level here :)
			local BaseXP = Config.RockstarRanks[#Config.RockstarRanks]
			local ExtraAddPerLevel = 50		-- This is the amount which rockstar ADDS on the amount required for the next level PER next level
			local MainAddPerLevel = 28550 	-- This is the amount of XP required for level 100 ***MINUS 50 so my "formula" will work correctly!***
			-- I'll try to explain in easy words: When going from level 100 to level 101 you'll need 28600XP, when going from level 101 to level 101
			-- you will need 28650XP .... So Notice the extra 50 XP here?
			
			local CurXPNeeded = 0
			local CurLevelFound = -1
			for i = 1, #Config.RockstarRanks - #Config.RockstarRanks ,1 do 			-- The - 998 in this loop ensures that the for loop result excludes the first 998 levels which are 
				MainAddPerLevel = MainAddPerLevel + 50
				CurXPNeeded = CurXPNeeded + MainAddPerLevel
				CurLevelFound = i
				if SearchingFor < (BaseXP + CurXPNeeded) then break end
			end
		
			return CurLevelFound + #Config.RockstarRanks
		end
	else
		print("=====================================================================================================")
		print("XNL WARNING: You have an error in one of your scripts calling the function 'GetLevelFromXP'")
		print("XNL WARNING: The script which is calling this function is not passing an integer!")
		print("=====================================================================================================")
		return 1 -- YES this MIGHT return the incorrect level... BUT will prevent possible crashes!
	end
end

--===================================================================================
-- This is the function that actually 'generates' the Rankbar and sets the variables
-- for it to make it function like it should
--===================================================================================
function CreateRankBar(XP_StartLimit_RankBar, XP_EndLimit_RankBar, playersPreviousXP, playersCurrentXP, CurrentPlayerLevel, TakingAwayXP)
	RankBarColor = 116 -- The Normal Online Ranbar color (IS NOT used for the globes!)
	if TakingAwayXP and Config.UseRedBarWhenLosingXP then
		RankBarColor = 6 -- Dark Red
	end
	
	
	-- Although some sites note that the RankBar is hud ID 40, this does not work when we want to 
	-- call it for drawing, we actually need to call id 19 (which is the WeaponWheel)
	--[[
		I have also located AND CONFIRMED (instead of just assuming internet data!) the following other components:
			WANTED_STARS 			= 1
			WEAPON_ICON 			= 2
			CASH 					= 3
			MP_CASH 				= 4
			MP_MESSAGE 				= 5
			VEHICLE_NAME 			= 6
			AREA_NAME 				= 7
			VEHICLE_CLASS 			= 8
			STREET_NAME 			= 9
			HELP_TEXT 				= 10
			FLOATING_HELP_TEXT_1 	= 11
			FLOATING_HELP_TEXT_2 	= 12
			CASH_CHANGE 			= 13
			RETICLE 				= 14
			SUBTITLE_TEXT 			= 15
			RADIO_STATIONS 			= 16
			SAVING_GAME 			= 17
			GAME_STREAM				= 18
			WEAPON_WHEEL 			= 19   <-- This sameone is also used to call the rankbar!
			WEAPON_WHEEL_STATS 		= 20
			HUD_COMPONENTS 			= 21
			HUD_WEAPONS 			= 22
	]]
	if not HasScaleformScriptHudMovieLoaded(19) then							-- Here we check if the scaleform has been loaded or not
        RequestHudScaleform(19)										-- If it's not loaded we will request (load) it
		while not HasScaleformScriptHudMovieLoaded(19) do						-- here we will wait until it has loaded
			Wait(1)													-- you will HAVE to put this wait here to prevent script hang and game freezing!
		end
    end
	
	-- Currently i can't find any links to change the colors of the rank logo's (the globes on both sides) effectively
	-- i have tried setting component color id's with functions like ApplyHudColour, Colourise and other functions like that,
	-- (NOPE! those where NOT just 'guesses' but actual functions found in the data files regarding the HUD/Rankbar)
	-- tried addressing thm at HUD item 19, 40 (since some websites state that this is the rankbar ID, however! i could/can
	-- not find any logical evidence for this in hud.gfx! (or i might have overlooked it) 
	--
	-- Also tried using loading and preparing scale forms etc with for loops etc, but for now I will just leave it at what it is
	-- I'm eventually planning on using the "Rank Globe Color's" for prestige players in my server so I MIGHT come back to it and
	-- do more research but for now this rather 'unimportant feature' is holding back to much other development to keep researching.
	-- IF someone else finds or knows the solution them please don't hesitate to notify me so I can add it to my functionality and update
	-- this 'public release' script to :)
	--
	-- But what i DID notice is that the rankbar somewhat has ID 140! This can be seen/found in:
	-- sprite652(_Packages.com.rockstargames.gtav.hud.NEW_HUD)
	--
	-- HOWERVER: My appologies but I WILL NOT copy/publish these lines since I'm not taking any risks on publishing
	-- copyrighted lines/decompiled code ;) People whom would actually need this data are also well aware on how
	-- they can obtain or view that data ;) .... IF you don't know it, then you don't need that data either ;)

	-- This function sets the color of the rankBAR (NOT the globes)
	-- This function is called inside hud.gfx and only takes ONE parameter
	-- The globe color needs to be set differently
	BeginScaleformScriptHudMovieMethod(19, "SET_COLOUR")
		ScaleformMovieMethodAddParamInt(RankBarColor) -- 116 is the "normal multiplayer rankbar color"
    EndScaleformMovieMethodReturnValue()

	
	--[[
	    PURE_WHITE 	= 0
		WHITE 		= 1
		BLACK 		= 2
		GREY 		= 3
		GREYLIGHT 	= 4
		GREYDARK 	= 5
		RED 		= 6
		REDLIGHT 	= 7
		REDDARK 	= 8
		BLUE 		= 9
		BLUELIGHT 	= 10
		BLUEDARK 	= 11
		YELLOW 		= 12
		YELLOWLIGHT = 13
		YELLOWDARK 	= 14
		ORANGE 		= 15
		ORANGELIGHT = 16
		ORANGEDARK 	= 17
		GREEN 		= 18
		GREENLIGHT 	= 19
		GREENDARK 	= 20
		PURPLE 		= 21
		PURPLELIGHT	= 22
		PURPLEDARK 	= 23
		PINK 		= 24
		BRONZE 		= 107
		SILVER 		= 108
		GOLD 		= 109
		PLATINUM 	= 110
		FREEMODE 	= 116	-- This is the 'normal blue color' for the Rankbar
	]]
	
	-- This function calls the function SET_RANK_SCORES inside HUD GFX (MP_RANK_BAR)
	-- and takes a maximum of 7 parameters which I have described bellow
    BeginScaleformScriptHudMovieMethod(19, "SET_RANK_SCORES")		-- The HUD/Movie Component we want to use to draw the Rankbar
		ScaleformMovieMethodAddParamInt(XP_StartLimit_RankBar)	-- This sets the 'absolute begin limit' for the bar where it can start drawing from (includes the blue "you already had this XP" bar)
		ScaleformMovieMethodAddParamInt(XP_EndLimit_RankBar)		-- This sets the 'end limit' for the current level bar AND the 'top value' of the displayed XP text beneath the bar
		ScaleformMovieMethodAddParamInt(playersPreviousXP)		-- This sets where the previous XP 'was located' at the bar and thus from where to start drawing the 'white/new xp bar'
		ScaleformMovieMethodAddParamInt(playersCurrentXP)		-- This sets the current players XP (to 'where' the bar has to move!)
		ScaleformMovieMethodAddParamInt(CurrentPlayerLevel)		-- This one Determines the LEFT 'globe', so the CURRENT player's level!
		ScaleformMovieMethodAddParamInt(100)						-- This one sets the opacity (visibility %) from 0 (invisible) to 100 (fully visible)
		--ScaleformMovieMethodAddParamInt(8)					 	-- This CAN be used to set the 'end level' when making ONE bar to level up multiple levels
																		-- This can then make it look like this for example (5)==========----------(8)
																		-- when leveling up from level 5 to level 8 at once. BUT we CHOOSE to make it like i did now
																		-- (making multiple bars fill), so IF you want to change it you can just adapt the code and 
																		-- set this 'extra' pushscale parameter :)
    EndScaleformMovieMethodReturnValue()										-- "Ends" the current command/function handler
end

--===================================================================================
-- This is a 'small function' which is basically not needed (IF there are no errors 
-- made when using my script!) BUT i've put it in here anyway since I have added some
-- 'extra error handling' to some functions to make it a bit easier and 'less crash 
-- prone' when new users/scripters try to use it or adapt it.
--===================================================================================
function is_int(n)
	if type(n) == "number" then
		if math.floor(n) == n then
			return true
		end
	end
	return false
end
