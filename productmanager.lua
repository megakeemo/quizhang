-----------------------------------------------------------------------------------------
-- QuizHang Products Manager
-- Get details of store items from the database
-- Update store items upon purchase AND activation
-----------------------------------------------------------------------------------------

local M = {}

local time = require( "mod_time" )

local utility = require( "utility" )

local iap = require( "plugin.iap_badger" )

local purchaseChoice
local buy500CoinsBtn
local buy200CoinsBtn
local buy50CoinsBtn
local buyRemoveAdsBtn
local lifeSaverBtn
local timePlusBtn
local timeFreezeBtn
local skipMasterBtn

local buyCoins = nil
local buyUnlock = nil

local scrollView

--Create the catalogue
local catalogue = {
    products = {    
        removeAds = {
            --A list of product names or identifiers specific to apple's App Store or Google Play.
            productNames = { apple="", google="buy_remove_ads", amazon="" },
            productType = "non-consumable",
            onRefund = function() iap.removeFromInventory("unlock", true) end,
        },

        buy500coins = {
            --A list of product names or identifiers specific to apple's App Store or Google Play.
            productNames = { apple="", google="buy_500_coins", amazon="" },
            productType = "consumable",
            onRefund = function() coins.minusCoins(500) end,
        },

        buy200coins = {
            --A list of product names or identifiers specific to apple's App Store or Google Play.
            productNames = { apple="", google="buy_200_coins", amazon="" },
            productType = "consumable",
            onRefund = function() coins.minusCoins(200) end,
        },
    
        buy50coins = {
            --A list of product names or identifiers specific to apple's App Store or Google Play.
            productNames = { apple="", google="buy_50_coins", amazon="" },
            productType = "consumable",
            onRefund = function() coins.minusCoins(50) end,
        },    
    },

    --Information about how to handle the inventory item
    inventoryItems = {
        unlock = { productType="non-consumable" },
        coins = { productType="consumable" },
    }
}


--Called when any purchase fails
local function failedListener()
    print("Purchase failed!")
end


local iapOptions = {
    catalogue = catalogue,
    filename = "inventory.txt",
    salt = "773(YW52Nj[M-L6;d9,?%64l8o431Sd1;=<99.,74y6%y8jJ&#34h36)-:42jY1N",

    failedListener = failedListener,
    cancelledListener = failedListener,
        
    --Once the product has been purchased, it will remain in the inventory. Uncomment the following line to test the purchase functions again in future. It's also useful for testing restore purchases.

    --doNotLoadInventory=true,
    --debugMode = true,  
}

--Initialise IAP badger
iap.init(iapOptions)



-----------------------------------------------------------------------------------------
-- Get LIFE SAVER store item from the database
-----------------------------------------------------------------------------------------
function M.getItemLifeSaver()
	if(databaseConnected == false) then
    	connectToDatabase()
  	end

	local getItems = [[SELECT * FROM store_items WHERE item_id = 1 ]]
	for row in db:nrows(getItems) do
		LIFE_SAVER = tostring(row.item_name)
		LIFE_SAVER_COST = tonumber(row.item_cost)
		LIFE_SAVER_DESCRIPTION = tostring(row.item_description)
		LIFE_SAVER_PURCHASED = tonumber(row.item_in_stock)
	end
end



-----------------------------------------------------------------------------------------
-- Get TIME PLUS store item from the database
-----------------------------------------------------------------------------------------
function M.getItemTimePlus()
  if(databaseConnected == false) then
    connectToDatabase()
  end

  local getItems = [[SELECT * FROM store_items WHERE item_id = 2 ]]
  for row in db:nrows(getItems) do
    TIME_PLUS = tostring(row.item_name)
    TIME_PLUS_COST = tonumber(row.item_cost)
    TIME_PLUS_DESCRIPTION = tostring(row.item_description)
    TIME_PLUS_PURCHASED = tonumber(row.item_in_stock)
  end
end



-----------------------------------------------------------------------------------------
-- Get TIME FREEZE store item from the database
-----------------------------------------------------------------------------------------
function M.getItemTimeFreeze()
  if(databaseConnected == false) then
    connectToDatabase()
  end

  local getItems = [[SELECT * FROM store_items WHERE item_id = 3 ]]
  for row in db:nrows(getItems) do
    TIME_FREEZE = tostring(row.item_name)
    TIME_FREEZE_COST = tonumber(row.item_cost)
    TIME_FREEZE_DESCRIPTION = tostring(row.item_description)
    TIME_FREEZE_PURCHASED = tonumber(row.item_in_stock)
  end
end



-----------------------------------------------------------------------------------------
-- Get SKIP MASTER store item from the database
-----------------------------------------------------------------------------------------
function M.getItemSkipMaster()
  if(databaseConnected == false) then
    connectToDatabase()
  end

  local getItems = [[SELECT * FROM store_items WHERE item_id = 4 ]]
  for row in db:nrows(getItems) do
    SKIP_MASTER = tostring(row.item_name)
    SKIP_MASTER_COST = tonumber(row.item_cost)
    SKIP_MASTER_DESCRIPTION = tostring(row.item_description)
    SKIP_MASTER_PURCHASED = tonumber(row.item_in_stock)
    print(LIFE_SAVER_PURCHASED)
  end
end



-----------------------------------------------------------------------------------------
-- In Game Purchase Function - Add 90 seconds to clock when time runs out
-- Should be called in the endGame() function
-----------------------------------------------------------------------------------------
function M.activateLifeSaver()
    audio.play(power_up, {channel=22})
    print("LIFE SAVER activated")
    toast.show("Phew, Life Saver Activated!", { gravity="BottomCenter"} )

    time.addTime(90)
    clockText.text = "01:30"
    gameOver = false

    --Item becomes consumed
    --Update purchase and activation status
    local updatePurchaseStatus = [[UPDATE store_items SET item_in_stock = 0 WHERE item_id = 1]]
    db:exec(updatePurchaseStatus)

    -- Error message
    if db:errcode() then
        print(db:errcode(), db:errmsg())
    end

    --Refresh in_stock value
    M.getItemLifeSaver()
end



-----------------------------------------------------------------------------------------
-- In Game Purchase Function - Start game with 90 additional seconds
-----------------------------------------------------------------------------------------
function M.activateTimePlus()
    time.addTime(90)
    
    if(isEndurance == true) then
        clockText.text = "03:00"
    end

    if(isTimeTrial == true) then
        clockText.text = "04:30"
    end

    audio.play(power_up, {channel=22})
    print("TIME PLUS activated")
    toast.show("TIME PLUS activated!", { gravity="BottomCenter"} )

    --Item becomes consumed
    --Update purchase and activation status
    local updatePurchaseStatus = [[UPDATE store_items SET item_in_stock = 0 WHERE item_id = 2]]
    db:exec(updatePurchaseStatus)


    -- Error message
    if db:errcode() then
        print(db:errcode(), db:errmsg())
    end

    --Refresh in_stock value
    M.getItemTimePlus()
end



-----------------------------------------------------------------------------------------
-- In Game Purchase Function - Freeze time for 60 seconds
-----------------------------------------------------------------------------------------
function M.activateTimeFreeze(clock)
    audio.play(power_up, {channel=22})
    print("TIME FREEZE activated")
    toast.show("TIME FREEZE activated! Pausing time ...", { gravity="BottomCenter"} )

    TIME_FREEZE_ACTIVATED = true
    
    -- Resume time
    local function resumeTime(event)
        timer.resume(clock)
        audio.play(power_up, {channel=22})
        TIME_FREEZE_ACTIVATED = false

        return true
    end

    timer.pause(clock)
    timer.performWithDelay( 60000, resumeTime )

    --Item becomes consumed
    --Update purchase and activation status
    local updatePurchaseStatus = [[UPDATE store_items SET item_in_stock = 0 WHERE item_id = 3]]
    db:exec(updatePurchaseStatus)


    -- Error message
    if db:errcode() then
        print(db:errcode(), db:errmsg())
    end

	--Refresh in_stock value
    M.getItemTimeFreeze()
end




-----------------------------------------------------------------------------------------
-- Remove all advertisements from the game upon succesful purchase of item
-----------------------------------------------------------------------------------------
local function removeAds()
    showAds = false

    --Item becomes purchased and in_stock becomes 1
    local updatePurchaseStatus = [[UPDATE store_items SET item_in_stock = 1 WHERE item_id = 5]]
    db:exec(updatePurchaseStatus)

    -- Error message
    if db:errcode() then
        print(db:errcode(), db:errmsg())
    end

    --Save the inventory change
    iap.saveInventory()

    --Tell user their purchase was successful
    native.showAlert("Info", "Congrats! Your purchase was successful. Ads will now be removed.", {"Okay"})
end



-----------------------------------------------------------------------------------------
-- Buy Coins
-----------------------------------------------------------------------------------------
local function purchaseListener()
	audio.play(purchase_successful, {channel=3})
    print("Product bought was: " .. purchaseChoice)

    --Remove the ads
    if(purchaseChoice == "removeAds") then 
         removeAds()

    elseif(purchaseChoice == "buy50coins") then
    	coins.addCoins(50)
        iap.addToInventory("coins", 50)

    elseif(purchaseChoice == "buy200coins") then
        coins.addCoins(200)
        iap.addToInventory("coins", 200)


    elseif(purchaseChoice == "buy500coins") then
        coins.addCoins(500)
        iap.addToInventory("coins", 500)
        
    end

    -- Save the inventory changes
    iap.saveInventory()

    print("Current coin inventory value is: " .. iap.getInventoryValue("coins"))

    --Tell user their purchase was successful
    native.showAlert("Info", "Congrats! Your purchase was successful.", {"Okay"})
end


-----------------------------------------------------------------------------------------
-- Buy Coins
-----------------------------------------------------------------------------------------
buyCoins=function(event)
	audio.play(button_click, {channel=2})

    --Tell IAP to initiate a purchase - the product name will be stored in target.product
    purchaseChoice = event.target.product
    print("Product being bought is " .. purchaseChoice )
    iap.purchase(purchaseChoice , purchaseListener)
    
    return true
end


-----------------------------------------------------------------------------------------
-- Buy Remove Ads
-----------------------------------------------------------------------------------------
buyUnlock=function(event)
	audio.play(button_click, {channel=2})

    --Tell IAP to initiate a purchase
    purchaseChoice = event.target.product
    print("Product being bought is " .. purchaseChoice )
    iap.purchase(purchaseChoice, purchaseListener)


    -- if(REMOVE_ADS_PURCHASED == 0 or REMOVE_ADS_PURCHASED == nil) then 
    --     --Tell IAP to initiate a purchase
    --     purchaseChoice = event.target.product
    --     print("Product being bought is " .. purchaseChoice )
    --     iap.purchase(purchaseChoice, purchaseListener)

    -- -- Prevent purchase if already in stock
    -- elseif(REMOVE_ADS_PURCHASED == 1) then
    --     audio.play(purchase_unsuccessful, {channel=3})
    --     print("The Remove Ads item is already purchased.")
    --     native.showAlert("Purchase unsuccessful", "Hey, don't be silly. The Remove Ads item is already purchased.", {"Okay"})
    -- end
    
    return true
end

-----------------------------------------------------------------------------------------
-- Restore user purchases
-----------------------------------------------------------------------------------------
local function restoreListener(productName, event)
    print(productName)
    
    if(event.firstRestoreCallback) then
        native.showAlert("Restore", "Your items are being restored", {"Okay"})
    end
    
    --Remove the ads
    if(productName == "removeAds") then 
        removeAds() 
    end
    
    --Save any inventory changes
    iap.saveInventory()
end


-----------------------------------------------------------------------------------------
-- Restore user purchases
-----------------------------------------------------------------------------------------
local function restorePurchases()
    iap.restore(false, restoreListener, failedListener)
end


-----------------------------------------------------------------------------------------
-- Complete item purchase from the store
-----------------------------------------------------------------------------------------
function M.purchaseItem(event, itemName)
	--Get total amount of coins earned in database
	coins.getCoins()

    -- Get correct item
    itemName = purchaseChoice

    if(event.action == "clicked") then
        local i = event.index
        if(i == 1) then
            -- do nothing, dialog will simply dismiss
        elseif(i == 2) then
        	--Purchase of LIFE SAVER item
        	if(itemName == LIFE_SAVER) then

        		-- Transaction logic
                -- Only allow purchase of item when in_stock is 0
                -- Item cannot be purchased more than once. Stock reverts to 0 upon activation
                if(LIFE_SAVER_PURCHASED == 0 or LIFE_SAVER_PURCHASED == nil) then
            		if(coinAmt >= LIFE_SAVER_COST) then
                        audio.play(purchase_successful, {channel=3})
            			print("Life Saver purchase successful.")
                        native.showAlert("Purchase successful!", "Congrats! Your " .. itemName .." purchase was successful.", {"Okay"})

            			--Update coin amount
            			coins.minusCoins(LIFE_SAVER_COST)


            			-- Update purchase status
            			local updatePurchaseStatus = [[UPDATE store_items SET item_in_stock = 1 WHERE item_id = 1]]
                    	db:exec(updatePurchaseStatus)

                        -- Update value of stock variable
                        -- Not being updated on the fly from database
                        LIFE_SAVER_PURCHASED = 1

                    	-- Error message
            	        if db:errcode() then
            	            print(db:errcode(), db:errmsg())
            	        end


            		else
                        audio.play(purchase_unsuccessful, {channel=3})
            			print("Not enough coins to make this purchase.")
                        native.showAlert("Purchase unsuccessful", "Sorry! You don't have enough coins to make this purchase.", {"Okay"})
            		end

                -- Prevent purchase if already in stock
                elseif(LIFE_SAVER_PURCHASED == 1) then
                    audio.play(purchase_unsuccessful, {channel=3})
                    print("Sorry, but item " .. itemName .. " is already purchased.")
                    native.showAlert("Purchase unsuccessful", "Sorry, but item " .. itemName .. " is already purchased.", {"Okay"})
                end
                

        	--Purchase of TIME PLUS item
        	elseif(itemName == TIME_PLUS) then
        		
        		-- Transaction logic
                -- Only allow purchase of item when in_stock is 0
                -- Item cannot be purchased more than once. Stock reverts to 0 upon activation
                if(TIME_PLUS_PURCHASED == 0 or TIME_PLUS_PURCHASED == nil) then
            		if(coinAmt >= TIME_PLUS_COST) then
                        audio.play(purchase_successful, {channel=3})
            			print("Time Plus purchase successful.")
            			native.showAlert("Purchase successful!", "Congrats! Your " .. itemName .." purchase was successful.", {"Okay"})

            			--Update coin amount
            			coins.minusCoins(TIME_PLUS_COST)

            			-- Update purchase status
            			local updatePurchaseStatus = [[UPDATE store_items SET item_in_stock = 1 WHERE item_id = 2]]
                    	db:exec(updatePurchaseStatus)

                        -- Update value of stock variable
                        -- Not being updated on the fly from database
                        TIME_PLUS_PURCHASED = 1

                    	-- Error message
            	        if db:errcode() then
            	            print(db:errcode(), db:errmsg())
            	        end


            		else
                        audio.play(purchase_unsuccessful, {channel=3})
            			print("Not enough coins to make this purchase.")
            			native.showAlert("Purchase unsuccessful", "Sorry! You don't have enough coins to make this purchase.", {"Okay"})
            		end

                -- Prevent purchase if already in stock
                elseif(TIME_PLUS_PURCHASED == 1) then
                    audio.play(purchase_unsuccessful, {channel=3})
                    print("Sorry, but item " .. itemName .. " is already purchased.")
                    native.showAlert("Purchase unsuccessful", "Sorry, but item " .. itemName .. " is already purchased.", {"Okay"})
                end


        	--Purchase of TIME FREEZE item
        	elseif(itemName == TIME_FREEZE) then

        		-- Transaction logic
                -- Only allow purchase of item when in_stock is 0
                -- Item cannot be purchased more than once. Stock reverts to 0 upon activation
                if(TIME_FREEZE_PURCHASED == 0 or TIME_FREEZE_PURCHASED == nil) then
            		if(coinAmt >= TIME_FREEZE_COST) then
                        audio.play(purchase_successful, {channel=3})
            			print("Time Freeze purchase successful.")
            			native.showAlert("Purchase successful!", "Congrats! Your " .. itemName .." purchase was successful.", {"Okay"})

            			--Update coin amount
            			coins.minusCoins(TIME_FREEZE_COST)

            			-- Update purchase status
            			local updatePurchaseStatus = [[UPDATE store_items SET item_in_stock = 1 WHERE item_id = 3]]
                    	db:exec(updatePurchaseStatus)

                        -- Update value of stock variable
                        -- Not being updated on the fly from database
                        TIME_FREEZE_PURCHASED = 1

                    	-- Error message
            	        if db:errcode() then
            	            print(db:errcode(), db:errmsg())
            	        end


            		else
                        audio.play(purchase_unsuccessful, {channel=3})
            			print("Not enough coins to make this purchase.")
            			native.showAlert("Purchase unsuccessful", "Sorry! You don't have enough coins to make this purchase.", {"Okay"})
            		end

                -- Prevent purchase if already in stock
                elseif(TIME_FREEZE_PURCHASED == 1) then
                    audio.play(purchase_unsuccessful, {channel=3})
                    print("Sorry, but item " .. itemName .. " is already purchased.")
                    native.showAlert("Purchase unsuccessful", "Sorry, but item " .. itemName .. " is already purchased.", {"Okay"})
                end



            --Purchase of SKIP MASTER item
            elseif(itemName == SKIP_MASTER) then

                -- Transaction logic
                -- Only allow purchase of item when in_stock is 0
                -- Item cannot be purchased more than once. Stock reverts to 0 upon activation
                if(SKIP_MASTER_PURCHASED == 0 or SKIP_MASTER_PURCHASED == nil) then
                    if(coinAmt >= SKIP_MASTER_COST) then
                        audio.play(purchase_successful, {channel=3})
                        print("Skip Master purchase successful.")
                        native.showAlert("Purchase successful!", "Congrats! Your " .. itemName .." purchase was successful.", {"Okay"})

                        --Update coin amount
            			coins.minusCoins(SKIP_MASTER_COST)

                        -- Update purchase status
                        local updatePurchaseStatus = [[UPDATE store_items SET item_in_stock = 1 WHERE item_id = 4]]
                        db:exec(updatePurchaseStatus)

                        -- Update value of stock variable
                        -- Not being updated on the fly from database
                        SKIP_MASTER_PURCHASED = 1

                        -- Error message
                        if db:errcode() then
                            print(db:errcode(), db:errmsg())
                        end


                    else
                        audio.play(purchase_unsuccessful, {channel=3})
                        print("Not enough coins to make this purchase.")
                        native.showAlert("Purchase unsuccessful", "Sorry! You don't have enough coins to make this purchase.", {"Okay"})
                    end

                -- Prevent purchase if already in stock
                elseif(SKIP_MASTER_PURCHASED == 1) then
                    audio.play(purchase_unsuccessful, {channel=3})
                    print("Sorry, but item " .. itemName .. " is already purchased.")
                    native.showAlert("Purchase unsuccessful", "Sorry, but item " .. itemName .. " is already purchased.", {"Okay"})
                end
            end
        end
    end
end


-- Confim the purchase, then go to purchaseItem function
local function confirmPurchase(event)
    audio.play(button_click, {channel=2})

    local phase = event.phase

    if(phase == "moved") then
        local dy = math.abs((event.y - event.yStart))
        -- If the touch on the button has moved more than 5 pixels,
        -- pass focus back to the scroll view so it can continue scrolling
        if(dy > 5) then
            scrollView:takeFocus(event)
        end
    end

    purchaseChoice = event.target.product
	print("Selected choice: ".. purchaseChoice)

	native.showAlert("Purchase Confirmation", "Are you sure you want to purchase " .. purchaseChoice .. "?", { "No", "Yes" }, M.purchaseItem)
 
    return true
end


-- Destroy store elements
function M.destroy()
    display.remove(lifeSaverBtn)
    display.remove(timePlusBtn)
    display.remove(timeFreezeBtn)
    display.remove(skipMasterBtn)
    display.remove(buy500CoinsBtn)
    display.remove(buy200CoinsBtn)
    display.remove(buy50CoinsBtn)
    display.remove(buyRemoveAdsBtn)

    display.remove(scrollView)
    display.remove(bg)
    display.remove(overlay)
    display.remove(counter_bg)
    display.remove(topbar)
    display.remove(bottombar)
    display.remove(titleTxt)
    display.remove(coinTxt)
    display.remove(coinImg)
    display.remove(backBtn)
    display.remove(restoreBtn)

    buy500CoinsBtn = nil
    buy200CoinsBtn = nil
    buy50CoinsBtn = nil
    buyRemoveAdsBtn = nil
    lifeSaverBtn = nil
    timePlusBtn = nil
    timeFreezeBtn = nil
    skipMasterBtn = nil

    scrollView = nil
    bg = nil
    overlay = nil
    counter_bg = nil
    topbar = nil
    bottombar = nil
    titleTxt = nil
    coinTxt = nil
    coinImg = nil
    backBtn = nil
    restoreBtn = nil

    
end


--Go to previous scene
local function goBack(event)
    audio.play(button_click, {channel=2}) 
    utility.biggerSmaller(backBtn)

    -- Close the database
    db:close()
    databaseConnected = false

    coins.destroy()
    products.destroy()

    composer.removeScene( "scene_store" )
    local prevScene = composer.getSceneName( "previous" )
    composer.gotoScene( prevScene )

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



-- Display store items
function M.setupStore(group)
	M.getItemLifeSaver()
    M.getItemTimePlus()
    M.getItemTimeFreeze()
    M.getItemSkipMaster()

    -- Background
    local bg = display.newImageRect("images/store_background.png", 360, 480)
    bg.width = screenWidth
    bg.height = screenHeight
    bg.x = centerX
    bg.y = centerY
    group:insert(bg)

    -- Overlay
    local overlay = display.newRect(centerX, centerY, screenWidth, screenHeight)
    overlay.width = screenWidth
    overlay.height = screenHeight
    overlay:setFillColor( 0, 0, 0 )
    overlay.alpha = 0.3
    group:insert(overlay)

    
    -- Scrollview
    scrollView = widget.newScrollView(
        {
            top = screenTop,
            left = screenLeft,
            width = screenWidth,
            height = screenHeight,
            scrollWidth = screenWidth,
            scrollHeight = screenHeight,
            topPadding = 80,
            bottomPadding = 110,
            hideBackground = true,
            horizontalScrollDisabled = true,
            listener = scrollListener
        }
    )

    
    -- Buy Remove Ads Button
    buyRemoveAdsBtn = widget.newButton
    {
        id = "buy_remove_ads_btn",
        x = centerX, 
        y = centerY - 230, 
        defaultFile = "images/buy_remove_ads.png",
        width = 350,
        height = 88,
        onRelease = buyUnlock
    }
    buyRemoveAdsBtn.product = "removeAds"
        scrollView:insert(buyRemoveAdsBtn)


    -- Buy 500 Coins Button
    buy500CoinsBtn = widget.newButton
    {
        id = "buy_500_coins_btn",
        x = centerX, 
        y = centerY - 130, 
        defaultFile = "images/buy_500_coins.png",
        width = 350,
        height = 88,
        onRelease = buyCoins
    }
    buy500CoinsBtn.product = "buy500coins"
    scrollView:insert(buy500CoinsBtn)


    -- Buy 200 Coins Button
    buy200CoinsBtn = widget.newButton
    {
        id = "buy_200_coins_btn",
        x = centerX, 
        y = centerY - 30, 
        defaultFile = "images/buy_200_coins.png",
        width = 350,
        height = 88,
        onRelease = buyCoins
    }
    buy200CoinsBtn.product = "buy200coins"
    scrollView:insert(buy200CoinsBtn)


    -- Buy 50 Coins Button
    buy50CoinsBtn = widget.newButton
    {
        id = "buy_50_coins_btn",
        x = centerX, 
        y = centerY + 70, 
        defaultFile = "images/buy_50_coins.png",
        width = 350,
        height = 88,
        onRelease = buyCoins
    }
    buy50CoinsBtn.product = "buy50coins"
    scrollView:insert(buy50CoinsBtn)


	-- Life Saver Button
    lifeSaverBtn = widget.newButton
    {
        id = "life_saver_btn",
        x = centerX, 
        y = centerY + 170, 
        defaultFile = "images/buy_life_saver.png",
        width = 350,
        height = 88,
        onRelease = confirmPurchase
    }
    lifeSaverBtn.product = LIFE_SAVER
    scrollView:insert(lifeSaverBtn)


    -- Time Plus Button
    timePlusBtn = widget.newButton
    {
        id = "time_plus_btn",
        x = centerX, 
        y = centerY + 270, 
        defaultFile = "images/buy_time_plus.png",
        width = 350,
        height = 88,
        onRelease = confirmPurchase
    }
    timePlusBtn.product = TIME_PLUS
    scrollView:insert(timePlusBtn)


    -- Time Freeze Button
    timeFreezeBtn = widget.newButton
    {
        id = "time_freeze_btn",
        x = centerX, 
        y = centerY + 370, 
        defaultFile = "images/buy_time_freeze.png",
        width = 350,
        height = 88,
        onRelease = confirmPurchase
    }
    timeFreezeBtn.product = TIME_FREEZE
    scrollView:insert(timeFreezeBtn)


    -- Skip Master Button
    skipMasterBtn = widget.newButton
    {
        id = "time_skip_master_btn",
        x = centerX, 
        y = centerY + 470, 
        defaultFile = "images/buy_skip_master.png",
        width = 350,
        height = 88,
        onRelease = confirmPurchase
    }
    skipMasterBtn.product = SKIP_MASTER
    scrollView:insert(skipMasterBtn)


    -- Add scrollView to sceneGroup
    group:insert(scrollView)


    -- Top Bar
    local topbar = display.newRect(group, 0, 0, screenWidth, 40 )
    topbar:setFillColor( 0.015, 0.13, 0.35 )
    topbar.x = centerX
    topbar.y = screenTop + 20
    group:insert(topbar)

    
    -- Title
    local titleTxt = display.newText( "Upgrades", centerX, screenTop + 18, "Arial Rounded MT Bold", 26 )
    titleTxt:setFillColor(1, 1, 1 )
    group:insert(titleTxt) 


    -- Coin Image
    local coinImg = display.newImage("images/coins.png")
    coinImg.x = screenLeft + 20
    coinImg.y = screenTop + 18
    utility.fitImage(coinImg, 25, 25, false)
    group:insert(coinImg)


    -- Counter Background
    local counter_bg = display.newImageRect("images/store_background_counter.png", 360, 480)
    counter_bg.width = screenWidth
    counter_bg.height = 96
    counter_bg.x = centerX
    counter_bg.y = screenBottom - 80
    group:insert(counter_bg)


    -- Top Bar
    local bottombar = display.newRect(group, 0, 0, screenWidth, 40 )
    bottombar:setFillColor( 100/255, 68/255, 61/255 )
    bottombar.height = 120
    bottombar.x = centerX
    bottombar.y = screenBottom + 20
    group:insert(bottombar)


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
        y = screenBottom - 75,
        shape = "roundedRect",
        fillColor = { default={ 0.97, 0.76, 0.22 }, over={ 0.8, 0.23, 0.02 } },
        srokeColor = { default={ 0, 0, 0 }, over={ 0.4, 0.1, 0.2 } },
        width = 120,  
        onRelease = goBack
    }
    group:insert(backBtn)


    -- Restore Button
    local restoreBtn = widget.newButton
    {
        id = "restore_btn",
        label = "Restore",
        labelColor = { default={ 1, 1, 1 }, over={ 1, 1, 1 } },
        font = "Arial Rounded MT Bold",
        fontSize = 22,
        emboss = false,
        x = screenRight - 80, 
        y = screenBottom - 75,
        shape = "roundedRect",
        fillColor = { default={ 211/255, 29/255, 1/255 }, over={ 0.8, 0.23, 0.02 } },
        srokeColor = { default={ 0, 0, 0 }, over={ 0.4, 0.1, 0.2 } },
        width = 120,  
        onRelease = restorePurchases
    }
    group:insert(restoreBtn)
end

return M