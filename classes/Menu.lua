-- Luminex - Laser Puzzle
-- License: MIT
-- Copyright (c) 2025 Jericho Crosby (Chalwk)

local ipairs = ipairs
local math_abs = math.abs
local math_floor = math.floor
local table_insert = table.insert

local setColor = love.graphics.setColor
local rectangle = love.graphics.rectangle
local setLineWidth = love.graphics.setLineWidth
local printf = love.graphics.printf
local print = love.graphics.print

local GRID_SIZE = 40

local Menu = {}
Menu.__index = Menu

function Menu.new()
    local instance = setmetatable({}, Menu)

    instance.screenWidth = 1200
    instance.screenHeight = 800
    instance.title = {
        text = "LUMINEX",
        scale = 1,
        scaleDirection = 1,
        scaleSpeed = 0.3,
        minScale = 0.95,
        maxScale = 1.05,
        hue = 0,         -- for color cycling
        hueSpeed = 60,   -- degrees per second
        beamX = 0,       -- beam sweep position
        beamSpeed = 250, -- pixels per second
    }

    instance:createMenuButtons()
    instance:createLevelButtons()

    return instance
end

function Menu:setFonts(fonts)
    self.smallFont = fonts.small
    self.mediumFont = fonts.medium
    self.largeFont = fonts.large
    self.sectionFont = fonts.section
end

function Menu:setScreenSize(width, height)
    self.screenWidth = width
    self.screenHeight = height
    self:updateButtonPositions()
    self:updateLevelButtonPositions()
end

function Menu:createMenuButtons()
    self.menuButtons = {
        {
            text = "Start Game",
            action = "start",
            width = 250,
            height = 60,
            x = 0,
            y = 0
        },
        {
            text = "Level Select",
            action = "level_select",
            width = 250,
            height = 60,
            x = 0,
            y = 0
        },
        {
            text = "Quit",
            action = "quit",
            width = 250,
            height = 60,
            x = 0,
            y = 0
        }
    }

    self:updateButtonPositions()
end

function Menu:createLevelButtons()
    self.levelManager = require("classes/LevelManager").new(GRID_SIZE)
    self.levelButtons = {}

    for i = 1, self.levelManager:getLevelCount() do
        table_insert(self.levelButtons, {
            text = "Level " .. i,
            subtext = self.levelManager:getLevelName(i),
            action = "level " .. i,
            width = 200,
            height = 60,
            x = 0,
            y = 0
        })
    end

    table_insert(self.levelButtons, {
        text = "Back",
        action = "back_to_menu",
        width = 200,
        height = 50,
        x = 0,
        y = 0
    })

    self:updateLevelButtonPositions()
end

function Menu:updateButtonPositions()
    local startY = self.screenHeight / 2
    for i, button in ipairs(self.menuButtons) do
        button.x = (self.screenWidth - button.width) / 2
        button.y = startY + (i - 1) * 80
    end
end

function Menu:updateLevelButtonPositions()
    local buttonsPerRow = 3
    local buttonSpacing = 20
    local startX = (self.screenWidth - (buttonsPerRow * 200 + (buttonsPerRow - 1) * buttonSpacing)) / 2
    local startY = self.screenHeight / 2.8

    for i, button in ipairs(self.levelButtons) do
        if button.action == "back_to_menu" then
            button.x = (self.screenWidth - button.width) / 2
            button.y = self.screenHeight - 100
        else
            local row = math_floor((i - 1) / buttonsPerRow)
            local col = (i - 1) % buttonsPerRow
            button.x = startX + col * (200 + buttonSpacing)
            button.y = startY + row * 80
        end
    end
end

function Menu:update(dt, screenWidth, screenHeight)
    if screenWidth ~= self.screenWidth or screenHeight ~= self.screenHeight then
        self.screenWidth = screenWidth
        self.screenHeight = screenHeight
        self:updateButtonPositions()
        self:updateLevelButtonPositions()
    end

    -- Pulsing scale
    self.title.scale = self.title.scale + self.title.scaleDirection * self.title.scaleSpeed * dt
    if self.title.scale > self.title.maxScale then
        self.title.scale = self.title.maxScale
        self.title.scaleDirection = -1
    elseif self.title.scale < self.title.minScale then
        self.title.scale = self.title.minScale
        self.title.scaleDirection = 1
    end

    -- Animate hue and beam
    self.title.hue = (self.title.hue + self.title.hueSpeed * dt) % 360
    self.title.beamX = (self.title.beamX + self.title.beamSpeed * dt) % self.screenWidth
end

local function hsvToRgb(h, s, v)
    local c = v * s
    local x = c * (1 - math_abs((h / 60) % 2 - 1))
    local m = v - c
    local r, g, b
    if h < 60 then
        r, g, b = c, x, 0
    elseif h < 120 then
        r, g, b = x, c, 0
    elseif h < 180 then
        r, g, b = 0, c, x
    elseif h < 240 then
        r, g, b = 0, x, c
    elseif h < 300 then
        r, g, b = x, 0, c
    else
        r, g, b = c, 0, x
    end
    return r + m, g + m, b + m
end

function Menu:draw(screenWidth, screenHeight, state)
    -- Animated title
    local r, g, b = hsvToRgb(self.title.hue, 0.8, 1.0)
    love.graphics.setFont(self.largeFont)
    love.graphics.push()
    love.graphics.translate(screenWidth / 2, screenHeight / 4)
    love.graphics.scale(self.title.scale, self.title.scale)

    -- Outer glow layers
    for i = 3, 1, -1 do
        local alpha = 0.1 * i
        setColor(r, g, b, alpha)
        printf(self.title.text, -screenWidth / 2, -self.largeFont:getHeight() / 2, screenWidth, "center")
    end

    -- Core bright text
    setColor(r, g, b)
    printf(self.title.text, -screenWidth / 2, -self.largeFont:getHeight() / 2, screenWidth, "center")

    -- Laser beam sweep
    local beamWidth = 10
    setColor(1, 1, 1, 0.15)
    rectangle("fill", self.title.beamX - beamWidth / 2, -self.largeFont:getHeight(), beamWidth,
        self.largeFont:getHeight() * 2)

    love.graphics.pop()

    if state == "menu" then
        self:drawMenuButtons()
        -- Draw tagline
        setColor(0.8, 0.9, 1.0)
        love.graphics.setFont(self.smallFont)
        printf("Laser Reflection Puzzle Game",
            0, screenHeight / 3 + 30, screenWidth, "center")
    elseif state == "level_select" then
        self:drawLevelSelect()
    end

    -- Draw copyright
    setColor(1, 1, 1, 0.5)
    love.graphics.setFont(self.smallFont)
    printf("Luminex - Copyright (c) 2025 Jericho Crosby (Chalwk)", 10, screenHeight - 25, screenWidth - 20, "right")
end

function Menu:drawLevelSelect()
    setColor(1, 1, 1)
    love.graphics.setFont(self.mediumFont)

    for _, button in ipairs(self.levelButtons) do
        self:drawButton(button)
        -- Draw level name for level buttons
        if button.subtext then
            setColor(0.8, 0.9, 1.0, 0.8)
            love.graphics.setFont(self.smallFont)
            printf(button.subtext, button.x, button.y + 37, button.width, "center")
        end
    end
end

function Menu:drawMenuButtons()
    for _, button in ipairs(self.menuButtons) do
        self:drawButton(button)
    end
end

function Menu:drawButton(button)
    setColor(0.2, 0.2, 0.4, 0.9)
    rectangle("fill", button.x, button.y, button.width, button.height, 10, 10)

    setColor(0.3, 0.8, 1.0)
    setLineWidth(2)
    rectangle("line", button.x, button.y, button.width, button.height, 10, 10)

    setColor(1, 1, 1)
    love.graphics.setFont(self.smallFont)
    local textWidth = self.smallFont:getWidth(button.text)
    local textHeight = self.smallFont:getHeight()
    print(button.text, button.x + (button.width - textWidth) / 2,
        button.y + (button.height - textHeight) / 2)

    setLineWidth(1)
end

function Menu:handleClick(x, y, state)
    local buttons = {}

    if state == "menu" then
        buttons = self.menuButtons
    elseif state == "level_select" then
        buttons = self.levelButtons
    end

    for _, button in ipairs(buttons) do
        if x >= button.x and x <= button.x + button.width and
            y >= button.y and y <= button.y + button.height then
            return button.action
        end
    end

    return nil
end

return Menu
