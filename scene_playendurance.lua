-----------------------------------------------------------------------------------------
-- QuizHang Endurance Mode
-- User will be presented with a series of random multiple choice questions.
-- Time will start at 60 seconds.
-- Time will be dynamic, and will be added to or subtracted from based on correct/incorrect answers.
-- Each correct answer will add to the score.
-- Game ends when time runs out.
-- Highscore will be saved to local and online leaderboard
-----------------------------------------------------------------------------------------

-- Scene Management
composer = require( "composer" )
local scene = composer.newScene()

local quiz = require( "quizmanager" )

local utility = require( "utility" )


-- -----------------------------------------------------------------------------------------------------------------
-- All code outside of the listener functions will only be executed ONCE unless "composer.removeScene()" is called.
-- -----------------------------------------------------------------------------------------------------------------

local quizDisplay
local scoreDisplay
local timeDisplay

local pausebtn
local pauseBackground
local pauseText
local correctAnswersTxt
local incorrectAnswersTxt
local skippedQuestionsTxt

local upgradesTxt
local lifeSaverTxt
local timePlusTxt
local timeFreezeTxt
local skipMasterTxt

local restartBtn
local resumeBtn
local menuBtn


-----------------------------------------------------------------------------------------------
--Restart the game mode
local function restartGame(event)
    if(event.action == "clicked") then
        local i = event.index
        if(i == 1) then
            -- do nothing, dialog will simply dismiss
        elseif(i == 2) then
            gamePaused = false
            audio.stop(9)
            transition.resume()
            databaseConnected = false
            db:close()
            quiz.destroy()

            local currScene = composer.getSceneName( "current" )
            composer.removeScene( currScene )
            composer.gotoScene( "scene_playendurance" )
        end
    end
end

-- Alert box to confirm game restart
local function onRestartTouch(event)
	audio.play(button_click, {channel=2})
    utility.biggerSmaller(event.target)

    native.showAlert("Restart Game", "Are you sure you want to restart?", { "No", "Yes" }, restartGame)    
end

-- End game and switch to menu scene
local function gotoMenu(event)
    if(event.action == "clicked") then
        local i = event.index
        if(i == 1) then
            -- do nothing, dialog will simply dismiss
        elseif(i == 2) then
            -- Cleanup scene and go to menu scene
            gamePaused = false
            audio.stop(9)
            transition.resume()
            databaseConnected = false
            db:close()
            quiz.destroy()

            local currScene = composer.getSceneName( "current" )
            composer.removeScene( currScene )
            composer.gotoScene( "scene_menu" )
        end
    end
end

-- Alert box to confirm switch to menu scene
local function onMenuTouch(event)
	audio.play(button_click, {channel=2})
	utility.biggerSmaller(event.target)

    native.showAlert("Go to Menu", "Are you sure you want to return to the main menu?", { "No", "Yes" }, gotoMenu)
end


-- Pause the game
local function onPauseTouch(event)
    -- Disable pause during game over sequence
    if(gameOver == false) then
        -- If pause button is touched then pause timer, pause animations and disable buttons
        if(event.phase == "began") then
            if(gamePaused == false) then
                gamePaused = true

                -- Pause audio
                --audio.pause(play_loop)
                audio.pause(question_right)
                audio.pause(question_wrong)
                audio.pause(question_skip)
                audio.pause(special_question_right)
                audio.pause(special_question_wrong)
                audio.pause(consecutive_questions_right)
                audio.pause(lever_turn)
                audio.pause(time_running_out)
                audio.pause(game_ends)
                audio.play(button_click, {channel=2})
             
                -- Pause all animations
                quiz.pauseQuiz()
                garry:pause()
                executioner:pause()
                trapdoor:pause()
                timer.cancel(countDownTimer)
                transition.pause()

                -- Add Pause Background overlay
                pauseBackground = display.newRect(0, 0, screenWidth, screenHeight)
                pauseBackground.x = centerX
                pauseBackground.y = centerY
                pauseBackground:setFillColor(0)
                pauseBackground.alpha = .9

                -- Add Pause text
                pauseText = display.newText("Game Paused", 0, 0, "Arial Rounded MT Bold", 32)
                pauseText.x = centerX
                pauseText.y = screenTop + pauseText.height

                -- Pause Stats
                correctAnswersTxt = display.newText("Questions answered correctly so far: " .. ansCorrectCount, centerX, screenTop + 75, "Arial Rounded MT Bold", 16 )

                incorrectAnswersTxt = display.newText("Questions answered incorrectly so far: " .. ansIncorrectCount, centerX, screenTop + 100, "Arial Rounded MT Bold", 16 )

                skippedQuestionsTxt = display.newText("Questions skipped so far: " .. quesSkipCount .. "/10", centerX, screenTop + 125, "Arial Rounded MT Bold", 16 )

                -- Resume button
                resumeBtn = widget.newButton
                {
                    id = "resume_btn",
                    x = centerX, 
                    y = centerY - 20, 
                    defaultFile = "images/play_icon.png",
                    width = 84,
                    height = 84,
                    onPress = onPauseTouch
                }

                -- Restart button
                restartBtn = widget.newButton
                {
                    id = "restart_btn",
                    x = centerX - 100, 
                    y = centerY - 20, 
                    defaultFile = "images/restart_icon.png",
                    width = 84,
                    height = 84,
                    onPress = onRestartTouch
                }

                -- MenuRestart button
                menuBtn = widget.newButton
                {
                    id = "menu_btn",
                    x = centerX + 100, 
                    y = centerY - 20, 
                    defaultFile = "images/menu_icon.png",
                    width = 84,
                    height = 84,
                    onPress = onMenuTouch
                }

                -- Display available upgrades
                upgradesTxt = display.newText("Upgrades Available", centerX, screenBottom - 235, "Arial Rounded MT Bold", 26 )

                -- Display Skip Master text is available
                if(SKIP_MASTER_PURCHASED == 1) then
                    skipMasterTxt = display.newText("Skip Master", centerX, screenBottom - 200, "PoetsenOne", 26 )
                end

                -- Display Life Saver text is available
                if(LIFE_SAVER_PURCHASED == 1) then
                    lifeSaverTxt = display.newText("Life Saver", centerX, screenBottom - 165, "PoetsenOne", 26 )
                end

                -- Display Time Freeze text is available
                if(TIME_FREEZE_PURCHASED == 1) then
                    timeFreezeTxt = display.newText("Time Freeze", centerX, screenBottom - 130, "PoetsenOne", 26 )
                end

                -- Show ads
                if(showAds == true) then
		            -- Display admob banner ad
		            ads.show("banner", { x=0, y=screenBottom, appId = bannerAppID })
		        else
		        	ads.hide()
		        end


            -- Resume game
            else
                utility.biggerSmaller(resumeBtn)
                gamePaused = false
                quiz.skipOnResume()

                -- Resume audio play
                --audio.resume(play_loop)
                audio.resume(question_right)
                audio.resume(question_wrong)
                audio.resume(question_skip)
                audio.resume(special_question_right)
                audio.resume(special_question_wrong)
                audio.resume(consecutive_questions_right)
                audio.resume(lever_turn)
                audio.resume(time_running_out)
                audio.resume(game_ends)
                audio.play(button_click, {channel=2})

                -- Resume animations
                quiz.resumeQuiz()
                garry:play()
                executioner:play()
                trapdoor:play()
                countDownTimer = timer.performWithDelay( 1000, time.updateTime, -1 )
                transition.resume()

                -- Remove display objects created
                display.remove(pauseBackground)
                display.remove(pauseText)
                display.remove(resumeBtn)
                display.remove(restartBtn)
                display.remove(menuBtn)
                display.remove(correctAnswersTxt)
                display.remove(incorrectAnswersTxt)
                display.remove(skippedQuestionsTxt)
                display.remove(upgradesTxt)
                display.remove(lifeSaverTxt)
                display.remove(timePlusTxt)
                display.remove(timeFreezeTxt)
                display.remove(skipMasterTxt)
                display.remove(pauseReminder)
                ads.hide()
            end

            return true
        end
    end
end



--Add images to scene
local function setUpDisplay(group)
    -- Clock text
    clockText = display.newText("1:30", 0, 0, display.contentCenterX, screenBottom - 50, "PoetsenOne", 32)

    -- Background
    local bg = display.newImageRect("images/background.png", 360, 480)
    bg.width = screenWidth
    bg.height = screenHeight
    bg.x = centerX
    bg.y = centerY
    group:insert(bg)

    -- Trapdoor bottomless pit
    local pit = display.newRect(group, screenBottom, 0, screenWidth, 150)
    pit:setFillColor( 0, 0, 0 )
    pit.x = centerX
    pit.y = screenBottom
    group:insert(pit)

    -- Background ironbars
    local ironbars = display.newImageRect("images/ironbars.png", 360, 336)
    ironbars.width = screenWidth
    ironbars.height = screenHeight
    ironbars.x = centerX
    ironbars.y = centerY - 50
    group:insert(ironbars)

    -- Background platform
    local platform = display.newImageRect("images/platform.png", 360, 159)
    platform.width = screenWidth
    platform.x = centerX
    platform.y = screenBottom - 80
    group:insert(platform)

    -- Hanging pole
    local pole = display.newImageRect("images/hangingpole.png", 230, 291)
    pole.x = screenLeft + 110
    pole.y = screenBottom - 200
    --utility.fitImage(pole, 200, 200, false)
    group:insert(pole)

    -- Top Bar
    local topbar = display.newRect(group, 0, 0, screenWidth, 40 )
    topbar:setFillColor( 0.97, 0.76, 0.22 )
    topbar.x = centerX
    topbar.y = screenTop + 15
    group:insert(topbar)

    -- Pause Button
    local pausebtn = display.newImage("images/pausebtn.png")
    pausebtn.x = screenRight - 15
    pausebtn.y = screenTop + 17
    utility.fitImage(pausebtn, 25, 25, false)
    pausebtn:addEventListener( "touch", onPauseTouch )
    group:insert(pausebtn)

   
    -- Garry Idle
    local garryIdleOptions = {width=460, height=640, numFrames=12}
    local garryIdleImageSheet = graphics.newImageSheet("images/garry_idle_spritesheet.png", garryIdleOptions)


    -- -- Garry Hanging
    -- local garryHangingOptions1 = {width=460, height=640, numFrames=12}
    -- local garryHangingImageSheet1 = graphics.newImageSheet("images/garry_hanging_spritesheet1.png", garryHangingOptions1)

    -- local garryHangingOptions2 = {width=460, height=640, numFrames=12}
    -- local garryHangingImageSheet2 = graphics.newImageSheet("images/garry_hanging_spritesheet2.png", garryHangingOptions2)

    -- local garryHangingOptions3 = {width=460, height=640, numFrames=12}
    -- local garryHangingImageSheet3 = graphics.newImageSheet("images/garry_hanging_spritesheet3.png", garryHangingOptions3)


    -- Executioner Idle
    local executionerIdleOptions = {width=360, height=640, numFrames=2}
    local executionerIdleImageSheet = graphics.newImageSheet("images/executioner_idle_spritesheet.png", executionerIdleOptions)

    -- Executioner Act
    local executionerActionOptions = {width=360, height=640, numFrames=15}
    local executionerActImageSheet = graphics.newImageSheet("images/executioner_act_spritesheet1.png", executionerActionOptions)

    -- Trapdoor
    local trapdoorOptions = {width=360, height=640, numFrames=2}
    local trapdoorImageSheet = graphics.newImageSheet("images/trapdoor.png", trapdoorOptions)


    -- Garry sequences will be "idle", "hanging" and "ghost" (each will require its own spritesheet)
    local sequenceData = 
    {
        {name="garry_idle", sheet=garryIdleImageSheet, start=1, count=12, time=2000, loopDirection="bounce"},

        -- {name="garry_hanging1", sheet=garryHangingImageSheet1, start=1, count=12, time=800, loopCount=1},

        -- {name="garry_hanging2", sheet=garryHangingImageSheet2, start=1, count=12, time=800, loopCount=1},

        -- {name="garry_hanging3", sheet=garryHangingImageSheet3, start=1, count=12, time=800, loopCount=1},

        {name="executioner_idle", sheet=executionerIdleImageSheet, start=1, count=2, time=2000, loopDirection="bounce"},

        {name="executioner_act", sheet=executionerActImageSheet, start=1, count=15, time=400, loopCount=1},

        {name="trapdoor_idle", sheet=trapdoorImageSheet, start=1, count=1},

        -- {name="trapdoor_open", sheet=trapdoorImageSheet, start=2, count=1, time=1200, loopDirection="forward"}
    }

    --Display executioner on screen
    executioner = display.newSprite(group, executionerIdleImageSheet, sequenceData)
    executioner.x = screenRight - 70
    executioner.y = screenBottom - 170
    utility.fitImage(executioner, 240, 240, true)
    group:insert(executioner)

    --Display trapdoor on screen
    trapdoor = display.newSprite(group, trapdoorImageSheet, sequenceData)
    trapdoor.x = centerX
    trapdoor.y = screenBottom - 78
    utility.fitImage(trapdoor, 360, 360, true)
    group:insert(trapdoor)

    --Display Garry on screen
    garry = display.newSprite(group, garryIdleImageSheet, sequenceData)
    garry.x = centerX + 2
    garry.y = screenBottom - 228
    utility.fitImage(garry, 460, 460, true)
    group:insert(garry)

end

-- "scene:create()"
function scene:create( event )

    local sceneGroup = self.view

    -- Initialize the scene here.
    -- Example: add display objects to "sceneGroup", add touch listeners, etc.

    -- Keeps track of game mode
    isEndurance = true
    isTimeTrial = false

    -- Sets time on the clock for Endurance Mode
    secondsLeft = 1.5 * 60

    --Display scene elements
    setUpDisplay(sceneGroup)

    -- Flurry Analytics - Start a timed event
	flurryAnalytics.startTimedEvent("Quiz Manager") 

end

-- "scene:show()"
function scene:show( event )

    local sceneGroup = self.view
    local phase = event.phase

    if ( phase == "will" ) then
        -- Called when the scene is still off screen (but is about to come on screen).
        print("play endurance scene")
    elseif ( phase == "did" ) then

        -- Called when the scene is now on screen.
        -- Insert code here to make the scene come alive.
        -- Example: start timers, begin animation, play audio, etc. )

        -- Hide ads
        ads.hide()

        audio.setVolume(1, {channel=2})
        audio.setVolume(1, {channel=3})
        audio.fadeOut({channel=1, time=500})
        audio.stop(1)


        -- Add Garry to scene
        garry:setSequence("garry_idle")
        garry:play()

        -- Add executioner to scene
        executioner:setSequence("executioner_idle")
        executioner:play()

        --Add trapdoor to scene
        trapdoor:setSequence("trapdoor_idle")
        trapdoor:play()

        -- Add quiz to scene
        quizDisplay = quiz.quizManager()

        -- Add time and score modules to scene
        timeDisplay = time.displayTime()
        scoreDisplay = score.displayScore()

        -- Play game audio
        audio.play(play_loop, {channel=9, fadeIn=5000, loops=-1})
        audio.setMaxVolume(0.50, {channel=9})

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

    -- NB: QuizDisplay objects are destroyed from within quizmanager when game ends

    -- Flurry Analytics - Start a timed event
	flurryAnalytics.endTimedEvent("Quiz Manager")

    display.remove(bg)
    display.remove(pit)
    display.remove(ironbars)
    display.remove(platform)
    display.remove(pole)
    display.remove(topbar)
    display.remove(pausebtn)
    display.remove(time_freeze_btn)
    display.remove(clockText)

    display.remove(garryIdleImageSheet)
    display.remove(garryHangingImageSheet1)
    display.remove(garryHangingImageSheet2)
    display.remove(garryHangingImageSheet3)
    display.remove(executionerIdleImageSheet)
    display.remove(executionerActImageSheet)
    display.remove(trapdoorImageSheet)

    display.remove(executioner)
    display.remove(trapdoor)
    display.remove(garry)

    display.remove(pauseBackground)  
    display.remove(pauseText) 
    display.remove(resumeBtn)
    display.remove(restartBtn)
    display.remove(menuBtn)
    display.remove(correctAnswersTxt)
    display.remove(incorrectAnswersTxt)
    display.remove(skippedQuestionsTxt)
    display.remove(upgradesTxt)
    display.remove(lifeSaverTxt)
    display.remove(timeFreezeTxt)
    display.remove(skipMasterTxt)
    display.remove(pauseReminder)

    bg = nil
    pit = nil
    ironbars = nil
    platform = nil
    pole = nil
    topbar = nil
    pausebtn = nil
    time_freeze_btn = nil
    clockText = nil

    garryIdleImageSheet = nil
    garryHangingImageSheet1 = nil
    garryHangingImageSheet2 = nil
    garryHangingImageSheet3 = nil
    executionerIdleImageSheet = nil
    executionerActImageSheet = nil
    trapdoorImageSheet = nil

    executioner = nil
    trapdoor = nil
    garry = nil

    pauseBackground = nil
    pauseText = nil
    resumeBtn = nil
    restartBtn = nil
    menuBtn = nil
    correctAnswersTxt = nil
    incorrectAnswersTxt = nil
    skippedQuestionsTxt = nil
    upgradesTxt = nil
    lifeSaverTxt = nil
    timeFreezeTxt = nil
    skipMasterTxt = nil
    pauseReminder = nil
end


-- -------------------------------------------------------------------------------

-- Listener setup
scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )

-- -------------------------------------------------------------------------------

return scene
