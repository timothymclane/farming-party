FarmingPartyMembers = ZO_CallbackObject:Subclass()

function FarmingPartyMembers:New(saveData)
    d("Inside FarmingPartyMembers:New")
    local storage = ZO_CallbackObject.New(self)
    storage.members = saveData.members or {}
    saveData.members = storage.members
    return storage
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

function FarmingPartyMembers:GetItemsForMember(key)
    local member = self:GetMember(key)
    local items = member.items
    return items
end

function FarmingPartyMembers:SetItemsForMember(key, items)
    local member = self:GetMember(key)
    member.items = items
    self:SetMember(member)
    return member
end

function FarmingPartyMembers:NewMember(name, displayName)
    name = zo_strformat(SI_UNIT_NAME, name)
    local newMember = {
        bestLoot = "None (0g)",
        totalValue = 0,
        items = {},
        displayName = displayName
    }
    return newMember
end

function FarmingPartyMembers:UpdateTotalValue(name)
    local member = self:GetMember(name)
    local totalValue = 0
    for _, item in pairs(member.items) do
        totalValue = totalValue + item.totalValue
    end
    member.totalValue = totalValue
end
