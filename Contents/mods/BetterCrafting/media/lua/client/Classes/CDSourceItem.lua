CDSourceItem = {};
CDSourceItem.baseItem = nil;
CDSourceItem.count = 0;
CDSourceItem.texture = nil;
CDSourceItem.name = "";
CDSourceItem.fullType = "";

-- TODO: Finish this bollocks.
function CDSourceItem:New(recipe, source, item_instance)
    local o = CDTools:ShallowCopy(CDSourceItem);
    o.baseItem = item_instance;

    o.count = source:getCount();
    o.texture = item_instance:getTex();

    -- Get the item_instance's name.
    if sourceFullType == "Water" then
        if o.count == 1 then
            o.name = getText("IGUI_CraftUI_CountOneUnit", getText("ContextMenu_WaterName"))
        else
            o.name = getText("IGUI_CraftUI_CountUnits", getText("ContextMenu_WaterName"), o.count)
        end
        if recipe:getHeat() < 0 then
            o.name = getText("IGUI_FoodTemperatureNaming", getText("IGUI_Temp_Hot"), o.name);
        elseif recipe:getHeat() > 0 then
            o.name = getText("IGUI_FoodTemperatureNaming", getText("IGUI_Temp_Cold"), o.name);
        end
    elseif source:getItems():size() > 1 then -- no units
        o.name = item_instance:getDisplayName()
    elseif not source:isDestroy() and item_instance:IsDrainable() then
        if o.count == 1 then
            o.name = getText("IGUI_CraftUI_CountOneUnit", item_instance:getDisplayName())
        else
            o.name = getText("IGUI_CraftUI_CountUnits", item_instance:getDisplayName(), o.count)
        end
        if recipe:getHeat() < 0 then
            o.name = getText("IGUI_FoodTemperatureNaming", getText("IGUI_Temp_Hot"), o.name);
        elseif recipe:getHeat() > 0 then
            o.name = getText("IGUI_FoodTemperatureNaming", getText("IGUI_Temp_Cold"), o.name);
        end;
    elseif not source:isDestroy() and source:getUse() > 0 then -- food
        o.count = source:getUse()
        if o.count == 1 then
            o.name = getText("IGUI_CraftUI_CountOneUnit", item_instance:getDisplayName())
        else
            o.name = getText("IGUI_CraftUI_CountUnits", item_instance:getDisplayName(), o.count)
        end
    elseif o.count > 1 then
        o.name = getText("IGUI_CraftUI_CountNumber", item_instance:getDisplayName(), o.count)
    else
        o.name = item_instance:getDisplayName()
    end

    o.fullType = item_instance:getFullType();
    if sourceFullType == "Water" then
        o.fullType = "Water"
    end

    return o
end