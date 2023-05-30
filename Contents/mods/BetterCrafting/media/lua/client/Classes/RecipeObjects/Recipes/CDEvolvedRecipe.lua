-- Implements CDIRecipe
CDEvolvedRecipe = {};

CDEvolvedRecipe.evolvedItems_ar = nil;

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

    -- Things in the original evolved recipe code I haven't found a use for yet.
    -- self.itemName = recipe:getName();
    -- self.baseItem = self:GetItemInstance(evolvedRecipe:getModule():getName() .. "." .. evolvedRecipe:getBaseItem())

    local possible_items = base_recipe:getPossibleItems();
    for i = 0, possible_items:size() - 1 do
        local item = possible_items:get(i);
        local instance = self:GetItemInstance(item:getFullType());
        local evo_item = CDEvolvedItem:New(self, instance);
        table.insert(self.evolvedItems_ar, evo_item);
    end

    return self;
end

function CDEvolvedRecipe:Inherit()
    -- Get a copy of its parents
    local obj = CDIRecipe:Inherit();

    -- Add its own dna
    obj = CDTools:TableConcat(obj, CDTools:DeepCopy(self));
    -- Update its types
    obj._types[self] = true;
    return obj;
end