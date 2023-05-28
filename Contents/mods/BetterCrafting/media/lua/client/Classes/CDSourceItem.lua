-- An item, as it relates to a Source.

--- If I want to improve performance, I might make a base "CDItem",
--- which CDSourceItem fetches/derives from. Prevents repeatedly making items.
--- Not sure how it's handled in the java though, so not sure if it's taxing.
CDSourceItem = {};
CDSourceItem.recipe = nil;  -- CDRecipe
CDSourceItem.source = nil;  -- CDSource
CDSourceItem.baseItem = nil;  -- zombie.inventory.InventoryItem, I think?
CDSourceItem.texture = nil;
CDSourceItem.name = "";
CDSourceItem.fullType = "";
CDSourceItem.numOfItem_i = 0;

CDSourceItem.available_b = false;
CDSourceItem.detailed_b = false;
CDSourceItem.availableChanged_b = false;
CDSourceItem.countChanged_b = false;
CDSourceItem.anyChange_b = false;

function CDSourceItem:New(recipe, source, item_instance)
    local o = CDTools:ShallowCopy(CDSourceItem);
    o.recipe = recipe;
    o.source = source;
    o.baseItem = item_instance;
    o.fullType = item_instance:getFullType();

    source.requiredCount_i = source.baseSource:getCount();
    o.texture = item_instance:getTex();

    -- Get the item_instance's name.
    if o.fullType == "Base.WaterDrop" then
        if source.requiredCount_i == 1 then
            o.name = getText("IGUI_CraftUI_CountOneUnit", getText("ContextMenu_WaterName"))
        else
            o.name = getText("IGUI_CraftUI_CountUnits", getText("ContextMenu_WaterName"), source.requiredCount_i)
        end
        if recipe.baseRecipe:getHeat() < 0 then
            o.name = getText("IGUI_FoodTemperatureNaming", getText("IGUI_Temp_Hot"), o.name);
        elseif recipe.baseRecipe:getHeat() > 0 then
            o.name = getText("IGUI_FoodTemperatureNaming", getText("IGUI_Temp_Cold"), o.name);
        end
    elseif source.baseSource:getItems():size() > 1 then -- no units
        o.name = item_instance:getDisplayName()
    elseif not source.baseSource:isDestroy() and item_instance:IsDrainable() then
        if source.requiredCount_i == 1 then
            o.name = getText("IGUI_CraftUI_CountOneUnit", item_instance:getDisplayName())
        else
            o.name = getText("IGUI_CraftUI_CountUnits", item_instance:getDisplayName(), source.requiredCount_i)
        end
        if recipe.baseRecipe:getHeat() < 0 then
            o.name = getText("IGUI_FoodTemperatureNaming", getText("IGUI_Temp_Hot"), o.name);
        elseif recipe.baseRecipe:getHeat() > 0 then
            o.name = getText("IGUI_FoodTemperatureNaming", getText("IGUI_Temp_Cold"), o.name);
        end;
    elseif not source.baseSource:isDestroy() and source.baseSource:getUse() > 0 then -- food
        source.requiredCount_i = source.baseSource:getUse()
        if source.requiredCount_i == 1 then
            o.name = getText("IGUI_CraftUI_CountOneUnit", item_instance:getDisplayName())
        else
            o.name = getText("IGUI_CraftUI_CountUnits", item_instance:getDisplayName(), source.requiredCount_i)
        end
    elseif source.requiredCount_i > 1 then
        o.name = getText("IGUI_CraftUI_CountNumber", item_instance:getDisplayName(), source.requiredCount_i)
    else
        o.name = item_instance:getDisplayName()
    end

    return o;
end

function CDSourceItem:UpdateAvailability(detailed_b)
    self.detailed_b = detailed_b;
    local last_available = self.available_b;
    local last_count = self.numOfItem_i;
    self.available_b = false;
    self.numOfItem_i = 0;
    self.availableChanged_b = false;
    self.countChanged_b = false;
    self.anyChange_b = false;

    -- Calculate uses of an item.
    -- Largely taken from ISCraftingUI.getAvailableItemType
    -- TODO: I'm pretty sure that water won't work with this system; Figure it out.
    local matching_items = ISCraftingUI.instance.availableItems_ht[self.fullType];
    if matching_items == nil then
        if self.numOfItem_i ~= last_count then
            self.countChanged_b = true;
            self.anyChange_b = true;
        end
        if self.available_b ~= last_available then
            self.availableChanged_b = true;
            self.anyChange_b = true;
        end
        return;
    end

    for _, item in pairs(matching_items) do
        local count = 1;
        if not self.source.baseSource:isDestroy() and item:IsDrainable() then
            count = item:getDrainableUsesInt()
        elseif not self.source.baseSource:isDestroy() and instanceof(item, "Food") then
            if self.source.baseSource:getUse() > 0 then
                count = -item:getHungerChange() * 100
            end
        end
        if self.recipe.onTest ~= nil and not self.recipe.onTest(item, self.recipe.resultItem) then
            count = 0;
        end

        self.numOfItem_i = self.numOfItem_i + count;
        self.available_b = self.source.requiredCount_i <= self.numOfItem_i;
        if self.available_b and not detailed_b then
            break;
        end
    end

    if self.numOfItem_i ~= last_count then
        self.countChanged_b = true;
        self.anyChange_b = true;
    end
    if self.available_b ~= last_available then
        self.availableChanged_b = true;
        self.anyChange_b = true;
    end
    return;
end