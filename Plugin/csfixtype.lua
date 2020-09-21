csfixtype = {}
csfixtype.VERSION = {major = 1, minor = 0, patch = 0, str = "1.0.0"}

local pooltools = require 'pooltools'
local x_cache

local function get_files(path, op_sys)
    --[[
        Searches for existing fixture type files and import their names into the table file_names,
        which is returned at the end.
        Parameters: path (str), op_sys(str)
        Return value: file_names (table)
    ]]
    local file_names = {}
    local list_cmd = ""
    if op_sys == "WINDOWS" then
        list_cmd = 'dir /B "'..path..'" | findstr /i "csfixtype.*.xml"'
    else
        list_cmd = 'ls "'..path..'" | grep "csfixtype.*.xml"'
    end
    local file_list = io.popen(list_cmd)
    local files = file_list:lines()
    for file in files do
        table.insert(file_names, file)
    end
    return file_names
end

local function name_to_vers(name)
    --[[
        Takes the filename as a parameter (str) and returns a table containing the major, minor and patch
        version.
    ]]
    local version_pos = name:find("v") + 1
    local version_str = name:sub(version_pos)
    local get_subversion = version_str:gmatch("%d")
    local version = {
        major = tonumber(get_subversion()),
        minor = tonumber(get_subversion()),
        patch = tonumber(get_subversion())
    }
    return version
end

local function is_deprecated(fname)
    --[[
        Returns true if the filename passed as a parameter (str), indicates a fixture type
        version that is not up to date. Returns false otherwise.
    ]]
    local file_vers = name_to_vers(fname)
    if file_vers.major < csfixtype.VERSION.major then
        return true
    elseif file_vers.minor < csfixtype.VERSION.minor then
        return true
    elseif file_vers.patch < csfixtype.VERSION.patch then
        return true
    end
    return false
end

local function delete_deprecated(path, op_sys)
    --[[
        Checks the library for deprecated CSF fixture types and deletes them.
        Parameter: path (to the library; str), op_sys (str)
        Returns nil.
    ]]
    local deleted_files_count = 0
    local files = get_files(path, op_sys)
    for _, file in pairs(files) do
        if is_deprecated(file) then
            os.remove(path..'/'..file)
            deleted_files_count = deleted_files_count + 1
        end
    end
    gma.echo(deleted_files_count..' deprecated fixturetypes deleted.')
end

local function calc_x(step_size)
    --[[
        Calculates the X coordinates for the DMX profile points.
        Parameters: step_size (number)
        Return value: t (table)
    ]]
    local a = x_cache or 0
    local b = (a*10 + 0.001)/10 -- multiply and divide by 10 to get more precise results!
    local c = a + step_size
    local d = (c*10 + 0.001)/10
    x_cache = c
    local t = {x0 = a, x1 = b, x2 = c, x3 = d}
    return t
end

local function create_fixtype(file, number_of_steps)
    --[[
        Creates a grandMA2 fixture type as an XML file depending on the given parameters.
        Parameters: file (file obj), number_of_steps (number)
        Returns nil.
    ]]
    local profile_index = pooltools.getFreeObj('Profile', 1, number_of_steps+1)
    local step_size = 1 / number_of_steps
    local points = {}
    local vers = table.concat(csfixtype.VERSION, ".")
    io.output(file)
    io.write(string.format(
        '<?xml version="1.0" encoding="utf-8"?>\n'..
        '<MA xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://schemas.malighting.de/grandma2/xml/MA" xsi:schemaLocation="http://schemas.malighting.de/grandma2/xml/MA http://schemas.malighting.de/grandma2/xml/3.7.0/MA.xsd" major_vers="3" minor_vers="7" stream_vers="0">\n'..
	    '\t<Info datetime="2019-11-26T13:18:25" showfile="" />\n'..
	    '\t<FixtureType name="CueStep Fader" mode="%i steps">\n'..
		'\t\t<short_name>CSF</short_name>\n'..
		'\t\t<manufacturer>JonasKochMarkHuber</manufacturer>\n'..
        '\t\t<short_manufacturer>JKMH</short_manufacturer>\n'..
        '\t\t<revision date="10.09.2020" text="Version %s" generator_software_name="CueStep Fader" generator_software_version="%s" />\n'..
		'\t\t<Profiles>', number_of_steps, vers, vers
    ))
    -- Generator start
    io.write(string.format('\n'..
        '\t\t\t<DMX_Profile index="%i" name="CSF_Profile 0/%i_%s" display_spec_index="1">\n'..
        '\t\t\t\t<DMX_Profile_Point index="0" y="1" mode="linear" />\n'..
        '\t\t\t\t<DMX_Profile_Point index="1" x="0.01" y="1" mode="linear" />\n'..
        '\t\t\t\t<DMX_Profile_Point index="2" x="0.0101" mode="linear" />\n'..
        '\t\t\t</DMX_Profile>\n',
    profile_index, number_of_steps, vers))
    x_cache = 0.01
    for i=profile_index+1, profile_index + number_of_steps-1 do
        points = calc_x(step_size)
        io.write(string.format(
            '\t\t\t<DMX_Profile index="%i" name="CSF_Profile %i/%i_%s" display_spec_index="1">\n'..
            '\t\t\t\t<DMX_Profile_Point index="0" x="%.4f" mode="linear" />\n'..
            '\t\t\t\t<DMX_Profile_Point index="1" x="%.4f" y="1" mode="linear" />\n'..
            '\t\t\t\t<DMX_Profile_Point index="2" x="%.4f" y="1" mode="linear" />\n'..
            '\t\t\t\t<DMX_Profile_Point index="3" x="%.4f" mode="linear" />\n'..
            '\t\t\t</DMX_Profile>\n',
        i, i-profile_index, number_of_steps, vers, points.x0, points.x1, points.x2, points.x3))
    end
    points = calc_x(step_size-0.01)
    io.write(string.format(
        '\t\t\t<DMX_Profile index="%i" name="CSF_Profile %i/%i_%s" display_spec_index="1">\n'..
        '\t\t\t\t<DMX_Profile_Point index="0" x="%.4f" mode="linear" />\n'..
        '\t\t\t\t<DMX_Profile_Point index="1" x="%.4f" y="1" mode="linear" />\n'..
        '\t\t\t\t<DMX_Profile_Point index="2" x="1" y="1" mode="linear" />\n'..
        '\t\t\t</DMX_Profile>\n',
    profile_index + number_of_steps, number_of_steps, number_of_steps, vers, points.x0, points.x1))
    -- Generator end
    io.write(
        '\t\t</Profiles>\n'..
		'\t\t<Modules index="0">\n'..
		'\t\t\t<Module index="0" class="None" beamtype="Wash" beam_angle="35" beam_intensity="10000">\n'..
		'\t\t\t\t<ChannelType index="0" attribute="DIM" feature="DIMMER" preset="DIMMER">\n'..
		'\t\t\t\t\t<ChannelFunction index="0" from="0" to="100" min_dmx_24="0" max_dmx_24="16777215" physfrom="0" physto="1" subattribute="DIM" subattribute_user_name="Dim" attribute="DIM" attribute_user_name="Dim" feature="DIMMER" feature_user_name="Dimmer" preset="DIMMER" preset_user_name="Dimmer" />\n'..
		'\t\t\t\t</ChannelType>\n'
    )
    -- Generator start
    local j = profile_index
    for i=1, number_of_steps+1 do
        io.write(string.format(
            '\t\t\t\t<ChannelType index="%i" attribute="UNKNOWN" feature="CONTROL" preset="CONTROL" coarse="%i" default="254.999" fade_path="%i" react_to_dim="1">\n'..
			'\t\t\t\t\t<ChannelFunction index="0" from="0" to="100" min_dmx_24="0" max_dmx_24="16777215" subattribute="UNKNOWN" subattribute_user_name="Unknown" attribute="UNKNOWN" attribute_user_name="Dummy" feature="CONTROL" feature_user_name="Control" preset="CONTROL" preset_user_name="Control" />\n'..
			'\t\t\t\t</ChannelType>\n',
        i, i, j))
        j = j + 1
    end
    -- Generator end
    io.write(
        '\t\t\t</Module>\n'..
        '\t\t</Modules>\n'..
        '\t\t<Instances index="1">\n'..
        '\t\t\t<Instance index="0" module_index="0" />\n'..
        '\t\t</Instances>\n'..
        '\t\t<Wheels index="2" />\n'..
        '\t\t<VirtualFunctionBlocks index="3" />\n'..
        '\t\t<FixtureMacroCollect index="5" />\n'..
        '\t\t<Body />\n'..
        '\t\t<AutoPresets index="4" />\n'..
        '\t\t<RdmNotifications index="6">\n'..
        '\t\t\t<RdmNotification index="0" Type="Absent" Subcategory="RDM Warning" />\n'..
        '\t\t</RdmNotifications>\n'..
        '\t</FixtureType>\n'.. 
        '</MA>'
    )
    file:close()
    gma.echo('CSFixtype created.')
end

function csfixtype.manage(path, num_of_steps, op_sys)
    --[[
        Triggers the deletion of deprecated fixture type files and creates a new fixture type file
        in case there doesn't already exist a matching file.
    ]]
    delete_deprecated(path, op_sys)
    local fname = string.format('csfixtype-%i--v%s.xml', num_of_steps, csfixtype.VERSION.str)
    local file = io.open(path..'/'..fname, 'r')
    if file then
        file:close()
    else
        file = io.open(path..'/'..fname, 'w')
        create_fixtype(file, num_of_steps)
    end
end

return csfixtype