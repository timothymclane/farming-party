local members
MemberList = {}

function MemberList:Initialize()
    EVENT_MANAGER:RegisterForEvent(
        ADDON_NAME,
        EVENT_LOOT_RECEIVED,
        function(...)
            self:OnItemLooted(...)
        end
    )
    Members = FarmingParty.Members
    members = Members:New(saveData.members)
    members:RegisterCallback("OnKeysUpdated", UpdateScrollList)
    self:AddAllGroupMembers()
    self:SetupScrollList()
    self:UpdateScrollList()
end

function MemberList:SetupScrollList()
    listContainer = FarmingPartyMembersWindow:GetNamedChild("List")
    ZO_ScrollList_AddDataType(
        listContainer,
        FarmingParty.DataTypes.MEMBER,
        "FarmingPartyMemberDataRow",
        20,
        InitializeRow
    )
end

function MemberList:UpdateScrollList()
    local scrollData = ZO_ScrollList_GetDataList(listContainer)
    ZO_ScrollList_Clear(listContainer)

    local groupMembers = members:GetKeys()
    for i = 1, #groupMembers do
        scrollData[#scrollData + 1] =
            ZO_ScrollList_CreateDataEntry(FarmingParty.DataTypes.MEMBER, {key = groupMembers[i]})
    end

    ZO_ScrollList_Commit(listContainer)
end

function MemberList:AddAllGroupMembers()
    local countMembers = GetGroupSize()

    -- Get list of member names in current group
    local members = {}
    for i = 1, countMembers do
        local unitTag = GetGroupUnitTagByIndex(i)
        d(unitTag)
        if unitTag then
            local name = zo_strformat(SI_UNIT_NAME, GetUnitName(unitTag))
            members[name] = GetUnitDisplayName(unitTag)
        end
    end

    -- Add all missing members
    for name, displayName in pairs(members) do
        if not Members:HasMember(name) then
            local newMember = Members:NewMember(name)
            Members:SetMember(name, displayName)
        end
    end
end

function MemberList:ShowAllGroupMembers()
    d(string.format("Group Size: %s", GetGroupSize()))
    local countMembers = GetGroupSize()

    -- Get list of member names in current group
    local members = {}
    for i = 1, countMembers do
        local unitTag = GetGroupUnitTagByIndex(i)
        d(unitTag)
        if unitTag then
            local name = zo_strformat(SI_UNIT_NAME, GetUnitName(unitTag))
            members[name] = GetUnitDisplayName(unitTag)
        end
    end
    if (countMembers == 0) then
        members[GetUnitName("player")] = GetDisplayName("player")
    end
    d(members)
end

function MemberList:FormatNumber(num, numDecimalPlaces)
    return tonumber(string.format("%." .. (numDecimalPlaces or 0) .. "f", num))
end

-- EVENT_LOOT_RECEIVED
function MemberList:OnItemLooted(event, name, itemLink, quantity, itemSound, lootType, player)
    local mmPrice = MemberList:GetMasterMerchantPrice(itemLink)
    local itemValue = {}
    if (mmPrice ~= nil) then
        itemValue = mmPrice
    else
        itemValue = GetItemLinkValue(itemLink, true)
    end

    local lootMessage = nil
    local itemQuality = GetItemLinkQuality(itemLink)
    local totalValue = MemberList:FormatNumber(itemValue * quantity, 2) --GetItemLinkValue(itemLink, true) * quantity
    local itemName = zo_strformat("<<t:1>>", itemLink)
    local itemFound = false

    -- Return if own (player) loot is off
    if player and not FPSettings:DisplayOwnLoot() then
        return
    end
    -- Return if group loot is off
    if not player and not FPSettings:DisplayGroupLoot() then
        return
    end
    -- Check if the loot receiver is already added into the members table, add if not.
    -- if not Members:HasMember(name) then
    --     local newMember = Members:NewMember(name)
    --     Members:SetMember(name, displayName)
    -- end

    -- Update total loot value
    -- FPHighScore:UpdateTotalValue(name, totalValue)
    -- FPHighScore:UpdateLootList(name, itemLink, quantity, mmPrice)

    -- -- Update best loot
    -- if FPHighScore:IsBestLoot(name, totalValue) then
    --     FPHighScore:UpdateBestLoot(name, itemLink, itemValue)
    -- end

    -- Player or group member
    if not player then
        if FPSettings:DisplayLootValue() then
            lootMessage =
                zo_strformat(
                "<<C:1>> received <<t:2>> x<<3>> worth |cFFFFFF<<4>>|rg",
                name,
                itemLink,
                quantity,
                totalValue
            )
        else
            lootMessage = zo_strformat("<<C:1>> received <<t:2>> x<<3>>", name, itemLink, quantity)
        end
        if FPSettings:DisplayInChat() then
            d(lootMessage)
        end
        FarmingPartyWindowBuffer:AddMessage(lootMessage, 255, 255, 0, 1)
    else
        if FPSettings:DisplayLootValue() then
            lootMessage = zo_strformat("Received <<t:1>> x<<2>> worth |cFFFFFF<<3>>|rg", itemLink, quantity, totalValue)
        else
            lootMessage = zo_strformat("Received <<t:1>> x<<2>>", itemLink, quantity)
        end
        if FPSettings:DisplayInChat() then
            d(lootMessage)
        end
        FarmingPartyWindowBuffer:AddMessage(lootMessage, 255, 255, 0, 1)
    end
end

function MemberList:GetMasterMerchantPrice(itemLink)
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
