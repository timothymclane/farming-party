local SECONDS_IN_DAY = 86400

local function GetItemPrice(itemLink)
    local price = LibPrice.ItemLinkToPriceGold(itemLink)
    if (price == nil or price == 0) then
        price = GetItemLinkValue(itemLink, true)
    end
    return price
end

FarmingPartyLoot = ZO_Object:Subclass()

local NOT_EQUIPPABLE = 0
local Members
local MemberList
local Logger
local Settings

function FarmingPartyLoot:New()
    local obj = ZO_Object.New(self)
    self:Initialize()
    return obj
end

function FarmingPartyLoot:Initialize()
    Members = FarmingParty.Modules.Members
    MemberList = FarmingParty.Modules.MemberList
    Logger = FarmingParty.Modules.Logger
    Settings = FarmingParty.Settings
    
    if (Settings:Status() == FarmingParty.Settings.TRACKING_STATUS.ENABLED) then
        self:AddEventHandlers()
    end
end

function FarmingPartyLoot:Finalize()

end

function FarmingPartyLoot:AddEventHandlers()
    EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_LOOT_RECEIVED, function(...)self:OnItemLooted(...) end)
    Settings:ToggleStatusValue(FarmingParty.Settings.TRACKING_STATUS.ENABLED)
end

function FarmingPartyLoot:RemoveEventHandlers()
    EVENT_MANAGER:UnregisterForEvent(ADDON_NAME, EVENT_LOOT_RECEIVED)
    Settings:ToggleStatusValue(FarmingParty.Settings.TRACKING_STATUS.DISABLED)
end

-- EVENT_LOOT_RECEIVED
function FarmingPartyLoot:OnItemLooted(eventCode, name, itemLink, quantity, itemSound, lootType, lootedByPlayer, isPickpocketLoot, questItemIcon, itemId)
    if not lootedByPlayer and not Settings:TrackGroupLoot() then return end
    if lootedByPlayer and not Settings:TrackSelfLoot() then return end
    local icon, sellPrice, meetsUsageRequirement, equipType, itemStyleId = GetItemLinkInfo(itemLink)
    local itemType = GetItemLinkItemType(itemLink)
    local itemQuality = GetItemLinkQuality(itemLink)

    if equipType ~= NOT_EQUIPPABLE and not Settings:TrackGearLoot() then return end
    if itemType == ITEMTYPE_RACIAL_STYLE_MOTIF and not Settings:TrackMotifLoot() then return end
    if itemQuality < Settings:MinimumLootQuality() then return end
    if (lootType == LOOT_TYPE_QUEST_ITEM) then return end

    local looterName = zo_strformat(SI_UNIT_NAME, name)
    local itemValue = GetItemPrice(itemLink)
    
    local lootMessage = nil
    local totalValue = itemValue * quantity
    local itemName = zo_strformat("<<t:1>>", itemLink)
    local itemFound = false
    
    local getMember = function(looterName)
        if Members:HasMember(looterName) then
            return Members:GetMember(looterName)
        else MemberList:AddAllGroupMembers()
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
    local lootedValue = itemValue * count
    Members:UpdateTotalValueAndSetBestItem(memberName, itemDetails, lootedValue)
end
