# EraDebuffed
FFXI Windower addon that tracks and displays debuffs on your current target. Filters are available to customise which
debuffs are shown. Modified for compatibility with Era.


## Installation
After downloading, extract to your Windower addons folder. Make sure the folder is called EraDebuffed, rather than
-master or -v1.whatever. Your file structure should look like this:

    addons/EraDebuffed/EraDebuffed.lua

Once the addon is in your Windower addons folder, it won't show up in the Windower launcher. You need to load it
manually or add a line to your `scripts/init.txt`:

    lua load EraDebuffed


## Commands
You can either use `//debuffed` or `//dbf`. There are many other abbreviations available as well.
`<text>` means user choice. Do not actually write `<` and `>`.

#### mode

    //debuffed mode
    //dbf m

This will switch between blacklist and whitelist mode for debuff filtering.

#### timers

    //debuffed timers
    //dbf t

This toggles the display of timers for debuffs.

#### interval \<seconds\>

    //debuffed interval <seconds>
    //dbf i <seconds>
    //dbf i 0.5

This allows you to adjust the refresh interval for the textbox. It will be updated every \<seconds\> number of seconds.

#### hide

    //debuffed hide
    //dbf h

This toggles the automatic removal of effects when their timer reaches zero.

#### whitelist add \<spell_name\>

    //debuffed whitelist add <spell_name>
    //dbf white a <spell_name>
    //dbf wlist + <spell_name>
    //dbf w a <spell_name>
    //dbf w a Dia

This adds the specified spell to the whitelist.

#### whitelist remove \<spell_name\>

    //debuffed whitelist remove <spell_name>
    //dbf white r <spell_name>
    //dbf wlist - <spell_name>
    //dbf w r <spell_name>
    //dbf w r slow

This removes the specified spell from the whitelist.

#### blacklist add \<spell_name\>

    //debuffed blacklist add <spell_name>
    //dbf black a <spell_name>
    //dbf blist + <spell_name>
    //dbf b a <spell_name>
    //dbf b a paralyze

This adds the specified spell to the blacklist.

#### blacklist remove \<spell_name\>

    //debuffed blacklist remove <spell_name>
    //dbf black r <spell_name>
    //dbf blist - <spell_name>
    //dbf b r <spell_name>
    //dbf b r Poison

This removes the specified spell from the blacklist.
