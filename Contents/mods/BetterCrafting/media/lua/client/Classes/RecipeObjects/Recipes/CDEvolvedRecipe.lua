-- An evolved recipe that hasn't yet been prepared.
CDEvolvedRecipe = {};

CDEvolvedRecipe.evolvedItems_ar = nil;  -- ar[CDEvolvedItem] Possible items to add.
CDEvolvedRecipe.baseItem = nil;  -- zombie.inventory.InventoryItem
CDEvolvedRecipe.itemsChanged_b = false;

function CDEvolvedRecipe:Inherit()
    -- Get a copy of its parents
    local obj = CDIRecipe:Inherit();

    -- Add its own dna
    obj = CDTools:TableConcat(obj, CDTools:DeepCopy(self));
    -- Update its types
    obj._types[self] = true;
    return obj;
end

function CDEvolvedRecipe:New(base_recipe)
    self = self:Inherit();
    self.evolvedItems_ar = {};
    self.resultItem = self:GetItemInstance(base_recipe:getFullResultItem());
    if not self.resultItem then
        return;
    end
    self.evolved = true;
    self.category_str = "Cooking";  -- Evo are only cooking recipes right now.
    self.baseRecipe = base_recipe;

    self.texture = self.resultItem:getTex();
    self.outputName_str = self.resultItem:getDisplayName();
    self.baseItem = self:GetItemInstance(base_recipe:getModule():getName() .. "." .. base_recipe:getBaseItem())
    
    local possible_items = base_recipe:getPossibleItems();
    for i = 0, possible_items:size() - 1 do
        local item = possible_items:get(i);
        local instance = self:GetItemInstance(item:getFullType());
        local evo_item = CDEvolvedItem:New(self, instance);
        table.insert(self.evolvedItems_ar, evo_item);
    end

    return self;
end

function CDEvolvedRecipe:UpdateAvailability(detailed_b)
    self.detailed_b = detailed_b;
    local last_available = self.available_b;
    self.available_b = false;
    self.availableChanged_b = false;
    self.itemsChanged_b = false;
    self.anyChange_b = false;

    -- Check for base item
    local have_base_item = true;
    if ISCraftingUI.instance.availableItems_ht[self.baseItem:getFullType()] == nil then
        have_base_item = false;
        if self.available_b ~= last_available then
            self.availableChanged_b = true;
            self.anyChange_b = true;
        end;
        if not detailed_b then
            return;
        end
    end

    local found_item = false;
    if detailed_b or have_base_item then
        found_item = self:CheckIngredients(detailed_b);
    end

    if found_item and have_base_item then
        self.available_b = true;
    end

    if self.available_b ~= last_available then
        self.availableChanged_b = true;
        self.anyChange_b = true;
    end
end

function CDEvolvedRecipe:CheckIngredients(detailed_b)
    local found_item = false;
    for _, item in pairs(self.evolvedItems_ar) do
        item:UpdateAvailability(detailed_b);
        if item.anyChange_b then
            self.itemsChanged_b = true;
        end
        if item.available_b then
            found_item = true;
            if not detailed_b then
                return true;
            end
        end

        if not detailed_b and found_item then
            break;
        end
    end
    return found_item;
end