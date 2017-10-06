FarmingPartyMemberList = ZO_Object:Subclass()
function FarmingPartyMemberList:New()
    local obj = ZO_Object.New(self)
    self:Initialize()
    return obj
end

local members = {}
local saveData = {}
function FarmingPartyMemberList:Initialize()
    EVENT_MANAGER:RegisterForEvent(
        ADDON_NAME,
        EVENT_LOOT_RECEIVED,
        function(...)
            self:OnItemLooted(...)
        end
    )
    EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_GROUP_MEMBER_JOINED, function(...)self:OnMemberJoined(...) end)
    EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_GROUP_MEMBER_LEFT, function(...)self:OnMemberLeft(...) end)
    saveData = ZO_SavedVars:New("FarmingPartyMemberList_db", 2, nil, {members = {}})
    members = FarmingPartyMembers:New(saveData)
    self.Members = members
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
end

-- EVENT_GROUP_MEMBER_JOINED
function FarmingPartyMemberList:OnMemberJoined(event, memberName)
    self:AddAllGroupMembers()
end

-- EVENT_GROUP_MEMBER_LEFT
function FarmingPartyMemberList:OnMemberLeft(event, memberName, reason, wasLocalPlayer)
    members:DeleteMember(memberName)
end

function FarmingPartyMemberList:SetupScrollList()
    listContainer = FarmingPartyMembersWindow:GetNamedChild("List")
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
    
    local groupMembers = members:GetKeys()
    for i = 1, #groupMembers do
        scrollData[#scrollData + 1] =
            ZO_ScrollList_CreateDataEntry(FarmingParty.DataTypes.MEMBER, members:GetMember(groupMembers[i]))
    end
    
    ZO_ScrollList_Commit(listContainer)
end

function FarmingPartyMemberList:SetupMemberRow(rowControl, rowData)
    rowControl.data = rowData
    local data = rowData.rawData
    local memberName = GetControl(rowControl, "Farmer")
    local bestItem = GetControl(rowControl, "BestItemName")
    local totalValue = GetControl(rowControl, "TotalValue")
    
    memberName:SetText(rowData.displayName)
    bestItem:SetText(rowData.bestItem.itemLink)
    totalValue:SetText(rowData.totalValue .. 'g')
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
    rawMembers[GetUnitName("player")] = GetDisplayName("player")
    
    -- Get list of member names in current group
    for i = 1, countMembers do
        local unitTag = GetGroupUnitTagByIndex(i)
        d(unitTag)
        if unitTag then
            local name = zo_strformat(SI_UNIT_NAME, GetUnitName(unitTag))
            if (name ~= playerName) then
                rawMembers[name] = GetUnitDisplayName(unitTag)
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

function FarmingPartyMemberList:FormatNumber(num, numDecimalPlaces)
    return tonumber(string.format("%." .. (numDecimalPlaces or 0) .. "f", num))
end

-- EVENT_LOOT_RECEIVED
function FarmingPartyMemberList:OnItemLooted(event, name, itemLink, quantity, itemSound, lootType, player)
    local looterName = zo_strformat(SI_UNIT_NAME, name)
    local itemValue = FarmingPartyMemberList:GetItemPrice(itemLink)
    
    local lootMessage = nil
    local itemQuality = GetItemLinkQuality(itemLink)
    local totalValue = FarmingPartyMemberList:FormatNumber(itemValue * quantity, 2)--GetItemLinkValue(itemLink, true) * quantity
    local itemName = zo_strformat("<<t:1>>", itemLink)
    local itemFound = false
    
    -- Return if own (player) loot is off
    -- if player and not FPSettings:DisplayOwnLoot() then
    --     return
    -- end
    -- -- Return if group loot is off
    -- if not player and not FPSettings:DisplayGroupLoot() then
    --     return
    -- end
    -- Check if the loot receiver is already added into the members table, add if not.
    -- if not Members:HasMember(name) then
    --     local newMember = Members:NewMember(name)
    --     Members:SetMember(name, displayName)
    -- end
    -- -- Update best loot
    -- if FPHighScore:IsBestLoot(name, totalValue) then
    --     FPHighScore:UpdateBestLoot(name, itemLink, itemValue)
    -- end
    FarmingPartyMemberList:AddNewLootedItem(looterName, itemLink, itemValue, quantity)
    
    -- Player or group member
    if not player then
        if FarmingParty.Settings:DisplayLootValue() then
            lootMessage =
                zo_strformat(
                    "<<C:1>> received <<t:2>> x<<3>> worth |cFFFFFF<<4>>|rg",
                    name,
                    itemLink,
                    quantity,
                    totalValue
        )
        else
            lootMessage = zo_strformat("<<C:1>> received <<t:2>> x<<3>>", looterName, itemLink, quantity)
        end
        if FarmingParty.Settings:DisplayInChat() then
            d(lootMessage)
        end
        FarmingPartyWindowBuffer:AddMessage(lootMessage, 255, 255, 0, 1)
    else
        if not FarmingParty.Settings:DisplayOwnLoot() then return end
        if FarmingParty.Settings:DisplayLootValue() then
            lootMessage = zo_strformat("Received <<t:1>> x<<2>> worth |cFFFFFF<<3>>|rg", itemLink, quantity, totalValue)
        else
            lootMessage = zo_strformat("Received <<t:1>> x<<2>>", itemLink, quantity)
        end
        if FarmingParty.Settings:DisplayInChat() then
            d(lootMessage)
        end
        FarmingPartyWindowBuffer:AddMessage(lootMessage, 255, 255, 0, 1)
    end
end

function FarmingPartyMemberList:GetATTPrice(itemLink)
    if (ArkadiusTradeTools.Modules.Sales == nil) then
        return nil
    end
    local itemPrice = ArkadiusTradeTools.Modules.Sales:GetAveragePricePerItem(itemLink)
    return itemPrice
end

function FarmingPartyMemberList:GetMMPrice(itemLink)
    if (MasterMerchant == nil) then
        return nil
    end
    local itemStats = MasterMerchant:itemStats(itemLink, false)
    if (itemStats == nil) then
        return itemStats
    else
        return itemStats.avgPrice
    end
end

function FarmingPartyMemberList:GetItemPrice(itemLink)
    local price = FarmingPartyMemberList:GetATTPrice(itemLink) or FarmingPartyMemberList:GetMMPrice(itemLink)
    if (price == nil or price == 0) then
        price = GetItemLinkValue(itemLink, true)
    end
    return price
end

-- Member Items Funcs --
function FarmingPartyMemberList:AddNewLootedItem(memberName, itemLink, itemValue, count)
    local items = members:GetItemsForMember(memberName)
    local itemDetails = items[itemLink]
    if (itemDetails == nil) then
        itemDetails = FarmingPartyMemberItem:New(itemLink)
    end
    -- This update and replace might be super expensive and inefficient. Need to investigate
    itemDetails = FarmingPartyMemberItem:UpdateItemCount(itemDetails, itemValue, count)
    items[itemLink] = itemDetails
    members:SetItemsForMember(memberName, items)
    members:UpdateTotalValueAndSetBestItem(memberName)
end

function FarmingPartyMemberList:PrintScoresToChat()
    local topScorers = 'FARMING SCORES: '
    local array = {}
    local groupMembers = members:GetKeys()
    for i = 1, #groupMembers do
        local member = members:GetMember(groupMembers[i])
        local scoreData = {name = groupMembers[i], totalValue = member.totalValue}
        array[#array + 1] = scoreData
    end
    table.sort(array, function(a, b) return a.totalValue > b.totalValue end)
    for i = 1, #array do
        topScorers = topScorers .. array[i].name .. ': ' .. FarmingPartyMemberList:FormatNumber(array[i].totalValue, 2) .. 'g. '
    end
    ZO_ChatWindowTextEntryEditBox:SetText(topScorers)
end
