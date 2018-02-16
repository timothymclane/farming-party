local RELEASE_COUNT = 3

local listContainer
local members = {}
local saveData = {}
local Settings

FarmingPartyMemberList = ZO_Object:Subclass()
function FarmingPartyMemberList:New()
    local obj = ZO_Object.New(self)
    self:Initialize()
    return obj
end

function FarmingPartyMemberList:Initialize()
    saveData = ZO_SavedVars:New("FarmingPartyMemberList_db", RELEASE_COUNT, nil, {members = {}})
    FarmingParty.Modules.Members = FarmingPartyMembers:New(saveData)
    members = FarmingParty.Modules.Members

    listContainer = FarmingPartyMembersWindow:GetNamedChild("List")

    FarmingPartyMembersWindow:ClearAnchors()
    Settings = FarmingParty.Settings
    FarmingPartyMembersWindow:SetAnchor(
        TOPLEFT,
        GuiRoot,
        TOPLEFT,
        Settings:Window().positionLeft,
        Settings:Window().positionTop
    )

    FarmingPartyMembersWindow:SetDimensions(Settings:Window().width, Settings:Window().height)
    FarmingPartyMembersWindow:SetHandler("OnResizeStop", function(...)self:WindowResizeHandler(...) end)
    FarmingPartyMembersWindow.onResize = self.onResize
    
    FarmingPartyMemberList:SetWindowTransparency()
    FarmingPartyMemberList:SetWindowBackgroundTransparency()

    self:AddAllGroupMembers()
    self:SetupScrollList()
    self:UpdateScrollList()

    if (Settings.Status() == Settings.TRACKING_STATUS.ENABLED) then
        self:AddEventHandlers()
    end

    members:RegisterCallback("OnKeysUpdated", self.UpdateScrollList)
end

-- I should handle this with callbacks from the settings, if possible
function FarmingPartyMemberList:AddEventHandlers()
    EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_GROUP_MEMBER_JOINED, function(...)self:OnMemberJoined(...) end)
    EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_GROUP_MEMBER_LEFT, function(...)self:OnMemberLeft(...) end)
    Settings:ToggleStatusValue(Settings.TRACKING_STATUS.ENABLED)
end

function FarmingPartyMemberList:RemoveEventHandlers()
    EVENT_MANAGER:UnregisterForEvent(ADDON_NAME, EVENT_GROUP_MEMBER_JOINED)
    EVENT_MANAGER:UnregisterForEvent(ADDON_NAME, EVENT_GROUP_MEMBER_LEFT)
    Settings:ToggleStatusValue(Settings.TRACKING_STATUS.DISABLED)
end

function FarmingPartyMemberList:Finalize()
    local _, _, _, _, offsetX, offsetY = FarmingPartyMembersWindow:GetAnchor(0)
    
    Settings:Window().positionLeft = FarmingPartyMembersWindow:GetLeft()
    Settings:Window().positionTop = FarmingPartyMembersWindow:GetTop()
    Settings:Window().width = FarmingPartyMembersWindow:GetWidth()
    Settings:Window().height = FarmingPartyMembersWindow:GetHeight()
    saveData.members = members:GetCleanMembers()
end

function FarmingPartyMemberList:GetWindowTransparency()
    return Settings:Window().transparency
end

function FarmingPartyMemberList:SetWindowTransparency(value)
    if value ~= nil then
        Settings:Window().transparency = value
    end
    FarmingPartyMembersWindow:SetAlpha(Settings:Window().transparency / 100)
end

function FarmingPartyMemberList:SetWindowBackgroundTransparency(value)
    if value ~= nil then
        Settings:Window().backgroundTransparency = value
    end
    FarmingPartyMembersWindow:GetNamedChild("BG"):SetAlpha(Settings:Window().backgroundTransparency / 100)
end

function FarmingPartyMemberList:WindowResizeHandler(control)
    local width, height = control:GetDimensions()
    Settings:Window().width = width
    Settings:Window().height = height
    
    local scrollData = ZO_ScrollList_GetDataList(listContainer)
    ZO_ScrollList_Commit(listContainer)
end

-- EVENT_GROUP_MEMBER_JOINED
function FarmingPartyMemberList:OnMemberJoined(event, memberName)
    self:AddAllGroupMembers()
end

-- EVENT_GROUP_MEMBER_LEFT
function FarmingPartyMemberList:OnMemberLeft(event, memberName, reason, wasLocalPlayer)
    -- Disbanding a group counts as the local player leaving the group
    -- so we want to not remove their items if they're on the event
    if (not wasLocalPlayer) then
        local name = zo_strformat(SI_UNIT_NAME, memberName)
        members:DeleteMember(name)
    else
        local playerName = GetUnitName("player")
        local memberKeys = members:GetKeys()
        for i = 1, #memberKeys do
            if (memberKeys[i] ~= playerName) then
                members:DeleteMember(memberKeys[i])
            end
        end
    end
end

function FarmingPartyMemberList:SetupScrollList()
    ZO_ScrollList_AddResizeOnScreenResize(listContainer)
    ZO_ScrollList_AddDataType(
        listContainer,
        FarmingParty.DataTypes.MEMBER,
        "FarmingPartyMemberDataRow",
        20,
        function(listControl, data)
            self:SetupMemberRow(listControl, data)
        end
)
end

function FarmingPartyMemberList:UpdateScrollList()
    local scrollData = ZO_ScrollList_GetDataList(listContainer)
    ZO_ScrollList_Clear(listContainer)
    
    local memberKeys = members:GetKeys()
    local memberList = members:GetMembers()
    local memberArray = {}
    for i = 1, #memberKeys do
        local mem = members:GetMember(memberKeys[i])
        mem.id = memberKeys[i]
        memberArray[#memberArray + 1] = mem
    end
    table.sort(memberArray, function(a, b)
        if (a.totalValue == b.totalValue) then
            return a.displayName < b.displayName
        end
        return a.totalValue > b.totalValue
    end)
    for i = 1, #memberArray do
        scrollData[#scrollData + 1] =
            ZO_ScrollList_CreateDataEntry(FarmingParty.DataTypes.MEMBER, {rawData = memberArray[i]})
    end
    
    ZO_ScrollList_Commit(listContainer)
end

function FarmingPartyMemberList:SetupMemberRow(rowControl, rowData)
    rowControl.data = rowData
    local data = rowData.rawData
    local memberId = GetControl(rowControl, "FarmerId")
    local memberName = GetControl(rowControl, "Farmer")
    local bestItem = GetControl(rowControl, "BestItemName")
    local totalValue = GetControl(rowControl, "TotalValue")
    
    memberId:SetText(data.id)
    memberName:SetText(data.displayName)
    bestItem:SetText(data.bestItem.itemLink)
    totalValue:SetText(FarmingParty.FormatNumber(data.totalValue, 2) .. 'g')
end

function FarmingPartyMemberList.onResize()
    ZO_ScrollList_Commit(listContainer)
end

function FarmingPartyMemberList:ToggleMembersWindow()
    FarmingPartyMembersWindow:SetHidden(not FarmingPartyMembersWindow:IsHidden())
end

function FarmingPartyMemberList:Reset()
    members:DeleteAllMembers()
    self:AddAllGroupMembers()
end

function FarmingPartyMemberList:AddAllGroupMembers()
    local countMembers = GetGroupSize()
    local rawMembers = {}
    local playerName = GetUnitName("player")
    rawMembers[playerName] = UndecorateDisplayName(GetDisplayName("player"))
    
    -- Get list of member names in current group
    for i = 1, countMembers do
        local unitTag = GetGroupUnitTagByIndex(i)
        if unitTag then
            local name = zo_strformat(SI_UNIT_NAME, GetUnitName(unitTag))
            if (name ~= playerName) then
                rawMembers[name] = UndecorateDisplayName(GetUnitDisplayName(unitTag))
            end
        end
    end
    
    -- Add all missing members
    for name, displayName in pairs(rawMembers) do
        if not members:HasMember(name) then
            local newMember = members:NewMember(name, displayName)
            members:SetMember(name, newMember)
        end
    end
end

function FarmingPartyMemberList:ShowAllGroupMembers()
    d(members)
    local player = members:GetMember(GetUnitName("player"))
    d("Total value: " .. tostring(player.totalValue))
end

function FarmingPartyMemberList:PrintScoresToChat()
    local topScorers = 'FARMING SCORES: '
    local array = {}
    local groupMembers = members:GetKeys()
    for i = 1, #groupMembers do
        local member = members:GetMember(groupMembers[i])
        local scoreData = {name = groupMembers[i], totalValue = member.totalValue, displayName = member.displayName}
        array[#array + 1] = scoreData
    end
    table.sort(array, function(a, b) return a.totalValue > b.totalValue end)
    for i = 1, #array do
        topScorers = topScorers .. array[i].displayName .. ': ' .. FarmingParty.FormatNumber(array[i].totalValue, 2) .. 'g. '
    end
    ZO_ChatWindowTextEntryEditBox:SetText(topScorers)
end
