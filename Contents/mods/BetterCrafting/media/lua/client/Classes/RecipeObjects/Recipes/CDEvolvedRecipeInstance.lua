CDEvolvedRecipeInstance = {};

CDEvolvedRecipeInstance.extraItems_ar = {};  -- ar[zombie.inventory.InventoryItem]. Items added to this recipe.
CDEvolvedRecipeInstance.customRecipeName = "";

function CDEvolvedRecipeInstance:Inherit()
    -- Get a copy of its parents
    local obj = CDEvolvedRecipe:Inherit();

    -- Add its own dna
    obj = CDTools:TableConcat(obj, CDTools:DeepCopy(self));
    -- Update its types
    obj._types[self] = true;
    return obj;
end

function CDEvolvedRecipeInstance:New(base_item, base_recipe)
    self = self:Inherit();
    -- Call the base constructor.
    self = CDEvolvedRecipe.New(self, base_recipe);
    if not self then
        print("CDDebug: " .. base_recipe:getName());
        return;
    end
    self.baseItem = base_item;
    self:UpdateExtraItems();

    return self;
end

function CDEvolvedRecipeInstance:GetBaseItem()
    -- For an instance, the base item *is* the instance of the base item.
    return self.baseItem;
end

function CDEvolvedRecipeInstance:UpdateExtraItems()
    self.customRecipeName = getText("IGUI_CraftUI_FromBaseItem", self.baseItem:getDisplayName());
    self.extraItems_ar = {};
    if self.baseItem:getExtraItems() then
        for i = 0, self.baseItem:getExtraItems():size() - 1 do
           local extra_item = self:GetItemInstance(self.baseItem:getExtraItems():get(i));
            if extra_item then
                table.insert(self.extraItems_ar, extra_item:getTex());
            end
        end
    end
    if instanceof(self.baseItem, "Food") and self.baseItem:getSpices() then
        for i = 0, self.baseItem:getSpices():size() - 1 do
           local extra_item = self:GetItemInstance(self.baseItem:getSpices():get(i));
            if extra_item then
                table.insert(self.extraItems_ar, extra_item:getTex());
            end
        end
    end
end