csfixtype = {}

local pooltools = require 'pooltools'
local x_cache

local function calc_x(step_size)
    local a = x_cache or 0
    local b = (a*10 + 0.0001*10)/10 -- multiply and divide by 10 to get more precise results! (Prog. languages have problems with precise float values.)
    local c = a + step_size
    local d = (c*10 + 0.0001*10)/10
    x_cache = c
    local t = {x0 = a, x1 = b, x2 = c, x3 = d}
    return t
end

function csfixtype.create(file, number_of_steps, vers)
    local profile_index = pooltools.getfrobj('Profile', 1, number_of_steps+1)
    local step_size = 1 / number_of_steps
    io.output(file)
    io.write(string.format(
        '<?xml version="1.0" encoding="utf-8"?>\n'..
        '<MA xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://schemas.malighting.de/grandma2/xml/MA" xsi:schemaLocation="http://schemas.malighting.de/grandma2/xml/MA http://schemas.malighting.de/grandma2/xml/3.7.0/MA.xsd" major_vers="3" minor_vers="7" stream_vers="0">\n'..
	    '\t<Info datetime="2019-11-26T13:18:25" showfile="" />\n'..
	    '\t<FixtureType name="CueStep Fader" mode="%i steps">\n'..
		'\t\t<short_name>CSF</short_name>\n'..
		'\t\t<manufacturer>JonasKochMarkHuber</manufacturer>\n'..
        '\t\t<short_manufacturer>JKMH</short_manufacturer>\n'..
        '\t\t<revision date="03.02.2020" text="Version %i" generator_software_name="CueStep Fader" generator_software_version="0.19" />\n'..
		'\t\t<Profiles>', number_of_steps, vers
    ))
    -- Generator start
    io.write(string.format('\n'..
        '\t\t\t<DMX_Profile index="%i" name="CSF_Profile 0/%i_%i" display_spec_index="1">\n'..
        '\t\t\t\t<DMX_Profile_Point index="0" y="1" mode="linear" />\n'..
        '\t\t\t\t<DMX_Profile_Point index="1" x="0.01" y="1" mode="linear" />\n'..
        '\t\t\t\t<DMX_Profile_Point index="2" x="0.0101" mode="linear" />\n'..
        '\t\t\t</DMX_Profile>\n',
    profile_index, number_of_steps, vers))
    x_cache = 0.01
    for i=profile_index+1, profile_index + number_of_steps-1 do
        local points = calc_x(step_size)
        io.write(string.format(
            '\t\t\t<DMX_Profile index="%i" name="CSF_Profile %i/%i_%i" display_spec_index="1">\n'..
            '\t\t\t\t<DMX_Profile_Point index="0" x="%.4f" mode="linear" />\n'..
            '\t\t\t\t<DMX_Profile_Point index="1" x="%.4f" y="1" mode="linear" />\n'..
            '\t\t\t\t<DMX_Profile_Point index="2" x="%.4f" y="1" mode="linear" />\n'..
            '\t\t\t\t<DMX_Profile_Point index="3" x="%.4f" mode="linear" />\n'..
            '\t\t\t</DMX_Profile>\n',
        i, i-profile_index, number_of_steps, vers, points.x0, points.x1, points.x2, points.x3))
    end
    points = calc_x(step_size-0.01)
    io.write(string.format(
        '\t\t\t<DMX_Profile index="%i" name="CSF_Profile %i/%i_%i" display_spec_index="1">\n'..
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
    gma.echo('CSFixtype created!')
end

return csfixtype