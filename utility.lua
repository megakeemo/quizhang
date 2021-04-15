-- Contains helpful functions that will probably be used in more than one file

local M = {}


-- Drifting text animation
function M.makeDriftingText(txt, opts)
	local isDrifting = 0
	
    local opts = opts or {}
    local dTime = opts.t or 2000 -- drift time
    local del = opts.del or 0 -- delay time
    local yVal = opts.yVal or -40 -- how far to drift
    local x = opts.x or centerX -- initial X location of text
    local y = opts.y or centerY -- initial Y location of text
    local fontFace = opts.font or "PoetsenOne" -- font to use
    local fontSize = opts.size or 18 -- font size

    local dTxt = display.newText( txt, x, y, fontFace, fontSize )
    local function killDTxt(obj)
        display.remove( obj )
        obj = nil
        isDrifting = isDrifting - 1
    end
    transition.to( dTxt,  { delay=del, time=dTime, y=y+yVal, alpha=0, onComplete=killDTxt } ) 
end


-- Button pressed animation
function M.biggerSmaller(obj)
    local transTime = 200
    local function shrinkBack(obj)
        transition.to(obj, {time=transTime/2, xScale=1, yScale=1})
    end
    transition.to(obj, {time=transTime/2, xScale=.8, yScale=.8, onComplete=shrinkBack})
end


-- Image resizing
function M.fitImage(displayObject, fitWidth, fitHeight, enlarge)
    -- first determine which edge is out of bounds
    local scaleFactor = fitHeight / displayObject.height 
    local newWidth = displayObject.width * scaleFactor
    if newWidth > fitWidth then
        scaleFactor = fitWidth / displayObject.width 
    end
    if not enlarge and scaleFactor > 1 then
        return
    end
    displayObject:scale( scaleFactor, scaleFactor )
end


-- Change spritesheets on the fly
function M.swapSheet(displayObj, sequenceName, delay)
    local function swap()
        displayObj:setSequence(sequenceName)
        displayObj:play()
    end
    
    timer.performWithDelay( delay, swap )
end


-- Check for internet access
function M.testConnection()   
    local socket = require("socket")
                
    local test = socket.tcp()
    test:settimeout(1, 't') -- Set timeout to 1 second

    local testResult = test:connect("www.google.com", 80)
     
    if(testResult == nil) then
        print("Internet access is not available")
        return false
    end

    print("Internet access is available")        
    test:close()
    test = nil
    return true

end


-- Testing function, outputs the contents of an array
function M.print_r(t)  
    local print_r_cache={}
    local function sub_print_r(t,indent)
        if (print_r_cache[tostring(t)]) then
            print(indent.."*"..tostring(t))
        else
            print_r_cache[tostring(t)]=true
            if (type(t)=="table") then
                for pos,val in pairs(t) do
                    if (type(val)=="table") then
                        print(indent.."["..pos.."] => "..tostring(t).." {")
                        sub_print_r(val,indent..string.rep(" ",string.len(pos)+8))
                        print(indent..string.rep(" ",string.len(pos)+6).."}")
                    elseif (type(val)=="string") then
                        print(indent.."["..pos..'] => "'..val..'"')
                    else
                        print(indent.."["..pos.."] => "..tostring(val))
                    end
                end
            else
                print(indent..tostring(t))
            end
        end
    end
    if (type(t)=="table") then
        print(tostring(t).." {")
        sub_print_r(t,"  ")
        print("}")
    else
        sub_print_r(t,"  ")
    end
    print()
end

return M