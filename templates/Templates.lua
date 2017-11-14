FarmingParty.Templates = {}

local FarmingPartyWindowBase = {}
FarmingParty.Templates.Window = FarmingPartyWindowBase

function FarmingPartyWindowBase:Initialize(control)
    ZO_ShallowTableCopy(self, control)
end

function FarmingPartyWindowBase:SetWindowTransparency(value, settingsKey)
    local settings = FarmingPartySettings:GetSettings()
    if value ~= nil then
        settings[settingsKey].transparency = value
    end
    self:SetAlpha(settings[settingsKey].transparency / 100)
end

function FarmingPartyWindowBase:SetWindowBackgroundTransparency(value, settingsKey)
    local settings = FarmingPartySettings:GetSettings()
    if value ~= nil then
        settings[settingsKey].backgroundTransparency = value
    end
    self:GetNamedChild("BG"):SetAlpha(settings[settingsKey].backgroundTransparency / 100)
end

function FarmingPartyWindowBase:SetTitle(titleText)
    local title = self:GetNamedChild("Title")
    title:SetText(titleText)
end

function FarmingPartyWindowBase:ToggleWindow()
    self:SetHidden(not self:IsHidden())
end

function FarmingPartyWindowBase:OpenWindow()
    self:SetHidden(false)
end