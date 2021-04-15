-----------------------------------------------------------------------------------------
-- QuizHang coins module
-- Time will start at 60 seconds.
-- Functions - getCoins, updateCoins,addCoins, minusCoins
-----------------------------------------------------------------------------------------

local M = {}

local coinTxt

-----------------------------------------------------------------------------------------
-- Get coin value from database
-----------------------------------------------------------------------------------------
function M.getCoins()
	if(databaseConnected == false) then
		connectToDatabase()
	end

	local getCoinsStmt = [[SELECT * FROM coins ]]
	for row in db:nrows(getCoinsStmt) do
		coinAmt = tonumber(row.amount)
	end

	print("Current coin amount is: " .. coinAmt)
end


-----------------------------------------------------------------------------------------
-- Display the coin value
-----------------------------------------------------------------------------------------
function M.displayCoins()
	M.getCoins()

    coinTxt = display.newText( coinAmt, screenLeft + 55, screenTop + 18, "Arial Rounded MT Bold", 18 )
    coinTxt:setFillColor(1, 1, 1 ) 
end


-----------------------------------------------------------------------------------------
-- Update coin value in database
-----------------------------------------------------------------------------------------
function M.updateCoins(coinAmt)
	if(databaseConnected == false) then
		connectToDatabase()
	end

	local updateCoinsStmt = [[UPDATE coins SET amount = ]] ..tostring(coinAmt) ..[[]]
	db:exec(updateCoinsStmt)

	print("New Total coin amount is: " .. coinAmt)
end


-----------------------------------------------------------------------------------------
-- Increment coin value
-----------------------------------------------------------------------------------------
function M.addCoins(amt)
	-- Get current coin value in database
	M.getCoins()

	-- Increment coin value by specified amount
	coinAmt = coinAmt + amt
	coinTxt.text = tostring(coinAmt)

	-- Update coin value in database
	M.updateCoins(coinAmt)
end


-----------------------------------------------------------------------------------------
-- Decrement coin value
-----------------------------------------------------------------------------------------
function M.minusCoins(amt)
	-- Get current coin value in database
	M.getCoins()

	-- Increment coin value by specified amount
	coinAmt = coinAmt - amt
	coinTxt.text = tostring(coinAmt)

	-- Update coin value in database
	M.updateCoins(coinAmt)
end


-----------------------------------------------------------------------------------------
-- Destroy the display object
-----------------------------------------------------------------------------------------
function M.destroy()
	coinTxt:removeSelf()
	coinTxt = nil
end

return M