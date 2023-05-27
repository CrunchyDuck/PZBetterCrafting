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

function CDSourceItem:New(recipe, source, item_instance)
    local o = CDTools:ShallowCopy(CDSourceItem);
    o.recipe = recipe;
    o.source = source;
    o.baseItem = item_instance;

    source.requiredCount_i = source.baseSource:getCount();
    o.texture = item_instance:getTex();

    -- Get the item_instance's name.
    if sourceFullType == "Water" then
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

    o.fullType = item_instance:getFullType();
    if sourceFullType == "Water" then
        o.fullType = "Water"
    end

    return o
end