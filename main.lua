love = require("love")

function love.load()
    love.window.setTitle("Sog clicker")
    love.graphics.setDefaultFilter("nearest", "nearest")
    _G.font = love.graphics.setNewFont("Assets/Font/Jersey10-Regular.ttf",50)
    _G.sog_rating = 0
    _G.RES_X, _G.RES_Y = love.graphics.getDimensions()
    _G.global_scale_mult = 1
    _G.global_scale = (math.min(RES_X,RES_Y)*global_scale_mult)/720
    _G.menu = ReturnMenu("clicker")
    _G.last_time = love.timer.getTime()
    _G.clickspeed = 0
    _G.menu_type_queued = "clicker"
    _G.id = 0

end

function PointBoxCollision(px,py,bx,by,bw,bh)
    -- point and box X
    if px > bx and px < bx+bw then
        --point and box y
        if py > by and py < by+bh then
            return true
        end
    end
    return false
end




function love.resize(w, h)
    _G.RES_X = w
    _G.RES_Y = h
    _G.global_scale = (math.min(RES_X,RES_Y)*global_scale_mult)/720
end

-- FONT PROCEDURES AND SUBROUTINES

function GetFontCenter(font, string, wrap)
    local width, lines = font:getWrap(string, wrap)
    lines = #lines
    local y = (font:getHeight()*lines)
    local x = width
    return {x, y}
end

function ReturnText()
    local text = {}
    text.text = function () return "No text given." end
    text.scale = function () return 1 end
    text.x = function () return RES_X/2 end
    text.y = function () return RES_Y/2 end
    text.limit_num = function () return 1 end
    text.limit = function () return (RES_X/text.limit_num())*global_scale end
    text.rotation = function() return 0 end
    text.render = function () DrawText(text.text(), text.x(), text.y(), text.limit(), text.rotation(), text.scale()) end
    return text
end

-- SCALE STUFF

function Scale(scale)
    return scale*global_scale
end



-- DRAW STUFF

--Reset

function ResetGraphicsColour()
    love.graphics.setColor(1, 1, 1, 1)
end


function DrawText(string, x, y, limit, rotation, scale)
    local font_center = GetFontCenter(font, string, limit*global_scale)
    love.graphics.printf(string, x, y, limit*global_scale, "left", rotation, scale * global_scale, scale * global_scale, font_center[1]/2, font_center[2]/2, 0, 0)
end


function DrawWithShadow(drawable, x, y, r, sx, sy, ox, oy, kx, ky, opacity)
    if opacity == nil then
       love.graphics.setColor(0, 0, 0, 0.2)
        love.graphics.draw(drawable, x+(5*global_scale), y+(5*global_scale), r, sx, sy, ox, oy, kx, ky)
        ResetGraphicsColour()
        love.graphics.draw(drawable, x, y, r, sx, sy, ox, oy, kx, ky) 
    else
        love.graphics.setColor(0, 0, 0, 0.2*opacity)
        love.graphics.draw(drawable, x+(5*global_scale), y+(5*global_scale), r, sx, sy, ox, oy, kx, ky)
        love.graphics.setColor(1, 1, 1, 1*opacity)
        love.graphics.draw(drawable, x, y, r, sx, sy, ox, oy, kx, ky)
    end
    
    
end

-- Items
function ReturnID()
    id = id + 1
    return id - 1
end


function NewClicksItem(texture_path, name, description, clicksgiven, cost, costexp, texturescale)
    local item = {}
    item.type = "clicks"
    item.texture = love.graphics.newImage(texture_path)
    item.texturescale = texturescale
    item.id = ReturnID()
    item.bounds = function(scroll_offset)
        return 0, (item.id*RES_Y/6)+scroll_offset, RES_X, RES_Y/6
    end

    item.clicksgiven = clicksgiven
    item.cost = cost
    item.costexp = costexp

    item.name = name
    item.description = function () return (string.format("Costs %s and gives +%s extra per click. %s", item.cost, item.clicksgiven, description)) end
    item.textscale = texturescale * 2

    item.newcost = function ()
        item.cost = item.cost ^ item.costexp
    end
    item.totalowned = 0
    -- item.totalowned = load the total amount of this item owned here...
    item.cost = item.cost * (item.costexp^item.totalowned)
    item.totalsogs = function ()
        return item.clicksgiven * item.totalowned
    end
    item.isclicked = function (x, y, scroll_offset) return PointBoxCollision(x, y, item.bounds(scroll_offset)) and PointBoxCollision(x, y, menu.shop.bounds()) end
    
    item.trybuy = function ()
        if sog_rating > item.cost then
            sog_rating = sog_rating - item.cost
            item.totalowned = item.totalowned + 1
            item.newcost()
        end
    end

    item.render = function (scroll_offset)
        local x, y, w, h = item.bounds(scroll_offset)
        DrawWithShadow(item.texture,x+h/2,y+h/2, 0, item.texturescale*global_scale, item.texturescale*global_scale, item.texture:getWidth()/2, item.texture:getHeight()/2, 0, 0)
        DrawText(item.name, x+h+RES_X/15,y+h/2, RES_X/4*item.textscale*global_scale, 0, item.textscale*global_scale)
        DrawText(item.description(), x+RES_X/2,y+h/2, (RES_X*item.textscale)/(global_scale), 0, item.textscale*((global_scale+1)/2))
    end
    return item
end




function NewPassiveItem(texture_path, name, sogspersecond, cost, costexp)
    local item = {}
    item.type = "passive"
    item.texture = love.graphics.newImage(texture_path)
    item.name = name
    item.sogspersecond = sogspersecond
    item.cost = cost
    item.costexp = costexp
    item.newcost = function ()
        item.cost = item.cost ^ item.costexp
    end
    item.totalowned = 0
    item.initialize = function ()
        -- item.totalowned = load the total amount of this item owned here...
        item.cost = item.cost * (item.costexp^item.totalowned)
    end
end

function ReturnItems()
    local items = {}
    for i=1,15 do
        table.insert(items, NewClicksItem("Assets/Textures/download.jpeg", "testname", "testdesc", 1, 1, 1.15,0.25))
    end
    return items
end


--MENU
function ReturnMenu(menu_type)
    if menu_type == "clicker" then

        --Setup

        local menu = {}
        menu.type = "clicker"
        menu.background = {}
        menu.foreground = {}


        -- Foreground 
        menu.foreground.buttons = {}
        menu.foreground.clicker = {}
        menu.foreground.borders = {}



        -- The top and bottom borders that store the score and buttons
        
        --Initial vars
        menu.foreground.borders.colour = {0.35,0.6,0.8}
        menu.foreground.borders.topheight = function () return (RES_Y*global_scale/6) end
        menu.foreground.borders.bottomheight = function () return (RES_Y*global_scale/4) end


        --Generate the top border
        menu.foreground.borders.top = function()
            love.graphics.setColor(menu.foreground.borders.colour[1], menu.foreground.borders.colour[2], menu.foreground.borders.colour[3], 1)
            love.graphics.rectangle("fill", 0, 0, RES_X, (RES_Y*global_scale/6))
            ResetGraphicsColour()
        end


        --Generate the bottom border
        menu.foreground.borders.bottom = function ()
            love.graphics.setColor(menu.foreground.borders.colour[1], menu.foreground.borders.colour[2], menu.foreground.borders.colour[3], 1)
            love.graphics.rectangle("fill", 0, RES_Y - menu.foreground.borders.bottomheight(), RES_X, menu.foreground.borders.bottomheight())
            ResetGraphicsColour()
        end


        --Render the borders
        menu.foreground.borders.render = function ()
            menu.foreground.borders.top()
            menu.foreground.borders.bottom()
        end
        





        --The warning message that appears when clicking fast
        
        -- Iitial vars
        menu.foreground.clicker.texture = love.graphics.newImage("Assets/Textures/soggycar.png")
        menu.foreground.clicker.warning = {}
        menu.foreground.clicker.warning.scale = 0.625
        menu.foreground.clicker.warning.texture = love.graphics.newImage("Assets/Textures/warning.png")
        menu.foreground.clicker.warning.timealive = 0
        menu.foreground.clicker.warning.update = function (dt) menu.foreground.clicker.warning.timealive = menu.foreground.clicker.warning.timealive + dt end
        menu.foreground.clicker.warning.active = false


        --Render function
        menu.foreground.clicker.warning.render = function ()
            if menu.foreground.clicker.warning.active then
                local opacity = (math.sin(menu.foreground.clicker.warning.timealive*math.max(1,clickspeed/4)+0.1))
                DrawWithShadow(menu.foreground.clicker.warning.texture, RES_X/2, (menu.foreground.borders.topheight()+(RES_Y - menu.foreground.borders.bottomheight()))/2,
                math.sin(love.timer.getTime())/10, menu.foreground.clicker.warning.scale * global_scale, menu.foreground.clicker.warning.scale * global_scale,
                menu.foreground.clicker.warning.texture:getWidth()/2, menu.foreground.clicker.warning.texture:getHeight()/2, 0, 0, opacity)
                if opacity < 0.05 then
                    menu.foreground.clicker.warning.active = false
                end
            end
        end
        




        --Text at the top of the screen saying the 'score'
        menu.foreground.sogratingtext = ReturnText()
        menu.foreground.sogratingtext.limit = function() return 999999999999 end
        menu.foreground.sogratingtext.scale = function () return 2*global_scale end
        menu.foreground.sogratingtext.y = function () return menu.foreground.borders.topheight()/2 end
        menu.foreground.sogratingtext.text = function () return string.format("SOG RATING: %s", sog_rating) end
        menu.foreground.sogratingtext.rotation = function () return 0 end







        --The sog (clicker in the middle of the screen)

        --Initial vars
        menu.foreground.clicker.scale = 2.5
        menu.foreground.clicker.texture:setFilter("linear","linear")

        --Click info storage
        menu.foreground.clicker.timeofclick = love.timer.getTime()
        menu.foreground.clicker.lastfewclicks = {-10,-10,-10,-10,-10}

        menu.foreground.clicker.addclick = function()
            table.insert(menu.foreground.clicker.lastfewclicks, 1, love.timer.getTime())
            table.remove(menu.foreground.clicker.lastfewclicks)
        end

        menu.foreground.clicker.averageclicks = function ()
            local lfc = menu.foreground.clicker.lastfewclicks
            local t1,t2,t3,t4,t5 = love.timer.getTime()-lfc[1],lfc[1]-lfc[2],lfc[2]-lfc[3],lfc[3]-lfc[4],lfc[4]-lfc[5]
            return 1/((t1+t2+t3+t4+t5)/4)
            --Returns clickspeed in frequency or hertz
        end

        menu.foreground.clicker.timesinceclick = function ()
            return (love.timer.getTime() - menu.foreground.clicker.timeofclick)
        end
        menu.foreground.clicker.sinpos = 0
        menu.foreground.clicker.sinspeed = 0
        menu.foreground.clicker.clickspeed = 0

        --Render function
        menu.foreground.clicker.render = function ()
            local tsc = menu.foreground.clicker.timesinceclick()
            local scale_x = ((1/(tsc*10+1)) + 1)
            local scale_y = (1 - (1/(tsc*10+2)))

            local rootcs = 1 + (math.sqrt(menu.foreground.clicker.clickspeed)/10)

            love.graphics.setColor(1, 1/rootcs, 1/rootcs, 1)
            local sogycenter = (menu.foreground.borders.topheight()+(RES_Y - menu.foreground.borders.bottomheight()))/2
            DrawWithShadow(menu.foreground.clicker.texture, RES_X/2, sogycenter, math.sin(menu.foreground.clicker.sinpos)/((menu.foreground.clicker.clickspeed)+4), scale_x * global_scale * menu.foreground.clicker.scale, scale_y * global_scale * menu.foreground.clicker.scale, 
            menu.foreground.clicker.texture:getWidth()/2, menu.foreground.clicker.texture:getHeight()/2)   

            if rootcs > 1.25 and not menu.foreground.clicker.warning.active then
                menu.foreground.clicker.warning.timealive = 0
                menu.foreground.clicker.warning.active = true
            end
            menu.foreground.clicker.warning.render()
            ResetGraphicsColour()
        end


        --Hitbox and click check
        menu.foreground.clicker.bounds = function () return 0, menu.foreground.borders.topheight(),RES_X,RES_Y - (menu.foreground.borders.topheight() + menu.foreground.borders.bottomheight()) end
        
        --for holding down a button, essentially only does the squish anim
        menu.foreground.clicker.CurrentlyClicked = function (x, y)
            local touches = love.touch.getTouches()
            if love.mouse.isDown(1) then
                if PointBoxCollision(x, y, menu.foreground.clicker.bounds()) then
                    menu.foreground.clicker.timeofclick = love.timer.getTime()
                end
            elseif love.keyboard.isDown("space") then
                menu.foreground.clicker.timeofclick = love.timer.getTime()
            elseif #touches > 0 then
                for touch=1, #touches do
                    if PointBoxCollision(love.touch.getPosition(touches[touch]), menu.foreground.clicker.bounds()) then
                        menu.foreground.clicker.timeofclick = love.timer.getTime()
                    end
                end
            end
        end







        --Shop button
        menu.foreground.buttons.shop = {}
        menu.foreground.buttons.shop.texture = love.graphics.newImage("Assets/Textures/shop.png")
        menu.foreground.buttons.shop.scale = function () return 6 end
        
        --Hitbox and click check
        menu.foreground.buttons.shop.bounds = function () return 0,RES_Y - menu.foreground.borders.bottomheight(), RES_X/2, menu.foreground.borders.bottomheight() end
        menu.foreground.buttons.shop.checkpressed = function (x,y)
            return PointBoxCollision(x,y,menu.foreground.buttons.shop.bounds())
        end

        --Render function
        menu.foreground.buttons.shop.render = function ()
            local x,y,w,h = menu.foreground.buttons.shop.bounds()
            local button_center = {x+w/2, y+h/2}
            local offset = {menu.foreground.buttons.shop.texture:getWidth()/2, menu.foreground.buttons.shop.texture:getHeight()/2}
            DrawWithShadow(menu.foreground.buttons.shop.texture, button_center[1], button_center[2], 0, menu.foreground.buttons.shop.scale()*global_scale, menu.foreground.buttons.shop.scale()*global_scale, offset[1], offset[2])
        end








        --Skins button
        menu.foreground.buttons.skins = {}
        menu.foreground.buttons.skins.texture = love.graphics.newImage("Assets/Textures/skins.png")
        menu.foreground.buttons.skins.scale = function () return 0.25 end
        menu.foreground.buttons.skins.bounds = function () return RES_X/2,RES_Y - menu.foreground.borders.bottomheight(), RES_X/2, menu.foreground.borders.bottomheight() end
        menu.foreground.buttons.skins.checkpressed = function (x,y)
            return PointBoxCollision(x,y,menu.foreground.buttons.skins.bounds())
        end
        menu.foreground.buttons.skins.render = function ()
            local x,y,w,h = menu.foreground.buttons.skins.bounds()
            local button_center = {x+w/2, y+h/2}
            local offset = {menu.foreground.buttons.skins.texture:getWidth()/2, menu.foreground.buttons.skins.texture:getHeight()/2}
            DrawWithShadow(menu.foreground.buttons.skins.texture, button_center[1], button_center[2], 0, menu.foreground.buttons.skins.scale()*global_scale, menu.foreground.buttons.skins.scale()*global_scale, offset[1], offset[2])
        end




        --Render the buttons
        menu.foreground.buttons.render = function ()
            menu.foreground.buttons.shop.render()
            menu.foreground.buttons.skins.render()
        end




        -- Render all foreground objects
        menu.foreground.render = function ()
            menu.foreground.clicker.render()
            menu.foreground.borders.render()
            menu.foreground.sogratingtext.render()
            menu.foreground.buttons.render()
        end






        --Background stuff


        --Background gradient
        menu.background.blur = love.graphics.newImage("Assets/Textures/blur.png")
        menu.background.blur:setFilter("linear","linear")
        menu.background.colour = {0.4,0.7,0.95}



        --Render the background
        menu.background.render = function ()
            love.graphics.setColor(menu.background.colour[1],menu.background.colour[2],menu.background.colour[3], 1)
            love.graphics.draw(menu.background.blur, 0, 0, 0, RES_X, RES_Y/2, 0, 0, 0, 0)
            ResetGraphicsColour()
        end

        --Render everything
        menu.render = function ()
            menu.background.render()
            menu.foreground.render()            
        end



        --Updates pretty much everything in the menu
        menu.update = function (dt)
            if menu.foreground.clicker.warning.active then
                menu.foreground.clicker.warning.update(dt)
            end
            local x, y = love.mouse.getPosition()
            menu.foreground.clicker.sinpos = (dt*menu.foreground.clicker.clickspeed) + menu.foreground.clicker.sinpos
            menu.foreground.clicker.CurrentlyClicked(x, y)
            if menu.foreground.clicker.timesinceclick() > 1 then 
                menu.foreground.clicker.clickspeed = math.max(1, menu.foreground.clicker.clickspeed-dt*5)
                menu.foreground.clicker.sinspeed = math.max(1, menu.foreground.clicker.sinspeed-dt*5)
            end
            menu.foreground.clicker.sinpos = menu.foreground.clicker.sinpos + dt*menu.foreground.clicker.sinspeed
        end



        --Checks for inputs

        --Checking for mouse inputs
        menu.mouseinputs = function (x, y, button, isTouch, presses)
            if button == 1 then

                -- has the ~sog~ been clicked
                if PointBoxCollision(x,y,menu.foreground.clicker.bounds()) then
                    sog_rating = sog_rating + 1
                    menu.foreground.clicker.sinpos = 1 + menu.foreground.clicker.sinpos
                    table.insert(menu.foreground.clicker.lastfewclicks, 1, love.timer.getTime())
                    menu.foreground.clicker.timeofclick = love.timer.getTime()
                    menu.foreground.clicker.clickspeed = menu.foreground.clicker.averageclicks()
                    menu.foreground.clicker.addclick()
                end

                -- Shop button has been pressed?
                if PointBoxCollision(x,y,menu.foreground.buttons.shop.bounds()) then
                    print("Shop button pressed, entering shop")
                    menu_type_queued = "shop"
                end
            end
        end



        --Checking for keyboard inputs
        menu.keyboardinputs = function (key, scancode)
            
            
            -- has the spacebar been pressed
            if key == "space" then
                sog_rating = sog_rating + 1
                menu.foreground.clicker.sinpos = 1 + menu.foreground.clicker.sinpos
                table.insert(menu.foreground.clicker.lastfewclicks, 1, love.timer.getTime())
                menu.foreground.clicker.timeofclick = love.timer.getTime()
                menu.foreground.clicker.clickspeed = menu.foreground.clicker.averageclicks()
                menu.foreground.clicker.addclick()
            end
        end




        --Checking for touch inputs
        menu.touchinputs = function (id, x, y, dx, dy, pressure)

            -- has the ~sog~ been clicked 
            if PointBoxCollision(x,y,menu.foreground.clicker.bounds()) then
                sog_rating = sog_rating + 1
                menu.foreground.clicker.sinpos = 1 + menu.foreground.clicker.sinpos
                table.insert(menu.foreground.clicker.lastfewclicks, 1, love.timer.getTime())
                menu.foreground.clicker.timeofclick = love.timer.getTime()
                menu.foreground.clicker.clickspeed = menu.foreground.clicker.averageclicks()
                menu.foreground.clicker.addclick()
            end

            -- Shop button has been pressed?
            if PointBoxCollision(x,y,menu.foreground.buttons.shop.bounds()) then
                print("Shop button pressed, entering shop")
            end
        end

        --Scroll inputs
        menu.scrollinputs = function (x, y)
        end


        return menu
     
    elseif menu_type == "shop" then
        --Setup

        local menu = {}
        menu.type = "shop"
        menu.background = {}
        menu.foreground = {}


        -- Foreground 
        menu.foreground.buttons = {}
        menu.foreground.borders = {}



        -- The top and bottom borders that store the score and buttons
        
        --Initial vars
        menu.foreground.borders.colour = {0.35,0.6,0.8}
        menu.foreground.borders.topheight = function () return (RES_Y*global_scale/6) end
        menu.foreground.borders.bottomheight = function () return (RES_Y*global_scale/4) end


        --Generate the top border
        menu.foreground.borders.top = function()
            love.graphics.setColor(menu.foreground.borders.colour[1], menu.foreground.borders.colour[2], menu.foreground.borders.colour[3], 1)
            love.graphics.rectangle("fill", 0, 0, RES_X, menu.foreground.borders.topheight())
            ResetGraphicsColour()
        end


        --Generate the bottom border
        menu.foreground.borders.bottom = function ()
            love.graphics.setColor(menu.foreground.borders.colour[1], menu.foreground.borders.colour[2], menu.foreground.borders.colour[3], 1)
            love.graphics.rectangle("fill", 0, RES_Y - menu.foreground.borders.bottomheight(), RES_X, menu.foreground.borders.bottomheight())
            ResetGraphicsColour()
        end


        --Render the borders
        menu.foreground.borders.render = function ()
            menu.foreground.borders.top()
            menu.foreground.borders.bottom()
        end
        




        --Text at the top of the screen saying the 'score'
        menu.foreground.sogratingtext = ReturnText()
        menu.foreground.sogratingtext.limit = function() return RES_X/global_scale end
        menu.foreground.sogratingtext.scale = function () return 2*global_scale end
        menu.foreground.sogratingtext.y = function () return menu.foreground.borders.topheight()/2 end
        menu.foreground.sogratingtext.text = function () return string.format("SOG RATING: %s", sog_rating) end
        menu.foreground.sogratingtext.rotation = function () return 0 end



        --Shop button
        menu.foreground.buttons.shop = {}
        menu.foreground.buttons.shop.texture = love.graphics.newImage("Assets/Textures/shop.png")
        menu.foreground.buttons.shop.scale = function () return 6 end
        
        --Hitbox and click check
        menu.foreground.buttons.shop.bounds = function () return 0,RES_Y - menu.foreground.borders.bottomheight(), RES_X/2, menu.foreground.borders.bottomheight() end
        menu.foreground.buttons.shop.checkpressed = function (x,y)
            return PointBoxCollision(x,y,menu.foreground.buttons.shop.bounds())
        end

        --Render function
        menu.foreground.buttons.shop.render = function ()
            local x,y,w,h = menu.foreground.buttons.shop.bounds()
            local button_center = {x+w/2, y+h/2}
            local offset = {menu.foreground.buttons.shop.texture:getWidth()/2, menu.foreground.buttons.shop.texture:getHeight()/2}
            DrawWithShadow(menu.foreground.buttons.shop.texture, button_center[1], button_center[2], math.sin(love.timer.getTime())/3, menu.foreground.buttons.shop.scale()*global_scale, menu.foreground.buttons.shop.scale()*global_scale, offset[1], offset[2])
        end








        --Skins button
        menu.foreground.buttons.skins = {}
        menu.foreground.buttons.skins.texture = love.graphics.newImage("Assets/Textures/skins.png")
        menu.foreground.buttons.skins.scale = function () return 0.25 end
        menu.foreground.buttons.skins.bounds = function () return RES_X/2,RES_Y - menu.foreground.borders.bottomheight(), RES_X/2, menu.foreground.borders.bottomheight() end
        menu.foreground.buttons.skins.checkpressed = function (x,y)
            return PointBoxCollision(x,y,menu.foreground.buttons.skins.bounds())
        end
        menu.foreground.buttons.skins.render = function ()
            local x,y,w,h = menu.foreground.buttons.skins.bounds()
            local button_center = {x+w/2, y+h/2}
            local offset = {menu.foreground.buttons.skins.texture:getWidth()/2, menu.foreground.buttons.skins.texture:getHeight()/2}
            DrawWithShadow(menu.foreground.buttons.skins.texture, button_center[1], button_center[2], 0, menu.foreground.buttons.skins.scale()*global_scale, menu.foreground.buttons.skins.scale()*global_scale, offset[1], offset[2])
        end




        --Render the buttons
        menu.foreground.buttons.render = function ()
            menu.foreground.buttons.shop.render()
            menu.foreground.buttons.skins.render()
        end

        




        -- Render all foreground objects
        menu.foreground.render = function ()
            menu.foreground.borders.render()
            menu.foreground.sogratingtext.render()
            menu.foreground.buttons.render()
        end






        --Background stuff


        --Background gradient
        menu.background.blur = love.graphics.newImage("Assets/Textures/blur.png")
        menu.background.blur:setFilter("linear","linear")
        menu.background.colour = {0.4,0.7,0.95}



        --Render the background
        menu.background.render = function ()
            love.graphics.setColor(menu.background.colour[1],menu.background.colour[2],menu.background.colour[3], 1)
            love.graphics.draw(menu.background.blur, 0, 0, 0, RES_X, RES_Y/2, 0, 0, 0, 0)
            ResetGraphicsColour()
        end

        menu.scroll = menu.foreground.borders.topheight()
        menu.shop = {}
        menu.shop.items = ReturnItems()
        menu.shop.bounds = function ()
            local topheight,bottomheight = menu.foreground.borders.topheight(), menu.foreground.borders.bottomheight()
            return 0, topheight, RES_X, RES_Y - topheight - bottomheight
        end
        menu.shop.render = function ()
            id = 0
            for item=1,#menu.shop.items do
                menu.shop.items[item].render(menu.scroll)
            end
        end

        --Render everything
        menu.render = function ()
            menu.background.render()
            menu.shop.render()
            menu.foreground.render()
            
        end



        --Updates pretty much everything in the menu
        menu.update = function (dt)
        end



        --Checks for inputs

        --Checking for mouse inputs
        menu.mouseinputs = function (x, y, button, isTouch, presses)
            if button == 1 then

                -- Shop button has been pressed?
                if PointBoxCollision(x,y,menu.foreground.buttons.shop.bounds()) then
                    print("Shop button pressed, leaving shop")
                    menu_type_queued = "clicker"
                end
            end
        end

        --Keyboard inputs so the shit doesnt crash even tho there is no kb inputs in this bit
        menu.keyboardinputs = function ()
        end

        --Checking for touch inputs
        menu.touchinputs = function (id, x, y, dx, dy, pressure)
            -- Shop button has been pressed?
            if PointBoxCollision(x,y,menu.foreground.buttons.shop.bounds()) then
                print("Shop button pressed, leaving shop")
                menu_type_queued = "clicker"
            end
        end

        menu.scrollinputs = function (x, y)
            menu.scroll = math.min(menu.scroll + (y^3)*10, menu.foreground.borders.topheight())
        end

        menu.touchmoved = function (id, x, y, dx, dy, pressure) 
            if PointBoxCollision(x, y, menu.shop.bounds()) then
                menu.scroll = math.min(menu.scroll + dy, menu.foreground.borders.topheight())
            end
        end


        return menu
    end
    
end

--Called when scrolled
function love.wheelmoved(x, y)
    menu.scrollinputs(x, y)
end

--Called when any mouse button is pressed
function love.mousereleased(x, y, button, isTouch, presses)
    menu.mouseinputs(x, y, button, isTouch, presses)
end

--Called when any keyboard key is released
function love.keyreleased(key, scancode)
    menu.keyboardinputs(key, scancode)

end

--Called when a touch from a touchscreen is released
function love.touchreleased(id, x, y, dx, dy, pressure)
    menu.touchinputs(id, x, y, dx, dy, pressure)
end


--https://open.spotify.com/track/4e6ZN0EcEqYx74BTC5xQzy 2:02
function love.touchmoved(id, x, y, dx, dy, pressure)
    menu.touchmoved(id, x, y, dx, dy, pressure)
end

function love.update(dt)
    if menu.type ~= menu_type_queued then
        menu = ReturnMenu(menu_type_queued)
    end
    menu.update(dt)
end

function love.draw()
    menu.render()
end