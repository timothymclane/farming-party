local FarmingPartyModule = ZO_Object:Subclass()
FarmingParty.Templates.Module = FarmingPartyModule

function FarmingPartyModule:New(moduleName)
    local object = ZO_Object.New(self)
    object.NAME = moduleName
    
    return object
end

--- Meant to be averridden ---
function FarmingPartyModule:Initialize(serverName, displayName)
end

--- meant to be averridden ---
function FarmingPartyModule:Finalize()
end
