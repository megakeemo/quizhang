-----------------------------------------------------------------------------------------
-- QuizHang GameOver Mode
-- Display stats at the end of the game session
-- Save stats to database
-----------------------------------------------------------------------------------------

-- Scene Management
composer = require( "composer" )
local scene = composer.newScene()

local utility = require("utility")

local facebook = require( "plugin.facebook.v4" )

local coins = require( "mod_coins" )

-- -----------------------------------------------------------------------------------------------------------------
-- All code outside of the listener functions will only be executed ONCE unless "composer.removeScene()" is called.
-- -----------------------------------------------------------------------------------------------------------------

-- local forward references should go here
local correctAnswerRatio = ansCorrectCount .. "/" .. questionCount
local coinsEarned
local grade
local gradeDisplay
local datetime = os.date("%Y-%m-%d %H:%M:%S")
local coin_count

local shareButton
local playAgainBtn
local menuBtn

local screenshotGroup
local screenshot

-- Facebook Commands
local fbCommand       
local LOGOUT = 1
local SHOW_FEED_DIALOG = 2
local SHARE_LINK_DIALOG = 3
local POST_MSG = 4
local POST_PHOTO = 5
local GET_USER_INFO = 6
local PUBLISH_INSTALL = 7
local GAME_REQUEST_DIALOG = 8


-- Check for an item inside the provided table
-- Based on implementation at: https://www.omnimaga.org/other-computer-languages-help/(lua)-check-if-array-contains-given-value/
local function inTable(table, item)
    for k,v in pairs(table) do
        if v == item then
            return true
        end
    end
    return false
end

-- This function is useful for debugging problems with using FB Connect's web api,
-- e.g. you passed bad parameters to the web api and get a response table back
local function printTable(t, label, level)
    if label then print(label) end
    level = level or 1

    if t then
        for k,v in pairs(t) do
            local prefix = ""
            for i=1,level do
                prefix = prefix .. "\t"
            end

            print(prefix .. "[" .. tostring(k) .. "] = " .. tostring(v))
            if type(v) == "table" then
                print(prefix .. "{")
                printTable(v, nil, level + 1)
                print(prefix .. "}")
            end
        end
    end
end


-- Runs the desired facebook command
local function processFBCommand()
    -- The following displays a Facebook dialog box for posting to your Facebook Wall
    if fbCommand == SHOW_FEED_DIALOG then
        -- "feed" is the standard "post status message" dialog
        local response = facebook.showDialog( "feed" )
    end

    -- This displays a Facebook Dialog for posting a link with a photo to your Facebook Wall
    if fbCommand == SHARE_LINK_DIALOG then
        local response = facebook.showDialog( "link", {
            name = "Check out my latest QuizHang stats!",
            link = "http://quizhang.com/",
            description = "Score: " .. tostring(scoreNo) .. "\n" ..
                    "Time gained: " .. tostring(totalTimeGained) .. "\n" ..
                    "Time lost: " .. tostring(totalTimeLost) .. "\n" ..
                    "Correct Answer Ratio: " .. tostring(correctAnswerRatio) .. "\n" ..
                    "Questions skipped: " .. tostring(quesSkipCount) .. "\n" ..
                    "Final grade: " .. tostring(gradeDisplay) .. "\n",
            picture = "http://quizhang.com/core/assets/images/quizhangicon.png",
        })
        printTable(response)
    end

    -- Request the current logged in user's info
    if fbCommand == GET_USER_INFO then
        local response = facebook.request( "me" )
        printTable(response)
        -- facebook.request( "me/friends" )     -- Alternate request
    end

    -- This code posts a photo image to your Facebook Wall
    if fbCommand == POST_PHOTO then
        local attachment = {
            name = "Check out my latest QuizHang stats!",
            link = "http://quizhang.com/",
            caption = "My latest stats",
            description = "Score: " .. tostring(scoreNo) .. "\n" ..
                    "Time gained: " .. tostring(totalTimeGained) .. "\n" ..
                    "Time lost: " .. tostring(totalTimeLost) .. "\n" ..
                    "Correct Answer Ratio: " .. tostring(correctAnswerRatio) .. "\n" ..
                    "Questions skipped: " .. tostring(quesSkipCount) .. "\n" ..
                    "Final grade: " .. tostring(gradeDisplay) .. "\n",
            picture = "http://quizhang.com/core/assets/images/quizhangicon.png",
            actions = json.encode( { { name = "Download Now", link = "http://quizhang.com" } } )
        }
    
        -- posting the photo
        local response = facebook.request( "me/feed", "POST", attachment )      
        printTable(response)
    end
    
    -- This code posts a message to your Facebook Wall
    if fbCommand == POST_MSG then
        local time = os.date("*t")
        local postMsg = {
            message = "Posting from Corona SDK! " ..
                os.date("%A, %B %e")  .. ", " .. time.hour .. ":"
                .. time.min .. "." .. time.sec
        }
    
        -- posting the message
        local response = facebook.request( "me/feed", "POST", postMsg )     
        printTable(response)
    end

    -- This code shares game invite with Facebook friends
    if fbCommand == GAME_REQUEST_DIALOG then
        facebook.showDialog( "requests", 
        { 
            message = "QuizHang - the new quiz game that's all the rave. Download it now!",
            filter = "APP_NON_USERS"
        })

    end
end



-- Facebook Connection listener
local function listener(event)
    -- Debug Event parameters printout --------------------------------------------------
    -- Prints Events received up to 20 characters. Prints "..." and total count if longer
    print("Facebook Listener events:")
    
    local maxStr = 20       -- set maximum string length
    local endStr
    
    for k,v in pairs(event) do
        local valueString = tostring(v)
        if string.len(valueString) > maxStr then
            endStr = " ... #" .. tostring(string.len(valueString)) .. ")"
        else
            endStr = ")"
        end
        print( "   " .. tostring( k ) .. "(" .. tostring( string.sub(valueString, 1, maxStr ) ) .. endStr )
    end
-- End of debug Event routine -------------------------------------------------------

    print( "event.name", event.name ) -- "fbconnect"
    print( "event.type:", event.type ) -- type is either "session" or "request" or "dialog"
    print( "isError: " .. tostring( event.isError ))
    print( "didComplete: " .. tostring( event.didComplete ))
    print( "response: " .. tostring( event.response ))
-----------------------------------------------------------------------------------------
    -- Process the response to the FB command
    -- Note: If the app is already logged in, we will still get a "login" phase
-----------------------------------------------------------------------------------------

    if("session" == event.type) then
        -- event.phase is one of: "login", "loginFailed", "loginCancelled", "logout"        
        print("Session Status: " .. event.phase)
        
        if event.phase ~= "login" then
            -- Exit if login error
            return
        else
            -- Run the desired command
            processFBCommand()
        end

    elseif("request" == event.type) then
        -- event.response is a JSON object from the FB server
        local response = event.response
        
        if(not event.isError) then
            response = json.decode(event.response)
            
            print("Facebook Command: " .. fbCommand)

            if fbCommand == GET_USER_INFO then
                printTable(response, "User Info", 3)
                print("name", response.name)
                
            elseif fbCommand == POST_PHOTO then
                printTable(response, "photo", 3)
                            
            elseif fbCommand == POST_MSG then
                printTable(response, "message", 3)

            elseif fbCommand == GAME_REQUEST_DIALOG then
                printTable(response, "invite", 3)

                -- Reward users for inviting others
                if(event.didComplete == true) then
			        coinAmt = cointAmt + 5
			        coins.updateCoins(coinAmt)
			        print("Reward earned!")
			        native.showAlert("Info", "Thanks for sharing! You've been rewarded with 5 extra coins. Check out the store and see which upgrades you can buy.", {"Okay"})
                end

            else
                -- Unknown command response
                print( "Unknown command response" )
            end

        else
            -- Post Failed
            printTable(event.response, "Post Failed Response", 3)
        end
        
    elseif("dialog" == event.type) then
        -- showDialog response
        print("dialog response:", event.response)
    end
end


-- Log in to Facebook
local function enforceFacebookLogin()
    if facebook.isActive then
        local accessToken = facebook.getCurrentAccessToken()
        if accessToken == nil then

            print("Need to log in")
            facebook.login(listener)

        elseif not inTable(accessToken.grantedPermissions, "publish_actions") then

            print("Logged in, but need permissions")
            printTable(accessToken, "Access Token Data")
            facebook.login(listener, {"publish_actions"})

        else

            print("Already logged in with needed permissions")
            printTable(accessToken, "Access Token Data")
            processFBCommand()

        end
    else
        print("Please wait for Facebook to finish initializing before checking the current access token");
    end
end



-- This code posts a photo image to your Facebook Wall
local function postPhoto_onRelease(event)
    -- call the login method of the FB session object, passing in a handler
    -- to be called upon successful login.
    audio.play(button_click, {channel=2})
    utility.biggerSmaller(shareButton)

    if(utility.testConnection() == true) then
        fbCommand = POST_PHOTO
        enforceFacebookLogin()
    else 
        print("No Internet connection.")
        toast.show("No Internet connection.", { gravity="BottomCenter"} )
    end 
end


-- Request the current logged in user's info
local function getInfo_onRelease(event)
    -- call the login method of the FB session object, passing in a handler
    -- to be called upon successful login.
    if(utility.testConnection() == true) then
        fbCommand = GET_USER_INFO
        enforceFacebookLogin()
    else 
        print("No Internet connection.")
        toast.show("No Internet connection.", { gravity="BottomCenter"} )
    end  
end


-- This code posts a message to your Facebook Wall
local function postMsg_onRelease(event)
    -- call the login method of the FB session object, passing in a handler
    -- to be called upon successful login.
    if(utility.testConnection() == true) then
        fbCommand = POST_MSG
        enforceFacebookLogin()
    else 
        print("No Internet connection.")
        toast.show("No Internet connection.", { gravity="BottomCenter"} )
    end 
end


-- The following displays a Facebook dialog box for posting to your Facebook Wall
local function showFeedDialog_onRelease(event)
    -- call the login method of the FB session object, passing in a handler
    -- to be called upon successful login.
    audio.play(button_click, {channel=2})
    utility.biggerSmaller(shareButton)

    if(utility.testConnection() == true) then
        fbCommand = SHOW_FEED_DIALOG
        enforceFacebookLogin()
    else 
        print("No Internet connection.")
        toast.show("No Internet connection.", { gravity="BottomCenter"} )
    end
end


-- This displays a Facebook Dialog for posting a link with a photo to your Facebook Wall
local function shareLinkDialog_onRelease(event)
    -- call the login method of the FB session object, passing in a handler
    -- to be called upon successful login.
    audio.play(button_click, {channel=2})
    utility.biggerSmaller(shareButton)

    -- Test for internet connection before opening sharing dialog
    if(utility.testConnection() == true) then
        fbCommand = SHARE_LINK_DIALOG
        enforceFacebookLogin()  
    else 
        print("No Internet connection.")
        toast.show("No Internet connection.", { gravity="BottomCenter"} )
    end
    
end


-- This displays a Facebook Dialog for sending game invites to users
local function gameRequestDialog_onRelease(event)
    -- call the login method of the FB session object, passing in a handler
    -- to be called upon successful login.
    audio.play(button_click, {channel=2})
    utility.biggerSmaller(shareButton)

    -- Test for internet connection before opening sharing dialog
    if(utility.testConnection() == true) then
        -- Log an event
        flurryAnalytics.logEvent( "Menu selection", { location="Game Over", selection="Facebook Invite" } )

        fbCommand = GAME_REQUEST_DIALOG
        enforceFacebookLogin()
    else 
        print("No Internet connection.")
        toast.show("No Internet connection.", { gravity="BottomCenter"} )
    end
    
end


local function publishInstall_onRelease(event)
    if(utility.testConnection() == true) then
        fbCommand = PUBLISH_INSTALL
        facebook.publishInstall()
    else 
        print("No Internet connection.")
        toast.show("No Internet connection.", { gravity="BottomCenter"} )
    end
end


local function logOut_onRelease(event)
    -- call the login method of the FB session object, passing in a handler
    -- to be called upon successful login.
    if(utility.testConnection() == true) then
        fbCommand = LOGOUT
        facebook.logout()
    else 
        print("No Internet connection.")
        toast.show("No Internet connection.", { gravity="BottomCenter"} )
    end
end


--Capture latest stats for sharing to Facebook
local function captureScreenStats(group)
    screenshot = "quizhang_stats_" ..os.date("%Y%m%d%H%M%S") .. ".jpg"

    display.save( group, { filename=screenshot, baseDir=system.DocumentsDirectory, captureOffscreenArea=false, jpegQuality=0.8, backgroundColor={0,0,0,0} } )

    print("Screenshot saved")
end


-----------------------------------------------------------------------------------
-- Calculate the user's grade and the coins earned
-----------------------------------------------------------------------------------
local function calcGrade()
    -- Get value of coins from database
    coins.getCoins()

    grade = math.floor((ansCorrectCount / questionCount) * 100)

    -- Rating scheme
    if (grade >= 90 and grade <= 100) then
        gradeDisplay = "A+"
        coinsEarned = 15
        coinAmt = coinAmt + coinsEarned

        -- iOS
        local gradeAchievement = ""

        -- Android
        if(system.getInfo("platformName") == "Android") then
            gradeAchievement = "CgkI9Nv6n_8cEAIQBA"
        end

        --Unlock achievement - Reach a grade of A+
        gameNetwork.request( "unlockAchievement",
        {
            achievement = { identifier=gradeAchievement, percentComplete=100, showsCompletionBanner=true }
        } )

    elseif(grade >= 80 and grade < 90) then
        gradeDisplay = "A"
        coinsEarned = 10
        coinAmt = coinAmt + coinsEarned

    elseif(grade >= 75 and grade < 80) then
        gradeDisplay = "A-"
        coinsEarned = 9
        coinAmt = coinAmt + coinsEarned

    elseif(grade >= 70 and grade < 75) then
        gradeDisplay = "B+"
        coinsEarned = 8
        coinAmt = coinAmt + coinsEarned

    elseif(grade >= 65 and grade < 70) then
        gradeDisplay = "B"
        coinsEarned = 7
        coinAmt = coinAmt + coinsEarned

    elseif(grade >= 60 and grade < 65) then
        gradeDisplay = "B-"
        coinsEarned = 6
        coinAmt = coinAmt + coinsEarned

    elseif(grade >= 55 and grade < 60) then
        gradeDisplay = "C+"
        coinsEarned = 5
        coinAmt = coinAmt + coinsEarned

    elseif(grade >= 50 and grade < 55) then
        gradeDisplay = "C"
        coinsEarned = 4
        coinAmt = coinAmt + coinsEarned

    elseif(grade >= 45 and grade < 50) then
        gradeDisplay = "C-"
        coinsEarned = 3
        coinAmt = coinAmt + coinsEarned

    elseif(grade >= 40 and grade < 45) then
        gradeDisplay = "D"
        coinsEarned = 2
        coinAmt = coinAmt +  coinsEarned

    elseif(grade >= 0 and grade < 40) then
        gradeDisplay = "F"
        coinsEarned = 1
        coinAmt = coinAmt + coinsEarned
    end
end



-----------------------------------------------------------------------------------
-- Save game stats to Google Play Game Services Leaderboard
-----------------------------------------------------------------------------------
local function saveToLeaderboard()
	local function postScoreSubmit(event)
   		print("New leaderboard score saved")
   		return true
	end

    -- iOS
    local leaderboardID = ""

    -- Android
    if(system.getInfo( "platformName" ) == "Android") then
       leaderboardID = "CgkI9Nv6n_8cEAIQAA"
    end
    
    gameNetwork.request( "setHighScore",
    {
       localPlayerScore = { category=leaderboardID, value=tonumber(scoreNo) }, listener = postScoreSubmit
    } )
end




-----------------------------------------------------------------------------------
-- Save game stats to local database
-----------------------------------------------------------------------------------
local function saveStats()
    -- Set up the table if it doesn't exist
    local playStatsTableSetup = [[CREATE TABLE IF NOT EXISTS playstats (play_id INTEGER PRIMARY KEY, score, time_gained, time_lost, question_count, correct_answers, questions_skipped, incorrect_answers, grade, datetime)]]
    db:exec(playStatsTableSetup)

    -- Set up the table if it doesn't exist
    local coinsTableSetup = [[CREATE TABLE IF NOT EXISTS coins (amount INTEGER PRIMARY KEY)]]
    db:exec(coinsTableSetup)

    -- Insert data into playstats table
    local insertPlayStats = [[INSERT INTO playstats(play_id, score, time_gained, time_lost, question_count, correct_answers, correct_answer_ratio, incorrect_answers, questions_skipped, grade, datetime) VALUES (NULL, ']]
        ..tostring(scoreNo)..[[',']]
        ..tostring(totalTimeGained)..[[',']]
        ..tostring(totalTimeLost)..[[',']]
        ..tostring(questionCount)..[[',']]
        ..tostring(ansCorrectCount)..[[',']]
        ..tostring(correctAnswerRatio)..[[',']]
        ..tostring(ansIncorrectCount)..[[',']]
        ..tostring(quesSkipCount)..[[',']]
        ..tostring(grade)..[[',']]
        ..tostring(datetime)..[[')]]

    db:exec(insertPlayStats)


    -- Update coin column in database
    for trow in db:nrows("SELECT count(*) As count FROM coins") do
        coin_count = tonumber(trow.count)
    end

    -- If there is no value in 'amount' column, then insert, else udpate the value
    if(coin_count == 0) then
        local insertCoins = [[INSERT INTO coins(amount) VALUES(']] ..tostring(coinAmt) ..[[')]]
        db:exec(insertCoins)

    elseif(coin_count > 0) then
        local updateCoinsStmt = [[UPDATE coins SET amount = ]] ..tostring(coinAmt) ..[[]]
        db:exec(updateCoinsStmt)
    end


    -- Error message
    if db:errcode() then
        print(db:errcode(), db:errmsg())
    end
end



-- Switch to menu scene
local function gotoMenu(event)
    if(event.action == "clicked") then
        local i = event.index
        if(i == 1) then
            -- do nothing, dialog will simply dismiss
        elseif(i == 2) then
            gameRestart = true

            audio.stop(9)

            -- Close the database
            db:close()
            databaseConnected = false

            -- Reset stats to default
            gameOver = false
            scoreNo = 0
            secondsLeft = 0
            totalTimeGained = 0
            totalTimeLost = 0
            questionCount = 0
            ansCorrectCount = 0
            ansIncorrectCount = 0
            quesSkipCount = 0
            correctAnswers = 0
            grade = 0

            composer.removeScene( "scene_gameover" )
            composer.gotoScene( "scene_menu" ) 
        end
    end
end


-- Alert box to confirm switch to menu scene
local function onMenuTouch(event)
    audio.play(button_click, {channel=2})
    utility.biggerSmaller(menuBtn)

    -- Log an event
flurryAnalytics.logEvent( "Menu selection", { location="Game Over", selection="Menu mode" } )

    native.showAlert("Go to Menu", "Are you sure you want to return to the main menu?", { "No", "Yes" }, gotoMenu)

end


-- Return to the previous scene and prepare new game
local function playAgain(event)
    audio.play(button_click, {channel=2})
    utility.biggerSmaller(playAgainBtn)

    gameRestart = true

    -- Close the database
    db:close()
    databaseConnected = false

    -- Reset stats to default
    gameOver = false
    scoreNo = 0
    secondsLeft = 0
    totalTimeGained = 0
    totalTimeLost = 0
    questionCount = 0
    ansCorrectCount = 0
    ansIncorrectCount = 0
    quesSkipCount = 0
    correctAnswers = 0
    grade = 0

    -- Log an event
    flurryAnalytics.logEvent( "Menu selection", { location="Game Over", selection="Play Again" } )

    composer.removeScene( "scene_gameover" )
    local prevScene = composer.getSceneName( "previous" )
    composer.gotoScene( prevScene )

    return true
end


-- Share stats to other Apps (except Facebook)
local function onShareButtonReleased(event)
    audio.play(button_click, {channel=2})
    utility.biggerSmaller(shareBtn)

     -- Save screenshot
    captureScreenStats(screenshotGroup)

    -- Test for internet connection before opening sharing dialog
    if(utility.testConnection() == true) then
        local serviceName = event.target.id
        local isAvailable = native.canShowPopup("social", serviceName)

        -- Log an event
        flurryAnalytics.logEvent( "Menu selection", { location="Game Over", selection="Share Stats" } )
     
        -- If it is possible to show the popup
        if isAvailable then
            local listener = {}
            function listener:popup(event)
                print( "name(" .. event.name .. ") type(" .. event.type .. ") action(" .. tostring(event.action) .. ") limitReached(" .. tostring(event.limitReached) .. ")" )          
            end
     
            -- Show the popup
            native.showPopup( "social",
            {
                service = serviceName, -- The service key is ignored on Android.
                message = "I just reached a score of " .. scoreNo .. " on QuizHang!",
                listener = listener,
                image = 
                {
                    { filename = screenshot, baseDir = system.DocumentsDirectory },
                },
                url = 
                { 
                    "http://www.quizhang.com",
                }
            })
        else
            if isSimulator then
                native.showAlert( "Build for device", "This plugin is not supported on the Corona Simulator, please build for an iOS/Android device or the Xcode simulator", { "OK" } )
            else
                -- Popup isn't available.. Show error message
                native.showAlert( "Cannot send " .. serviceName .. " message.", "Please setup your " .. serviceName .. " account or check your network connection (on android this means that the package/app (ie Twitter) is not installed on the device)", { "OK" } )
            end
        end

    else 
        print("No Internet connection.")
        toast.show("No Internet connection.", { gravity="BottomCenter"} )
    end

    return true
end


-- Display the stats
local function setUpDisplay(group)
    -- Background
    local gameOverBg = display.newImageRect("images/gameover_background.png", 360, 480)
    gameOverBg.width = screenWidth
    gameOverBg.height = screenHeight
    gameOverBg.x = centerX
    gameOverBg.y = centerY
    group:insert(gameOverBg)

    -- Final score   
    local finalScoreTxt = display.newText("Your Score: " .. scoreNo, centerX, centerY - 75, "Arial Rounded MT Bold", 16 )
    group:insert(finalScoreTxt)

    -- Total time gained
    local timeGainedTxt = display.newText("Time gained: " .. totalTimeGained .. " seconds", centerX, centerY - 45, "Arial Rounded MT Bold", 16 )
    group:insert(timeGainedTxt)

    -- Total time lost
    local timeLostTxt = display.newText("Time lost: " .. totalTimeLost .. " seconds", centerX, centerY - 15, "Arial Rounded MT Bold", 16 )
    group:insert(timeLostTxt)

    -- Questions answered correctly out of questions reached
    local correctAnswersTxt = display.newText("Answered correctly: " .. correctAnswerRatio, centerX, centerY + 15, "Arial Rounded MT Bold", 16 )
    group:insert(correctAnswersTxt)

    -- Questions answered correctly out of questions reached
    local skippedQuestionsTxt = display.newText("Questions skipped: " .. quesSkipCount, centerX, centerY + 45, "Arial Rounded MT Bold", 16 )
    group:insert(skippedQuestionsTxt)

    -- Coins earned in play session
    local coinsEarnedTxt = display.newText("Coins earned: " .. coinsEarned, centerX, centerY + 75, "Arial Rounded MT Bold", 16 )
    group:insert(coinsEarnedTxt)

    -- Grade
    local gradeTxt = display.newText(gradeDisplay, centerX, centerY + 125, "Arial Rounded MT Bold", 60 )
    group:insert(gradeTxt)


    -- Facebook Share Button
    local facebookButton = widget.newButton
    {
        id = "facebook",
        x = centerX - 130,
        y = screenBottom - 70,
        defaultFile = "images/facebook_icon.png",
        width = 64,
        height = 64,
        onRelease = gameRequestDialog_onRelease,
    }
    group:insert(facebookButton)


    -- Share Button
    local shareButton = widget.newButton
    {
        id = "share",
        x = centerX - 50,
        y = screenBottom - 70,
        defaultFile = "images/share_icon.png",
        width = 64,
        height = 64,
        onRelease = onShareButtonReleased,
    }
    group:insert(shareButton)


    --Play Again Button
    local playAgainBtn = widget.newButton
    {
        id = "playagain_btn",
        x = centerX + 50, 
        y = screenBottom - 70,
        defaultFile = "images/play_icon.png",
        width = 64,
        height = 64,
        onRelease = playAgain
    }
    group:insert(playAgainBtn)
  

    -- Menu button
    local menuBtn = widget.newButton
    {
        id = "menu_btn",
        x = centerX + 130, 
        y = screenBottom - 70, 
        defaultFile = "images/menu_icon.png",
        width = 64,
        height = 64,
        onRelease = onMenuTouch
    }
    group:insert(menuBtn)

end


-- "scene:create()"
function scene:create( event )

    local sceneGroup = self.view

    -- Initialize the scene here.
    -- Example: add display objects to "sceneGroup", add touch listeners, etc.

    -- Save game stats
    calcGrade()
    saveToLeaderboard()
    saveStats()
    
    --Display scene elements
    setUpDisplay(sceneGroup)

end


-- "scene:show()"
function scene:show( event )

    local sceneGroup = self.view
    local phase = event.phase

    if ( phase == "will" ) then
        -- Called when the scene is still off screen (but is about to come on screen).
        -- Save screenshot of stats   
        print("game over scene")

    elseif ( phase == "did" ) then

        -- Called when the scene is now on screen.
        -- Insert code here to make the scene come alive.
        -- Example: start timers, begin animation, play audio, etc.

        screenshotGroup = sceneGroup

        -- Show ads
        local function displayAd()
            if(showAds == true) then
                -- Display admob interstitial ad
                ads.show("interstitial", {appId=interstitialAppID })
            else
                ads.hide()
            end
        end

        timer.performWithDelay( 6000, displayAd)

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

    display.remove(gameOverBg)

    display.remove(finalScoreTxt)    
    display.remove(timeGainedTxt)
    display.remove(timeLostTxt)
    display.remove(correctAnswersTxt)
    display.remove(skippedQuestionsTxt)
    display.remove(coinsEarnedTxt)
    display.remove(gradeTxt)

    display.remove(facebookButton)
    display.remove(shareButton)
    display.remove(playAgainBtn)
    display.remove(menuBtn)

    gameOverBg = nil

    finalScoreTxt = nil
    timeGainedTxt = nil
    timeLostTxt = nil
    correctAnswersTxt = nil
    skippedQuestionsTxt = nil
    coinsEarnedTxt = nil
    gradeTxt = nil

    facebookButton = nil
    shareButton = nil
    playAgainBtn = nil
    menuBtn = nil

    -- Stop main loop
    audio.stop(1)

    -- Only dispose audio references if user chooses NOT to play again
    if(gameRestart == false) then
        audio.dispose(button_click)  
        audio.dispose(question_right)
        audio.dispose(question_wrong)
        audio.dispose(question_skip)
        audio.dispose(special_question_right)
        audio.dispose(special_question_wrong)
        audio.dispose(consecutive_questions_right)
        audio.dispose(lever_turn)
        audio.dispose(time_running_out)
        audio.dispose(game_ends)
        audio.dispose(menu_loop)
        audio.dispose(play_loop)
        audio.dispose(update_complete)
        audio.dispose(garry_cry)
        audio.dispose(purchase_successful)
        audio.dispose(purchase_unsuccessful)
        audio.dispose(power_up)
    end

end


-- -------------------------------------------------------------------------------

-- Listener setup
scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )

-- -------------------------------------------------------------------------------

return scene
