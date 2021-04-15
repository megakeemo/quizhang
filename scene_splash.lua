-----------------------------------------------------------------------------------------
-- QuizHang splash scene
-- Display ACEMADE logo
-----------------------------------------------------------------------------------------
composer = require( "composer" )
local scene = composer.newScene()

local utility = require( "utility" )

-- -----------------------------------------------------------------------------------------------------------------
-- All code outside of the listener functions will only be executed ONCE unless "composer.removeScene()" is called.
-- -----------------------------------------------------------------------------------------------------------------

-- local forward references should go here
local splashBG
local splashLogo

-- -------------------------------------------------------------------------------
-- Switch to menu scene
local function endSplash() 
    composer.removeScene( "scene_splash" )
    composer.gotoScene( "scene_menu" )
end 


local function setUpDisplay(group)
    -- Splash Background
    splashBG = display.newRect(group, screenX, screenY, screenWidth, screenHeight)
    splashBG.width = screenWidth
    splashBG.height = screenHeight
    splashBG.x = centerX
    splashBG.y = centerY
    group:insert(splashBG)

    --Splash Logo
    splashLogo = display.newImage("images/splash_logo.png")
    splashLogo.x = centerX
    splashLogo.y = centerY
    splashLogo.alpha = 0
    utility.fitImage(splashLogo, 300, 300, false)
    group:insert(splashLogo)

    transition.to(splashLogo, {time=1000, alpha=1.0})

    timer.performWithDelay(2000, endSplash)
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
    elseif ( phase == "did" ) then

        -- Called when the scene is now on screen.
        -- Insert code here to make the scene come alive.
        -- Example: start timers, begin animation, play audio, etc.
        
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

    display.remove(splashBG)
    display.remove(splashLogo)
    
    splashBG = nil
    splashLogo = nil

end


-- -------------------------------------------------------------------------------

-- Listener setup
scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )

-- -------------------------------------------------------------------------------

return scene
