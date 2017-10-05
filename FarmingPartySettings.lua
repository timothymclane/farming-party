local ADDON_NAME = "FarmingParty"
local ADDON_VERSION = "0.1.0"

local LAM2 = LibStub("LibAddonMenu-2.0")
if not LAM2 then return end

FarmingPartySettings = ZO_Object:Subclass()

local settings = nil

function FarmingPartySettings:New()
    local obj = ZO_Object.New(self)
    obj:Initialize()
    return obj
end

function FarmingPartySettings:Initialize()
    local FarmingPartyDefaults = {
        displayOnWindow = true,
        displayOnChat = true,
        displayOwnLoot = true,
        displayGroupLoot = true,
        positionLeft = nil,
        positionTop = nil,
        displayLootValue = true,
        manualHighscoreReset = true,
    }
    
    --
    settings = ZO_SavedVars:New(ADDON_NAME .. "_db", 2, nil, FarmingPartyDefaults)
    --
    if not settings.displayOnWindow then FarmingPartyWindow:SetHidden(not settings.displayOnWindow) end
    local sceneFragment = ZO_HUDFadeSceneFragment:New(FarmingPartyWindow)
    sceneFragment:SetConditional(function() return settings.displayOnWindow end)
    HUD_SCENE:AddFragment(sceneFragment)
    HUD_UI_SCENE:AddFragment(sceneFragment)
    --
    if settings.displayOnWindow then
        self:SetWindowValues()
    end
    
    local panelData = {
        type = "panel",
        name = "Farming Party",
        displayName = "Farming Party",
        author = "Aldanga",
        version = ADDON_VERSION,
        slashCommand = "/fp",
        registerForRefresh = true,
        registerForDefaults = true,
    }
    
    LAM2:RegisterAddonPanel(ADDON_NAME .. "Panel", panelData)
    
    local optionsTable = {
        {
            type = "header",
            name = "Display and Count",
            width = "full",
        },
        {
            type = "checkbox",
            name = "Own loot",
            tooltip = "Show or hide loot the loot you get.",
            getFunc = function() return settings.displayOwnLoot end,
            setFunc = function(value)self:ToggleOwnLoot(value) end,
            width = "full",
            default = FarmingPartyDefaults.displayOwnLoot,
        },
        {
            type = "checkbox",
            name = "Group loot",
            tooltip = "Show or hide the loot group members get.",
            getFunc = function() return settings.displayGroupLoot end,
            setFunc = function(value)self:ToggleFarmingParty(value) end,
            width = "full",
            default = FarmingPartyDefaults.displayGroupLoot,
        },
        {
            type = "checkbox",
            name = "Loot value",
            tooltip = "Show or hide loot value on chat/window.",
            getFunc = function() return settings.displayLootValue end,
            setFunc = function(value)self:ToggleLootValue(value) end,
            width = "full",
            default = FarmingPartyDefaults.displayLootValue,
        },
        {
            type = "checkbox",
            name = "Trash",
            tooltip = "Show or hide trash (grey) items on loot.",
            getFunc = function() return settings.displayTrash end,
            setFunc = function(value)self:ToggleTrash(value) end,
            width = "full",
            default = FarmingPartyDefaults.displayTrash
        },
        {
            type = "checkbox",
            name = "Normal",
            tooltip = "Show or hide normal (white) items on loot.",
            getFunc = function() return settings.displayNormal end,
            setFunc = function(value)self:ToggleNormal(value) end,
            width = "full",
            default = FarmingPartyDefaults.displayNormal
        },
        {
            type = "checkbox",
            name = "Fine",
            tooltip = "Show or hide fine (green) items on loot.",
            getFunc = function() return settings.displayFine end,
            setFunc = function(value)self:ToggleFine(value) end,
            width = "full",
            default = FarmingPartyDefaults.displayFine
        },
        {
            type = "checkbox",
            name = "Superior",
            tooltip = "Show or hide superior (blue) items on loot.",
            getFunc = function() return settings.displaySuperior end,
            setFunc = function(value)self:ToggleSuperior(value) end,
            width = "full",
            default = FarmingPartyDefaults.displaySuperior
        },
        {
            type = "checkbox",
            name = "Epic",
            tooltip = "Show or hide epic (purple) items on loot.",
            getFunc = function() return settings.displayEpic end,
            setFunc = function(value)self:ToggleEpic(value) end,
            width = "full",
            default = FarmingPartyDefaults.displayEpic
        },
        {
            type = "checkbox",
            name = "Legendary",
            tooltip = "Show or hide legendary (yellow) items on loot.",
            getFunc = function() return settings.displayLegendary end,
            setFunc = function(value)self:ToggleLegendary(value) end,
            width = "full",
            default = FarmingPartyDefaults.displayLegendary
        },
        
        {
            type = "header",
            name = "Display Settings",
            width = "full",
        },
        {
            type = "checkbox",
            name = "Display on chat",
            tooltip = "Show or hide loot on chat.",
            getFunc = function() return settings.displayOnChat end,
            setFunc = function(value)self:ToggleOnChat(value) end,
            width = "full",
            default = FarmingPartyDefaults.displayOnChat
        },
        {
            type = "checkbox",
            name = "Display on window",
            tooltip = "Show or hide loot on the window.",
            getFunc = function() return settings.displayOnWindow end,
            setFunc = function(value)self:ToggleOnWindow(value) end,
            width = "full",
            default = FarmingPartyDefaults.displayOnWindow,
        },
    }
    
    LAM2:RegisterOptionControls(ADDON_NAME .. "Panel", optionsTable)
end

function FarmingPartySettings:GetSettings()
    return settings
end

function FarmingPartySettings:DisplayInChat()
    return settings.displayOnChat
end

function FarmingPartySettings:DisplayOwnLoot()
    return settings.displayOwnLoot
end

function FarmingPartySettings:DisplayGroupLoot()
    return settings.displayGroupLoot
end

function FarmingPartySettings:DisplayLootValue()
    return settings.displayLootValue
end

function FarmingPartySettings:MoveStart()
    FarmingPartyWindowBG:SetAlpha(0.5)
    FarmingPartyWindowBuffer:ShowFadedLines()
end

function FarmingPartySettings:MoveStop()
    FarmingPartyWindowBG:SetAlpha(0)
    settings.positionLeft = math.floor(FarmingPartyWindow:GetLeft())
    settings.positionTop = math.floor(FarmingPartyWindow:GetTop())
end

function FarmingPartySettings:SetWindowValues()
    local left = settings.positionLeft
    local top = settings.positionTop
    
    FarmingPartyWindow:ClearAnchors()
    FarmingPartyWindow:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, left, top)
    FarmingPartyWindow:SetAlpha(0.5)
    FarmingPartyWindowBG:SetAlpha(0)
    FarmingPartyWindow:SetHidden(false)
    
    FarmingPartyWindowBuffer:ClearAnchors()
    FarmingPartyWindowBuffer:SetAnchor(TOP, FarmingPartyWindow, TOP, 0, 0)
    FarmingPartyWindowBuffer:SetWidth(400)
    FarmingPartyWindowBuffer:SetHeight(80)
    
    --use the same font as in chat window
    local face = ZoFontEditChat:GetFontInfo()
    local fontSize = GetChatFontSize()
    local decoration = (fontSize <= 14 and "soft-shadow-thin" or "soft-shadow-thick")
    FarmingPartyWindowBuffer:SetFont(zo_strjoin("|", face, fontSize, decoration))
end

--[[
Addon menu functions
]]
--
function FarmingPartySettings:ToggleTrash(value)
    settings.displayTrash = value
end

function FarmingPartySettings:ToggleNormal(value)
    settings.displayNormal = value
end

function FarmingPartySettings:ToggleFine(value)
    settings.displayFine = value
end

function FarmingPartySettings:ToggleSuperior(value)
    settings.displaySuperior = value
end

function FarmingPartySettings:ToggleEpic(value)
    settings.displayEpic = value
end

function FarmingPartySettings:ToggleLegendary(value)
    settings.displayLegendary = value
end

function FarmingPartySettings:ToggleOnChat(value)
    settings.displayOnChat = value
end

function FarmingPartySettings:ToggleOnWindow(value)
    settings.displayOnWindow = value
    if value then self:SetWindowValues() end
end

function FarmingPartySettings:ToggleOwnLoot(value)
    settings.displayOwnLoot = value
end

function FarmingPartySettings:ToggleFarmingParty(value)
    settings.displayGroupLoot = value
end

function FarmingPartySettings:ToggleLootValue(value)
    settings.displayLootValue = value
end
