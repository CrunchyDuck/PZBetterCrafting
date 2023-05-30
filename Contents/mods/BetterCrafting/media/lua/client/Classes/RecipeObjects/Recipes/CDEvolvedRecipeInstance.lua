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
    -- local base_recipe = RecipeManager.getEvolvedRecipe(base_item, self.character, self.containerList, false);
    -- Call the base constructor.
    self = CDEvolvedRecipe.New(self, base_recipe);
    if not self then
        return;
    end
    self.baseItem = base_item;
    self.customRecipeName = getText("IGUI_CraftUI_FromBaseItem", base_item:getDisplayName());

    if base_item:getExtraItems() then
        for i = 0, base_item:getExtraItems():size() - 1 do
           local extra_item = self:GetItemInstance(base_item:getExtraItems():get(i));
            if extra_item then
                table.insert(self.extraItems_ar, extra_item:getTex());
            end
        end
    end
    if instanceof(base_item, "Food") and base_item:getSpices() then
        for i = 0, base_item:getSpices():size() - 1 do
           local extra_item = self:GetItemInstance(base_item:getSpices():get(i));
            if extra_item then
                table.insert(self.extraItems_ar, extra_item:getTex());
            end
        end
    end
end