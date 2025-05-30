local function logDebug(message)
    local debugEnabled = false -- Set to false to disable debug messages
    if debugEnabled then
        print("GigaBooster: " .. message)
    end
end



logDebug("GigaBooster Addon Loaded")


local frame = CreateFrame("Frame")
local SLKeystoneItemId = 180653
local currentCharKey = UnitName("player") .. "-" .. GetRealmName()
GigaBoosterDB = GigaBoosterDB or {}

local function onEvent(self, event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        local isInitialLogin, isReloadingUi = ...
        if not isInitialLogin and not isReloadingUi then
            logDebug("PLAYER_ENTERING_WORLD event: not initial login or UI reload")
            SaveWeeklyMPlus10RunsCount() -- at this point, the weekly M+10 runs count is already registered. wont work if the player just logged in, because it would read previous char's session
            return
        else
            logDebug("EVENT [PLAYER_ENTERING_WORLD]")
            SaveItemLevel()
            SaveKeystone()
            SaveMythicPlusRating()
        end
    elseif event == "CHALLENGE_MODE_MAPS_UPDATE" then
        logDebug("EVENT [CHALLENGE_MODE_MAPS_UPDATE]")
        SaveWeeklyMPlus10RunsCount()
    elseif event == "ITEM_CHANGED" then
        local _, newHyperlink = ...
        logDebug("EVENT [ITEM_CHANGED] " .. newHyperlink)
        SaveKeystone()
    elseif event == "BAG_UPDATE_DELAYED" then
        SaveKeystone()
    elseif event == "CHALLENGE_MODE_COMPLETED" then
        logDebug("EVENT [CHALLENGE_MODE_COMPLETED]")
        SaveKeystone()
        SaveMythicPlusRating()
    elseif event == "CHALLENGE_MODE_START" then
        logDebug("EVENT [CHALLENGE_MODE_START]")
        SaveKeystone()
    elseif event == "WEEKLY_REWARDS_UPDATE" then
        logDebug("EVENT [WEEKLY_REWARDS_UPDATE]")
        -- uncommented for now, because it keeps triggering too early to register the newest run
        -- SaveWeeklyMPlus10RunsCount()
    elseif event == "UNIT_INVENTORY_CHANGED" then
        logDebug("EVENT [UNIT_INVENTORY_CHANGED]")
        SaveItemLevel()
    else
        logDebug("EVENT [" .. event .. "]")
    end
end

function SaveKeystone()
    C_Timer.After(0.5, function()
        local keystoneItemLink = FindCurrentKeystoneLink()
        if keystoneItemLink then
            local dungeon, level = string.match(keystoneItemLink, "%[Keystone:%s*(.-)%s*%((%d+)%)%]") -- [Keystone: Operation: Mechagon - Workshop (10)]
            GetCharDb().currKeystoneDungeon = GetDungeonAbbreviation(dungeon)
            GetCharDb().currKeyStoneLevel = tonumber(level)
            GetCharDb().currKeystoneLink = keystoneItemLink
        else
            logDebug("No Keystone found.")
        end
    end)
end

function FindCurrentKeystoneLink()
    for bag = 0, NUM_BAG_SLOTS do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            if (C_Container.GetContainerItemID(bag, slot) == SLKeystoneItemId) then
                local itemLink = C_Container.GetContainerItemLink(bag, slot) -- [Keystone: Operation: Mechagon - Workshop (10)]
                if itemLink then
                    logDebug("Found Keystone: " .. itemLink)
                    return itemLink
                end
            end
        end
    end
    logDebug("No Keystone found in bags.")
end

function SaveMythicPlusRating()
    local mythicPlusRating = C_ChallengeMode.GetOverallDungeonScore()
    logDebug("Mythic Plus Rating: " .. mythicPlusRating)
    GetCharDb().mythicPlusRating = mythicPlusRating
end

function SaveItemLevel()
    C_Timer.After(0.5, function()
        local avgItemLevel, avgItemLevelEquipped = GetAverageItemLevel()
        logDebug("New Item Level: " .. avgItemLevel .. " | " .. avgItemLevelEquipped)
        GetCharDb().avgItemLevel = avgItemLevel
        GetCharDb().avgItemLevelEquipped = avgItemLevelEquipped
    end)
end

---@return GigaBoosterCharDB
function GetCharDb()
    if not GigaBoosterDB[currentCharKey] then
        GigaBoosterDB[currentCharKey] = {
            currKeystoneDungeon = nil,
            currKeyStoneLevel = nil,
            currKeystoneLink = nil,
            avgItemLevel = nil,
            avgItemLevelEquipped = nil,
            mythicPlusRating = nil,
            weeklyMPlus10RunsCount = 0,
        }
    end

    return GigaBoosterDB[currentCharKey]
end

function GetDungeonAbbreviation(dungeonName)
    local dungeonAbbreviations = {
        ["The MOTHERLODE!!"] = "ML",
        ["Theater of Pain"] = "TOP",
        ["The Rookery"] = "ROOK",
        ["Priory of the Sacred Flame"] = "PSF",
        ["Cinderbrew Meadery"] = "BREW",
        ["Darkflame Cleft"] = "DFC",
        ["Operation: Mechagon - Workshop"] = "WORK",
        ["Operation: Floodgate"] = "FLOOD",
    }
    return dungeonAbbreviations[dungeonName] or dungeonName
end

function SaveWeeklyMPlus10RunsCount()
    local runs = C_MythicPlus.GetRunHistory(false, true)
    local plus10Runs = 0
    for _, run in ipairs(runs) do
        if run.level >= 10 then
            plus10Runs = plus10Runs + 1
        end
    end

    logDebug("Weekly M+10 Runs Count: " .. plus10Runs)

    local charDb = GetCharDb()
    if (plus10Runs < charDb.weeklyMPlus10RunsCount) then
        logDebug("Warning: Weekly M+10 runs count decreased from " ..
            charDb.weeklyMPlus10RunsCount .. " to " .. plus10Runs)
        return
    end
    GetCharDb().weeklyMPlus10RunsCount = plus10Runs
end

function PrintAllKeystones()
    print("=== GigaBooster: All Character Keystones ===")
    for char, data in pairs(GigaBoosterDB) do
        local dungeon = data.currKeystoneDungeon or "None"
        local level = data.currKeyStoneLevel or "-"
        print(char .. ": " .. dungeon .. " (" .. level .. ")")
    end
end

function PrintAllWeeklyMplus10RunCounts()
    print("=== GigaBooster: Weekly M+10 Runs ===")
    for char, data in pairs(GigaBoosterDB) do
        local count = data.weeklyMPlus10RunsCount or 0
        print(char .. ": " .. count .. " runs")
    end
end

SLASH_GIGABOOSTER1 = "/gb"
SLASH_GIGABOOSTER2 = "/gigabooster"
SlashCmdList["GIGABOOSTER"] = function(msg)
    msg = msg:lower()
    if msg == "keys" then
        PrintAllKeystones()
    elseif msg == "vault" then
        PrintAllWeeklyMplus10RunCounts()
    else
        print("GigaBooster: Unknown command. Try '/gb keys' or '/gb vault'.")
    end
end



frame:RegisterEvent("PLAYER_ENTERING_WORLD")      -- player entering world (after loading screen)
frame:RegisterEvent("BAG_UPDATE_DELAYED")         -- new key from vault
frame:RegisterEvent("ITEM_CHANGED")               -- downgrade keystone in dornogal, change key end of dungeon
frame:RegisterEvent("CHALLENGE_MODE_START")       -- start of dungeon (keystone drops by 1 level)
frame:RegisterEvent("CHALLENGE_MODE_COMPLETED")   -- end of mythic dungeon
frame:RegisterEvent("WEEKLY_REWARDS_UPDATE")      -- when a dungeon is completed and the run has been registered
frame:RegisterEvent("CHALLENGE_MODE_MAPS_UPDATE") -- when a new keystone is added to the bag
frame:SetScript("OnEvent", onEvent)

---@class GigaBoosterCharDB
---@field currKeystoneDungeon string | nil
---@field currKeyStoneLevel number | nil
---@field currKeystoneLink string | nil
---@field avgItemLevel number | nil
---@field avgItemLevelEquipped number | nil
---@field mythicPlusRating number | nil
---@field weeklyMPlus10RunsCount number
