--- This is kind of an empty class.
--- Mostly it's here to make this mess of a system a little clearer to me.

CDSource = {};
CDSource.baseSource = nil;
CDSource.recipe = nil;
CDSource.requiredCount_i = 0;
CDSource.items_ar = {};  -- ar[CDSourceItem]

CDSource.available_b = false;
CDSource.detailed_b = false;
CDSource.availableChanged_b = false;
CDSource.itemsChanged_b = false;
CDSource.anyChange_b = false;

function CDSource:Inherit()
    -- Get a copy of its parents
    local obj = CDBaseClass:Inherit();

    -- Add its own dna
    obj = CDTools:TableConcat(obj, CDTools:DeepCopy(self));
    -- Update its types
    obj._types[self] = true;
    return obj;
end

function CDSource:New(recipe, baseSource)
    self = self:Inherit();
    self.baseSource = baseSource;
    self.recipe = recipe;
    -- Originally this was stored on the items rather than the source? why??
    self.requiredCount_i = baseSource:getCount();

    self.items_ar = {};
    for k = 0, baseSource:getItems():size() - 1 do
        local fullType = baseSource:getItems():get(k);
        local item_instance = nil;
        if fullType == "Water" then
            item_instance = recipe:GetItemInstance("Base.WaterDrop");
        elseif luautils.stringStarts(fullType, "[") then  -- Some debug thing.
            item_instance = recipe:GetItemInstance("Base.WristWatch_Right_DigitalBlack");
        else
            item_instance = recipe:GetItemInstance(fullType);
        end

        -- Is this ever false?
        if item_instance then
            local cditem = CDSourceItem:New(recipe, self, item_instance);
            table.insert(self.items_ar, cditem);
        end
    end

    return self;
end

function CDSource:UpdateAvailability(detailed_b)
    self.detailed_b = detailed_b;
    local last_available = self.available_b;
    self.available_b = false;
    self.availableChanged_b = false;
    self.itemsChanged_b = false;
    self.anyChange_b = false;

    for _, item in pairs(self.items_ar) do
        item:UpdateAvailability(detailed_b);
        if item.available then
            self.available_b = true;
        end

        if item.anyChange_b then
            self.itemsChanged_b = true;
            self.anyChange_b = true;
        end
        
        -- Sources are valid if any item is available.
        if item.available_b then
            self.available_b = true;
            -- If not detailed view, don't bother checking any more items.
            if not detailed_b then
                break;
            end
        end
    end

    if last_available ~= self.available_b then
        self.availableChanged_b = true;
        self.anyChange_b = true;
    end
    return;
end