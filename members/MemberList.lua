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
    -- Disbanding a group counts as the local player leaving the group
    -- so we want to not remove their items if they're on the event
    if (not wasLocalPlayer) then
        local name = zo_strformat(SI_UNIT_NAME, memberName)
        members:DeleteMember(name)
    end
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
            ZO_ScrollList_CreateDataEntry(FarmingParty.DataTypes.MEMBER, {rawData = members:GetMember(groupMembers[i])})
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
    totalValue:SetText(data.totalValue .. 'g')
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
function FarmingPartyMemberList:OnItemLooted(eventCode, name, itemLink, quantity, itemSound, lootType, lootedByPlayer, isPickpocketLoot, questItemIcon, itemId)
    local looterName = zo_strformat(SI_UNIT_NAME, name)
    local itemValue = FarmingPartyMemberList:GetItemPrice(itemLink)
    
    local lootMessage = nil
    local itemQuality = GetItemLinkQuality(itemLink)
    local totalValue = FarmingPartyMemberList:FormatNumber(itemValue * quantity, 2)--GetItemLinkValue(itemLink, true) * quantity
    local itemName = zo_strformat("<<t:1>>", itemLink)
    local itemFound = false
    
    FarmingPartyMemberList:AddNewLootedItem(looterName, itemLink, itemValue, quantity)
    local looterMember = members:GetMember(looterName)
    FarmingPartyMemberList:LogLootItem(looterMember.displayName, lootedByPlayer, itemLink, quantity, totalValue, itemName, lootType, questItemIcon)
end

function FarmingPartyMemberList:LogLootItem(looterName, lootedByPlayer, itemLink, quantity, totalValue, itemName, lootType, questItemIcon)
    local icon = FarmingPartyMemberList:GetItemIcon(itemLink, lootType, questItemIcon)
    local itemText
    local itemValueText = FarmingParty.Settings:DisplayLootValue() and zo_strformat(' - |cFFFFFF<<1>>|r|t16:16:EsoUI/Art/currency/currency_gold.dds|t', totalValue) or ''
    if quantity == 1 then
        itemText = zo_strformat(icon .. itemLink .. itemValueText)
    else
        itemText = zo_strformat(icon .. itemLink .. ' |cFFFFFFx' .. quantity .. '|r' .. itemValueText)
    end
    
    local lootMessage = ''
    if not lootedByPlayer then
        lootMessage = zo_strformat("|cFFFFFF<<C:1>>|r |c228B22received|r <<t:2>>", looterName, itemText)
    else
        if not FarmingParty.Settings:DisplayOwnLoot() then return end
        lootMessage = zo_strformat("|c228B22Received|r <<t:1>>", itemText)
    end
    if FarmingParty.Settings:DisplayInChat() then
        CHAT_SYSTEM:AddMessage(lootMessage)
    end
    
    FarmingPartyWindowBuffer:AddMessage(lootMessage, 255, 255, 0, 1)
end

function FarmingPartyMemberList:GetItemIcon(itemLink, lootType, questItemIcon)
    local icon = ""
    if lootType == LOOT_TYPE_QUEST_ITEM then
        icon = questItemIcon
    elseif lootType == LOOT_TYPE_COLLECTIBLE then
        local collectibleId = GetCollectibleIdFromLink(itemLink)
        local _, _, collectibleIcon = GetCollectibleInfo(collectibleId)
        icon = collectibleIcon
    else
        local itemIcon, _, _, _, _ = GetItemLinkInfo(itemLink)
        icon = itemIcon
    end
    icon = icon ~= "" and ("|t16:16:" .. icon .. "|t ") or ""
    return icon
end

function FarmingPartyMemberList:GetATTPrice(itemLink)
    if (ArkadiusTradeTools == nil or ArkadiusTradeTools.Modules.Sales == nil) then
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
        local scoreData = {name = groupMembers[i], totalValue = member.totalValue, displayName = groupMembers[i].displayName}
        array[#array + 1] = scoreData
    end
    table.sort(array, function(a, b) return a.totalValue > b.totalValue end)
    for i = 1, #array do
        topScorers = topScorers .. array[i].displayName .. ': ' .. FarmingPartyMemberList:FormatNumber(array[i].totalValue, 2) .. 'g. '
    end
    ZO_ChatWindowTextEntryEditBox:SetText(topScorers)
end
