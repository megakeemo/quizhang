-----------------------------------------------------------------------------------------
-- QuizHang score module
-- Score will be dynamic, and will be added to or subtracted from based on correct/incorrect answers.

-- Score value will be global and will be saved to the device and leaderboard for later retreival

-- Functions:
--  1. AddScore
--  2. MinusScore
--  3. MultiplyScore
-----------------------------------------------------------------------------------------

local M = {}

local utility = require( "utility" )

local scoreTxt

-- Set up the score display
function M.displayScore()
	scoreTxt = display.newText( "0 pts", 0, 0, "PoetsenOne", 32 )
	scoreTxt.anchorX = 0
	scoreTxt.anchorY = 0
	scoreTxt.x = screenLeft + 20
	scoreTxt.y = screenBottom - 40

end


-- Add to the existing score value
function M.addScore(amt)
	scoreNo = scoreNo + amt
	scoreTxt.text = scoreNo .. " pts"
	utility.makeDriftingText("+" .. amt, {yVal=-12, x=scoreTxt.x+20, y=scoreTxt.y-5, size=22, t=250})


	--Unlock Achievement - Reach 500 points
    if(scoreNo >= 500 and scoreNo < 1000) then
        -- iOS
        local score500Achievement = ""

        -- Android
        if(system.getInfo("platformName") == "Android") then
            score500Achievement = "CgkI9Nv6n_8cEAIQAQ"
        end

        gameNetwork.request( "unlockAchievement",
        {
            achievement = { identifier=score500Achievement, percentComplete=100, showsCompletionBanner=true }
        } )

    --Unlock Achievement - Reach 1000 points
    elseif(scoreNo >= 1000 and scoreNo < 5000) then
         -- iOS
        local score1000Achievement = ""

        -- Android
        if(system.getInfo("platformName") == "Android") then
            score1000Achievement = "CgkI9Nv6n_8cEAIQBw"
        end

        gameNetwork.request( "unlockAchievement",
        {
            achievement = { identifier=score1000Achievement, percentComplete=100, showsCompletionBanner=true }
        } )

    --Unlock Achievement - Reach 5000 points
    elseif(scoreNo >= 5000 and scoreNo < 15000) then
        -- iOS
        local score5000Achievement = ""

        -- Android
        if(system.getInfo("platformName") == "Android") then
            score5000Achievement = "CgkI9Nv6n_8cEAIQCA"
        end

        gameNetwork.request( "unlockAchievement",
        {
            achievement = { identifier=score5000Achievement, percentComplete=100, showsCompletionBanner=true }
        } )

    --Unlock Achievement - Reach 15000 points
    elseif(scoreNo >= 15000 and scoreNo < 30000) then
        -- iOS
        local score15000Achievement = ""

        -- Android
        if(system.getInfo("platformName") == "Android") then
            score15000Achievement = "CgkI9Nv6n_8cEAIQCQ"
        end

        gameNetwork.request( "unlockAchievement",
        {
            achievement = { identifier=score15000Achievement, percentComplete=100, showsCompletionBanner=true }
        } )

    --Unlock Achievement - Reach 30000 points
    elseif(scoreNo >= 30000 and scoreNo < 50000) then
        -- iOS
        local score30000Achievement = ""

        -- Android
        if(system.getInfo("platformName") == "Android") then
            score30000Achievement = "CgkI9Nv6n_8cEAIQCg"
        end

        gameNetwork.request( "unlockAchievement",
        {
            achievement = { identifier=score30000Achievement, percentComplete=100, showsCompletionBanner=true }
        } )

    --Unlock Achievement - Reach 50000 points
    elseif(scoreNo >= 50000) then
        -- iOS
        local score50000Achievement = ""

        -- Android
        if(system.getInfo("platformName") == "Android") then
            score50000Achievement = "CgkI9Nv6n_8cEAIQCw"
        end

        gameNetwork.request( "unlockAchievement",
        {
            achievement = { identifier=score50000Achievement, percentComplete=100, showsCompletionBanner=true }
        } )
    end
end


-- Subtract from the existing score value
function M.minusScore(amt)
	scoreNo = scoreNo - amt
	scoreTxt.text = scoreNo .. " pts"
	utility.makeDriftingText("-" .. amt, {yVal=-12, x=scoreTxt.x+20, y=scoreTxt.y-5, size=22, t=250})

	if scoreNo <= 0 then
		scoreNo = 0
		scoreTxt.text = "0 pts"
	end
end


-- Multiply the existing score value by a factor
function M.multiplyScore(amt)
	scoreNo = scoreNo * amt
	scoreTxt.text = scoreNo .. " pts"
	utility.makeDriftingText("x" .. amt, {yVal=-12, x=scoreTxt.x+20, y=scoreTxt.y-5, size=22, t=250})
end

-- Divide the existing score value by a factor
function M.divideScore(amt)
	scoreNo = scoreNo / amt
	scoreTxt.text = scoreNo .. " pts"
	utility.makeDriftingText("/" .. amt, {yVal=-12, x=scoreTxt.x+20, y=scoreTxt.y-5, size=22, t=250})
end


-- Remove the object from memory
local function cleanup()
    scoreTxt:removeSelf()
    scoreTxt = nil
end

-- Remove score display
function M.destroy()
    if(gameOver == true) then
        transition.to(scoreTxt, {time=100, delay=250, y=screenBottom, oncomplete=cleanup})
        scoreTxt.alpha = 0
    else
        scoreTxt:removeSelf()
        scoreTxt = nil
    end
end

return M