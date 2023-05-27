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

    -- Calculate uses of an item.
    -- Largely taken from ISCraftingUI.getAvailableItemType
    -- TODO: I'm pretty sure that water won't work with this system; Figure it out.
    local matching_items = ISCraftingUI.instance.availableItems_ht[o.fullType];
    if matching_items == nil then
        return o;
    end
    for _, item in pairs(matching_items) do
        local count = 1;
        if not o.source.baseSource:isDestroy() and item:IsDrainable() then
            count = item:getDrainableUsesInt()
        end
        if not o.source.baseSource:isDestroy() and instanceof(item, "Food") then
            if o.source.baseSource:getUse() > 0 then
                count = -item:getHungerChange() * 100
            end
        end
        o.numOfItem_i = o.numOfItem_i + count;
    end
    o.available_b = o.source.requiredCount_i <= o.numOfItem_i;

    return o;
end

function CDSourceItem.isWaterSource(item)
    return instanceof(item, "DrainableComboItem") and item:isWaterSource() and item:getDrainableUsesInt() >= count;
end