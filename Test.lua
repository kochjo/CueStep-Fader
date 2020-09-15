-- This file is for automatically testing and logging CueStep Fader.
-- 0.1.2

Test = {} -- module table to be returned
local cmd = function(syntax, ...) gma.cmd(syntax:format(...)) end
local LOGFILE = io.open("Test.log", "w+")
io.output(LOGFILE)
io.write(
    '-- Values to be tested for every input: --\n',
    'emtpy string\n',
    '0\n',
    '1\n',
    '10\n',
    '100\n',
    '200\n',
    '1.5\n',
    'a\n',
    'bla \\ bla\n',
    '"test" tada\n\n',
    '---------------------------------------\n\n'
)

local function log(varname, var, ...)
    --[[
        Writes logging / debugging infos to LOGFILE.
    ]]
    if varname ~= nil then
        io.write(varname..": "..(var or "").."| ", ... or "", "\n")
    else
        io.write(..., "\n")
    end
    io.flush()
end

local function all_tested()
    --[[
        Checks if all listed inputs have been tested and returns true if this is the case.
        Otherwise it returns false.
    ]]
    log("steps.num_of_tested", Test.steps.num_of_tested)
    log("execnum.num_of_tested", Test.execnum.num_of_tested)
    log("name.num_of_tested", Test.name.num_of_tested)
    if Test.steps.num_of_tested < #Test.steps.inputs then
        return false
    end
    if Test.execnum.num_of_tested < #Test.execnum.inputs then
        return false
    end
    if Test.name.num_of_tested < #Test.name.inputs then
        return false
    end
    return true
end

Test.test = coroutine.create(function()
    --[[
        The main function for the test. It runs CSF repeatedly (with param. 'testmode' set to true)
        until all inputs listed in Test.lua are tested.
    ]]
    local run = 1
    while not all_tested() do
        log("Run", run, 'Not all tested. Next one.')
        cmd('LUA "CSF_main(true)"')
        coroutine.yield() -- wait for the current run of CSF to finish.
        log(nil, nil, "\n Resume yielding loop.")
        run = run+1
    end
    log(nil, nil, "Test completed.")
    LOGFILE:close()
end)

Inputs = {} -- class / metatable
function Inputs:new(name) -- init instance of Inputs
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.name = name
    o.num_of_tested = 0
    o.inputs = {
        { val = '', tested = false },
        { val = '0', tested = false },
        { val = '1', tested = false },
        { val = '10', tested = false },
        { val = '100', tested = false },
        { val = '200', tested = false },
        { val = '1.5', tested = false },
        { val = 'a', tested = false },
        { val = 'bla \\ bla', tested = false },
        { val = '\"test\" tada', tested = false },
    }

    function o:get_new_val()
    --[[
        Returns the first untested value.
        If all values have already been tested, it returns "2" as it's an valid input in anycase.
    ]]
        for _, input in ipairs(self.inputs) do
            if not input.tested then
                input.tested = true
                self.num_of_tested = self.num_of_tested + 1
                log("new_val", input.val, 'for '..self.name)
                return input.val
            end
        end
        log(nil, nil,"All values for "..self.name.." tested. Return '2'")
        return "2"
    end
    return o
end

Test.steps = Inputs:new("steps")
Test.execnum = Inputs:new("execnum")
Test.name = Inputs:new("name")

return Test