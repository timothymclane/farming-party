local listContainer
FarmingPartyMemberItems = ZO_Object:Subclass()
local members = {}

function FarmingPartyMemberItems:New()
    local obj = ZO_Object.New(self)
    self:Initialize()
    return obj
end

function FarmingPartyMemberItems:Initialize()
    listContainer = FarmingPartyMemberItemsWindow:GetNamedChild("List")
    FarmingPartyMemberItemsWindow:SetHandler("OnResizeStop", function(...)self:WindowResizeHandler(...) end)
    members = FarmingParty.Modules.Members    
    self:SetupScrollList()
    self:UpdateScrollList()
    members:RegisterCallback("OnKeysUpdated", self.UpdateScrollList)
end


function FarmingPartyMemberItems:SetupScrollList()
    ZO_ScrollList_AddResizeOnScreenResize(listContainer)
    ZO_ScrollList_AddDataType(
        listContainer,
        FarmingParty.DataTypes.MEMBER_ITEM,
        "FarmingPartyItemDataRow",
        20,
        function(listControl, data)
            self:SetupItemRow(listControl, data)
        end
)
end

function FarmingPartyMemberItems:UpdateScrollList()
    local scrollData = ZO_ScrollList_GetDataList(listContainer)
    ZO_ScrollList_Clear(listContainer)
    
    local member = members:GetMember("Aldanga")
    local memberItems = members:GetItemsForMember("Aldanga")
    local memberItemArray = {}
    for key, value in pairs(memberItems) do
        value.itemLink = key
        memberItemArray[#memberItemArray + 1] = value
    end
    table.sort(memberItemArray, function(a, b)
        if (a.totalValue == b.totalValue) then
            return a.itemLink < b.itemLink
        end
        return a.totalValue > b.totalValue
    end)
    for i = 1, #memberItemArray do
        scrollData[#scrollData + 1] =
            ZO_ScrollList_CreateDataEntry(FarmingParty.DataTypes.MEMBER_ITEM, {rawData = memberItemArray[i]})
    end
    
    ZO_ScrollList_Commit(listContainer)
end

function FarmingPartyMemberItems:SetupItemRow(rowControl, rowData)
    rowControl.data = rowData
    local data = rowData.rawData
    local itemName = GetControl(rowControl, "ItemName")
    local itemCount = GetControl(rowControl, "Count")
    local totalValue = GetControl(rowControl, "TotalValue")

    itemName:SetText(data.itemLink)
    itemCount:SetText(data.count)
    totalValue:SetText(FarmingParty.FormatNumber(data.totalValue, 2) .. 'g')
end

function FarmingPartyMemberItems:WindowResizeHandler(control)
    ZO_ScrollList_Commit(listContainer)
end

function FarmingPartyMemberItems:ToggleWindow()
    FarmingPartyMemberItemsWindow:SetHidden(not FarmingPartyMemberItemsWindow:IsHidden())
end
