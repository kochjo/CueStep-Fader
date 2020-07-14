-- V 1.11

local pooltools = {}
local gethandle = gma.show.getobj.handle

function pooltools.getfrobj(target, start, amount)
    --[[
        Searches for 'amount' consecutive free pool slots of a specific pool type ('target') starting at slot number 'start'.
        Returns the number of the first suitable slot. 'momode' prints the result in the system monitor.
    ]]--
    local a = 0
    while true do
        local firsttarget = target..' '..start
        local handle      = gethandle(firsttarget)
        if not handle then
            for i = start, start+amount-1 do
                local multitarget = target..' '..i
                local multihandle = gethandle(multitarget)
                if not multihandle then
                    a = a + 1
                else
                    a = 0
                    break
                end
                if a >= amount then return start end
            end
        end
        start = start+1
    end
end

function pooltools.getfruni()
    --[[
        Returns the first completely unpatched universe.
    ]]
    local getprop = gma.show.property.get
    local START = 1
    local END = 255

    for i=START, END do
        local target = 'DMX '..i..'.'
        local a = 0
        for j=1, 512 do
            local handle = gethandle(target..j)
            local name = getprop(handle, 1)
            if name == "" then
                a = a + 1
            else
                a = 0
                break
            end
            if a >= 512 then return i end
        end
    end
end

function pooltools.getalt(target, layer, index, range) -- range must be a table! E.g. range = {1, 15}
    --[[
        Returns index of the nearest free pool object within "range" depending on the given index.
        If there's no free pool object within "range", it returns 0.
    ]]
    local alts = {0, 0}
    for i=1, 2 do
        local steps = range[i] > index and 1 or -1
        for j=index, range[i], steps do
            local newtarget = target..' '..layer..'.'..j -- "Target x.y"
            if not gethandle(newtarget) then
                alts[i] = j
                break
            end
        end
    end
    local dist1 = math.abs(index - alts[1])
    local dist2 = math.abs(index - alts[2])
    return dist1 < dist2 and alts[1] or alts[2]
end

return pooltools