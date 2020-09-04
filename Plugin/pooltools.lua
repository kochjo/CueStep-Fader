-- V 2.0.0

local pooltools = {}
local gethandle = gma.show.getobj.handle

function pooltools.getFreeObj(target, start, amount)
    --[[
        Searches for 'amount' consecutive free pool slots of a specific pool type ('target') starting at slot number 'start'.
        Returns the number of the first suitable slot. 'momode' prints the result in the system monitor.
    ]]--
    local free_slots = 0
    while true do
        local firsttarget = target..' '..start
        local handle      = gethandle(firsttarget)
        if not handle then
            for i = start, start+amount-1 do
                local multitarget = target..' '..i
                local multihandle = gethandle(multitarget)
                if not multihandle then
                    free_slots = free_slots + 1
                else
                    free_slots = 0
                    break
                end
                if free_slots >= amount then return start end
            end
        end
        start = start+1
    end
end

function pooltools.getUni(start_uni, start_addr, amount)
    --[[
        Returns the first matching universe while all parameters are optional.
        start_uni: The universe at which the search should start. Is set to 1 if parameter is nil.
        start_addr: The DMX address at which the search at start_uni should start.
                    Is set to 1 if:
                        - parameter is nil
                        - start_uni has not enough consecutive free DMX addresses, so start_uni is counted up.
        amount: The amount of required consecutive free DMX addresses. Is set to 512 if parameter is nil.
    ]]
    local getprop = gma.show.property.get
    start_uni = start_uni or 1
    start_addr = start_addr or 1
    amount = amount or 512
    local end_uni = 255
    local critical_addr = 512 - amount
    for uni=start_uni, end_uni do
        local target = 'DMX '..uni..'.'
        local free_addr = 0
        for addr=start_addr, 512 do
            local handle = gethandle(target..addr)
            local name = getprop(handle, 1)
            if name == "" then
                free_addr = free_addr + 1
            else
                free_addr = 0
            end
            if free_addr >= amount then return uni end
            if addr > critical_addr and free_addr == 0 then break end
        end
        start_addr = 1
    end
end

function pooltools.getAlt(target, layer, index, range) -- range must be a table! E.g. range = {1, 15}
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