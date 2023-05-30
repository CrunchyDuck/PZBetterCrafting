CDEvolvedItem = {};

function CDEvolvedItem:Inherit()
    -- Get a copy of its parents
    local obj = CDIItem:Inherit();

    -- Add its own dna
    obj = CDTools:TableConcat(obj, CDTools:DeepCopy(self));
    -- Update its types
    obj._types[self] = true;
    return obj;
end

function CDEvolvedItem:New(recipe, item_instance)
    self = CDEvolvedItem:Inherit();
    self.recipe = recipe;
    self.baseItem = item_instance;
    self.fullType = item_instance:getFullType();
    self.name = item_instance:getDisplayName();

    -- source.requiredCount_i = source.baseSource:getCount();
    self.texture = item_instance:getTex();

    return self;
end

function CDEvolvedItem:UpdateAvailability(detailed_b)
    self.detailed_b = detailed_b;
    local last_available = self.available_b;
    -- local last_count = self.numOfItem_i;
    self.available_b = false;
    -- self.numOfItem_i = 0;
    self.availableChanged_b = false;
    -- self.countChanged_b = false;
    self.anyChange_b = false;

    -- Calculate uses of an item.
    -- Largely taken from ISCraftingUI.getAvailableItemType
    -- TODO: I'm pretty sure that water won't work with this system; Figure it out.
    local matching_items = ISCraftingUI.instance.availableItems_ht[self.fullType];
    if matching_items == nil then
        -- if self.numOfItem_i ~= last_count then
        --     -- self.countChanged_b = true;
        --     self.anyChange_b = true;
        -- end
        if self.available_b ~= last_available then
            self.availableChanged_b = true;
            self.anyChange_b = true;
        end
        return;
    --- As I understand it, so long as the food has any nutrition left,
    --- it can be used in a recipe.
    else
        self.available_b = true;
    end

    -- for _, item in pairs(matching_items) do
    --     local count = 1;
    --     if not self.source.baseSource:isDestroy() and item:IsDrainable() then
    --         count = item:getDrainableUsesInt()
    --     elseif not self.source.baseSource:isDestroy() and instanceof(item, "Food") then
    --         if self.source.baseSource:getUse() > 0 then
    --             count = -item:getHungerChange() * 100
    --         end
    --     end

    --     -- Not fully sure how onTest and onCanPerform differ besides their inputs.
    --     if self.recipe.onTest ~= nil and not self.recipe.onTest(item, self.recipe.resultItem) then
    --         count = 0;
    --     end
    --     --- I thought this was broken at first because I wasn't able to craft the "slice pizza" recipe
    --     --- It turns out, that's totally vanilla behaviour!
    --     --- Slice pizza has an inverted check, and it checks if the knife is cooked. (It isn't.)
    --     --- Muffins are also broken! But I don't quite know why.
    --     if self.recipe.onCanPerform ~= nil and not self.recipe.onCanPerform(self.recipe.baseRecipe, getPlayer(), item) then
    --         count = 0;
    --     end

    --     self.numOfItem_i = self.numOfItem_i + count;
    --     self.available_b = self.source.requiredCount_i <= self.numOfItem_i;
    --     if self.available_b and not detailed_b then
    --         break;
    --     end
    -- end

    -- if self.numOfItem_i ~= last_count then
    --     self.countChanged_b = true;
    --     self.anyChange_b = true;
    -- end
    if self.available_b ~= last_available then
        self.availableChanged_b = true;
        self.anyChange_b = true;
    end
end

-- try to get an instance of this item from our items list
function CDEvolvedItem:GetItem()
    local matching_items = ISCraftingUI.instance.availableItems_ht[self.fullType];
    if not matching_items or #matching_items < 1 then return; end

    -- For now I just get the first; In the future, better sorting method.
    return matching_items[1];
end