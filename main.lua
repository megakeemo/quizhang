-----------------------------------------------------------------------------------------
-- QuizHang - a hangman quiz game with its own unique twist
-- An ACEMADE Project
-- Copyright Akeem C.E. Murray
-- Libraries are copyright to their respective owners
-----------------------------------------------------------------------------------------

-- Hide the status bar
display.setStatusBar(display.HiddenStatusBar)

-- Keep screen on
system.setIdleTimer(false)

-- Scene management
composer = require( "composer" )

-- Widget library (buttons etc)
widget = require( "widget" )
widget.setTheme( "widget_theme_ios" )

-- Toast messages
toast = require('plugin.toast')

-- Require Power Up Functions
products = require('productmanager')


-----------------------------------------------------------------------------------------
-- Add support for Flurry Analytics
-----------------------------------------------------------------------------------------
flurryAnalytics = require("plugin.flurry.analytics")

local function flurryListener(event)
    if(event.phase == "init") then  -- Successful initialization
        print(event.provider)
    end
end

-- Initialize the Flurry plugin
flurryAnalytics.init(flurryListener, { apiKey="JNDB28YPH5Q4RWW7ZZHZ" })



-----------------------------------------------------------------------------------------
-- Add support for Google ads (admob)
-- Will be in the form of an interstitial ad (full screen), which will be displayed on the GameOver scene
-----------------------------------------------------------------------------------------
ads = require("ads")
adProvider = "admob"
showAds = true -- default ads setting

bannerAppID = ""
interstitialAppID = ""

-- Android ads
if(system.getInfo("platformName") == "Android") then
    bannerAppID = "ca-app-pub-8999932178456077/4363176349"
    interstitialAppID = "ca-app-pub-8999932178456077/5839909549"
end

ads.init(adProvider, bannerAppID, adListener)
ads.init(adProvider, interstitialAppID)
ads.load("admob", { appId = bannerAppID, testMode=false })
ads.load("admob", { appId = interstitialAppID, testMode=false })



-----------------------------------------------------------------------------------------
-- Require sqlite database functionality
-- Database will contain quizzes as well as user play stats
-- Database will be regularly updated with new quizzes via a remote server
-- See module 'quizupdater.lua'
-----------------------------------------------------------------------------------------
sqlite3 = require( "sqlite3" )
dbfunc = require( "copyDBto" )
db = ""
databaseConnected = false

-- Required version of the database. If required version is higher than current version, then upgrade the database
appDBVersion = 0



-- Global time and score variables
scoreNo = 0
secondsLeft = 0
local clockText
local countDownTimer

-- Variables to check if conditions have been met
gameOver = false
gamePaused = false
gameRestart = false
playSound = true

-- Game modes
isEndurance = false
isTimeTrial = false

-- Stats to be displayed on GameOver Scene
totalTimeGained = 0
totalTimeLost = 0
questionCount = 0
ansCorrectCount = 0
ansIncorrectCount = 0
quesSkipCount = 0
consecutiveCorrectAnswers = 0
consecutiveIncorrectAnswers = 0

-- Global Spritesheets
local garry
local exeutioner
local trapdoor


-----------------------------------------------------------------------------------------
-- Screen positioning variables
-----------------------------------------------------------------------------------------
centerX = display.contentCenterX
centerY = display.contentCenterY
screenX = display.screenOriginX
screenY = display.screenOriginY
screenWidth = display.contentWidth - screenX * 2
screenHeight = display.contentHeight - screenY * 2
screenLeft = screenX
screenRight = screenX + screenWidth
screenTop = screenY
screenBottom = screenY + screenHeight
display.contentWidth = screenWidth
display.contentHeight = screenHeight



-----------------------------------------------------------------------------------------
-- Load Audio
-----------------------------------------------------------------------------------------
button_click = audio.loadSound("audio/button_click.wav")
question_right = audio.loadSound("audio/question_right.wav")
question_wrong = audio.loadSound("audio/question_wrong.wav")
question_skip = audio.loadSound("audio/question_skip.wav")
special_question_right = audio.loadSound("audio/special_question_right.wav")
special_question_wrong = audio.loadSound("audio/special_question_wrong.wav")
consecutive_questions_right = audio.loadSound("audio/consecutive_right.wav")
lever_turn = audio.loadSound("audio/lever_turn.wav")
time_running_out = audio.loadSound("audio/time_running_out.wav")
game_ends = audio.loadSound("audio/game_ends.wav")
menu_loop = audio.loadStream("audio/menu_loop.wav")
play_loop = audio.loadStream("audio/play_loop.wav")
update_complete = audio.loadSound("audio/update_complete.wav")
purchase_successful = audio.loadSound("audio/purchase_successful.wav")
purchase_unsuccessful = audio.loadSound("audio/purchase_unsuccessful.wav")
power_up = audio.loadSound("audio/power_up.wav")



-----------------------------------------------------------------------------------------
-- In App Store items
-- With the exception of SKIP MASTER, all items will have a maximum quantity of 1
-- Hence they will expire after initial use

-- ITEMS ARE:
-- LIFE_SAVER -- adds 90 seconds to clock after time runs out
-- TIME_PLUS -- start game with 90 seconds extra
-- TIME_FREEZE -- freeze time for 60 seconds
-- SKIP_MASTER -- lose no time for skipping questions, skip up to 50 of questions 
-----------------------------------------------------------------------------------------
local LIFE_SAVER
local LIFE_SAVER_COST
local LIFE_SAVER_DESCRIPTION
local LIFE_SAVER_PURCHASED

local TIME_PLUS
local TIME_PLUS_COST
local TIME_PLUS_DESCRIPTION
local TIME_PLUS_PURCHASED

local TIME_FREEZE
local TIME_FREEZE_COST
local TIME_FREEZE_DESCRIPTION
local TIME_FREEZE_PURCHASED
local TIME_FREEZE_ACTIVATED = false

local SKIP_MASTER
local SKIP_MASTER_COST
local SKIP_MASTER_DESCRIPTION
local SKIP_MASTER_PURCHASED

local REMOVE_ADS_PURCHASED


-- Rewards which can be used to purchase in game items
-- Can be earned through regular play or bought through the Play Store
-- Stored in database
coinAmt = 0


-----------------------------------------------------------------------------------------
-- Connect to the database
-----------------------------------------------------------------------------------------
function connectToDatabase()
	local filename = "quizhang.db"
  local baseDir = system.DocumentsDirectory

  -- Open database file. If the file doesn't exist, it will be created
  local path = system.pathForFile( filename, baseDir )
  local doesExist = io.open( path, "r" )

  if not doesExist then
      local result = dbfunc.copyDatabaseTo( "quizhang.db", { filename="quizhang.db", baseDir=system.DocumentsDirectory } )
      assert( result, "Database failed to copy. Check the logs.")
  else
      io.close( doesExist )
  end

  db = sqlite3.open( path )
  databaseConnected = true
end



-----------------------------------------------------------------------------------------
-- Get current and local DB version from the database
-----------------------------------------------------------------------------------------
function getAppDBVersion()
	if(databaseConnected == false) then
		connectToDatabase()
	end

	local getVersion = [[SELECT * FROM dbversion ]]
	for row in db:nrows(getVersion) do
		appDBVersion = tonumber(row.current_version)
	end

  print("Current App DB Version is " .. appDBVersion)
end



-----------------------------------------------------------------------------------------
-- Prevent ads from showing if Remove Ads item has been purchased 
----------------------------------------------------------------------------------------- 
function getShowAdStatus()
  if(databaseConnected == false) then
      connectToDatabase()
  end

  local getAdStatus = [[SELECT item_in_stock FROM store_items WHERE item_id = 5 ]]
  for row in db:nrows(getAdStatus) do
      REMOVE_ADS_PURCHASED = tonumber(row.item_in_stock)
  end

  if(REMOVE_ADS_PURCHASED == 1) then
      showAds = false
  end

  print("Ad display status: " .. REMOVE_ADS_PURCHASED)
end



-----------------------------------------------------------------------------------------
-- HANDLE SYSTEM EVENTS
-----------------------------------------------------------------------------------------
local function systemEvents(event)
   print("systemEvent " .. event.type)

   if(event.type == "applicationStart" ) then
   		print( "starting..........................." )
      	
      -- Set initial database connection state to false
     databaseConnected = false       
  
   elseif(event.type == "applicationSuspend") then
      	print("suspending...........................")

   elseif(event.type == "applicationResume") then
      	print("resuming.............................")

   elseif(event.type == "applicationExit") then
      	print("exiting..............................")
      	gameOver = true
      
      	if(databaseConnected == true) then
        	db:close()
      	end 
   end

   return true
end

Runtime:addEventListener("system", systemEvents)


-- Switch to splash scene
composer.gotoScene( "scene_splash" )