# FastFollow
FFXI Windower addon that allows multiboxers to follow more easily and keep their characters more tightly grouped. ONLY
WORKS WITH MULTIBOXERS. Note that this is NOT the same as `/follow`. You must use `//ffo <name>` or `//ffo me` to start
following.


## Installation
After downloading, extract to your Windower addons folder. Make sure the folder is called FastFollow, rather than
-master or -v1.whatever. Your file structure should look like this:

    addons/FastFollow/FastFollow.lua
    addons/FastFollow/spell_cast_times.lua

Once the addon is in your Windower addons folder, it won't show up in the Windower launcher. You need to load it
manually or add a line to your `scripts/init.txt`:

    lua load FastFollow


## Commands
You can use `//fastfollow` or `//ffo`. Note that `<text>` means user choice. Do not actually write `<` and `>`.
Similarly, `[text]` means that `text` is optional. `text1|text2` means choose one of `text1` *or* `text2`.

#### [follow] \<character_name\>

    //ffo Kaiyra
    //ffo follow Maruru

Will cause the current character to follow the specified character.

#### followme

    //ffo followme
    //ffo me

Cause all other characters to follow this one.

#### stop

    //ffo stop

Make this character stop following.

#### stopall

    //ffo stopall

Stop following on all characters.

#### pauseon \<spells|items|dismount\>

    //ffo pauseon spells
    //ffo pauseon items
    //ffo pauseon dismount

Use auto-pausing to temporarily stop following to cast spells, etc.

#### pausedelay \<delay\>

    //ffo pausedelay 0.2

Choose how long to wait for following to correctly stop before doing the action.

#### min \<distance\>
    //ffo min <distance>

Set how closely to follow. Minimum 0.2 yalms, maximum 50.0 yalms.

#### zone \<duration\>
    //ffo zone <duration>

Set how long to attempt to follow into the next zone.

#### info [on|off]

    //ffo info [on|off]

Display a box containing client-to-client distances, to detect when an alt gets orphaned.
