-- Luminex - Laser Puzzle
-- License: MIT
-- Copyright (c) 2025 Jericho Crosby (Chalwk)

local helpers = {
    OPPOSITES = {
        up = "down",
        down = "up",
        left = "right",
        right = "left"
    },

    BULB_COLORS = {
        [1] = {
            bulbColor = { 0.9, 0.9, 0.8, 0.3 },
            glowColor = { 1.0, 0.9, 0.6 },
            filamentColor = { 1.0, 0.8, 0.3 }
        },
        [2] = {
            bulbColor = { 0.7, 0.8, 1.0, 0.3 },
            glowColor = { 0.6, 0.8, 1.0 },
            filamentColor = { 0.8, 0.9, 1.0 }
        },
        [3] = {
            bulbColor = { 0.8, 1.0, 0.8, 0.3 },
            glowColor = { 0.6, 1.0, 0.6 },
            filamentColor = { 0.9, 1.0, 0.7 }
        },
        [4] = {
            bulbColor = { 0.9, 0.7, 1.0, 0.3 },
            glowColor = { 0.8, 0.6, 1.0 },
            filamentColor = { 1.0, 0.8, 1.0 }
        }
    },

    CONNECTIONS = {
        straight = {
            [0] = { "up", "down" },
            [1] = { "left", "right" },
            [2] = { "up", "down" },
            [3] = { "left", "right" },
        },
        corner = {
            [0] = { "up", "right" },
            [1] = { "right", "down" },
            [2] = { "down", "left" },
            [3] = { "left", "up" },
        },
        t_junction = {
            [0] = { "up", "right", "down" },
            [1] = { "right", "down", "left" },
            [2] = { "down", "left", "up" },
            [3] = { "left", "up", "right" },
        },
        cross = { [0] = { "up", "right", "down", "left" } },
        source = {
            [0] = { "right" },
            [1] = { "down" },
            [2] = { "left" },
            [3] = { "up" },
        },
        target = { [0] = { "up", "right", "down", "left" } }
    },

    TOOL_MAP = {
        ["1"] = "empty",
        ["2"] = "straight",
        ["3"] = "corner",
        ["4"] = "t_junction",
        ["5"] = "cross",
        ["6"] = "source",
        ["7"] = "target",
    },

    levelToLua = function(levelData)
        local lua = "return {\n"

        -- Name
        lua = lua .. "    name = \"" .. levelData.name .. "\",\n"

        -- Grid
        lua = lua .. "    grid = {\n"
        for y, row in ipairs(levelData.grid) do
            lua = lua .. "        { "
            for x, tileType in ipairs(row) do
                lua = lua .. "\"" .. tileType .. "\""
                if x < #row then lua = lua .. ", " end
            end
            lua = lua .. " }"
            if y < #levelData.grid then lua = lua .. ",\n" else lua = lua .. "\n" end
        end
        lua = lua .. "    },\n"

        -- Rotations
        local columns = #levelData.grid[1] -- Get the number of columns from the first row
        lua = lua .. "    rotations = {\n        "
        for i, rotation in ipairs(levelData.rotations) do
            lua = lua .. rotation
            if i < #levelData.rotations then lua = lua .. ", " end
            if i % columns == 0 and i < #levelData.rotations then
                lua = lua .. "\n        "
            end
        end
        lua = lua .. "\n    },\n"

        -- Bulb types
        if #levelData.bulbTypes > 0 then
            lua = lua .. "    bulbTypes = { "
            for i, bulbType in ipairs(levelData.bulbTypes) do
                lua = lua .. bulbType
                if i < #levelData.bulbTypes then lua = lua .. ", " end
            end
            lua = lua .. " }\n"
        else
            lua = lua .. "    bulbTypes = { 1 }\n"
        end

        lua = lua .. "}"
        return lua
    end
}

return helpers
