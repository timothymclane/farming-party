local ADDON_NAME = "Farming Party"
local ADDON_VERSION = "2.10.1"

local LAM2 = LibStub("LibAddonMenu-2.0")
if not LAM2 then
    return
end

FarmingPartySettings = ZO_Object:Subclass()

local qualityChoiceValues = {
    ITEM_QUALITY_TRASH,
    ITEM_QUALITY_NORMAL,
    ITEM_QUALITY_MAGIC,
    ITEM_QUALITY_ARCANE,
    ITEM_QUALITY_ARTIFACT,
    ITEM_QUALITY_LEGENDARY
}

FarmingPartySettings.TRACKING_STATUS = {
    ENABLED = "ENABLED",
    DISABLED = "DISABLED"
}

function FarmingPartySettings:New()
    local obj = ZO_Object.New(self)
    self:Initialize()
    return obj
end

function FarmingPartySettings:Initialize()
    local FarmingPartyDefaults = {
        excludeFromTracking = {
            gear = false,
            motifs = false
        },
        minimumLootQuality = qualityChoiceValues[1],
        trackGroupLoot = true,
        trackSelfLoot = true,
        displayOnWindow = true,
        displayOnChat = true,
        displayOwnLoot = true,
        displayGroupLoot = true,
        positionLeft = nil,
        positionTop = nil,
        displayLootValue = true,
        manualHighscoreReset = true,
        window = {
            transparency = 100,
            backgroundTransparency = 100,
            positionLeft = 0,
            positionTop = 0,
            width = 650,
            height = 150
        },
        itemsWindow = {
            transparency = 100,
            backgroundTransparency = 100,
            positionLeft = 0,
            positionTop = 150,
            width = 650,
            height = 150
        },
        status = self.TRACKING_STATUS.ENABLED,
        chatPrefix = "FARMING SCORES:"
    }
    
    self.settings = ZO_SavedVars:New("FarmingPartySettings_db", 2, nil, FarmingPartyDefaults)

    if not self:DisplayOnWindow() then
        FarmingPartyWindow:SetHidden(true)
    end
    local sceneFragment = ZO_HUDFadeSceneFragment:New(FarmingPartyWindow)
    sceneFragment:SetConditional(
        function()
            return self:DisplayOnWindow()
        end
    )
    HUD_SCENE:AddFragment(sceneFragment)
    HUD_UI_SCENE:AddFragment(sceneFragment)

    if self.settings.displayOnWindow then
        self:SetWindowValues()
    end
    
    local panelData = {
        type = "panel",
        name = ADDON_NAME,
        displayName = ADDON_NAME,
        author = "Aldanga",
        version = ADDON_VERSION,
        slashCommand = "/fp",
        registerForRefresh = true,
        registerForDefaults = true
    }
    
    LAM2:RegisterAddonPanel(ADDON_NAME .. "Panel", panelData)
    
    local optionsTable = {
        {
            type = "header",
            name = "Loot Tracking",
            width = "full"
        },
        {
            type = "dropdown",
            name = "Minimum Item Quality",
            choices = {"Trash", "Normal", "Fine", "Superior", "Epic", "Legendary"},
            choicesValues = qualityChoiceValues,
            tooltip = "Minimum item quality tracked.",
            getFunc = function()
                return self:MinimumLootQuality()
            end,
            setFunc = function(value)
                self:ToggleMinimumLootQuality(value)
            end,
            width = "full"
        },
        {
            type = "checkbox",
            name = "Gear",
            tooltip = "Track gear items looted by group members.",
            getFunc = function()
                return self:TrackGearLoot()
            end,
            setFunc = function(value)
                self:ToggleTrackGearLoot(value)
            end,
            width = "full"
        },
        {
            type = "checkbox",
            name = "Motifs",
            tooltip = "Track motifs looted by group members.",
            getFunc = function()
                return self:TrackMotifLoot()
            end,
            setFunc = function(value)
                self:ToggleTrackMotifLoot(value)
            end,
            width = "full"
        },
        {
            type = "checkbox",
            name = "Group members",
            tooltip = "Track items looted by group members.",
            getFunc = function()
                return self:TrackGroupLoot()
            end,
            setFunc = function(value)
                self:ToggleTrackGroupLoot(value)
            end,
            width = "full"
        },
        {
            type = "checkbox",
            name = "Self",
            tooltip = "Track items looted by you.",
            getFunc = function()
                return self:TrackSelfLoot()
            end,
            setFunc = function(value)
                self:ToggleTrackSelfLoot(value)
            end,
            width = "full"
        },
        {
            type = "header",
            name = "Display Settings",
            width = "full"
        },
        {
            type = "checkbox",
            name = "Log own loot",
            tooltip = "Show or hide the loot you get.",
            getFunc = function()
                return self:DisplayOwnLoot()
            end,
            setFunc = function(value)
                self:ToggleOwnLoot(value)
            end,
            width = "full"
        },
        {
            type = "checkbox",
            name = "Log group loot",
            tooltip = "Show or hide the loot group members get.",
            getFunc = function()
                return self:DisplayGroupLoot()
            end,
            setFunc = function(value)
                self:ToggleFarmingParty(value)
            end,
            width = "full"
        },
        {
            type = "checkbox",
            name = "Show loot value",
            tooltip = "Show or hide loot value on chat/window.",
            getFunc = function()
                return self:DisplayLootValue()
            end,
            setFunc = function(value)
                self:ToggleLootValue(value)
            end,
            width = "full"
        },
        {
            type = "checkbox",
            name = "Log to chat",
            tooltip = "Show or hide loot on chat.",
            getFunc = function()
                return self:DisplayInChat()
            end,
            setFunc = function(value)
                self:ToggleOnChat(value)
            end,
            width = "full"
        },
        {
            type = "checkbox",
            name = "Log to loot window",
            tooltip = "Show or hide loot on the window.",
            getFunc = function()
                return self:DisplayOnWindow()
            end,
            setFunc = function(value)
                self:ToggleOnWindow(value)
            end,
            width = "full"
        },
        {
            type = "slider",
            name = "Member window background transparency",
            tooltip = "Change the transparency of the background of the member window",
            min = 0,
            max = 100,
            step = 5,
            getFunc = function()
                return self:GetSettings().window.backgroundTransparency
            end,
            setFunc = function(value)
                FarmingParty.Modules.MemberList:SetWindowBackgroundTransparency(value)
            end,
            width = "full"
        },
        {
            type = "slider",
            name = "Member window transparency",
            tooltip = "Change the transparency of the member window",
            min = 0,
            max = 100,
            step = 5,
            getFunc = function()
                return self:GetSettings().window.transparency
            end,
            setFunc = function(value)
                FarmingParty.Modules.MemberList:SetWindowTransparency(value)
            end,
            width = "full"
        },
        {
            type = "slider",
            name = "Member items window background transparency",
            tooltip = "Change the transparency of the background of the member items window",
            min = 0,
            max = 100,
            step = 5,
            getFunc = function()
                return self:GetSettings().itemsWindow.backgroundTransparency
            end,
            setFunc = function(value)
                FarmingParty.Modules.MemberItems:SetWindowBackgroundTransparency(value)
            end,
            width = "full",
            default = 0
        },
        {
            type = "slider",
            name = "Member items window transparency",
            tooltip = "Change the transparency of the member items window",
            min = 0,
            max = 100,
            step = 5,
            getFunc = function()
                return self:GetSettings().itemsWindow.transparency
            end,
            setFunc = function(value)
                FarmingParty.Modules.MemberItems:SetWindowTransparency(value)
            end,
            width = "full",
            default = 0
        },
        {
            type = "header",
            name = "Chat Settings",
            width = "full"
        },
        {
            type = "editbox",
            name = "Scores to Chat Prefix",
            tooltip = "Change the text that's output before scores when using /fpc",
            getFunc = function()
                return self:ChatPrefix()
            end,
            setFunc = function(value)
                self:SetChatPrefix(value)
            end,
            width = "full"
        }
    }
    
    LAM2:RegisterOptionControls(ADDON_NAME .. "Panel", optionsTable)
end

function FarmingPartySettings:GetSettings()
    return self.settings
end

function FarmingPartySettings:MinimumLootQuality()
    return self.settings.minimumLootQuality
end

function FarmingPartySettings:TrackMotifLoot()
    return not self.settings.excludeFromTracking.motifs
end

function FarmingPartySettings:TrackGearLoot()
    return not self.settings.excludeFromTracking.gear
end

function FarmingPartySettings:TrackGroupLoot()
    return self.settings.trackGroupLoot
end

function FarmingPartySettings:TrackSelfLoot()
    return self.settings.trackSelfLoot
end

function FarmingPartySettings:DisplayInChat()
    return self.settings.displayOnChat
end

function FarmingPartySettings:DisplayOnWindow()
    return self.settings.displayOnWindow
end

function FarmingPartySettings:DisplayOwnLoot()
    return self.settings.displayOwnLoot
end

function FarmingPartySettings:DisplayGroupLoot()
    return self.settings.displayGroupLoot
end

function FarmingPartySettings:DisplayLootValue()
    return self.settings.displayLootValue
end

function FarmingPartySettings:ChatPrefix()
    return self.settings.chatPrefix
end

function FarmingPartySettings:Status()
    return self.settings.status
end

function FarmingPartySettings:Window()
    return self.settings.window
end

function FarmingPartySettings:ItemsWindow()
    return self.settings.itemsWindow
end

function FarmingPartySettings:MoveStart()
    FarmingPartyWindowBG:SetAlpha(0.5)
    FarmingPartyWindowBuffer:ShowFadedLines()
end

function FarmingPartySettings:MoveStop()
    FarmingPartyWindowBG:SetAlpha(0)
    self.settings.positionLeft = math.floor(FarmingPartyWindow:GetLeft())
    self.settings.positionTop = math.floor(FarmingPartyWindow:GetTop())
end

function FarmingPartySettings:SetWindowValues()
    local left = self.settings.positionLeft
    local top = self.settings.positionTop
    
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
function FarmingPartySettings:ToggleMinimumLootQuality(value)
    self.settings.minimumLootQuality = value
end

function FarmingPartySettings:ToggleTrackMotifLoot(value)
    self.settings.excludeFromTracking.motifs = not value
end

function FarmingPartySettings:ToggleTrackGearLoot(value)
    self.settings.excludeFromTracking.gear = not value
end

function FarmingPartySettings:ToggleTrackGroupLoot(value)
    self.settings.trackGroupLoot = value
end

function FarmingPartySettings:ToggleTrackSelfLoot(value)
    self.settings.trackSelfLoot = value
end

function FarmingPartySettings:ToggleOnChat(value)
    self.settings.displayOnChat = value
end

function FarmingPartySettings:ToggleOnWindow(value)
    self.settings.displayOnWindow = value
    if value then
        self:SetWindowValues()
    end
end

function FarmingPartySettings:ToggleOwnLoot(value)
    self.settings.displayOwnLoot = value
end

function FarmingPartySettings:ToggleFarmingParty(value)
    self.settings.displayGroupLoot = value
end

function FarmingPartySettings:ToggleLootValue(value)
    self.settings.displayLootValue = value
end

function FarmingPartySettings:ToggleStatusValue(value)
    self.settings.status = value
end

function FarmingPartySettings:SetChatPrefix(value)
    self.settings.chatPrefix = value
end
