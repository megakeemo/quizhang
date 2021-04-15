-----------------------------------------------------------------------------------------
-- QuizHang menu scene
-- Main navigation for app
-----------------------------------------------------------------------------------------

composer = require( "composer" )
local scene = composer.newScene()

local updater = require( "quizupdater" )

local utility = require( "utility" )

-----------------------------------------------------------------------------------------
-- Google Play Game Services and Apple GameCenter
-- Adds support for global leaderboard and achievements
-----------------------------------------------------------------------------------------
gameNetwork = require("gameNetwork")

local playerName
 
local function loadLocalPlayerCallback(event)
   playerName = event.data.alias
   --saveSettings()  --save player data locally using your own "saveSettings()" function
end
 
local function gameNetworkLoginCallback(event)
   gameNetwork.request("loadLocalPlayer", {listener=loadLocalPlayerCallback })
   return true
end
 
local function gpgsInitCallback(event)
   gameNetwork.request("login", { userInitiated=true, listener=gameNetworkLoginCallback })
end
 
local function gameNetworkSetup()
   if(system.getInfo("platformName") == "Android") then
      gameNetwork.init("google", gpgsInitCallback)
   else
      gameNetwork.init("gamecenter", gameNetworkLoginCallback)
   end
end


-- -----------------------------------------------------------------------------------------------------------------
-- All code outside of the listener functions will only be executed ONCE unless "composer.removeScene()" is called.
-- -----------------------------------------------------------------------------------------------------------------

-- local forward references should go here
local bg
local titleLogo
local enduranceBtn
local timeTrialBtn
local rapSheetBtn
local updaterBtn
local volumeOnBtn
local volumeOffBtn
local achievementBtn
local leaderboardBtn
local storeBtn
local updateButtonPressed = false




--goto Endurance Mode when button is pressed
local function gotoEndurance(event)
    audio.play(button_click, {channel=2})
    utility.biggerSmaller(enduranceBtn)

    composer.removeScene( "scene_menu" )
    composer.gotoScene( "scene_playendurance" )  

    return true
end


--goto Time Trial Mode when button is pressed
local function gotoTimeTrial(event)
    audio.play(button_click, {channel=2})
    utility.biggerSmaller(timeTrialBtn)

    composer.removeScene( "scene_menu" )
    composer.gotoScene( "scene_playtimetrial" )

    return true
end


--goto Stats Mode when button is pressed
local function gotoStats(event)
    audio.play(button_click, {channel=2})
    utility.biggerSmaller(timeTrialBtn)

    composer.removeScene( "scene_menu" )
    composer.gotoScene( "scene_stats" )

    return true
end


--goto Store Mode when button is pressed
local function gotoStore(event)
    audio.play(button_click, {channel=2})
    utility.biggerSmaller(storeBtn)

    composer.removeScene( "scene_menu" )
    composer.gotoScene( "scene_store" )

    return true
end


--Turn volume on/off
local function volumeControl(event)
	audio.play(button_click, {channel=2})
	utility.biggerSmaller(volumeOnBtn)

    if(event.phase == "began" and playSound == true) then 
        -- mute the game
        audio.setVolume(0, {channel=1})
        volumeOnBtn.alpha = 0.5

        playSound = false
    else 
        -- unmute the game
       audio.setVolume(1, {channel=1})
        volumeOnBtn.alpha = 1
        playSound = true
    end

    return true
end


--Update Quizzes when button is pressed
local function updateQuizzes(event)
    audio.play(button_click, {channel=2}) 
    utility.biggerSmaller(updaterBtn) 

    if((event.phase == "began") and (updateButtonPressed == false)) then 
        -- Download new quizzes
        if(utility.testConnection() == true) then
            updater.requestNewQuizzes()
            
        else 
            print("No Internet connection.")
            toast.show("No Internet connection.", { gravity="BottomCenter"} )
        end

        updateButtonPressed = true
        updaterBtn.alpha = 0.5
    end

    return true
end


--Display leaderboards
local function displayLeaderboards(event)
	audio.play(button_click, {channel=2}) 
    utility.biggerSmaller(leaderboardBtn)

    if(system.getInfo("platformName") == "Android") then
    	gameNetwork.show("leaderboards")
    else
      gameNetwork.show("leaderboards", { leaderboard = {timeScope="AllTime"} } )
    end

    return true
end


--Display achievements
local function displayAchievements(event)
    audio.play(button_click, {channel=2}) 
    utility.biggerSmaller(achievementBtn)

    gameNetwork.show("achievements")
    return true
end


--Add images to scene
local function setUpDisplay(group)
	bg = display.newImageRect("images/menu_bg.png", 360, 480)
	bg.width = screenWidth
    bg.height = screenHeight
    bg.x = centerX
    bg.y = centerY
    group:insert(bg)

    titleLogo = display.newImage("images/title_logo.png")
    titleLogo.x = centerX
    titleLogo.y = screenTop + 50
    utility.fitImage(titleLogo, 360, 360, false)
    group:insert(titleLogo)


 	--button for endurance mode
    enduranceBtn = widget.newButton
    {
        id = "endurance_btn",
        x = centerX, 
        y = centerY - 100,
        defaultFile = "images/endurance_btn.png",
        width = 202,
        height = 33,
        onPress = gotoEndurance
    } 
    group:insert(enduranceBtn)
    
    
    --button for endurance mode
    timeTrialBtn = widget.newButton
    {
        id = "timetrial_btn",
        x = centerX, 
        y = centerY - 40, 
        defaultFile = "images/time_trial_btn.png",
        width = 180,
        height = 33,
        onPress = gotoTimeTrial
    } 
    group:insert(timeTrialBtn)


    --button for stats mode
    rapSheetBtn = widget.newButton
    {
        id = "rapsheet_btn",
        x = centerX, 
        y = centerY + 30, 
        defaultFile = "images/rapsheet_btn.png",
        width = 173,
        height = 38,
        onPress = gotoStats
    } 
    group:insert(rapSheetBtn)


    --button for store mode
    storeBtn = widget.newButton
    {
        id = "store_btn",
        x = centerX, 
        y = centerY + 90, 
        defaultFile = "images/store_btn.png",
        width = 105,
        height = 33,
        onPress = gotoStore
    } 
    group:insert(storeBtn)


    --button for volume
    volumeOnBtn = widget.newButton
    {
        id = "volume_on_btn",
        x = screenRight - 50, 
        y = screenBottom - 80,
        defaultFile = "images/volume_on_btn.png",
        overFile = "images/volume_on_btn.png",
        width = 50,
        height = 50,
        onPress = volumeControl
    }
    group:insert(volumeOnBtn)


    --button for QuizUpdater
    updaterBtn = widget.newButton
    {
        id = "updater_btn",
        x = screenRight - 120, 
        y = screenBottom - 80, 
        defaultFile = "images/download_btn.png",
        width = 50,
        height = 50,
        onPress = updateQuizzes
    }
    group:insert(updaterBtn)


    --button for Google Play Game Services Achievements
    achievementBtn = widget.newButton
    {
        id = "achievement_btn",
        x = screenLeft + 50, 
        y = screenBottom - 80, 
        defaultFile = "images/achievement_btn.png",
        width = 50,
        height = 50,
        onPress = displayAchievements
    }
    group:insert(achievementBtn)   


    --button for Google Play Game Services Leaderboards
    leaderboardBtn = widget.newButton
    {
        id = "leaderboard_btn",
        x = screenLeft + 120, 
        y = screenBottom - 80, 
        defaultFile = "images/leaderboard_btn.png",
        width = 50,
        height = 50,
        onPress = displayLeaderboards
    }
    group:insert(leaderboardBtn)   
end



-- "scene:create()"
function scene:create( event )

    local sceneGroup = self.view

    -- Initialize the scene here.
    -- Example: add display objects to "sceneGroup", add touch listeners, etc. 
    
    --Display scene elements
    setUpDisplay(sceneGroup)
   
end


-- "scene:show()"
function scene:show( event )

    local sceneGroup = self.view
    local phase = event.phase

    if ( phase == "will" ) then
        -- Called when the scene is still off screen (but is about to come on screen).
        print("menu scene")
    elseif ( phase == "did" ) then

        -- Called when the scene is now on screen.
        -- Insert code here to make the scene come alive.
        -- Example: start timers, begin animation, play audio, etc.

        --Login to the GPGS/Game Center network
        gameNetworkSetup() 

        -- Play main audio
        audio.play(menu_loop, {channel=1, fadeIn=1000, loops=-1})

        -- Get the show ad status
        getShowAdStatus()

        -- Show ads
        if(showAds == true) then
            -- Display admob banner ad
            ads.show("banner", { x=0, y=screenBottom, appId = bannerAppID })
        else
        	ads.hide()
        end

    end
end


-- "scene:hide()"
function scene:hide( event )

    local sceneGroup = self.view
    local phase = event.phase

    if ( phase == "will" ) then
        -- Called when the scene is on screen (but is about to go off screen).
        -- Insert code here to "pause" the scene.
        -- Example: stop timers, stop animation, stop audio, etc.
    elseif ( phase == "did" ) then
        -- Called immediately after scene goes off screen.
    end
end


-- "scene:destroy()"
function scene:destroy( event )

    local sceneGroup = self.view

    -- Called prior to the removal of scene's view ("sceneGroup").
    -- Insert code here to clean up the scene.
    -- Example: remove display objects, save state, etc.

    display.remove(menu_bg)
    display.remove(titleLogo)
    display.remove(enduranceBtn)
    display.remove(timeTrialBtn)
    display.remove(rapSheetBtn)
    display.remove(storeBtn)
    display.remove(volumeOnBtn)
    display.remove(volumeOffBtn)
    display.remove(updaterBtn)
    display.remove(achievementBtn)
    display.remove(leaderboardBtn)

    menu_bg = nil
    titleLogo = nil
    enduranceBtn = nil
    timeTrialBtn = nil
    rapSheetBtn = nil
    storeBtn = nil
    volumeOnBtn = nil
    volumeOffBtn = nil
    updaterBtn = nil
    achievementBtn = nil
    leaderboardBtn = nil

end


-- -------------------------------------------------------------------------------

-- Listener setup
scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )

-- -------------------------------------------------------------------------------

return scene
