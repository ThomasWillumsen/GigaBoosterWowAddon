local debugEnabled = false

if debugEnabled then print("Gigabooster successfully loaded!") end

local frame = CreateFrame("Frame")
local SLKeystoneItemId = 180653
local currentCharKey = UnitName("player") .. "-" .. GetRealmName()
GigaBoosterDB = GigaBoosterDB or {}

local function onEvent(self, event, ...)
    if event == "PLAYER_LOGIN" then
        if debugEnabled then print("EVENT [PLAYER_LOGIN]") end
        SaveItemLevel()
        SaveKeystone()
        SaveMythicPlusRating()
    elseif event == "ITEM_CHANGED" then
        local _, newHyperlink = ...
        if debugEnabled then print("EVENT [ITEM_CHANGED] " .. newHyperlink) end
        SaveKeystone()
    elseif event == "BAG_UPDATE" then
        SaveKeystone()
    elseif event == "CHALLENGE_MODE_COMPLETED" then
        if debugEnabled then print("EVENT [CHALLENGE_MODE_COMPLETED]") end
        SaveKeystone()
        SaveMythicPlusRating()
    elseif event == "CHALLENGE_MODE_START" then
        if debugEnabled then print("EVENT [CHALLENGE_MODE_START]") end
        SaveKeystone()
    elseif event == "UNIT_INVENTORY_CHANGED" then
        if debugEnabled then print("EVENT [UNIT_INVENTORY_CHANGED]") end
        SaveItemLevel()
    else
        if debugEnabled then print("EVENT [" .. event .. "]") end
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
            if debugEnabled then print("No Keystone found.") end
        end
    end)
end

function FindCurrentKeystoneLink()
    for bag = 0, NUM_BAG_SLOTS do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            if (C_Container.GetContainerItemID(bag, slot) == SLKeystoneItemId) then
                local itemLink = C_Container.GetContainerItemLink(bag, slot) -- [Keystone: Operation: Mechagon - Workshop (10)]
                if itemLink then
                    if debugEnabled then print("Found Keystone: " .. itemLink) end
                    return itemLink
                end
            end
        end
    end
    if debugEnabled then print("No Keystone found in bags.") end
end

function SaveMythicPlusRating()
    local mythicPlusRating = C_ChallengeMode.GetOverallDungeonScore()
    if debugEnabled then print("Mythic Plus Rating: " .. mythicPlusRating) end
    GetCharDb().mythicPlusRating = mythicPlusRating
end

function SaveItemLevel()
    C_Timer.After(0.5, function()
        local avgItemLevel, avgItemLevelEquipped = GetAverageItemLevel()
        if debugEnabled then print("New Item Level: " .. avgItemLevel .. " | " .. avgItemLevelEquipped) end
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

function PrintAllKeystones()
    print("=== GigaBooster: All Character Keystones ===")
    for char, data in pairs(GigaBoosterDB) do
        local dungeon = data.currKeystoneDungeon or "None"
        local level = data.currKeyStoneLevel or "-"
        print(char .. ": " .. dungeon .. " (" .. level .. ")")
    end
end

SLASH_GIGABOOSTER1 = "/gb"
SLASH_GIGABOOSTER2 = "/gigabooster"
SlashCmdList["GIGABOOSTER"] = function(msg)
    msg = msg:lower()
    if msg == "keys" then
        PrintAllKeystones()
    else
        print("GigaBooster: Unknown command. Try '/gb keys'")
    end
end



frame:RegisterEvent("PLAYER_LOGIN")             -- player login
frame:RegisterEvent("BAG_UPDATE")               -- new key from vault
frame:RegisterEvent("ITEM_CHANGED")             -- downgrade keystone in dornogal, change key end of dungeon
frame:RegisterEvent("CHALLENGE_MODE_START")     -- start of dungeon (keystone drops by 1 level)
frame:RegisterEvent("CHALLENGE_MODE_COMPLETED") -- end of mythic dungeon
frame:SetScript("OnEvent", onEvent)

---@class GigaBoosterCharDB
---@field currKeystoneDungeon string | nil
---@field currKeyStoneLevel number | nil
---@field currKeystoneLink string | nil
---@field avgItemLevel number | nil
---@field avgItemLevelEquipped number | nil
---@field mythicPlusRating number | nil
