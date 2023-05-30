require "CDTools"

-- Inherits from CDIRecipe
CDRecipe = {};
CDRecipe.sources_ar = nil;  -- ar[CDSource]
CDRecipe.onTest = nil;
CDRecipe.onCanPerform = nil;

-- CDRecipe.evolved = false;
-- CDRecipe.evolvedItems_ar = nil;

CDRecipe.sourcesChanged_b = false;  -- Whether a source, or any of its items, changed. Only updated for detailed searches.

function CDRecipe:Inherit()
    -- Get a copy of its parents
    local obj = CDIRecipe:Inherit();

    -- Add its own dna
    obj = CDTools:TableConcat(obj, CDTools:DeepCopy(self));
    -- Update its types
    obj._types[self] = true;
    return obj;
end

-- From ISCraftingUI:populateRecipesList
function CDRecipe:New(recipe)
    self = self:Inherit();
    self.sources_ar = {};

    self.baseRecipe = recipe;
    if recipe:getCategory() then
        self.category_str = recipe:getCategory();
    else
        self.category_str = getText("IGUI_CraftCategory_General");
    end

    if recipe:getLuaTest() ~= nil then
        self.onTest = CDTools:FindGlobal(recipe:getLuaTest());
    end
    if recipe:getCanPerform() ~= nil then
        self.onCanPerform = CDTools:FindGlobal(recipe:getCanPerform());
    end

    self.resultItem = self:GetItemInstance(recipe:getResult():getFullType());
    -- When is this ever false?
    if self.resultItem then
        self.texture = self.resultItem:getTex();
        self.outputName_str = self.resultItem:getDisplayName();
        -- if recipe:getResult():getCount() > 1 then
            -- How does the math here work?
            -- self.outputCount = (recipe:getResult():getCount() * self.resultItem:getCount()) .. " " .. self.outputName_str;
        -- end
    end

    for i = 0, recipe:getSource():size() - 1 do
        local source = CDSource:New(self, recipe:getSource():get(i));  -- zombie.scripting.objects.Recipe.Source
        table.insert(self.sources_ar, source);
    end
    return self;
end

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