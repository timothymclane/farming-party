local RELEASE_COUNT = 3

FarmingPartyMemberList = ZO_Object:Subclass()
function FarmingPartyMemberList:New()
    local obj = ZO_Object.New(self)
    self:Initialize()
    return obj
end

local listContainer
local members = {}
local saveData = {}

function FarmingPartyMemberList:Initialize()
    EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_GROUP_MEMBER_JOINED, function(...)self:OnMemberJoined(...) end)
    EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_GROUP_MEMBER_LEFT, function(...)self:OnMemberLeft(...) end)
    saveData = ZO_SavedVars:New("FarmingPartyMemberList_db", RELEASE_COUNT, nil, {members = {}})
    FarmingParty.Modules.Members = FarmingPartyMembers:New(saveData)
    members = FarmingParty.Modules.Members
    FarmingPartyMembersWindow:ClearAnchors()
    local settings = FarmingPartySettings:GetSettings()
    FarmingPartyMembersWindow:SetAnchor(
        TOPLEFT,
        GuiRoot,
        TOPLEFT,
        settings.window.positionLeft,
        settings.window.positionTop
    )
    FarmingPartyMembersWindow:SetDimensions(settings.window.width, settings.window.height)
    FarmingPartyMembersWindow:SetHandler("OnResizeStop", function(...)self:WindowResizeHandler(...) end)
    FarmingPartyMemberList:SetWindowTransparency()
    FarmingPartyMemberList:SetWindowBackgroundTransparency()
    self:AddAllGroupMembers()
    self:SetupScrollList()
    self:UpdateScrollList()
    members:RegisterCallback("OnKeysUpdated", self.UpdateScrollList)
end

function FarmingPartyMemberList:Finalize()
    local _, _, _, _, offsetX, offsetY = FarmingPartyMembersWindow:GetAnchor(0)
    
    local settings = FarmingPartySettings:GetSettings()
    settings.window.positionLeft = FarmingPartyMembersWindow:GetLeft()
    settings.window.positionTop = FarmingPartyMembersWindow:GetTop()
    settings.window.width = FarmingPartyMembersWindow:GetWidth()
    settings.window.height = FarmingPartyMembersWindow:GetHeight()
    saveData.members = members:GetCleanMembers()
end

function FarmingPartyMemberList:GetWindowTransparency()
    return settings.window.transparency
end

function FarmingPartyMemberList:SetWindowTransparency(value)
    local settings = FarmingPartySettings:GetSettings()
    if value ~= nil then
        settings.window.transparency = value
    end
    FarmingPartyMembersWindow:SetAlpha(settings.window.transparency / 100)
end

function FarmingPartyMemberList:SetWindowBackgroundTransparency(value)
    local settings = FarmingPartySettings:GetSettings()
    if value ~= nil then
        settings.window.backgroundTransparency = value
    end
    FarmingPartyMembersWindow:GetNamedChild("BG"):SetAlpha(settings.window.backgroundTransparency / 100)
end

function FarmingPartyMemberList:WindowResizeHandler(control)
    local width, height = control:GetDimensions()
    local settings = FarmingPartySettings:GetSettings()
    settings.window.width = width
    settings.window.height = height
    
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
    listContainer = FarmingPartyMembersWindow:GetNamedChild("List")
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
        memberArray[#memberArray + 1] = members:GetMember(memberKeys[i])
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
    local memberName = GetControl(rowControl, "Farmer")
    local bestItem = GetControl(rowControl, "BestItemName")
    local totalValue = GetControl(rowControl, "TotalValue")
    
    memberName:SetText(data.displayName)
    bestItem:SetText(data.bestItem.itemLink)
    totalValue:SetText(FarmingParty.FormatNumber(data.totalValue, 2) .. 'g')
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
