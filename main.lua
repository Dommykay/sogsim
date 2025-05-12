love = require("love")

function love.load()
    love.window.setTitle("Sog clicker")
    love.graphics.setDefaultFilter("nearest", "nearest")
    _G.font = love.graphics.setNewFont("Assets/Font/Jersey10-Regular.ttf",25)
    _G.sog_rating = 0
    _G.RES_X, _G.RES_Y = love.graphics.getDimensions()
    _G.global_scale_mult = 1
    _G.global_scale = (math.min(RES_X,RES_Y)*global_scale_mult)/720
    _G.menu = ReturnMenu("clicker")
    _G.last_time = love.timer.getTime()
    _G.clickspeed = 0
    _G.clickerwigglespeed = 1
    _G.clickerwigglepos = 0
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
    print(font_center[1],font_center[2])
    love.graphics.printf(string, x, y, limit*global_scale, "left", rotation, scale * global_scale, scale * global_scale, font_center[1]/2, font_center[2]/2, 0, 0)
end



--MENU
function ReturnMenu(menu_type)
    if menu_type == "clicker" then

        --Setup

        local menu = {}
        menu.background = {}
        menu.foreground = {}
        menu.textures = {}


        -- Foreground 
        menu.foreground.buttons = {}
        menu.foreground.clicker = {}
        menu.foreground.borders = {}


        menu.foreground.borders.colour = {0.35,0.6,0.8}
        menu.foreground.borders.topend = function () return (RES_Y*global_scale/6) end
        menu.foreground.borders.bottomend = function () return RES_Y - (RES_Y*global_scale/4) end

        menu.foreground.borders.top = function()
            love.graphics.setColor(menu.foreground.borders.colour[1], menu.foreground.borders.colour[2], menu.foreground.borders.colour[3], 1)
            love.graphics.rectangle("fill", 0, 0, RES_X, (RES_Y*global_scale/6))
            ResetGraphicsColour()
        end

        menu.foreground.borders.bottom = function ()
            love.graphics.setColor(menu.foreground.borders.colour[1], menu.foreground.borders.colour[2], menu.foreground.borders.colour[3], 1)
            love.graphics.rectangle("fill", 0, RES_Y - (RES_Y*global_scale/4), RES_X, (RES_Y*global_scale/4))
            ResetGraphicsColour()
        end

        menu.foreground.borders.render = function ()
            menu.foreground.borders.top()
            menu.foreground.borders.bottom()
        end

        menu.foreground.clicker.texture = love.graphics.newImage("Assets/Textures/soggycar.png")
        menu.foreground.clicker.warning = {}
        menu.foreground.clicker.warning.scale = 0.625
        menu.foreground.clicker.warning.texture = love.graphics.newImage("Assets/Textures/warning.png")
        menu.foreground.clicker.warning.timealive = 0
        menu.foreground.clicker.warning.update = function (dt)
        menu.foreground.clicker.warning.timealive = menu.foreground.clicker.warning.timealive + dt            
        end
        menu.foreground.clicker.warning.active = false
        menu.foreground.clicker.warning.render = function ()
            if menu.foreground.clicker.warning.active then
                local opacity = (math.sin(menu.foreground.clicker.warning.timealive*math.max(1,clickspeed/4)+0.05))
                love.graphics.setColor(1,1,1,opacity)
                love.graphics.draw(menu.foreground.clicker.warning.texture, RES_X/2, (menu.foreground.borders.topend()+menu.foreground.borders.bottomend())/2,
                math.sin(love.timer.getTime())/10, menu.foreground.clicker.warning.scale * global_scale, menu.foreground.clicker.warning.scale * global_scale,
                menu.foreground.clicker.warning.texture:getWidth()/2, menu.foreground.clicker.warning.texture:getHeight()/2)
                if opacity < 0.01 then
                    menu.foreground.clicker.warning.active = false
                end
            end
        end

        menu.foreground.sogratingtext = ReturnText()
        menu.foreground.sogratingtext.limit = function() return RES_X end
        menu.foreground.sogratingtext.scale = function () return 3 end
        menu.foreground.sogratingtext.y = function () return menu.foreground.borders.topend()/2 end
        menu.foreground.sogratingtext.text = function () return string.format("SOG RATING: %s", sog_rating) end
        menu.foreground.sogratingtext.rotation = function () return math.sin(love.timer.getTime())/15 end


        menu.foreground.clicker.scale = 2.5
        menu.foreground.clicker.texture:setFilter("linear","linear")
        menu.foreground.clicker.timeofclick = love.timer.getTime()
        menu.foreground.clicker.timesinceclick = function ()
            return (love.timer.getTime() - menu.foreground.clicker.timeofclick)
        end
        menu.foreground.clicker.render = function ()
            local tsc = menu.foreground.clicker.timesinceclick()
            local scale_x = ((1/(tsc*10+1)) + 1)
            local scale_y = (1 - (1/(tsc*10+2)))

            local rootcs = 1 + (math.sqrt(clickspeed)/10)

            love.graphics.setColor(1, 1/rootcs, 1/rootcs, 1)
            local sogycenter = (menu.foreground.borders.topend()+menu.foreground.borders.bottomend())/2
            love.graphics.draw(menu.foreground.clicker.texture, RES_X/2, sogycenter, math.sin(clickerwigglepos)/(clickspeed+3), scale_x * global_scale * menu.foreground.clicker.scale, scale_y * global_scale * menu.foreground.clicker.scale, 
            menu.foreground.clicker.texture:getWidth()/2, menu.foreground.clicker.texture:getHeight()/2)   

            if rootcs > 1.15 and not menu.foreground.clicker.warning.active then
                menu.foreground.clicker.warning.timealive = 0
                menu.foreground.clicker.warning.active = true
            end
            menu.foreground.clicker.warning.render()
            ResetGraphicsColour()
        end

        menu.foreground.clicker.CurrentlyClicked = function ()
            if love.mouse.isDown(1) then
                local mouse_y = love.mouse.getY()
                if mouse_y > (RES_Y*global_scale/6) and mouse_y < (RES_Y - (RES_Y*global_scale/4)) then
                    menu.foreground.clicker.timeofclick = love.timer.getTime()
                end
            end
        end


        menu.foreground.render = function ()
            menu.foreground.clicker.render()
            menu.foreground.borders.render()
            menu.foreground.sogratingtext.render()
        end

        --Background stuff
        menu.background.blur = love.graphics.newImage("Assets/Textures/blur.png")
        menu.background.blur:setFilter("linear","linear")
        menu.background.colour = {0.4,0.7,0.95}

        menu.background.render = function ()
            love.graphics.setColor(menu.background.colour[1],menu.background.colour[2],menu.background.colour[3], 1)
            love.graphics.draw(menu.background.blur, 0, 0, 0, RES_X, RES_Y/2, 0, 0, 0, 0)
            ResetGraphicsColour()
        end

        return menu
    end
    
end

function love.mousereleased(x, y, button, isTouch, presses)
    if button == 1 then
        if y > (RES_Y*global_scale/6) and y < (RES_Y - (RES_Y*global_scale/4)) then
            sog_rating = sog_rating + 1
        end
    end
    clickspeed = presses
    clickerwigglespeed = 1 + clickspeed
end


function love.update(dt)
    if menu.foreground.clicker.warning.active then
        menu.foreground.clicker.warning.update(dt)
    end
    menu.foreground.clicker.CurrentlyClicked()
    if menu.foreground.clicker.timesinceclick() > 1 then 
        clickspeed = math.max(1, clickspeed-dt*20)
        clickerwigglespeed = math.max(1, clickerwigglespeed-dt*20)
    end
    clickerwigglepos = clickerwigglepos + dt*clickerwigglespeed
end

function love.draw()
    menu.background.render()
    menu.foreground.render()

end