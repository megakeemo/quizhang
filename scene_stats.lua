-----------------------------------------------------------------------------------------
-- QuizHang Stats Mode
-- Display best of stats for a single game session
-- Display all time accumulated stats
-----------------------------------------------------------------------------------------

composer = require( "composer" )
local scene = composer.newScene()

local utility = require( "utility" )

-- -----------------------------------------------------------------------------------------------------------------
-- All code outside of the listener functions will only be executed ONCE unless "composer.removeScene()" is called.
-- -----------------------------------------------------------------------------------------------------------------

-- local forward references should go here
local highestScore
local mostTimeGained
local mostTimeLost
local highestQuestionCount
local mostCorrectAnswers
local mostIncorrectAnswers
local mostQuestionsSkipped
local highestGrade
local gradeDisplay

local totalScore
local totalTimeGained
local totalTimeLost
local totalCorrectAnswers
local totalIncorrectAnswers
local totalQuestionsSkipped

local achievementBtn
local leaderboardBtn



-- -------------------------------------------------------------------------------
-- Get playstats from the database
local function fetchStats()
    local statsStmt = "SELECT MAX(score) AS score, MAX(time_gained) AS time_gained, MAX(time_lost) AS time_lost, MAX(question_count) AS question_count, MAX(correct_answers) AS correct_answers, MAX(incorrect_answers) AS incorrect_answers, MAX(questions_skipped) AS questions_skipped, MAX(grade) AS grade FROM playstats"

    for row in db:nrows( statsStmt ) do
        highestScore = tostring(row.score)
        mostTimeGained = tostring(row.time_gained)
        mostTimeLost = tostring(row.time_lost)
        highestQuestionCount = tostring(row.question_count)
        mostCorrectAnswers = tostring(row.correct_answers)
        mostIncorrectAnswers = tostring(row.incorrect_answers)
        mostQuestionsSkipped = tostring(row.questions_skipped)
        highestGrade = tonumber(row.grade)

    end

    --Total stats
    local totalStatsStmt = "SELECT SUM(score) AS score, SUM(time_gained) AS time_gained, SUM(time_lost) AS time_lost, SUM(correct_answers) AS correct_answers, SUM(incorrect_answers) AS incorrect_answers, SUM(questions_skipped) AS questions_skipped FROM playstats"

    for row in db:nrows( totalStatsStmt ) do
        totalScore = tostring(row.score)
        totalTimeGained = tostring(row.time_gained)
        totalTimeLost = tostring(row.time_lost)
        totalCorrectAnswers = tostring(row.correct_answers)
        totalIncorrectAnswers = tostring(row.incorrect_answers)
        totalQuestionsSkipped = tostring(row.questions_skipped)

    end
end


--Go to previous scene
local function goBack(event)
    audio.play(button_click, {channel=2}) 
    utility.biggerSmaller(backBtn)

    -- Close the database
    db:close()
    databaseConnected = false

    composer.removeScene( "scene_stats" )
    local prevScene = composer.getSceneName( "previous" )
    composer.gotoScene( prevScene )

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


-- ScrollView listener
local function scrollListener(event)

    local phase = event.phase
    if ( phase == "began" ) then print( "Scroll view was touched" )
    elseif ( phase == "moved" ) then print( "Scroll view was moved" )
    elseif ( phase == "ended" ) then print( "Scroll view was released" )
    end

    -- In the event a scroll limit is reached...
    if ( event.limitReached ) then
        if ( event.direction == "up" ) then print( "Reached bottom limit" )
        elseif ( event.direction == "down" ) then print( "Reached top limit" )
        elseif ( event.direction == "left" ) then print( "Reached right limit" )
        elseif ( event.direction == "right" ) then print( "Reached left limit" )
        end
    end

    return true
end


-- Display the stats
local function setUpDisplay(group)
	-- Rating scheme
    if(highestGrade ~= nil) then
    	if(highestGrade >= 95 and highestGrade <= 100) then
    	    gradeDisplay = "A+"

    	elseif(highestGrade >= 80 and highestGrade < 95) then
    	    gradeDisplay = "A"

    	elseif(highestGrade >= 75 and highestGrade < 80) then
    	    gradeDisplay = "A-"

    	elseif(highestGrade >= 70 and highestGrade < 75) then
    	    gradeDisplay = "B+"

    	elseif(highestGrade >= 65 and highestGrade < 70) then
    	    gradeDisplay = "B"

    	elseif(highestGrade >= 60 and highestGrade < 65) then
    	    gradeDisplay = "B-"

    	elseif(highestGrade >= 55 and highestGrade < 60) then
    	    gradeDisplay = "C+"

    	elseif(highestGrade >= 50 and highestGrade < 55) then
    	    gradeDisplay = "C"

    	elseif(highestGrade >= 45 and highestGrade < 50) then
    	    gradeDisplay = "C-"

    	elseif(highestGrade >= 40 and highestGrade < 45) then
    	    gradeDisplay = "D"

    	elseif(highestGrade >= 0 and highestGrade < 40) then
    	    gradeDisplay = "F"
    	end
    else
        gradeDisplay = "nil"
    end

    -- Background
    local bg = display.newImageRect("images/rapsheet_bg.png", 360, 480)
    bg.width = screenWidth
    bg.height = screenHeight
    bg.x = centerX
    bg.y = centerY
    group:insert(bg)

   
    -- Scrollview
    local scrollView = widget.newScrollView(
        {
            top = screenTop,
            left = screenLeft,
            width = screenWidth,
            height = screenHeight,
            scrollWidth = screenWidth,
            scrollHeight = screenHeight,
            topPadding = 80,
            hideBackground = true,
            horizontalScrollDisabled = true,
            listener = scrollListener
        }
    )

    --Scene Title
    local rapSheetBtn = display.newImage("images/rapsheet_btn.png")
    rapSheetBtn.x = centerX
    rapSheetBtn.y = screenTop + 40
    utility.fitImage(rapSheetBtn, 200, 200, false)
    scrollView:insert(rapSheetBtn)
    

    -- Highest score gained in a single playthrough
    local highestScoreTxt = display.newText("Highest Score: " .. highestScore, 275, centerY - 205, "Arial Rounded MT Bold", 17, "left" )
    highestScoreTxt.anchorX = 10
    scrollView:insert(highestScoreTxt)

    -- Max time gained in a single playthrough
    local timeGainedTxt = display.newText("Most Time Gained: " .. mostTimeGained .. " seconds", 275, centerY - 175, "Arial Rounded MT Bold", 17 )
    timeGainedTxt.anchorX = 10
    scrollView:insert(timeGainedTxt)

    -- Max time gained in a single playthrough
    local timeLostTxt = display.newText("Most Time Lost: " .. mostTimeLost .. " seconds", 275, centerY - 145, "Arial Rounded MT Bold", 17 )
    timeLostTxt.anchorX = 10
    scrollView:insert(timeLostTxt)

    -- Max question count gained in a single playthrough
    local questionCountTxt = display.newText("Highest Question Reached: " .. highestQuestionCount, 275, centerY - 115, "Arial Rounded MT Bold", 17 )
    questionCountTxt.anchorX = 10
    scrollView:insert(questionCountTxt)

    -- Max correct answers in a single playthrough
    local correctAnswersTxt = display.newText("Most Correct Answers: " .. mostCorrectAnswers, 275, centerY - 85, "Arial Rounded MT Bold", 17 )
    correctAnswersTxt.anchorX = 10
    scrollView:insert(correctAnswersTxt)

    -- Max incorrect answers in a single playthrough
    local incorrectAnswersTxt = display.newText("Most Incorrect Answers: " .. mostIncorrectAnswers, 275, centerY - 55, "Arial Rounded MT Bold", 17 )
    incorrectAnswersTxt.anchorX = 10
    scrollView:insert(incorrectAnswersTxt)

    -- Max questions skipped in a single playthrough
    local skippedQuestionsTxt = display.newText("Most Questions Skipped: " .. mostQuestionsSkipped, 275, centerY - 25, "Arial Rounded MT Bold", 17 )
    skippedQuestionsTxt.anchorX = 10
    scrollView:insert(skippedQuestionsTxt)

    -- Highest grade achieved in a single playthru
    local gradeTxt = display.newText("Highest Grade: " .. gradeDisplay, 275, centerY + 5, "Arial Rounded MT Bold", 17 )
    gradeTxt.anchorX = 10
    scrollView:insert(gradeTxt)



    -- All time Total Score
    local totalScoreTxt = display.newText("Total Score: " .. totalScore, 275, centerY + 65, "Arial Rounded MT Bold", 17 )
    totalScoreTxt.anchorX = 10
    scrollView:insert(totalScoreTxt)

    -- All time Time Gained
    local totalTimeGainedTxt = display.newText("Total Time Gained: " .. totalTimeGained, 275, centerY + 95, "Arial Rounded MT Bold", 17 )
    totalTimeGainedTxt.anchorX = 10
    scrollView:insert(totalTimeGainedTxt)

    -- All time Time Lost
    local totalTimeLostTxt = display.newText("Total Time Lost: " .. totalTimeLost, 275, centerY + 125, "Arial Rounded MT Bold", 17 )
    totalTimeLostTxt.anchorX = 10
    scrollView:insert(totalTimeLostTxt)

    -- All time Correct Answers
    local totalCorrectAnswersTxt = display.newText("Total Correct Answers: " .. totalCorrectAnswers, 275, centerY + 155, "Arial Rounded MT Bold", 17 )
    totalCorrectAnswersTxt.anchorX = 10
    scrollView:insert(totalCorrectAnswersTxt)

    -- All time Incorrect Answers
    local totalIncorrectAnswersTxt = display.newText("Total Incorrect Answers: " .. totalIncorrectAnswers, 275, centerY + 185, "Arial Rounded MT Bold", 17 )
    totalIncorrectAnswersTxt.anchorX = 10
    scrollView:insert(totalIncorrectAnswersTxt)

    -- All time Questions Skipped
    local totalQuestionsSkippedTxt = display.newText("Total Questions Skipped: " .. totalQuestionsSkipped, 275, centerY + 215, "Arial Rounded MT Bold", 17 )
    totalQuestionsSkippedTxt.anchorX = 10
    scrollView:insert(totalQuestionsSkippedTxt)


    -- Add scrollView to sceneGroup
    group:insert(scrollView)



    -- Back Button
    local backBtn = widget.newButton
    {
        id = "back_btn",
        label = "BACK",
        labelColor = { default={ 1, 1, 1 }, over={ 1, 1, 1 } },
        font = "Arial Rounded MT Bold",
        fontSize = 22,
        emboss = false,
        x = screenLeft + 80, 
        y = screenBottom - 80,
        shape = "roundedRect",
        fillColor = { default={ 0.97, 0.76, 0.22 }, over={ 0.8, 0.23, 0.02 } },
        srokeColor = { default={ 0, 0, 0 }, over={ 0.4, 0.1, 0.2 } },
        width = 120,  
        onRelease = goBack
    }
    group:insert(backBtn)


    --button for Google Play Game Services Achievements
    achievementBtn = widget.newButton
    {
        id = "achievement_btn",
        x = screenRight - 50, 
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
        x = screenRight - 120, 
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

    --Connect to database
    if(databaseConnected == false) then
        connectToDatabase()
    end

    --Get stats from database and display them on screen
    fetchStats()

    --Display scene elements
    setUpDisplay(sceneGroup)
end


-- "scene:show()"
function scene:show( event )

    local sceneGroup = self.view
    local phase = event.phase

    if ( phase == "will" ) then
        -- Called when the scene is still off screen (but is about to come on screen).
        print("high scores scene")
    elseif ( phase == "did" ) then

        -- Called when the scene is now on screen.
        -- Insert code here to make the scene come alive.
        -- Example: start timers, begin animation, play audio, etc.

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

    display.remove(scrollView)
    display.remove(bg)
    display.remove(rapSheetBtn)
    display.remove(highestScoreTxt)
    display.remove(timeGainedTxt)
    display.remove(timeLostTxt)
    display.remove(questionCountTxt)
    display.remove(correctAnswersTxt)
    display.remove(incorrectAnswersTxt)
    display.remove(skippedQuestionsTxt)
    display.remove(gradeTxt)

    display.remove(totalScoreTxt)
    display.remove(totalTimeGainedTxt)
    display.remove(totalTimeLostTxt)
    display.remove(totalCorrectAnswers)
    display.remove(totalIncorrectAnswers)
    display.remove(totalQuestionsSkipped)

    display.remove(backBtn)
    display.remove(achievementBtn)
    display.remove(leaderboardBtn)

    scrollView = nil
    bg = nil
    rapSheetBtn = nil
    highestScoreTxt = nil
    timeGainedTxt = nil
    timeLostTxt = nil
    questionCountTxt = nil
    correctAnswersTxt = nil
    incorrectAnswersTxt = nil
    skippedQuestionsTxt = nil
    gradeTxt = nil

    totalScoreTxt = nil
    totalTimeGainedTxt = nil
    totalTimeLostTxt = nil
    totalCorrectAnswersTxt = nil
    totalIncorrectAnswersTxt = nil
    totalQuestionsSkipped = nil

    backBtn = nil
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
