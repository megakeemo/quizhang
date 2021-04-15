-----------------------------------------------------------------------------------------
-- QuizHang time module
-- Time will be dynamic, and will be added to or subtracted from based on correct/incorrect answers.
-----------------------------------------------------------------------------------------

local M = {}

local utility = require( "utility" )


-- Initialize time display. Time duration is set in individual game modes
function M.initTime()
    clockText.anchorX = 0
    clockText.anchorY = 0
    clockText.x = screenRight - 100
    clockText.y = screenBottom - 40
end


-- Update countdown timer
function M.updateTime()
    -- Decrement the number of seconds
    secondsLeft = secondsLeft - 1
    
    -- Time is tracked in seconds.  We need to convert it to minutes and seconds
    local minutes = math.floor( secondsLeft / 60 )
    local seconds = secondsLeft % 60
    
    -- Make it a string using string format.  
    local timeDisplay = string.format( "%02d:%02d", minutes, seconds )
    clockText.text = timeDisplay

    -- prevent time from going below 0:00, call destroy() function in quizmanager
    if(secondsLeft <= 0) then
    	audio.stop(7)

    	--Only consume item if it was purchased
    	if(LIFE_SAVER_PURCHASED == 1) then
    		-- this works because products is already included from quizmanager
    		products.activateLifeSaver()   
    		
    	else 
			secondsLeft = 0
			clockText.text = "0:00"
			gameOver = true
		end 
	end

    --Play special audio when time is below 6 seconds
    if(secondsLeft > 0 and secondsLeft <= 6) then
        audio.play(time_running_out, {channel=7, fadeIn=3000})

        if(secondsLeft > 6) then
            audio.stop(7)
        end
    end

    --Add achievement. Only valid for Endurance mode
    if (isTimeTrial ~= true) then
        if(secondsLeft >= 300) then
            -- iOS
            local timeAchievement = ""

            -- Android
            if(system.getInfo("platformName") == "Android") then
                timeAchievement = "CgkI9Nv6n_8cEAIQBQ"
            end

            --Unlock achievement - Gain 300 seconds
            gameNetwork.request( "unlockAchievement",
            {
                achievement = { identifier=timeAchievement, percentComplete=100, showsCompletionBanner=true }
            } )
        end
    end
end


-- Display and run the timer
function M.displayTime()
    M.initTime()
    --set to -1 so it loops forever
    countDownTimer = timer.performWithDelay( 1000, M.updateTime, -1 ) 
end


-- Add to the existing time
function M.addTime(amt)
	secondsLeft = secondsLeft + amt

    -- Stat to display on GameOver scene
    totalTimeGained = totalTimeGained + amt

    utility.makeDriftingText("+" .. amt, {yVal=-12, x=clockText.x+20, y=clockText.y-5, size=22, t=250})

end


-- Subtract from the existing time
function M.minusTime(amt)
	secondsLeft = secondsLeft - amt

    -- Stat to display on GameOver scene
    totalTimeLost = totalTimeLost + amt

    utility.makeDriftingText("-" .. amt, {yVal=-12, x=clockText.x+20, y=clockText.y-5, size=22, t=250})
end


-- Remove the object from memory
local function cleanup()
    clockText:removeSelf()
    clockText = nil
end

-- Cancel timer and end game when the time runs out
function M.destroy()
    secondsLeft = 0
    timer.cancel(countDownTimer)

    if(gameOver == true) then
        transition.to(clockText, {time=100, delay=250, y=screenBottom, oncomplete=cleanup})
        clockText.alpha = 0
    else
        clockText:removeSelf()
        clockText = nil
    end
end


return M