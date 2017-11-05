FarmingPartyLogger = ZO_Object:Subclass()

function FarmingPartyLogger:Finalize()
end

local function GetItemIcon(itemLink, lootType, questItemIcon)
    local icon = ""
    if lootType == LOOT_TYPE_COLLECTIBLE then
        local collectibleId = GetCollectibleIdFromLink(itemLink)
        local _, _, collectibleIcon = GetCollectibleInfo(collectibleId)
        icon = collectibleIcon
    else
        local itemIcon, _, _, _, _ = GetItemLinkInfo(itemLink)
        icon = itemIcon
    end
    icon = icon ~= "" and ("|t16:16:" .. icon .. "|t ") or ""
    return icon
end

function FarmingPartyLogger:LogLootItem(looterName, lootedByPlayer, itemLink, quantity, totalValue, itemName, lootType, questItemIcon)
    local icon = GetItemIcon(itemLink, lootType, questItemIcon)
    local itemText
    local itemValueText = FarmingParty.Settings:DisplayLootValue() and zo_strformat(' - |cFFFFFF<<1>>|r|t16:16:EsoUI/Art/currency/currency_gold.dds|t', totalValue) or ''
    if quantity == 1 then
        itemText = zo_strformat(icon .. itemLink .. itemValueText)
    else
        itemText = zo_strformat(icon .. itemLink .. ' |cFFFFFFx' .. quantity .. '|r' .. itemValueText)
    end
    
    local lootMessage = ''
    if not lootedByPlayer then
        lootMessage = zo_strformat("|cFFFFFF<<C:1>>|r |c228B22received|r <<2>>", looterName, itemText)
    else
        if not FarmingParty.Settings:DisplayOwnLoot() then return end
        lootMessage = zo_strformat("|c228B22Received|r <<1>>", itemText)
    end
    if FarmingParty.Settings:DisplayInChat() then
        CHAT_SYSTEM:AddMessage(lootMessage)
    end
    
    FarmingPartyWindowBuffer:AddMessage(lootMessage, 255, 255, 0, 1)    
end
