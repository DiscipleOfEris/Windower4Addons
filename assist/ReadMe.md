# Assist
FFXI Windower addon that lets you tell your multiboxed alts to target your target without locking on.


## Installation
After downloading, extract to your Windower addons folder. Make sure the folder is called Assist, rather than
-master or -v1.whatever. Your file structure should look like this:

    addons/Assist/Assist.lua

Once the addon is in your Windower addons folder, it won't show up in the Windower launcher. You need to load it
manually or add a line to your `scripts/init.txt`:

    lua load Assist


## Commands
Note that `<text>` means user choice. Do not actually write `<` and `>`. Similarly, `[text]` means that `text` is
optional. `text1|text2` means choose one of `text1` *or* `text2`.

#### [help]

    //assist help
    //assist
    
Display the usage information.

#### me

    //assist me

Will tell all alts to target your target.

#### target \<target_id\>

    //assist target 17228215

Set the target to the mob/player specified by <target_id>.

#### delock [on|off]

    //assist delock on
    //assist delock off
    //assist delock

Enable/disable/toggle the delock feature. Prevents the normal /lockon effect caused by /assist.
