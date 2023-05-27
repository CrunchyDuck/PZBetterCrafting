require "CDTools"

-- TODO: Index recipe skill.
CDRecipe = {};
CDRecipe.category_str = "";
CDRecipe.baseRecipe = nil;  -- K: zombie.scripting.objects.Recipe
CDRecipe.items_hs = {};  --   
-- CDRecipe.product = nil;  -- zombie.scripting.objects.Recipe.Result
CDRecipe.texture = nil;
CDRecipe.outputName_str = "";
CDRecipe.sources_ar = {};  -- ar[CDSource]
CDRecipe.available_b = false;
CDRecipe.typesAvailable_hs = {};  -- Filled by the crafting UI... for some reason.

-- Bit gross to give every instance its own copy of static.
CDRecipe.static = {};
CDRecipe.static.itemInstances_ht = {};

-- From ISCraftingUI:populateRecipesList
function CDRecipe:New(recipe, character, containers_ar)
    o = CDTools:ShallowCopy(CDRecipe);
    
    o.baseRecipe = recipe;
    if recipe:getCategory() then
        o.category_str = recipe:getCategory();
    else
        o.category_str = getText("IGUI_CraftCategory_General");
    end

    if character then
        o.available_b = RecipeManager.IsRecipeValid(recipe, character, nil, containers_ar);

        -- local modData = character:getModData();
        -- if modData[self:getFavoriteModDataLocalString(recipe)] or false then  -- Update the favorite list and save backward compatibility
        --     --table.remove(modData, self:getFavoriteModDataLocalString(recipe));
        --     modData[self:getFavoriteModDataString(recipe)] = true;
        -- end
        -- newItem.favorite = modData[self:getFavoriteModDataString(recipe)] or false;
    end
    -- if newItem.favorite then
    --     table.insert(self.recipesList[getText("IGUI_CraftCategory_Favorite")], newItem);
    -- end

    local result_item = self:GetItemInstance(recipe:getResult():getFullType());
    -- When is this ever false?
    if result_item then
        o.texture = result_item:getTex();
        o.outputName_str = result_item:getDisplayName();
        if recipe:getResult():getCount() > 1 then
            -- How does the math here work?
            o.outputCount = (recipe:getResult():getCount() * result_item:getCount()) .. " " .. o.outputName_str;
        end
    end

    o.sources_ar = {};
    for x = 0, recipe:getSource():size() - 1 do
        local source = CDSource:New(recipe, recipe:getSource():get(x));  -- zombie.scripting.objects.Recipe.Source
        table.insert(o.sources_ar, source);
    end

    -- o.product = recipe:getResult();
    return o;
end

function CDRecipe:CompareTo(other)
    -- Compare items
    for k, _ in pairs(self.items_hs) do
        if other.items_hs[k] == nil then
            return false;
        end
    end

    -- TOOD: Compare product
    return true;
end

function CDRecipe:SearchComponent(name_str)

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

-- From ISCraftingUI:GetItemInstance
function CDRecipe:GetItemInstance(type)
    local item_instance = self.static.itemInstances_ht[type];
    if item_instance then return item_instance end;

    item_instance = InventoryItemFactory.CreateItem(type);  -- What is this type? What does it do?
    -- Shouldn't this break if item_instance is nil?
    if item_instance then
        self.static.itemInstances_ht[type] = item_instance;
        self.static.itemInstances_ht[item_instance:getFullType()] = item_instance;  -- I don't understand why this is needed.
    end
    return item_instance
end