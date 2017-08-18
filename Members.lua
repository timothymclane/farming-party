local Members = ZO_CallbackObject:Subclass()
FarmingParty.Members = Members

function Members:New(saveData)
    local storage = ZO_CallbackObject.New(self)
    storage.members = saveData.members or {}
    saveData.members = storage.members
    return storage
end

function Members:GetKeys()
    local keys = {}
    for key in pairs(self.members) do
        keys[#keys + 1] = key
    end
    table.sort(keys)
    return keys
end

function Members:GetMember(key)
    return self.members[key]
end

function Members:HasMember(key)
    return self.members[key] ~= nil
end

function Member:HasMembers()
    return next(self.members) ~= nil
end

function Members:SetMember(key, member)
    local keyExists = self:HashMember(key)
    self.members[key] = member
    if(not keyExists) then
        self:FireCallbacks("OnKeysUpdated")
    end
end

function Members:DeleteMember(key)
    local keyExists = self:HashMember(key)
    self.members[key] = nil
    if(keyExists) then
        self:FireCallbacks("OnKeysUpdated")
    end
end

function Members:DeleteAllMembers()
    local hasMembers = self:HasMembers()
    ZO_ClearTable(self.members)
    if(hasMembers) then
        self:FireCallbacks("OnKeysUpdated")
    end
end

function Members:GetItemsForMember(key)
    local member = self.GetMember(key)
    local items = member.items
    return items
end

function Members:SetItemsForMember(key, items)
    local member = self.GetMember(key)
    member.items = items
    self.SetMember(member)
    return member
end

function Members:NewMember(name, displayName)
    name = zo_strformat(SI_UNIT_NAME, name)
    local newMember = {
            bestLoot = "None (0g)",
            totalValue = 0,
            items = {},
            displayName = displayName
        }
    return newMember
end