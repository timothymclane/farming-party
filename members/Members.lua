FarmingPartyMembers = ZO_CallbackObject:Subclass()

function FarmingPartyMembers:New(saveData)
    local storage = ZO_CallbackObject.New(self)
    storage.members = saveData.members or {}
    saveData.members = storage.members
    return storage
end

function FarmingPartyMembers:Finalize()
end

function FarmingPartyMembers:GetMembers()
    return self.members
end

function FarmingPartyMembers:GetCleanMembers()
    local cleanMembers = {}
    for key, member in pairs(self.members) do
        cleanMembers[key] = {bestItem = member.bestItem, totalValue = member.totalValue, items = member.items, displayName = member.displayName}
    end
    return cleanMembers
end

function FarmingPartyMembers:GetKeys()
    local keys = {}
    for key in pairs(self.members) do
        keys[#keys + 1] = key
    end
    table.sort(keys)
    return keys
end

function FarmingPartyMembers:GetMember(key)
    return self.members[key]
end

function FarmingPartyMembers:HasMember(key)
    return self.members[key] ~= nil
end

function FarmingPartyMembers:HasMembers()
    return next(self.members) ~= nil
end

function FarmingPartyMembers:SetMember(key, member)
    local keyExists = self:HasMember(key)
    self.members[key] = member
    if (not keyExists) then
        self:FireCallbacks("OnKeysUpdated")
    end
end

function FarmingPartyMembers:DeleteMember(key)
    local keyExists = self:HasMember(key)
    self.members[key] = nil
    if (keyExists) then
        self:FireCallbacks("OnKeysUpdated")
    end
end

function FarmingPartyMembers:DeleteAllMembers()
    local hasMembers = self:HasMembers()
    ZO_ClearTable(self.members)
    if (hasMembers) then
        self:FireCallbacks("OnKeysUpdated")
    end
end

function FarmingPartyMembers:GetItemForMember(memberKey, itemLink)
    local member = self:GetMember(memberKey)
    return member.items[itemLink]
end

function FarmingPartyMembers:SetItemForMember(memberKey, itemLink, item)
    local member = self:GetMember(memberKey)
    member.items[itemLink] = item
end

function FarmingPartyMembers:GetItemsForMember(key)
    local member = self:GetMember(key)
    local items = member.items
    return items
end

function FarmingPartyMembers:SetItemsForMember(key, items)
    local member = self:GetMember(key)
    member.items = items
    self:FireCallbacks("OnKeysUpdated")
    return member
end

function FarmingPartyMembers:NewMember(name, displayName)
    name = zo_strformat(SI_UNIT_NAME, name)
    local newMember = {
        bestItem = {itemLink = "", value = 0},
        totalValue = 0,
        items = {},
        displayName = displayName
    }
    self:FireCallbacks("OnKeysUpdated")
    return newMember
end

function FarmingPartyMembers:UpdateTotalValueAndSetBestItem(name, item, valueToAdd)
    local member = self:GetMember(name)
    local bestItem = member.bestItem
    if(item.value > bestItem.value) then
        bestItem = item
        bestItem.itemLink = item.itemLink
    end
    member.bestItem = bestItem
    member.totalValue = member.totalValue + valueToAdd
    self:FireCallbacks("OnKeysUpdated")
end
