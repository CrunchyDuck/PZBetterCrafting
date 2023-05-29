CDEvolvedItem = {};

function CDEvolvedItem:New(recipe, item_instance)
    self = CDTools:InheritFrom({CDIItem, CDEvolvedItem});
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