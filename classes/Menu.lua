-- Luminex - Laser Puzzle
-- License: MIT
-- Copyright (c) 2025 Jericho Crosby (Chalwk)

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
        maxScale = 1.05
    }

    instance:createMenuButtons()
    instance:createLevelButtons()
    instance:createOptionsButtons()

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
    self:updateOptionsButtonPositions()
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
            text = "Options",
            action = "options",
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

function Menu:createOptionsButtons()
    self.optionsButtons = {
        {
            text = "Level Select",
            action = "level_select",
            width = 250,
            height = 60,
            x = 0,
            y = 0
        },
        {
            text = "Back",
            action = "back",
            width = 250,
            height = 60,
            x = 0,
            y = 0
        }
    }

    self:updateOptionsButtonPositions()
end

function Menu:createLevelButtons()
    self.levelManager = require("classes/LevelManager").new(GRID_SIZE)
    self.levelButtons = {}

    for i = 1, self.levelManager:getLevelCount() do
        table.insert(self.levelButtons, {
            text = "Level " .. i,
            subtext = self.levelManager:getLevelName(i),
            action = "level " .. i,
            width = 200,
            height = 60,
            x = 0,
            y = 0
        })
    end

    table.insert(self.levelButtons, {
        text = "Back",
        action = "back_to_options",
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

function Menu:updateOptionsButtonPositions()
    local startY = self.screenHeight / 2
    for i, button in ipairs(self.optionsButtons) do
        button.x = (self.screenWidth - button.width) / 2
        button.y = startY + (i - 1) * 80
    end
end

function Menu:updateLevelButtonPositions()
    local buttonsPerRow = 3
    local buttonSpacing = 20
    local startX = (self.screenWidth - (buttonsPerRow * 200 + (buttonsPerRow - 1) * buttonSpacing)) / 2
    local startY = self.screenHeight / 4

    for i, button in ipairs(self.levelButtons) do
        if button.action == "back_to_options" then
            button.x = (self.screenWidth - button.width) / 2
            button.y = self.screenHeight - 100
        else
            local row = math.floor((i - 1) / buttonsPerRow)
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
        self:updateOptionsButtonPositions()
    end

    -- Update title animation
    self.title.scale = self.title.scale + self.title.scaleDirection * self.title.scaleSpeed * dt

    if self.title.scale > self.title.maxScale then
        self.title.scale = self.title.maxScale
        self.title.scaleDirection = -1
    elseif self.title.scale < self.title.minScale then
        self.title.scale = self.title.minScale
        self.title.scaleDirection = 1
    end
end

function Menu:draw(screenWidth, screenHeight, state)
    -- Draw animated title
    love.graphics.setColor(0.3, 0.8, 1.0)
    love.graphics.setFont(self.largeFont)

    love.graphics.push()
    love.graphics.translate(screenWidth / 2, screenHeight / 4)
    love.graphics.scale(self.title.scale, self.title.scale)
    love.graphics.printf(self.title.text, -screenWidth / 2, -self.largeFont:getHeight() / 2, screenWidth, "center")
    love.graphics.pop()

    if state == "menu" then
        self:drawMenuButtons()
        -- Draw tagline
        love.graphics.setColor(0.8, 0.9, 1.0)
        love.graphics.setFont(self.smallFont)
        love.graphics.printf("Laser Reflection Puzzle Game",
            0, screenHeight / 3 + 30, screenWidth, "center")
    elseif state == "options" then
        self:drawOptionsMenu()
    elseif state == "level_select" then
        self:drawLevelSelect()
    end

    -- Draw copyright
    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.setFont(self.smallFont)
    love.graphics.printf("Luminex - Copyright (c) 2025 Jericho Crosby (Chalwk)", 10, screenHeight - 25, screenWidth - 20,
        "right")
end

function Menu:drawOptionsMenu()
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(self.mediumFont)
    love.graphics.printf("Options", 0, self.screenHeight / 4 - 40, self.screenWidth, "center")

    for _, button in ipairs(self.optionsButtons) do
        self:drawButton(button)
    end
end

function Menu:drawLevelSelect()
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(self.mediumFont)
    love.graphics.printf("Select Level", 0, self.screenHeight / 6, self.screenWidth, "center")

    for _, button in ipairs(self.levelButtons) do
        self:drawButton(button)
        -- Draw level name for level buttons
        if button.subtext then
            love.graphics.setColor(0.8, 0.9, 1.0, 0.8)
            love.graphics.setFont(self.smallFont)
            love.graphics.printf(button.subtext, button.x, button.y + 35, button.width, "center")
        end
    end
end

function Menu:drawMenuButtons()
    for _, button in ipairs(self.menuButtons) do
        self:drawButton(button)
    end
end

function Menu:drawButton(button)
    love.graphics.setColor(0.2, 0.2, 0.4, 0.9)
    love.graphics.rectangle("fill", button.x, button.y, button.width, button.height, 10, 10)

    love.graphics.setColor(0.3, 0.8, 1.0)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", button.x, button.y, button.width, button.height, 10, 10)

    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(self.smallFont)
    local textWidth = self.smallFont:getWidth(button.text)
    local textHeight = self.smallFont:getHeight()
    love.graphics.print(button.text, button.x + (button.width - textWidth) / 2,
        button.y + (button.height - textHeight) / 2)

    love.graphics.setLineWidth(1)
end

function Menu:handleClick(x, y, state)
    local buttons = {}

    if state == "menu" then
        buttons = self.menuButtons
    elseif state == "options" then
        buttons = self.optionsButtons
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
