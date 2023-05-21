require "CDTools"

CDRecipe = {};
CDRecipe.baseRecipe = nil;  -- K:zombie.scripting.objects.Recipe
CDRecipe.items_hs = {};  --   
CDRecipe.product = nil;  -- zombie.scripting.objects.Recipe.Result


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

function CDRecipe:SearchComponent(name_str)

end