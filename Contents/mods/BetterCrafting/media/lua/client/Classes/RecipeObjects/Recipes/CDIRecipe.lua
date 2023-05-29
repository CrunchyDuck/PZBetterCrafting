-- Generic recipe passed around.
CDIRecipe = {};
CDIRecipe.baseRecipe = nil;  -- zombie.scripting.objects.Recipe
CDIRecipe.resultItem = nil;
CDIRecipe.texture = nil;
CDIRecipe.category_str = "";
CDIRecipe.outputName_str = "";
-- CDIRecipe.sources_ar = {};  -- ar[CDSource]
-- CDIRecipe.onTest = nil;
-- CDIRecipe.onCanPerform = nil;

-- CDIRecipe.evolved = false;
-- CDIRecipe.evolvedItems_ar = {};

CDIRecipe.available_b = false;
CDIRecipe.detailed_b = false;  -- A non-detailed recipe only checks enough to figure out if it is unavailable.
CDIRecipe.availableChanged_b = false;  -- Whether this recipe's state changed.
-- CDIRecipe.sourcesChanged_b = false;  -- Whether a source, or any of its items, changed. Only updated for detailed searches.
CDIRecipe.anyChange_b = false;

CDIRecipe.static = {};
CDIRecipe.static.itemInstances_ht = {};

-- From ISCraftingUI:GetItemInstance
function CDIRecipe:GetItemInstance(type)
    local item_instance = CDIRecipe.static.itemInstances_ht[type];
    if item_instance then return item_instance end;

    item_instance = InventoryItemFactory.CreateItem(type);
    -- Above can return null; We index it anyway.
    CDIRecipe.static.itemInstances_ht[type] = item_instance;
    CDIRecipe.static.itemInstances_ht[item_instance:getFullType()] = item_instance;  -- I don't understand why this is needed.
    -- This is placed in here so that it only triggers once.
    if item_instance == nil then
        print('CDBetterCrafting: Could not find result item "' .. item_instance);
    end
    return item_instance;
end

function CDIRecipe.SortFromListbox(a_listboxElement, b_listboxElement)
    local a = a_listboxElement.item;
    local b = b_listboxElement.item;

    -- Available recipes are at the top
    if a.available_b and not b.available_b then return true end
    if not a.available_b and b.available_b then return false end

    -- ????
    -- if a.customRecipeName and not b.customRecipeName then return true end
    -- if not a.customRecipeName and b.customRecipeName then return false end

    -- Sort alphabetically
    return not string.sort(a.baseRecipe:getName(), b.baseRecipe:getName())
end

-- Abstract class
function CDIRecipe:UpdateAvailability(detailed_b)

end