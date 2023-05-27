--- This is kind of an empty class.
--- Mostly it's here to make this mess of a system a little clearer to me.

CDSource = {};
CDSource.baseSource = nil;
CDSource.recipe = nil;
CDSource.fullType = nil
CDSource.items_ar = {};  -- ar[CDSourceItem]

function CDSource:New(recipe, source)
    local o = CDTools:ShallowCopy(CDSource)
    o.baseSource = source;
    o.recipe = recipe;

    for k = 0, source:getItems():size() - 1 do
        local fullType = source:getItems():get(k);
        local item_instance = nil;
        if fullType == "Water" then
            item_instance = CDRecipe:GetItemInstance("Base.WaterDrop");
        elseif luautils.stringStarts(fullType, "[") then  -- Some debug thing.
            item_instance = CDRecipe:GetItemInstance("Base.WristWatch_Right_DigitalBlack");
        else
            item_instance = CDRecipe:GetItemInstance(fullType);
        end

        -- Is this ever false?
        if item_instance then
            local cditem = CDSourceItem:New(recipe, source, item_instance);
            table.insert(o.items_ar, cditem);
        end
    end

    return o;
end