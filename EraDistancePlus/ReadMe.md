# EraDistancePlus
FFXI Windower addon that displays color-coded distance to your target. Modified from Sammeh's addon for compatibility with Era.

## Installation
After downloading, extract to your Windower addons folder. Make sure the folder is called EraDistancePlus, rather than -master or -v1.whatever. Your file structure should look like this:

    addons/EraDistancePlus/EraDistancePlus.lua

Once the addon is in your Windower addons folder, it won't show up in the Windower launcher. You need to add a line to your `scripts/init.txt`:

    lua load EraDistancePlus

## Commands

    //dp help - Shows help
    //dp MaxDecimal - Extends decimal out 12 points - really only useful for debugging.
    //dp height - Shows a height delta  - Green - Can avoid AOE's, Red - danger of being hit by AOE
    //dp Magic - Sets defaults for magic casting
    //dp Gun|Bow|Xbow - sets defaults for shooting
    //dp ja - Shows a Job ability list and correlates distance/color for them.
