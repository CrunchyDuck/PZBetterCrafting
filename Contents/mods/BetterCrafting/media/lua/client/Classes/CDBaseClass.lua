--- Hello person snooping through my code!
--- I figure I should explain the structure I'm using throughout my project.
---
--- If you're used to standard Lua it probably looks pretty weird.
--- My background in code is largely C#, and C# has many nice things.
--- Objects, typing, interfaces, inheritance, etc.
--- A lot of this relies on the idea of a base class. This, this!
---
--- While I do think it makes the code look a little cleaner to implement these,
--- I'm also just doing it because I enjoy doing it.
--- I don't really like working in Lua, so making it more like "home"
--- keeps me motivated.
--- Sorry if it's confusing! I don't really expect anyone else to use it.

CDBaseClass = {};
CDBaseClass._types = {};

--- I'd have liked to just pass an array of types
--- all the way down to this base object, and handle it all in this func,
--- rather than needing this everywhere.
--- But it seems like lua's vargs is kind of garbo.
function CDBaseClass:Inherit()
    -- Get a copy of its parents
    -- CDBaseClass:Inherit(obj);
    -- Add its own dna
    local obj = CDTools:DeepCopy(self);
    -- Update its types
    obj._types = CDTools:TableConcat({self = true}, obj._types);
    return obj;
end

function CDBaseClass:IsType(type)
    return self._types[type] == true;
end