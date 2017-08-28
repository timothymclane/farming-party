local listContainer
MemberItems = {}

function MemberItems:Initialize()
    listContainer = FarmingPartyMemberItemsWindow:GetNamedChild("List")
    ZO_ScrollList_AddDataType(listContainer, FarmingParty.DataTypes.MEMBER_ITEM, "FarmingPartyItemDataRow", 20, InitializeRow)
end

local function InitializeRow(control, data)
    control:SetText(data.key)

    control:SetHandler(
        "OnClicked",
        function()
            local note = members:GetMember(data.key)

            currentKey = data.key
            d(currentKey)
        end
    )
end
