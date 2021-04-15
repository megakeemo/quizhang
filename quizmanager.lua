-----------------------------------------------------------------------------------------
-- QuizHang QuizManager
-- This is where all the quiz logic takes place
-- User will be presented with a series of random multiple choice questions.
-- Time will start at 60 seconds.
-- Time will be dynamic, and will be added to or subtracted from based on correct/incorrect answers.
-- Each correct answer will add to the score.
-- Game ends when time runs out.
-- Highscore will be saved to local and online leaderboard
-----------------------------------------------------------------------------------------

local M = {}

-- Include time and score modules. Need arithmetic functions
score = require( "mod_score" )
time = require( "mod_time" )

local utility = require( "utility" )

-----------------------------------------------------------------------------------------------

-- Variables to store database data
local quizID
local quizCategory
local quizQuestion
local quizOption1
local quizOption2
local quizOption3
local quizOption4
local quizAnswer

-- Variable to get ID of random quiz from database 
-- Variable to hold an an array of quiz IDs
local quizRandom
local quizAr = {}

-- Quiz components
local categoryTxt
local questionTxt
local selectOption1
local selectOption2
local selectOption3
local selectOption4
local skipBtn
local timeFreezeBtn
local selectedAnswer
local isSpecialQuestion = false
local isSpecialCount = 0;


--Keep track of the number of questions being pulled from database
local quizCnt
local maxQuizzes

-- Seeds the random number generator
math.randomseed(os.time())

-----------------------------------------------------------------------------------------------
-- Endlessly running game 'tick' to keep track of game over conditions. 
-- Game ends when the time reaches 0 or when there are no more questions. 
-- Switch to GameOver scene
local function gameTick(event)
    if(event.name == "enterFrame") then
        if(gameOver == true) then
            M.endGame()

            if(quizCnt > maxQuizzes) then
                print("Oh oh! There are no more questions available.")
                toast.show("Game Over! There are no more questions available.", { gravity="BottomCenter"} )
            else
                print("Time ran out! Game has ended!")
            end
        end

        -- In Game Purchase Function - Skip up to 50 questions with no penalties. 
        if(SKIP_MASTER_PURCHASED == 1) then
        	if(quesSkipCount >= 50) then
	            print("Too many questions skipped.")
	            toast.show("Game Over! Too many questions skipped.", { gravity="BottomCenter"} )
	            M.endGame()
	        end
        end

        -- End game if more than 10 questions are skipped
        if(quesSkipCount >= 10 and SKIP_MASTER_PURCHASED == 0) then
            print("Too many questions skipped.")
            toast.show("Game Over! Too many questions skipped.", { gravity="BottomCenter"} )
            M.endGame()
        end
    end 

    return true
end

-- Disable quiz components - prevents them from being touched
function M.pauseQuiz()
    skipBtn:setEnabled(false)
    selectOption1:setEnabled(false)
    selectOption2:setEnabled(false)
    selectOption3:setEnabled(false)
    selectOption4:setEnabled(false)
end

-- Reenable touch on quiz components
function M.resumeQuiz()
    skipBtn:setEnabled(true)
    selectOption1:setEnabled(true)
    selectOption2:setEnabled(true)
    selectOption3:setEnabled(true)
    selectOption4:setEnabled(true)

end



-- Get the total number of quizzes(rows) from the database
local function getTotalQuizzes()
    for trow in db:nrows("SELECT count(*) As count FROM quizzes") do
        maxQuizzes = tonumber(trow.count)
        return maxQuizzes
    end
end


-- Initializes the array.
-- The purpose of this array is to select a random, non repeating number, from 1 to the total number of quizzes in the database. This random number will then be used in the SQL SELECT statement, in order to retrieve random quizzes from the database each time.
local function initArray(min,max)
	for i=min,max,1 do
		quizAr[i] = i
	end
end


-- Fisher-Yates shuffle algorithm. 
-- Randomizes the elements of an array with great optimization
local function shuffle(arr)
   local n = #arr -- table length
   for i=1, n-1 do
      local r = math.random(i,n)
      arr[i], arr[r] = arr[r], arr[i]
   end

   return arr
end


-- Gets a random element from the table/array
local function getRandomNumber()
	local numQuizzes = shuffle(quizAr)
	quizRandom = table.remove(numQuizzes)
end


-- Clear text data for quiz components
local function clearComponents()
    categoryTxt.text = null
    questionTxt.text = null

    selectOption1:removeSelf()
    selectOption2:removeSelf()
    selectOption3:removeSelf()
    selectOption4:removeSelf()
end


-- Remove all on screen components and remove event listeners
function M.destroy()
    clearComponents()

    categoryTxt:removeSelf()
    questionTxt:removeSelf()
    skipBtn:removeSelf()
    
    questionTxt = nil
    selectOption1 = nil
    selectOption2 = nil
    selectOption3 = nil
    selectOption4 = nil

    categoryTxt = nil
    skipBtn = nil
    

    if(TIME_FREEZE_PURCHASED == 1) then
        timeFreezeBtn:removeSelf()
        timeFreezeBtn = nil
    end

    time.destroy()
    score.destroy()

    Runtime:removeEventListener( "enterFrame", gameTick )
end

-- Save stats and switch to the Game Over scene
function M.endGame()
    audio.play(game_ends, {channel=31})
    audio.play(lever_turn, {channel=32})
    
    -- Remove display objects and event listenerss
    M.destroy()

    audio.play(garry_cry, {channel=16})

    -- Play hanging animation
    utility.swapSheet(executioner, "executioner_act", 0 )
    -- utility.swapSheet(trapdoor, "trapdoor_open", 300 )
    -- utility.swapSheet(garry, "garry_hanging1", 100 )
    -- utility.swapSheet(garry, "garry_hanging2", 500 )
    -- utility.swapSheet(garry, "garry_hanging3", 550 )
    
    -- Remove the current play scene and switch the game over mode
    local function gotoGameOver()
        local currScene = composer.getSceneName( "current" )
        composer.removeScene( currScene )
        composer.gotoScene( "scene_gameover" )
    end


    -- Go to game over scene after animation has been played
    timer.performWithDelay( 350, gotoGameOver )    
end


--Skips to a next random question on button press
local function skipQuestion(event)
    audio.play(question_skip, {duration=300, channel=30})
    quesSkipCount = quesSkipCount + 1

    if (isSpecialQuestion == true) then
        clearComponents()
        getRandomNumber()
        fetchData()
        
    else
    	-- In Game Purchase Function - Skip up to 50 questions with no penalties. 
        if(SKIP_MASTER_PURCHASED == 1) then
            -- do nothing
        else 
            time.minusTime(5)
        end
        
        clearComponents()
        getRandomNumber()
        fetchData()
    end

    utility.biggerSmaller(event.target)
    return true
end


-- Skips question on game resume
-- This is to prevent people from pausing the game and googling answers
function M.skipOnResume()
    quesSkipCount = quesSkipCount + 1

    time.minusTime(0)
    clearComponents()
    getRandomNumber()
    fetchData()

end



-- Called when a choice is selected.
-- Determines if choice is correct or not
local function onChoiceSelect(event)
	local choice = event.target
	print("Selected choice: "..choice.selectedItem)

    -- IF ANSWER IS CORRECT
	if (quizAnswer == choice.selectedItem) then
        ansCorrectCount = ansCorrectCount + 1
        consecutiveCorrectAnswers = consecutiveCorrectAnswers + 1
        consecutiveIncorrectAnswers = 0 --reset

        -- iOS
        local correctCountAchievement = ""

        -- Android
        if(system.getInfo("platformName") == "Android") then
            correctCountAchievement = "CgkI9Nv6n_8cEAIQAg"
        end

        --Unlock achievement - Answer more than 50 Questions correctly
        if(ansCorrectCount >= 50) then
            gameNetwork.request( "unlockAchievement",
            {
                achievement = { identifier=correctCountAchievement, percentComplete=100, showsCompletionBanner=true }
            } )
        end
        

        -- Massive point and score increase if Special Question is answered correctly
        if (isSpecialQuestion == true) then
            -- Score multiplier of 4 when the 5th consecutive correct answer is a special question
            if (consecutiveCorrectAnswers == 5) then
                audio.play(consecutive_questions_right, {channel=27})
                score.multiplyScore(4)

            -- Score multiplier of 5 when the 15th consecutive correct answer is a special question
            elseif (consecutiveCorrectAnswers == 15) then
                audio.play(consecutive_questions_right, {channel=27})
                score.multiplyScore(5)

            -- Regular bonus for answering Special Question correctly
            else
                audio.play(special_question_right, {channel=29})
                score.addScore(50)
            end

            -- There are no time additions in Time Trial mode
            -- There are no time additions when Time Freeze is activated
            if (isTimeTrial ~= true) then
                if(TIME_FREEZE_ACTIVATED == true) then
                    -- do nothing 
                else
                    time.addTime(25)
                end
            end

        -- Score multiplier of 2 when 5 questions are answered correctly
        elseif (consecutiveCorrectAnswers == 5) then
            audio.play(consecutive_questions_right, {channel=27})
            score.multiplyScore(2)

            -- There are no time additions in Time Trial mode
            -- There are no time additions when Time Freeze is activated
            if (isTimeTrial ~= true) then
                if(TIME_FREEZE_ACTIVATED == true) then
                    -- do nothing 
                else
                    time.addTime(25)
                end
            end
            

        -- Score multiplier of 3 when 15 questions are answered correctly
        elseif (consecutiveCorrectAnswers == 15) then
            audio.play(consecutive_questions_right, {channel=27})
            score.multiplyScore(3)

            -- There are no time additions in Time Trial mode
            -- There are no time additions when Time Freeze is activated
            if (isTimeTrial ~= true) then
                if(TIME_FREEZE_ACTIVATED == true) then
                    -- do nothing 
                else
                    time.addTime(50)
                end
            end

            -- iOS
            local consecutiveAchievement = ""

            -- Android
            if(system.getInfo("platformName") == "Android") then
                consecutiveAchievement = "CgkI9Nv6n_8cEAIQAw"
            end

            --Unlock Achievement Answer 15 Consecutive Questions Correctly
            gameNetwork.request( "unlockAchievement",
            {
                achievement = { identifier=consecutiveAchievement, percentComplete=100, showsCompletionBanner=true }
            } )

            consecutiveCorrectAnswers = 0 --reset  


        -- If not a special question aka a regular question
        else
            audio.play(question_right, {duration=700, channel=28})
            score.addScore(5)

            -- There are no time additions in Time Trial mode
            -- There are no time additions when Time Freeze is activated
            if (isTimeTrial ~= true) then
                if(TIME_FREEZE_ACTIVATED == true) then
                    -- do nothing 
                else
                    time.addTime(5)
                end
            end
        end
        
        
        print("Questions answered correctly: "..ansCorrectCount)
        print("Questions answered incorrectly: "..ansIncorrectCount)
    

        -- Cleanup and prepare next question
		clearComponents()
		getRandomNumber()
		fetchData()
      
    

    -- IF ANSWER IS INCORRECT
    elseif (quizAnswer ~= choice.selectedItem) then
        ansIncorrectCount = ansIncorrectCount + 1
        consecutiveIncorrectAnswers = consecutiveIncorrectAnswers + 1
        consecutiveCorrectAnswers = 0 --reset
        
        
        -- Massive time loss if Special Question is answered incorrectly
        -- Can be skipped without penalty
        if (isSpecialQuestion == true) then
            audio.play(special_question_wrong, {channel=29})
            score.minusScore(50)

            -- There are no time deductions in Time Trial mode
            -- There are no time deductions when Time Freeze is activated
            if (isTimeTrial ~= true) then
                if(TIME_FREEZE_ACTIVATED == true) then
                    -- do nothing 
                else
                    time.minusTime(30)
                end
            end

        --Score and time subtraction when 5 questions are answered incorrectly
        elseif (consecutiveIncorrectAnswers == 5) then
            audio.play(special_question_wrong, {channel=27})
            score.minusScore(15)
            
            -- There are no time deductions in Time Trial mode
            -- There are no time deductions when Time Freeze is activated
            if (isTimeTrial ~= true) then
                if(TIME_FREEZE_ACTIVATED == true) then
                    -- do nothing 
                else
                     time.minusTime(30)
                end
            end

            consecutiveIncorrectAnswers = 0 --reset
        

        -- If not a special question aka a regular question
        else
            audio.play(question_wrong, {duration=500, channel=24})
            score.minusScore(5)

            -- There are no time deductions in Time Trial mode
            -- There are no time deductions when Time Freeze is activated
            if (isTimeTrial ~= true) then
                if(TIME_FREEZE_ACTIVATED == true) then
                    -- do nothing 
                else
                     time.minusTime(5)
                end
            end 
        end

        
        print("Questions answered correctly: "..ansCorrectCount)
        print("Questions answered incorrectly: "..ansIncorrectCount)

        -- Cleanup and prepare next question
        clearComponents()
        getRandomNumber()
        fetchData()

    end

    return true
end


-- Display quiz components
local function setupQuiz()
    -- Increment question count total each time the function is called
    questionCount = questionCount + 1

    -- Special question randomizer
    if (isSpecialCount <= 5 and quizRandom == math.floor((math.random() * maxQuizzes) + 0)) then
        isSpecialQuestion = true;
        isSpecialCount = isSpecialCount + 1;
        
    else
        isSpecialQuestion = false;
    end

    -- Category
    categoryTxt = display.newText( quizCategory, centerX, screenTop + 15, "Arial Rounded MT Bold", 26 )

    -- Question options
    local questionTxtOptions = 
    {
       text = quizQuestion,
       x = centerX,
       y = screenTop + 85,
       width = 300,
       height = 100,
       font = "Arial Rounded MT Bold",
       fontSize = 20,
       align = "center"
    }

    -- Actual question
    questionTxt = display.newText( questionTxtOptions )

    -- Change color when it's a Special Question
    if (isSpecialQuestion) then 
        questionTxt:setFillColor(1, 0.2, 0.2 )      
    end

    -- Choice 1
    selectOption1 = widget.newButton
    {
        id = "quiz_option1",
        label = quizOption1,
        labelColor = { default={ 1, 1, 1 }, over={ 1, 1, 1 } },
        font = "Arial Rounded MT Bold",
        fontSize = 15,
        emboss = false,
        x = screenLeft + 90, 
        y = screenTop + 160,
        shape = "roundedRect",
        fillColor = { default={ 0.97, 0.76, 0.22 }, over={ 0.8, 0.23, 0.02 } },
        srokeColor = { default={ 0, 0, 0 }, over={ 0.4, 0.1, 0.2 } },
        width = 170,  
        onRelease = onChoiceSelect
    }
    selectOption1.selectedItem = quizOption1

    -- Choice 2
    selectOption2 = widget.newButton
    {
        id = "quiz_option2",
        label = quizOption2,
        labelColor = { default={ 1, 1, 1 }, over={ 1, 1, 1 } },
        font = "Arial Rounded MT Bold",
        fontSize = 15,
        emboss = false,
        x = screenRight - 90, 
        y = screenTop + 160,
        shape = "roundedRect",
        fillColor = { default={ 0.97, 0.76, 0.22 }, over={ 0.8, 0.23, 0.02 } },
        srokeColor = { default={ 0, 0, 0 }, over={ 0.4, 0.1, 0.2 } },
        width = 170,  
        onRelease = onChoiceSelect
    }
    selectOption2.selectedItem = quizOption2

    -- Choice 3
    selectOption3 = widget.newButton
    {
        id = "quiz_option3",
        label = quizOption3,
        labelColor = { default={ 1, 1, 1 }, over={ 1, 1, 1 } },
        font = "Arial Rounded MT Bold",
        fontSize = 15,
        emboss = false,
        x = screenLeft + 90, 
        y = screenTop + 220,
        shape = "roundedRect",
        fillColor = { default={ 0.97, 0.76, 0.22 }, over={ 0.8, 0.23, 0.02 } },
        srokeColor = { default={ 0, 0, 0 }, over={ 0.4, 0.1, 0.2 } },
        width = 170,  
        onRelease = onChoiceSelect
    }
    selectOption3.selectedItem = quizOption3

    -- Choice 4
    selectOption4 = widget.newButton
    {
        id = "quiz_option4",
        label = quizOption4,
        labelColor = { default={ 1, 1, 1 }, over={ 1, 1, 1 } },
        font = "Arial Rounded MT Bold",
        fontSize = 15,
        emboss = false,
        x = screenRight - 90, 
        y = screenTop + 220,
        shape = "roundedRect",
        fillColor = { default={ 0.97, 0.76, 0.22 }, over={ 0.8, 0.23, 0.02 } },
        srokeColor = { default={ 1, 0, 1 }, over={ 0.4, 0.1, 0.2 } },
        strokeWidth = 10,
        width = 170,  
        onRelease = onChoiceSelect
    }
    selectOption4.selectedItem = quizOption4

    print("Total Number of Questions: "..questionCount)
end


-- Get quiz data from the database
function fetchData()
    -- If there are no more questions then end game
    if (quizCnt > maxQuizzes) then
        gameOver = true
         
    -- Business as usual
    else
    	local quizSelectStmt = "SELECT * FROM quizzes WHERE quiz_id = ".. tostring(quizRandom)..""

    	for row in db:nrows( quizSelectStmt ) do
    		quizID = tostring(row.quiz_id)
    		quizCategory = tostring(row.category)
    		quizQuestion = tostring(row.question)
    		quizOption1 = tostring(row.option1)
    		quizOption2 = tostring(row.option2)
    		quizOption3 = tostring(row.option3)
    		quizOption4 = tostring(row.option4)
    		quizAnswer = tostring(row.answer)

            quizCnt = quizCnt + 1
    	end

        -- Display the quiz
        setupQuiz()
    end
end


-- Connect to the QuizHang database
-- Get the total number of quizzes from the database
-- Create an array and insert all quiz IDs into it
-- Gets a random quiz ID from the array
-- Get the quiz and all its attributes based on the random ID
function M.quizManager()
    --Reset counters (especially necessary when returning from GameOver scene )
    quizCnt = 1
    consecutiveCorrectAnswers = 0
    consecutiveIncorrectAnswers = 0

    scoreNo = 0
    totalTimeGained = 0
    totalTimeLost = 0
    questionCount = 0
    ansCorrectCount = 0
    ansIncorrectCount = 0
    quesSkipCount = 0

    -- Ready the game
    if(databaseConnected == false) then
      connectToDatabase()
    end

    getTotalQuizzes()
	initArray(1,maxQuizzes)
	getRandomNumber()
    fetchData()

    -- Get details for in app purchases
    products.getItemLifeSaver()
    products.getItemTimePlus()
    products.getItemTimeFreeze()
    products.getItemSkipMaster()

    -- Skip Button
    skipBtn = widget.newButton
    {
        id = "skip_btn",
        x = screenLeft + 70, 
        y = screenBottom - 135, 
        defaultFile = "images/skipbtn.png",
        width = 80,
        height = 66,
        onPress = skipQuestion
    }

    local function onTimeFreezeTouch(event)
        products.activateTimeFreeze(countDownTimer)
        timeFreezeBtn.alpha = 0

        return true
    end

    -- Display Time Freeze button if it is purchased
    if(TIME_FREEZE_PURCHASED == 1) then
        -- Time Freeze Button
        timeFreezeBtn = widget.newButton
        {
            id = "time_freeze_btn",
            x = screenLeft + 15,
            y = screenTop + 17,
            defaultFile = "images/time_freeze_btn.png",
            width = 25,
            height = 25,
            onPress = onTimeFreezeTouch
        }

    end

     --Only consume item if it was purchased
    if(TIME_PLUS_PURCHASED == 1) then
        timer.performWithDelay(1000, products.activateTimePlus)
    end


    -- Interal game clock. Keeps track of when time reaches 0 to switch to Game Over scene
    Runtime:addEventListener( "enterFrame", gameTick )
 
end


return M