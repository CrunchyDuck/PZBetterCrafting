--- Also known as a growing list of ways Lua is an anemic language.
CDTools = {}

function CDTools:ShallowCopy(t)
    local t2 = {};
    for k,v in pairs(t) do
        t2[k] = v;
    end
    return t2;
end


function CDTools:DeepCopy(t)
    local ret = {}
    if type(t) == "table" then
        for k, v in pairs(t) do
            ret[k] = CDTools:DeepCopy(v);
        end
    else
        ret = t;
    end

    return ret;
end

-- Taken from: https://www.programming-idioms.org/idiom/10/shuffle-a-list/2019/lua
function CDTools:FisherYatesShuffle(x)
    for i = #x, 2, -1 do
        local j = ZombRand(i);
        x[i], x[j] = x[j], x[i];
    end
end

function CDTools:TableContains(table, item, comparison_func)
    if comparison_func == nil then
        comparison_func = function(a, b) 
            return a == b;
        end
    end

    for index, value in pairs(table) do
        if comparison_func(value, item) then
            return index;
        end
    end
    return -1;
end

-- Taken from: https://stackoverflow.com/questions/1410862/concatenation-of-tables-in-lua
function CDTools:ListConcat(t1, t2)
    -- Avoids us writing to t1
    local l = CDTools:ShallowCopy(t1);
    for i = 1, #t2 do
        l[#l + 1] = t2[i];
    end
    return l;
end

function CDTools:TableConcat(t1, t2)
    local t = CDTools:ShallowCopy(t1);
    for k, v in pairs(t2) do
        t[k] = v;
    end
    return t;
end

-- AHAHAHAHHAHAHAHAHAHAHAHH
-- THER'ES ONO BULT IN WAY TO COUNT NUM ENTRIES IN DICTIONRARY IN LUA
-- HAHAAHHAHASDADSHDSADSAHDDS
function CDTools:CountTable(tab)
    local i = 0;
    for _, _ in pairs(tab) do
        i = i + 1;
    end
    return i;
end

function CDTools:FindGlobal(dot_path_str)
    local result = _G;
    for _, path in pairs(CDTools:SplitString(dot_path_str, ".")) do
        result = result[path];
        if result == nil then
            return nil;
        end
    end
    return result;
end

function CDTools:SplitString(str, split_char)
    local t = {};
    for s in string.gmatch(str, "([^" .. split_char .. "]+)") do
        table.insert(t, s);
    end
    return t
end

-- Will likely need to update this function as my style solidifies.
function CDTools:InheritFrom(class_ar)
    local o = {};
    o._types = {};  -- Used for typing objects.
    for _, obj in pairs(class_ar) do
        o = CDTools:TableConcat(o, CDTools:ShallowCopy(obj));
        table.insert(o._types, obj);
    end
    return o;
end