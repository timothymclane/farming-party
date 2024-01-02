local SECONDS_IN_DAY = 86400

local function GetItemPrice(itemLink)
  local price = LibPrice.ItemLinkToPriceGold(itemLink)
  if (price == nil or price == 0) then
    price = GetItemLinkValue(itemLink, true)
  end
  return price
end

FarmingPartyLoot = ZO_Object:Subclass()

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
local async = LibAsync
function FarmingPartyLoot:AddEventHandlers()
  EVENT_MANAGER:RegisterForEvent(
    ADDON_NAME,
    EVENT_LOOT_RECEIVED,
    function(...)
      async:Call(self:OnItemLooted(...))
    end
  )
  Settings:ToggleStatusValue(FarmingParty.Settings.TRACKING_STATUS.ENABLED)
end

function FarmingPartyLoot:RemoveEventHandlers()
  EVENT_MANAGER:UnregisterForEvent(ADDON_NAME, EVENT_LOOT_RECEIVED)
  Settings:ToggleStatusValue(FarmingParty.Settings.TRACKING_STATUS.DISABLED)
end

local getMember = function(looterName)
  if Members:HasMember(looterName) then
    return Members:GetMember(looterName)
  else
    MemberList:AddAllGroupMembers()
    return Members:GetMember(looterName)
  end
end

function FarmingPartyLoot:OnItemLooted(eventCode, receivedBy, itemLink, quantity, soundCategory, lootType, lootedByPlayer, isPickpocketLoot, questItemIcon, itemId, isStolen)
  --[[ API docs state that itemLink is itemName

  Which is odd because a lead like Lustrous Prong Clasps is the name
  but other items like ore is an itemLink.
  ]]--
  if not lootedByPlayer and not Settings:TrackGroupLoot() then
    return
  end
  if lootedByPlayer and not Settings:TrackSelfLoot() then
    return
  end
  local icon, sellPrice, meetsUsageRequirement, equipType, itemStyleId = GetItemLinkInfo(itemLink)
  local itemType = GetItemLinkItemType(itemLink)
  local itemQuality = GetItemLinkQuality(itemLink)

  if equipType ~= EQUIP_TYPE_INVALID and not Settings:TrackGearLoot() then
    return
  end
  if itemType == ITEMTYPE_RACIAL_STYLE_MOTIF and not Settings:TrackMotifLoot() then
    return
  end
  if itemQuality < Settings:MinimumLootQuality() then
    return
  end
  if (lootType == LOOT_TYPE_QUEST_ITEM) then
    return
  end
  if (lootType == LOOT_TYPE_QUEST_ITEM) then
    return
  end
  if (lootType == LOOT_TYPE_ANTIQUITY_LEAD) then
    return
  end

  local looterName = zo_strformat(SI_UNIT_NAME, receivedBy)
  local itemValue = GetItemPrice(itemLink)

  local lootMessage = nil
  local totalValue = itemValue * quantity
  local itemName = zo_strformat('<<t:1>>', itemLink)
  local itemFound = false
  local looterMember = getMember(looterName)
  self:AddNewLootedItem(looterName, itemLink, itemValue, quantity)
  Logger:LogLootItem(looterMember.displayName, lootedByPlayer, itemLink, quantity, totalValue, itemName, lootType, questItemIcon)
end

function FarmingPartyLoot:AddNewLootedItem(memberName, itemLink, itemValue, count)
  local itemDetails = Members:GetItemForMember(memberName, itemLink)
  if (itemDetails == nil) then
    itemDetails = FarmingPartyMemberItem:New(itemLink)
  end
  -- This could probably use a bit more fine tuning for performance
  itemDetails = FarmingPartyMemberItem:UpdateItemCount(itemDetails, itemValue, count)
  Members:SetItemForMember(memberName, itemLink, itemDetails)
  local lootedValue = itemValue * count
  Members:UpdateTotalValueAndSetBestItem(memberName, itemDetails, lootedValue)
end
