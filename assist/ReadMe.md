# Assist
FFXI Windower addon that lets you tell your multiboxed alts to target your target without locking on.


## Installation
After downloading, extract to your Windower addons folder. Make sure the folder is called Assist, rather than
-master or -v1.whatever. Your file structure should look like this:

    addons/Assist/Assist.lua

Once the addon is in your Windower addons folder, it won't show up in the Windower launcher. You need to load it
manually or add a line to your `scripts/init.txt`:

    lua load Assist


## Usage
To get all your other alts to target your target, use `//assist me`. If you want all your characters to *attack* your
target, use either `//assist attack` for a one-time command, or `//assist awm` so your alts will change their attack
target whenever you do. Note that the `attackwithme` mode tells your alts to copy you *when you do something.* They
might fail to copy you for the same reasons your own action might fail, such as their weapon swing being on cooldown.
If that happens, you can just use the normal "Switch Target" command and select the enemy you're already attacking.

For anything more complicated, see the commands below.


## Commands
Note that `<text>` means user choice. Do not actually write `<` and `>`. Similarly, `[text]` means that `text` is
optional. `text1|text2` means choose one of `text1` *or* `text2`.
`@<shortcut>` can be one of `@all`, `@self`, `@others`, or `@<job>` (e.g. `@blm`).

#### [help]

    //assist help
    //assist
    
Display the usage information.

#### \<char_name\>

    //assist Kaiyra
    //assist Maruru

Set your target to that of the specified alt.

#### me [\<char_name\>|@\<shortcut\>]

    //assist me

Tell the specified alt(s) (default `@others`) to set their target to yours.

#### delock [all|target|attack] on|off|t

    //assist delock on
    //assist delock attack off
    //assist delock target t

Enable/disable/toggle delock on this character. Prevents the normal `/lockon` effect from assist/attack.

#### verbose on|off|t

    //assist verbose on
    //assist verbose off
    //assist verbose t

Enable/disable/toggle verbose mode. Displays more messages while the addon is active.

#### attack|a [\<char_name\>|@\<shortcut\>]

    //assist attack
    //assist a @others
    //assist a @war
    //assist a Maruru

Tell alts (default `@all`) to attack your current target.

#### disengage|d [\<char_name\>|@\<shortcut\>]

    //assist disengage
    //assist d @blm
    //assist d Maruru

Tell alts (default `@all`) to disengage.

#### attackwith|aw \<char_name\>

    //assist attackwith Kaiyra
    //assist aw Maruru

Maintain your attack target to be the same as the specified alt.

#### attackwithme|awm [\<char_name\>|@\<shortcut\>]

    //assist attackwithme
    //assist awm @war
    //assist awm Maruru

Tell the specified alt(s) (default `@others`) to maintain their attack target with yours.

#### stopattack|sa [\<char_name\>|@\<shortcut\>]

    //assist stopattack
    //assist sa @war
    //assist sa Maruru

Tell the specified alt(s) (default `@all`) to stop doing `attackwith`.

#### target|t \<char_name\>|@\<shortcut\> \<target_id\>

    //assist target @self 17027458
    //assist t Maruru 17027458

Tell the specified alt(s) to target the entity with the specified id.

#### targetwith|tw \<char_name\>

    //assist targetwith Kaiyra
    //assist tw Maruru

Maintain your target to be the same as the specified alt.

#### targetwithme|twm [\<char_name\>|@\<shortcut\>]

    //assist targetwithme
    //assist twm @war
    //assist twm Maruru

Tell the specified alt(s) (default `@others`) to maintain their target with yours.

#### stoptarget|st [\<char_name\>|@\<shortcut\>]

    //assist stoptarget
    //assist st @blm
    //assist st Maruru

Tell the specified alt(s) (default `@all`) to stop doing `targetwith`.
