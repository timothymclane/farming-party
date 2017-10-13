-- Local functions --
local function GetATTPrice(itemLink)
    if (ArkadiusTradeTools == nil or ArkadiusTradeTools.Modules.Sales == nil) then
        return nil
    end
    local itemPrice = ArkadiusTradeTools.Modules.Sales:GetAveragePricePerItem(itemLink)
    return itemPrice
end

local function GetMMPrice(itemLink)
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

local function GetItemPrice(itemLink)
    local price = GetATTPrice(itemLink) or GetMMPrice(itemLink)
    if (price == nil or price == 0) then
        price = GetItemLinkValue(itemLink, true)
    end
    return price
end

FarmingPartyLoot = ZO_Object:Subclass()

local Members
local MembersList
local Logger

function FarmingPartyLoot:New()
    local obj = ZO_Object.New(self)
    self:Initialize()
    return obj
end

function FarmingPartyLoot:Initialize()
    EVENT_MANAGER:RegisterForEvent(
        ADDON_NAME,
        EVENT_LOOT_RECEIVED,
        function(...)
            self:OnItemLooted(...)
        end
    )
    Members = FarmingParty.Modules.Members
    MembersList = FarmingParty.Modules.MembersList
    Logger = FarmingParty.Modules.Logger
end

function FarmingPartyLoot:Finalize()

end

-- EVENT_LOOT_RECEIVED
function FarmingPartyLoot:OnItemLooted(eventCode, name, itemLink, quantity, itemSound, lootType, lootedByPlayer, isPickpocketLoot, questItemIcon, itemId)
    if (lootType == LOOT_TYPE_QUEST_ITEM) then return end
    local looterName = zo_strformat(SI_UNIT_NAME, name)
    local itemValue = GetItemPrice(itemLink)
    
    local lootMessage = nil
    local itemQuality = GetItemLinkQuality(itemLink)
    local totalValue = FarmingParty.FormatNumber(itemValue * quantity, 2)--GetItemLinkValue(itemLink, true) * quantity
    local itemName = zo_strformat("<<t:1>>", itemLink)
    local itemFound = false
    
    local getMember = function(looterName)
        if Members:HasMember(looterName) then
            return Members:GetMember(looterName)
        else MembersList:AddAllGroupMembers()
            return Members:GetMember(looterName) end
    end
    local looterMember = getMember(looterName)
    self:AddNewLootedItem(looterName, itemLink, itemValue, quantity)
    Logger:LogLootItem(looterMember.displayName, lootedByPlayer, itemLink, quantity, totalValue, itemName, lootType, questItemIcon)
end

function FarmingPartyLoot:AddNewLootedItem(memberName, itemLink, itemValue, count)
    local items = Members:GetItemsForMember(memberName)
    local itemDetails = items[itemLink]
    if (itemDetails == nil) then
        itemDetails = FarmingPartyMemberItem:New(itemLink)
    end
    -- This update and replace might be super expensive and inefficient. Need to investigate
    itemDetails = FarmingPartyMemberItem:UpdateItemCount(itemDetails, itemValue, count)
    items[itemLink] = itemDetails
    Members:SetItemsForMember(memberName, items)
    Members:UpdateTotalValueAndSetBestItem(memberName)
end
