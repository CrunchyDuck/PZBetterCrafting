CDIItem = {};
CDIItem.recipe = nil;  -- CDRecipe
CDIItem.baseItem = nil;  -- zombie.inventory.InventoryItem, I think?
CDIItem.texture = nil;
CDIItem.name = "";
CDIItem.fullType = "";

CDIItem.available_b = false;
CDIItem.detailed_b = false;
CDIItem.availableChanged_b = false;
CDIItem.anyChange_b = false;

function CDIItem:Inherit()
    -- Get a copy of its parents
    local obj = CDBaseClass:Inherit();

    -- Add its own dna
    obj = CDTools:TableConcat(obj, CDTools:DeepCopy(self));
    -- Update its types
    obj._types[self] = true;
    return obj;
end

function CDIItem:UpdateAvailability(detailed_b)

end