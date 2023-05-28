require "CDTools"

-- TODO: Index recipe skill.
CDRecipe = {};
CDRecipe.category_str = "";
CDRecipe.baseRecipe = nil;  -- zombie.scripting.objects.Recipe
CDRecipe.texture = nil;
CDRecipe.outputName_str = "";
CDRecipe.sources_ar = {};  -- ar[CDSource]
CDRecipe.onTest = nil;
CDRecipe.resultItem = nil;

CDRecipe.available_b = false;
CDRecipe.detailed_b = false;  -- A non-detailed recipe only checks enough to figure out if it is unavailable.
CDRecipe.availableChanged_b = false;  -- Whether this recipe's state changed.
CDRecipe.sourcesChanged_b = false;  -- Whether a source, or any of its items, changed. Only updated for detailed searches.
CDRecipe.anyChange_b = false;

CDRecipe.static = {};
CDRecipe.static.itemInstances_ht = {};

-- From ISCraftingUI:populateRecipesList
function CDRecipe:New(recipe)
    o = CDTools:ShallowCopy(CDRecipe);
    o.sources_ar = {};
    
    o.baseRecipe = recipe;
    if recipe:getCategory() then
        o.category_str = recipe:getCategory();
    else
        o.category_str = getText("IGUI_CraftCategory_General");
    end

    if recipe:getLuaTest() ~= nil then
        o.onTest = CDTools:FindGlobal(recipe:getLuaTest());
    end

    o.resultItem = o:GetItemInstance(recipe:getResult():getFullType());
    -- When is this ever false?
    if o.resultItem then
        o.texture = o.resultItem:getTex();
        o.outputName_str = o.resultItem:getDisplayName();
        if recipe:getResult():getCount() > 1 then
            -- How does the math here work?
            o.outputCount = (recipe:getResult():getCount() * o.resultItem:getCount()) .. " " .. o.outputName_str;
        end
    end

    for i = 0, recipe:getSource():size() - 1 do
        local source = CDSource:New(o, recipe:getSource():get(i));  -- zombie.scripting.objects.Recipe.Source
        table.insert(o.sources_ar, source);
    end
    return o;
end

-- Returns true if a state happened, false if not.
-- In non-detailed mode, it will only return "true" if the recipe state changed.
function CDRecipe:UpdateAvailability(detailed_b)
    self.detailed_b = detailed_b;
    local last_available = self.available_b;
    self.available_b = true;
    self.availableChanged_b = false;
    self.sourcesChanged_b = false;
    self.anyChange_b = false;

    for i, source in pairs(self.sources_ar) do
        source:UpdateAvailability(detailed_b);
        self.available_b = self.available_b and source.available_b;
        
        if source.anyChange_b then
            self.sourcesChanged_b = true;
            self.anyChange_b = true;
        end

        -- Recipes require all sources to be valid to use.
        if not detailed_b and not self.available_b then
            break;
        end
    end

    if self.available_b ~= last_available then
        self.availableChanged_b = true;
        self.anyChange_b = true;
    end
    return;
end

-- From ISCraftingUI:GetItemInstance
function CDRecipe:GetItemInstance(type)
    local item_instance = CDRecipe.static.itemInstances_ht[type];
    if item_instance then return item_instance end;

    item_instance = InventoryItemFactory.CreateItem(type);
    -- Shouldn't this break if item_instance is nil?
    if item_instance then
        CDRecipe.static.itemInstances_ht[type] = item_instance;
        CDRecipe.static.itemInstances_ht[item_instance:getFullType()] = item_instance;  -- I don't understand why this is needed.
    end
    return item_instance;
end

function CDRecipe.SortFromListbox(a_listboxElement, b_listboxElement)
    a = a_listboxElement.item;
    b = b_listboxElement.item;

    -- Available recipes are at the top
    if a.available_b and not b.available_b then return true end
    if not a.available_b and b.available_b then return false end

    -- ????
    -- if a.customRecipeName and not b.customRecipeName then return true end
    -- if not a.customRecipeName and b.customRecipeName then return false end

    -- Sort alphabetically
    return not string.sort(a.baseRecipe:getName(), b.baseRecipe:getName())
end