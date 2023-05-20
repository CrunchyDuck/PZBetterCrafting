CDTools = {}

function CDTools:ShallowCopy(t)
    local t2 = {};
    for k,v in pairs(t) do
        t2[k] = v;
    end
    return t2;
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