--- This is used to add a tab to a ISTabPanel,
---   without putting any functionality in that tab.
--- As the crafting UI is the same between each tab,
---   controlling it all from CraftingUI makes the logic cleaner.

require "Classes/CDDummyView"

CDDummyView = ISPanelJoypad:derive("CDDummyView");
CDDummyView.instance = nil;
CDDummyView.category = "";
CDDummyView.parent = nil;

function CDDummyView:initialise()
    ISPanelJoypad.initialise(self);
end

function CDDummyView:update()
    if not self.parent:getIsVisible() then return; end
end

function CDDummyView:new(name_str, parent)
    local o = {};
    o = ISPanelJoypad:new(0, 0, 0, 0);
    setmetatable(o, self);
    CDDummyView.instance = o;
    -- TODO: Change these to o?
    self.__index = self;
    self:noBackground();
    self.category = name_str;
    self.parent = parent;
    
    return o;
end
