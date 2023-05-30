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

end