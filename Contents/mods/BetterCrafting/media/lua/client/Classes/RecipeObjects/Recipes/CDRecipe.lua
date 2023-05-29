require "CDTools"

-- Inherits from CDIRecipe
CDRecipe = {};
CDRecipe.sources_ar = nil;  -- ar[CDSource]
CDRecipe.onTest = nil;
CDRecipe.onCanPerform = nil;

-- CDRecipe.evolved = false;
-- CDRecipe.evolvedItems_ar = nil;

CDRecipe.sourcesChanged_b = false;  -- Whether a source, or any of its items, changed. Only updated for detailed searches.


-- From ISCraftingUI:populateRecipesList
function CDRecipe:New(recipe)
    local o = CDTools:InheritFrom({CDIRecipe, CDRecipe});
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
    if recipe:getCanPerform() ~= nil then
        o.onCanPerform = CDTools:FindGlobal(recipe:getCanPerform());
    end

    o.resultItem = o:GetItemInstance(recipe:getResult():getFullType());
    -- When is this ever false?
    if o.resultItem then
        o.texture = o.resultItem:getTex();
        o.outputName_str = o.resultItem:getDisplayName();
        -- if recipe:getResult():getCount() > 1 then
            -- How does the math here work?
            -- o.outputCount = (recipe:getResult():getCount() * o.resultItem:getCount()) .. " " .. o.outputName_str;
        -- end
    end

    for i = 0, recipe:getSource():size() - 1 do
        local source = CDSource:New(o, recipe:getSource():get(i));  -- zombie.scripting.objects.Recipe.Source
        table.insert(o.sources_ar, source);
    end
    return o;
end

-- function CDRecipe:NewEvolved(recipe)
--     o = CDTools:ShallowCopy(CDRecipe);
--     o.evolvedItems_ar = {};
--     o.resultItem = self:GetItemInstance(recipe:getFullResultItem());
--     if not o.resultItem then
--         return;
--     end
--     o.evolved = true;
--     o.category_str = "Cooking";  -- Evo are only cooking recipes right now.
--     o.baseRecipe = recipe;

--     o.texture = o.resultItem:getTex();
--     o.outputName_str = o.resultItem:getDisplayName();

--     -- Things in the original evolved recipe code I haven't found a use for yet.
--     -- o.itemName = recipe:getName();
--     -- o.baseItem = self:GetItemInstance(evolvedRecipe:getModule():getName() .. "." .. evolvedRecipe:getBaseItem())

--     local possible_items = recipe:getPossibleItems();
--     for i = 0, possible_items:size() - 1 do
--         local item = possible_items:get(i);
--         local instance = self:GetItemInstance(item:getFullType());
--         local evo_item = CDEvolvedItem:New(o, instance);
--         table.insert(o.evolvedItems_ar, evo_item);
--     end

--     return o;
-- end

function CDRecipe:UpdateAvailability(detailed_b)
    self.detailed_b = detailed_b;
    local last_available = self.available_b;
    self.available_b = true;
    self.availableChanged_b = false;
    self.sourcesChanged_b = false;
    self.anyChange_b = false;

    for _, source in pairs(self.sources_ar) do
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
end

-- function CDRecipe:UpdateEvolvedRecipe(detailed_b)
    
-- end