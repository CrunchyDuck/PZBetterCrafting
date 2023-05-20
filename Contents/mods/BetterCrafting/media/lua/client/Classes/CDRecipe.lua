require "CDTools"
--- The goal of this class is to group common recipes together.
--- This allows them to be grouped and displayed differently.

CDRecipe = {};
CDRecipe.commonComponent_hs = {};
CDRecipe.baseRecipes_hs = {};  -- K:zombie.scripting.objects.Recipe
CDRecipe.items_hs = {};  
CDRecipe.product = {};  -- zombie.scripting.objects.Recipe.Result


function CDRecipe:New(recipe)
    cdr = shallow_copy(CDRecipe);
    cdr.baseRecipes_hs[recipe] = true;
    cdr.product = recipe:getResult();
    return cdr
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