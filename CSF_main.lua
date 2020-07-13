--[[BETA NOTES:
    To be enhanced for Vers 0.24.3:

    Bugs to fix for Vers. 0.24.3:

    Features to add for Vers. 0.24.3:
    
]]

-- ************************************************
-- CREATED AND DEVELOPED BY JONAS KOCH & MARK HUBER
-- ************************************************
--               Version 0.24.2 (Beta)
-- ************************************************

--********************************************************--
-- *************** Initialize Variables ***************** --
--********************************************************--

local getobj = gma.show.getobj
local getvar = gma.show.getvar
local setvar = gma.show.setvar

if getvar("OS") == "WINDOWS" then
    package.path = package.path..';'..getvar('pluginpath')..'/CueStep Fader/?.lua'
else
    package.path = package.path..';/media/sdb/gma2/plugins/CueStep Fader/?.lua;/media/sdb1/gma2/plugins/CueStep Fader/?.lua;/media/sdb2/gma2/plugins/CueStep Fader/?.lua'
end

local pooltools    = require 'pooltools'
local csfixtype    = require 'csfixtype'

local addr_cache   = tonumber(getvar("CSF_ADDR_CACHE") or 1)
local cmd          = function(syntax, ...) gma.cmd(syntax:format(...)) end
local FTYPEVERS    = 10
local LIB_PATH     = getvar("PATH")..'/library'
local gethandle    = function(syntax, ...) return getobj.handle(syntax:format(...)) end
local num_of_steps
local tryagain     = false -- control flag for user input.
local UNI          = tonumber(getvar("CSF_UNI") or pooltools.getfruni())
local userinfo     = {}

--********************************************************--
-- ********************* START CODE ********************* --
--********************************************************--

local function verify_execnumber(num, heading)
    --[[
        requestes user to specify preferred execnumber. returns that execnumber if it's available resp.
        returns the next free alternative.
    ]]
    local exec
    local page
    repeat
        if tryagain then 
            heading = "Invalid executor number! Try again."
            num = nil
        end
        num = num or gma.textinput(heading, "")
        local border1, border2  = num:find('%.')
        if border1 then
            page = tonumber(num:sub(1, border1-1))
            exec = tonumber(num:sub(border2+1))
        else
            page = tonumber(getvar('Faderpage'))
            exec = tonumber(num)
        end
        tryagain = true
    until page and exec
    tryagain = false
    exec = pooltools.getalt('Executor', page, exec, {1, 15})
    if #tostring(exec) == 1 then exec = '0'..exec end
    local execnum = exec ~= '00' and page..'.'..exec or verify_execnumber(1+page..'.1') --recursively calls verify_execnumber with increasing page numbers until a page with any free executors is found.
    if not gethandle('Page %i', page) then
        for i=tonumber(getvar('Faderpage')), page-1 do
            cmd('page +')
        end
    end
    return execnum
end

local function delete_deprecated(path)
    --[[
        Detects and deletes deprecated fixturetype files
    ]]
    local a = 0
    for i=FTYPEVERS-1, 1, -1 do
        local name    = string.format('csfixtype-%i--v%i.xml', num_of_steps, i)
        local slash   = package.config:sub(1,1)
        path = path..slash..name
        local file    = io.open(path, 'r')
        if file then
            file:close()
            local syntax = getvar('OS') == 'WINDOWS' and 'del "%s"' or 'rm -f %s'
            os.execute(syntax:format(path))
            a = a + 1
        end
    end
    return gma.echo(a..' deprecated fixturetypes deleted.')
end

local function manage_ftype_files(path, fname)
    --[[
        Returns 'true' if the requested file already exists, 
        otherwise it returns 'false' and a writable file object.
    ]]
    delete_deprecated(LIB_PATH)
    local flag = false
    local file = io.open(path..'/'..fname, 'r')
    if file then
        flag = true
        file:close()
    else
        file = io.open(path..'/'..fname, 'w')
    end
    return flag, file
end

local function setup_CSFader(csf_seq, exec, name, fname)
    --[[
        Import and patch the CSFixture and store it to the CSFader.
    ]]
    local ftypename = "CueStep Fader "..num_of_steps.." steps"
    local fix_id    = pooltools.getfrobj('fixture', 10001, 1)
    cmd('cd EditSetup; cd Layers')
    local layerhandle = getobj.handle('CSLayer')
    if not layerhandle then
        cmd('store "CSLayer"')
        layerhandle = getobj.handle('CSLayer')
    end
    local fix = getobj.amount(layerhandle)+1
    cmd('cd CSLayer')
    if not gethandle('Fixturetype "%s"', ftypename) then
        local ftypeno = pooltools.getfrobj('fixturetype', 1, 1)
        cmd('Import "%s" At Fixturetype %i /path="%s"', fname, ftypeno, LIB_PATH)
    end
    cmd('store %i; assign FixtureType "%s" at %i', fix, ftypename, fix)
    cmd('Assign %i /name="CSFixture"; assign %i /fixid=%i; assign %i /patch="%i.%i"; assign %i /ReactToMaster="Off"',
        fix, fix, fix_id, fix, UNI, addr_cache, fix)
    cmd('cd /')
    cmd('Fixture %i at 100; store seq %i "%s CSF"', fix_id, csf_seq, name)
    cmd('assign seq %i at exec %s', csf_seq, exec)
    cmd('assign exec %s /SwopProtect="On"', exec)
    cmd('clearall')
    addr_cache = addr_cache + num_of_steps+1 -- Footprint is +1, because of the "CSF_OFF" step
    setvar("CSF_ADDR_CACHE", addr_cache)
end

local function create_CSContainer(seq, exec, name)
    --[[
        Create an executor containing the steps as cues
    ]]
    exec, subs     = verify_execnumber(exec:gsub('%.', '.1'))
    userinfo.csc   = seq
    cmd('store seq %i Cue 1 thru %i "Step 1"', seq, num_of_steps)
    cmd('label seq %i "CSC_%s"', seq, name)
    cmd('assign seq "CSC_%s" at exec %s', name, exec) 
end

local function setup_remotes(name, csc_seq)
    --[[
        Create the desired DMX remotes.
    ]]
    local remote      = pooltools.getfrobj('remote 3.', 1, num_of_steps+1)
    local last_remote = remote + num_of_steps
    local j = 1
    cmd('store remote 3.%i thru 3.%i', remote, last_remote)
    cmd('assign remote 3.%i thru 3.%i /Type="CMD"', remote, last_remote)
    for i = remote, last_remote do
        if j == 1 then
            cmd('assign remote 3.%i /name="CSF Off" /CMD="off executor *.CSC_%s" /DMX="%i.%i"', i, name, UNI, j)
        else
            cmd('assign remote 3.%i /name="CSF %i" /CMD="goto executor *.CSC_%s cue %i" /DMX="%i.%i"', i, j-1, name, j-1, UNI, j)
        end
        j = j + 1
    end
end

local function print_user_infos()
    --[[
        Informs the user if the plugin was run successfully and if so,
        it prints the location of the CSF-Executor and it's corresponding cue container into a message box.
    ]]
    gma.echo("\n CueStep Fader successfully accomplished. \n \n ************************************ \n created by Jonas Koch and Mark Huber \n ************************************")
    gma.feedback("\n You can find \n - The CSF-Executor at "..userinfo.exec..". \n - The 'cue container' at sequence "..userinfo.csc..".")
    gma.gui.msgbox("INFO","You can find \n - The CSF-Executor at "..userinfo.exec..". \n - The 'cue container' at sequence "..userinfo.csc..".")
end

local function main()
    --[[
        Requests user input for the number of steps and the CSF-name
        and executes all necessary functions in order.
    ]]
    local heading = "How many Steps"
    repeat
        if tryagain then 
            heading = "Number of Steps has to be a natural number."
        end
        num_of_steps = tonumber(gma.textinput(heading, ""))
        tryagain = true
    until num_of_steps and num_of_steps == math.floor(num_of_steps) and num_of_steps > 0
    tryagain = false
    local csfexec = verify_execnumber(nil, "Enter executor number. (e.g 1.1)")
    local csfname
    heading = "Enter a name for the CSF."
    repeat
        if tryagain then
            heading = "Name is invalid or already in use."
        end
        csfname = gma.textinput(heading, "")
        tryagain = true
    until csfname and not getobj.handle("executor *.CSC_"..csfname)
    tryagain = false
    local fname       = string.format('csfixtype-%i--v%i.xml', num_of_steps, FTYPEVERS)
    local found, file = manage_ftype_files(LIB_PATH, fname)
    local csf_seq     = pooltools.getfrobj('sequence', 101, 1)
    local csc_seq     = pooltools.getfrobj('sequence', csf_seq+1, 1)
    userinfo.exec     = csfexec
    if not getvar('CSF_UNI') then setvar("CSF_UNI", UNI) end
    if not found then csfixtype.create(file, num_of_steps, FTYPEVERS) end
    setup_CSFader(csf_seq, csfexec, csfname, fname)
    create_CSContainer(csc_seq, csfexec, csfname)
    setup_remotes(csfname, csc_seq)
    print_user_infos()
end

return main