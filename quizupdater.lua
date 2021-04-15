-----------------------------------------------------------------------------------------
-- QuizHang Question Updater module
-- This module will silently update/append the local SQLite database with more questions.
-- The questions will be downloaded from a database on a remote server,
-- This serves to circumvent the need for updating through the respective app stores (as well as database overwrites).
-----------------------------------------------------------------------------------------
local M = {}

local json = require("json")

local remoteData -- data from server
local decodedData -- remote data from server that is decoded

-- Variables to store database data
local quizCategory
local quizQuestion
local quizOption1
local quizOption2
local quizOption3
local quizOption4
local quizAnswer
local remoteDBVersion

-- Add new quizzes to local database
function M.updateLocalDatabase()
    local counter = 1
    remoteDBVersion = tonumber(decodedData[counter]["dbversion"])

    print("Remote DB version: "..remoteDBVersion)
    print("Local DB version: "..appDBVersion)

	-- Save data to database
    if(remoteDBVersion > appDBVersion) then
        local quiz = decodedData[counter]

        -- Update the database version
        local versionUpdate = [[UPDATE dbversion SET current_version = ]] ..tostring(remoteDBVersion) ..[[]]
        db:exec(versionUpdate)

        -- Loop through the remote data
        while(quiz ~= nil) do    
            quizCategory = tostring(quiz["category"])
            quizQuestion = tostring(quiz["question"])
            quizOption1 = tostring(quiz["option1"])
            quizOption2 = tostring(quiz["option2"])
            quizOption3 = tostring(quiz["option3"])
            quizOption4 = tostring(quiz["option4"])
            quizAnswer = tostring(quiz["answer"])
            quizDifficulty = tostring(quiz["difficulty"])
            remoteDBVersion = tostring(quiz["dbversion"])

            -- Use prepared statements to escape quotes
            local quizInsert = db:prepare[[insert into quizzes values(:NULL, :category, :question, :option1, :option2, :option3, :option4, :answer, :difficulty)]]

            quizInsert:bind_names(
                {
                    category=quizCategory, 
                    question=quizQuestion,
                    option1=quizOption1,
                    option2=quizOption2,
                    option3=quizOption3,
                    option4=quizOption4,
                    answer=quizAnswer,
                    difficulty=quizDifficulty
                })

            quizInsert:step()

            counter = counter + 1
            quiz = decodedData[counter]    
        end
    else 
        print("No update needed.")
        toast.show("No update needed.")
    end

    -- Everything is saved to SQLite database; close database
    databaseConnected = false
    db:close()
end


-- Database network listener
local function networkListener(event)
    if(event.isError) then
        print("Network error! Unable to connect to remote database.")

        toast.show("Network error! Unable to connect to remote database.", { gravity="BottomCenter"})

        db:close()
        databaseConnected = false

    elseif(event.phase == "began") then
        if(event.bytesEstimated <= 0) then
            print("Download starting, size unknown.")
        else
            print("Download starting, estimated size: " .. event.bytesEstimated)

            toast.show("Download starting, estimated size: " .. event.bytesEstimated, { gravity="BottomCenter"})
        end

    elseif(event.phase == "progress") then
        if(event.bytesEstimated <= 0) then
            print("Download progress: " .. event.bytesTransferred)
        else
            print("Download progress: " .. event.bytesTransferred .. " of estimated: " .. event.bytesEstimated)
        end

    elseif(event.phase == "ended") then
        remoteData = event.response
        decodedData = (json.decode(remoteData))

        --Only update local database if there are new quizzes to be added
        if(decodedData ~= nil) then
            print("RESPONSE: " .. remoteData)
            print("Download complete, total bytes transferred: " .. event.bytesTransferred)

            toast.show("Download complete. Go check out the new quizzes!", { gravity="BottomCenter"})

            M.updateLocalDatabase() 
            audio.play(update_complete, {channel=19}) 

        -- If decoded data is nil, i.e, there is no data sent back from the server
        else
            db:close()
            databaseConnected = false

            print("Quizzes are up to date, nothing to do.")
            print("RESPONSE: " .. remoteData)
            toast.show("Quizzes are up to date.", { gravity="BottomCenter"})

            audio.play(question_skip, {channel=19})
        end
    end
end


-- Send a network call to request new quizzes from the QuizHang remote server
function M.requestNewQuizzes()
    --Send local database version to server
    getAppDBVersion()

    local params = {}
    local headers = {}
    local info = {
        ["local_version"] = appDBVersion,
        ["secret_key"] = "oO7C25t82a73K3Of8hh2Ja122o4g7r201nA81d364BvayP4rs3g7P9MR6F3hJM1K",
    }
    headers["Content-Type"] = "application/json"
    headers["Accept-Language"] = "en-US"
    headers["User-Agent"] = "zzzz"
    params.headers = headers
    params.body = json.encode(info)
    params.progess = "download"
    params.timeout = 1 --seconds

    network.request("http://quizhang.com/core/dbupdate.php", "POST", networkListener, params)

end


-- Send a network call to check if new quizzes are avaiable on the QuizHang remote server
function M.checkForNewQuizzes()

end

return M