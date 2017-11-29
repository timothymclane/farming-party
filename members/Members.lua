local FarmingPartyMembers = ZO_CallbackObject:Subclass()
FarmingParty.Modules.Members = FarmingPartyMembers
local storage

function FarmingPartyMembers:New(saveData)
    storage = ZO_CallbackObject.New(self)
    storage.members = saveData.members or {}
    saveData.members = storage.members
    FarmingParty.Modules.Members = self
end

function FarmingPartyMembers:Initialize()
end

function FarmingPartyMembers:Finalize()
end

function FarmingPartyMembers:GetMembers()
    return storage.members
end

function FarmingPartyMembers:GetCleanMembers()
    local cleanMembers = {}
    for key, member in pairs(storage.members) do
        cleanMembers[key] = {bestItem = member.bestItem, totalValue = member.totalValue, items = member.items, displayName = member.displayName}
    end
    return cleanMembers
end

function FarmingPartyMembers:GetKeys()
    local keys = {}
    for key in pairs(storage.members) do
        keys[#keys + 1] = key
    end
    table.sort(keys)
    return keys
end

function FarmingPartyMembers:GetMember(key)
    return storage.members[key]
end

function FarmingPartyMembers:HasMember(key)
    return storage.members[key] ~= nil
end

function FarmingPartyMembers:HasMembers()
    return next(storage.members) ~= nil
end

function FarmingPartyMembers:SetMember(key, member)
    local keyExists = self:HasMember(key)
    storage.members[key] = member
    if (not keyExists) then
        storage:FireCallbacks("OnKeysUpdated")
    end
end

function FarmingPartyMembers:DeleteMember(key)
    local keyExists = self:HasMember(key)
    storage.members[key] = nil
    if (keyExists) then
        storage:FireCallbacks("OnKeysUpdated")
    end
end

function FarmingPartyMembers:DeleteAllMembers()
    local hasMembers = self:HasMembers()
    ZO_ClearTable(storage.members)
    if (hasMembers) then
        storage:FireCallbacks("OnKeysUpdated")
    end
end

function FarmingPartyMembers:GetItemsForMember(key)
    local member = storage:GetMember(key)
    local items = member.items
    return items
end

function FarmingPartyMembers:SetItemsForMember(key, items)
    local member = storage:GetMember(key)
    member.items = items
    self:SetMember(member)
    storage:FireCallbacks("OnKeysUpdated")
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
    storage:FireCallbacks("OnKeysUpdated")
    return newMember
end

function FarmingPartyMembers:UpdateTotalValueAndSetBestItem(name)
    local member = self:GetMember(name)
    local totalValue = 0
    local bestItem = member.bestItem
    for link, item in pairs(member.items) do
        if (item.value > bestItem.value) then
            bestItem = item
            bestItem.itemLink = link
        end
        totalValue = totalValue + item.totalValue
    end
    member.bestItem = bestItem
    member.totalValue = totalValue
    storage:FireCallbacks("OnKeysUpdated")
end
