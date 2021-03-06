-- ************************************************
-- CREATED AND DEVELOPED BY JONAS KOCH & MARK HUBER
-- ************************************************
--               Version 0.27.0 (Beta)
-- ************************************************

--********************************************************--
-- *************** Initialize Variables ***************** --
--********************************************************--

local getobj = gma.show.getobj
local getvar = gma.show.getvar
local setvar = gma.show.setvar

local OS = getvar('OS')
if OS == "WINDOWS" then -- Configure Lua's native 'package.path' variable to ensure that the machine finds all necessary modules.
    local module_path = getvar('pluginpath')..'/CueStep Fader'
    package.path = package.path..';'..
    module_path..'/Plugin/?.lua;'..
    module_path..'/?.lua'
else
    local module_path = "/media/%s/gma2/plugins/CueStep Fader"
    package.path = package.path..';'..
    module_path:format('sdb')..'/?.lua;'..
    module_path:format('sdb')..'/Plugin/?.lua;'..
    module_path:format('sdb1')..'/?.lua;'..
    module_path:format('sdb1')..'/Plugin/?.lua;'..
    module_path:format('sdb2')..'/?.lua;'..
    module_path:format('sdb2')..'/Plugin/?.lua;'
end

local csfixtype = require 'csfixtype'
local pooltools = require 'pooltools'
local REQ_SUCCESS, Test = pcall(function() return require 'Test' end)
--^ Prevent the plugin from crashing if "Test.lua" is not available as it is not necessary for it to run.

local cmd = function(syntax, ...) gma.cmd(syntax:format(...)) end
local gethandle = function(syntax, ...) return getobj.handle(syntax:format(...)) end

local DMX_ADDR
local LIB_PATH = getvar("PATH")..'/library'
local NUM_OF_STEPS
local TESTMODE = false -- Is set by calling the main function with 'true' as argument.
local UNI
local userinfo = {}

--********************************************************--
-- ********************* START CODE ********************* --
--********************************************************--

local function get_dmx_address()
    --[[
        Determines the DMX universe and startaddress for the CSF.
        Returns both as separate values of type int.
    ]]
    local amount_of_channels
    local uni = getvar('CSF_UNI')
    local addr = tonumber(getvar("CSF_ADDR_CACHE") or 1)
    if uni then
        uni = tonumber(uni)
        amount_of_channels = NUM_OF_STEPS
    end
    uni = pooltools.getUni(uni, nil, amount_of_channels)
    setvar('CSF_UNI', uni)
    return uni, addr
end

local function verify_execnumber(num, heading)
    --[[
        Requests user to specify preferred execnumber. returns that execnumber if it's available resp.
        returns the next free alternative.
    ]]
    local exec
    local page
    repeat
        num = num or (TESTMODE and Test.execnum:get_new_val() or gma.textinput(heading, ""))
        local border1, border2  = num:find('%.')
        if border1 then
            page = tonumber(num:sub(1, border1-1))
            exec = tonumber(num:sub(border2+1))
        else
            page = tonumber(getvar('Faderpage'))
            exec = tonumber(num)
        end
        heading = "Invalid executor number! Try again."
        num = nil
    until page and exec
    exec = pooltools.getAlt('Executor', page, exec, {1, 15})
    if #tostring(exec) == 1 then exec = '0'..exec end
    local execnum = exec ~= '00' and page..'.'..exec or verify_execnumber(1+page..'.1') 
    --recursively calls verify_execnumber with increasing page numbers until a page with any free executors is found.
    if not gethandle('Page %i', page) then
        for i=tonumber(getvar('Faderpage')), page-1 do
            cmd('page +')
        end
    end
    return execnum
end

local function setup_CSFader(csf_seq, exec, name)
    --[[
        Import and patch the CSFixture and store it to the CSFader.
    ]]
    local dmx_addr = DMX_ADDR
    local ftypename = "CueStep Fader "..NUM_OF_STEPS.." steps"
    local fix_id = pooltools.getFreeObj('fixture', 10001, 1)
    cmd('cd EditSetup; cd Layers')
    local layerhandle = getobj.handle('CSLayer')
    if not layerhandle then
        cmd('store "CSLayer"')
        layerhandle = getobj.handle('CSLayer')
    end
    local fix = getobj.amount(layerhandle)+1
    cmd('cd CSLayer')
    if not gethandle('Fixturetype "%s"', ftypename) then
        local fname = string.format('csfixtype-%i--v%s.xml', NUM_OF_STEPS, csfixtype.VERSION.str)
        local ftypeno = pooltools.getFreeObj('fixturetype', 1, 1)
        cmd('Import "%s" At Fixturetype %i /path="%s"', fname, ftypeno, LIB_PATH)
    end
    cmd('store %i; assign FixtureType "%s" at %i', fix, ftypename, fix)
    cmd('Assign %i /name="CSFixture"; assign %i /fixid=%i; assign %i /patch="%i.%i"; assign %i /ReactToMaster="Off"',
        fix, fix, fix_id, fix, UNI, dmx_addr, fix)
    cmd('cd /')
    cmd('Fixture %i at 100; store seq %i "%s CSF"', fix_id, csf_seq, name)
    cmd('assign seq %i at exec %s', csf_seq, exec)
    cmd('assign exec %s /SwopProtect="On"', exec)
    cmd('clearall')
    dmx_addr = dmx_addr + NUM_OF_STEPS+1 -- Footprint is +1, because of the "CSF_OFF" step
    setvar("CSF_ADDR_CACHE", dmx_addr)
end

local function create_CSContainer(seq, exec, name)
    --[[
        Create an executor containing the steps as cues
    ]]
    exec = verify_execnumber(exec:gsub('%.', '.1'))
    userinfo.csc = seq
    cmd('store seq %i Cue 1 thru %i "Step 1"', seq, NUM_OF_STEPS)
    cmd('label seq %i "CSC_%s"', seq, name)
    cmd('assign seq "CSC_%s" at exec %s', name, exec) 
end

local function setup_remotes(name)
    --[[
        Create the desired DMX remotes.
    ]]
    local remote = pooltools.getFreeObj('remote 3.', 1, NUM_OF_STEPS+1)
    local last_remote = remote + NUM_OF_STEPS
    local dmx_addr = DMX_ADDR
    local step = 0
    cmd('store remote 3.%i thru 3.%i', remote, last_remote)
    cmd('assign remote 3.%i thru 3.%i /Type="CMD"', remote, last_remote)
    for i = remote, last_remote do
        if i == remote then
            cmd('assign remote 3.%i /name="CSF Off" /CMD="off executor *.CSC_%s" /DMX="%i.%i"', i, name, UNI, dmx_addr)
        else
            cmd('assign remote 3.%i /name="CSF %i" /CMD="goto executor *.CSC_%s cue %i" /DMX="%i.%i"', i, step, name, step, UNI, dmx_addr)
        end
        dmx_addr = dmx_addr + 1
        step = step + 1
    end
end

local function print_user_infos()
    --[[
        Informs the user if the plugin was run successfully and if so,
        it prints the location of the CSF-Executor and it's corresponding cue container into a message box.
    ]]
    gma.echo([[CueStep Fader successfully accomplished.
            ************************************
            created by Jonas Koch and Mark Huber
            ************************************]])
    gma.feedback("\n You can find \n - The CSF-Executor at "..userinfo.exec..". \n - The 'cue container' at sequence "..userinfo.csc..".")
    if not TESTMODE then
        gma.gui.msgbox("INFO","You can find \n - The CSF-Executor at "..userinfo.exec..". \n - The 'cue container' at sequence "..userinfo.csc..".")
    end
end

local function validate_steps_input(input)
    --[[
        Checks wether the given parameter input is a natural number less then 100.
        Returns boolean.
    ]]
    if type(input) ~= "number" then return false end
    local is_valid = false
    if input == math.floor(input) and input > 0 and input <= 100 then
        is_valid = true
    end
    return is_valid
end

local function validate_name_input(input)
    --[[
        Checks wether the given parameter input is a legal executorname.
        Returns boolean.
    ]]
    if not input then return false end
    local is_valid = false
    local has_dot = input:match("%.")
    if not has_dot and not getobj.handle("executor *.CSC_"..input) then
        is_valid = true
    end
    return is_valid
end

function CSF_main(testmode)
    --[[
        Requests user input for the number of steps and the CSF-name
        and executes all necessary functions in order.
    ]]
    if testmode and REQ_SUCCESS then
        TESTMODE = true
    elseif not REQ_SUCCESS then
        gma.echo('CSF plugin: Test script not found. Thus test mode is not available.')
    end
    local csfname
    local heading = "How many steps?"
    repeat
        NUM_OF_STEPS = TESTMODE and Test.steps:get_new_val() or gma.textinput(heading, "")
        NUM_OF_STEPS = tonumber(NUM_OF_STEPS)
        heading = "Number of Steps has to be a natural number."
    until validate_steps_input(NUM_OF_STEPS)
    local csfexec = verify_execnumber(nil, "Enter executor number. (e.g 1.1)")
    heading = "Enter a name for the CSF."
    repeat
        csfname = TESTMODE and Test.name:get_new_val() or gma.textinput(heading, "")
        heading = "Name is invalid or already in use."
    until validate_name_input(csfname)
    local csf_seq = pooltools.getFreeObj('sequence', 101, 1)
    local csc_seq = pooltools.getFreeObj('sequence', csf_seq+1, 1)
    UNI, DMX_ADDR = get_dmx_address()
    userinfo.exec = csfexec
    csfixtype.manage(LIB_PATH, NUM_OF_STEPS, OS)
    setup_CSFader(csf_seq, csfexec, csfname)
    create_CSContainer(csc_seq, csfexec, csfname)
    setup_remotes(csfname)
    print_user_infos()
    if TESTMODE then coroutine.resume(Test.test); gma.echo("resumed") end
end

return CSF_main