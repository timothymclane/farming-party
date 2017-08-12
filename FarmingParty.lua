local ADDON_NAME    = "FarmingParty"

local FPSettings
local FPHighScore 

FarmingParty = {}

function FarmingParty:Initialize()
    EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_LOOT_RECEIVED, function(...) self:OnItemLooted(...) end)
end

-- EVENT_ADD_ON_LOADED
function FarmingParty:OnAddOnLoaded(event, addonName)
    if(addonName ~= ADDON_NAME) then return end
    EVENT_MANAGER:UnregisterForEvent(ADDON_NAME, EVENT_ADD_ON_LOADED)

    FPSettings  = FarmingPartySettings:New()
    FPHighScore = FarmingPartyHighscore:New()

    FarmingPartyWindowBuffer:SetLineFade(6,4)

    self:Initialize()
end

function FarmingParty:FormatNumber(num, numDecimalPlaces)
    return tonumber(string.format("%." .. (numDecimalPlaces or 0) .. "f", num))
end

-- EVENT_LOOT_RECEIVED
function FarmingParty:OnItemLooted(event, name, itemLink, quantity, itemSound, lootType, player)
    local mmPrice       = FarmingParty:GetMasterMerchantPrice(itemLink)
    local itemValue     = {}
    if(mmPrice ~= nil) then
        itemValue = mmPrice
    else
        itemValue = GetItemLinkValue(itemLink, true)
    end

    local lootMessage   = nil
    local itemQuality   = GetItemLinkQuality(itemLink)
    local totalValue    = FarmingParty:FormatNumber(itemValue * quantity, 2) --GetItemLinkValue(itemLink, true) * quantity
    local itemName      = zo_strformat("<<t:1>>", itemLink)
    local itemFound     = false

    -- Return if own (player) loot is off
    if player and not FPSettings:DisplayOwnLoot() then return end
    -- Return if group loot is off
    if not player and not FPSettings:DisplayGroupLoot() then return end
    -- Check if the loot receiver is already added into the members table, add if not.
    if not FPHighScore:MemberExists(name) then FPHighScore:NewMember(name) end

    -- Update total loot value
    FPHighScore:UpdateTotalValue(name, totalValue)
    FPHighScore:UpdateLootList(name, itemLink, quantity)

    -- Update best loot
    if FPHighScore:IsBestLoot(name, totalValue) then
        FPHighScore:UpdateBestLoot(name, itemLink, itemValue)
    end

    -- Player or group member
    if not player then
        if FPSettings:DisplayLootValue() then
            lootMessage = zo_strformat("<<C:1>> received <<t:2>> x<<3>> worth |cFFFFFF<<4>>|rg", name, itemLink, quantity, totalValue)
        else
            lootMessage = zo_strformat("<<C:1>> received <<t:2>> x<<3>>", name, itemLink, quantity)
        end
        if FPSettings:DisplayInChat() then d(lootMessage) end
        FarmingPartyWindowBuffer:AddMessage(lootMessage, 255, 255, 0, 1)
    else
        if FPSettings:DisplayLootValue() then
            lootMessage = zo_strformat("Received <<t:1>> x<<2>> worth |cFFFFFF<<3>>|rg", itemLink, quantity, totalValue)
        else
            lootMessage = zo_strformat("Received <<t:1>> x<<2>>", itemLink, quantity)
        end
        if FPSettings:DisplayInChat() then d(lootMessage) end
        FarmingPartyWindowBuffer:AddMessage(lootMessage, 255, 255, 0, 1)
     end
end

function FarmingParty:GetMasterMerchantPrice(itemLink)
    return MasterMerchant:itemStats(itemLink, false).avgPrice
end

-- Load the addon with this
EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_ADD_ON_LOADED, function(...) FarmingParty:OnAddOnLoaded(...) end)