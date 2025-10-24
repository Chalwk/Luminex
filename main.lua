-- Luminex - Laser Puzzle
-- License: MIT
-- Copyright (c) 2025 Jericho Crosby (Chalwk)

local Game = require("classes/Game")
local Menu = require("classes/Menu")
local BackgroundManager = require("classes/BackgroundManager")

local game, menu, backgroundManager
local screenWidth, screenHeight
local gameState = "menu"
local fonts = {}

local function updateScreenSize()
    screenWidth = love.graphics.getWidth()
    screenHeight = love.graphics.getHeight()
end

function love.load()
    love.window.setTitle("Luminex - Laser Puzzle")
    love.graphics.setDefaultFilter("nearest", "nearest")
    love.graphics.setLineStyle("smooth")

    -- Load fonts
    fonts.small = love.graphics.newFont(16)
    fonts.medium = love.graphics.newFont(22)
    fonts.large = love.graphics.newFont(52)
    fonts.section = love.graphics.newFont(18)

    love.graphics.setFont(fonts.medium)

    game = Game.new()
    menu = Menu.new()
    backgroundManager = BackgroundManager.new()

    menu:setFonts(fonts)
    game:setFonts(fonts)

    updateScreenSize()
    menu:setScreenSize(screenWidth, screenHeight)
    game:setScreenSize(screenWidth, screenHeight)
end

function love.update(dt)
    updateScreenSize()
    if gameState == "menu" or gameState == "options" or gameState == "level_select" then
        menu:update(dt, screenWidth, screenHeight)
    elseif gameState == "playing" then
        game:update(dt)
    end

    backgroundManager:update(dt)
end

function love.draw()
    backgroundManager:draw(screenWidth, screenHeight, gameState)

    if gameState == "menu" or gameState == "options" or gameState == "level_select" then
        menu:draw(screenWidth, screenHeight, gameState)
    elseif gameState == "playing" then
        game:draw()
    end
end

function love.mousepressed(x, y, button, istouch)
    if button == 1 or button == 2 then -- Left click (1) or right click (2)
        if gameState == "menu" then
            local action = menu:handleClick(x, y, "menu")
            if action == "start" then
                gameState = "playing"
                game:loadLevel(1) -- Start with level 1
            elseif action == "options" then
                gameState = "options"
            elseif action == "quit" then
                love.event.quit()
            end
        elseif gameState == "options" then
            local action = menu:handleClick(x, y, "options")
            if action == "level_select" then
                gameState = "level_select"
            elseif action == "back" then
                gameState = "menu"
            end
        elseif gameState == "level_select" then
            local action = menu:handleClick(x, y, "level_select")
            if action and action:sub(1, 5) == "level" then
                local level = tonumber(action:sub(7))
                gameState = "playing"
                game:loadLevel(level)
            elseif action == "back_to_options" then
                gameState = "options"
            end
        elseif gameState == "playing" then
            game:handleTouch(x, y, button)
        end
    end
end

function love.keypressed(key)
    if key == "escape" then
        if gameState == "playing" then
            gameState = "menu"
        elseif gameState == "level_select" then
            gameState = "options"
        elseif gameState == "options" then
            gameState = "menu"
        else
            love.event.quit()
        end
    elseif gameState == "playing" then
        game:handleKeypress(key)
    end
end

function love.resize(w, h)
    updateScreenSize()
    menu:setScreenSize(screenWidth, screenHeight)
    game:setScreenSize(screenWidth, screenHeight)
end
