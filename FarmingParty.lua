local ADDON_NAME = "FarmingParty"

local FPSettings
local FPHighScore
local Members
local members
local saveData

FarmingParty = {}

function FarmingParty:Initialize()
    EVENT_MANAGER:RegisterForEvent(
        ADDON_NAME,
        EVENT_LOOT_RECEIVED,
        function(...)
            self:OnItemLooted(...)
        end
    )
    Members = FarmingParty.Members
    saveData =
        ZO_SavedVars:NewAccountWide(
        "FarmingParty_db",
        1,
        nil,
        {members = {}, memberCount = 0, positionLeft = 0, positionTop = 0}
    )

    members = Members:New(saveData)
    members:RegisterCallback("OnKeysUpdated", UpdateIndex)

    UpdateIndex()
end

function FarmingParty:AddAllGroupMembers()
    function FarmingPartyHighScore:AddAllMembersInGroup()
        local countMembers = GetGroupSize()

        -- Get list of member names in current group
        local members = {}
        for i = 1, countMembers do
            local unitTag = GetGroupUnitTagByIndex(i)
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

        self:UpdateHighscoreWindow()
    end
end

-- EVENT_ADD_ON_LOADED
function FarmingParty:OnAddOnLoaded(event, addonName)
    if (addonName ~= ADDON_NAME) then
        return
    end
    EVENT_MANAGER:UnregisterForEvent(ADDON_NAME, EVENT_ADD_ON_LOADED)

    FPSettings = FarmingPartySettings:New()
    FPHighScore = FarmingPartyHighScore:New()

    FarmingPartyWindowBuffer:SetLineFade(6, 4)

    self:Initialize()
end

function FarmingParty:FormatNumber(num, numDecimalPlaces)
    return tonumber(string.format("%." .. (numDecimalPlaces or 0) .. "f", num))
end

-- EVENT_LOOT_RECEIVED
function FarmingParty:OnItemLooted(event, name, itemLink, quantity, itemSound, lootType, player)
    local mmPrice = FarmingParty:GetMasterMerchantPrice(itemLink)
    local itemValue = {}
    if (mmPrice ~= nil) then
        itemValue = mmPrice
    else
        itemValue = GetItemLinkValue(itemLink, true)
    end

    local lootMessage = nil
    local itemQuality = GetItemLinkQuality(itemLink)
    local totalValue = FarmingParty:FormatNumber(itemValue * quantity, 2) --GetItemLinkValue(itemLink, true) * quantity
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
    FPHighScore:UpdateTotalValue(name, totalValue)
    FPHighScore:UpdateLootList(name, itemLink, quantity, mmPrice)

    -- Update best loot
    if FPHighScore:IsBestLoot(name, totalValue) then
        FPHighScore:UpdateBestLoot(name, itemLink, itemValue)
    end

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

function FarmingParty:GetMasterMerchantPrice(itemLink)
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

-- Load the addon with this
EVENT_MANAGER:RegisterForEvent(
    ADDON_NAME,
    EVENT_ADD_ON_LOADED,
    function(...)
        FarmingParty:OnAddOnLoaded(...)
    end
)
