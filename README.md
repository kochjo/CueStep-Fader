# CueStep Fader

## Disclaimer
__ATTENTION!__
You are using this plugin at your own risk!
Even though there have been no critical bugs reported until now, the creator of this plugin under no circumstances assumes responsibility for damaged, destroyed or in any way negatively influenced show files or damaged or destroyed content or parts of a show file.
Please always do a backup on an external USB-Stick BEFORE running this plugin.
DO NOT RUN THIS PLUGIN IN ANY SHOW-CRITICAL SITUATIONS!


## Table of contents
* [What is CueStep Fader?](#what-is-cuestep-fader?)
* [How to use it](#how-to-use-it)
* [Installation guide](#installation-guide)
* [Developer infos](#developer-infos)
* [Technology](#technology)


## What is CueStep Fader?
CueStep Fader is a Lua plugin for GrandMA2 lighting consoles and its goal is to make cue-step fader usable for everyone!
With CSF you can trigger specific cues in a sequence depending on the faderposition. For example if you have a 10 channel sunstrip and want to control how many lamps are glowing by moving the fader up and down. And the best: It doesn't require any in-depth knowlege of the console and sets up everything in seconds and nearly completely automatically!


## How to use it
CueStep Fader is very simple to use. Once it is installed (see installation guide below), you can either click on the plugin in the plugin pool window or type 'Plugin "CueStep Fader"' into the command line, to start it.
1. Enter the amount of steps you need, as an integer. Mind, that the maximum number is steps is currently limited to 100 for technical reasons.
2. Enter your preferred executor number by using either the format PAGE.EXECUTOR or EXECUTOR (for using the current page).
3. Enter a name for your CSF. The name must not contain dots but _can_ be empty - however this is not recommended in terms of later identification.


## Installation guide
Please follow these Steps for the installation of CSF:
1. Move the required files to the right directory.<br> 
   1.1 For onPC: Copy the folder named 'CueStep Fader' into: C:\Program Data\MA Lighting Technologies\grandma\gma2_V_X\plugins.<br>
   1.2 For Console: Copy the folder 'CueStep Fader' to a USB-Stick at: „STICK NAME"\gma2\plugins.
   _Important(for both cases): The folder HAS to be labeled as 'CueStep Fader'. Otherwise the Plugin won't run!_
2. Open GrandMA2 onPC / start console.
3. Open a PLUGIN-Pool. You can find it under „System".
4. Right-click on a free plugin-field.
5. Click at "import", navigate to 'CueStep Fader/Plugin' and choose „CSP2.xml"
6. Close the window.

## Developer infos
### General informations
Plugin versions are based on "Semantic Versioning 2.0.0". Visit [semver.org](https://semver.org) for more informations.

### Automated testings
To test the plugin automatically with the Test.lua script, import the plugin as described above. But instead of running the plugin directly type<br>
    ```LUA 'CSF_main(true)'```<br>
into the commandline, as it runs CSF in test mode.<br>
A Test.log file is created under /ProgramData/MA Lighting Technologies/grandma/gma2_V_X.X.<br>

## Technology
* Lua 
* XML
