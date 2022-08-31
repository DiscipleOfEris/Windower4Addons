# EraScoreboard
FFXI Windower addon that displays a live dps chart for your party. Modified from Suji's original addon for compatibility with Era.


## Installation
After downloading, extract to your Windower addons folder. Make sure the folder is called EraScoreboard, rather than -master or -v1.whatever. Your file structure should look like this:

    addons/EraScoreboard/EraScoreboard.lua
    addons/EraScoreboard/damagedb.lua
    addons/EraScoreboard/display.db
    addons/EraScoreboard/dpsclock.lua
    addons/EraScoreboard/mergedplayer.lua
    addons/EraScoreboard/player.lua

Once the addon is in your Windower addons folder, it won't show up in the Windower launcher. You need to load it manually or add a line to your `scripts/init.txt`:

    lua load EraScoreboard


## Usage

 * Live DPS
 * You can still parse damage even if you enable chat filters.
 * Ability to filter only the mobs you want to see damage for.
 * Report command for reporting damage to party chat or wherever you want.

DPS accumulation is active whenever anyone in your alliance is currently in battle.

### Configuration

To change settings, run the addon once (which will create the file), then open the
`addons/EraScoreboard/data/settings.xml` file with a text editor. Change values inside tags as you wish. For example:
`<showfellow>true</showfellow>` or `<showfellow>false</showfellow>.

### List of variables

 * `showallidps`     : Set to `true` to display the alliance DPS, `false` otherwise.
 * `showfellow`      : Set to `true` to display your adventuring fellow's DPS, `false` otherwise.
 * `combinepets`     : Set to `true` to display the pet owner's name next to the pet.
 * `UpdateFrequency` : The value (in seconds) for how frequently to update the display.
 * `resetfilters`    : Set to `true` if you want filters reset when you "//sb reset", `false` otherwise.
 * `sbcolor`         : Color of scoreboard's chat log output
 * `numplayers`      : Max players to display.


## Commands
You can use either `//scoreboard` or `//sb`.
`<text>` means user choice. Do not actually write `<` and `>`.
`[text]` means optional. Do not actually write `[` and `]`.

#### help

    //sb help

Displays the help text.

#### reset

    //sb reset

Resets all the data that's been tracked so far.

#### report [\<chat_mode\>]

    //sb report
    //sb report l
    //sb report t suji

Reports the damage. With no argument, it will go to your current chatmode. You may also pass the standard FFXI chat
abbreviations as arguments. Supported arguments are `s`, `t <player_name>`, `p`, and `l`.

#### reportstat <stat> [\<player_name\>] [\<chat_mode\>]

    //sb reportstat acc
    //sb rs crit
    //sb rs crit p
    //sb rs acc tell suji
    //sb rs acc t suji
    //rb rs acc tulia t suji

Reports the given stat. Supports stats are `mavg`, `mrange`, `acc`, `ravg`, `rrange`, `racc`, `critavg`, `critrange`,
`crit`, `rcritavg`, `rcritrange`, `rcrit`, `wsavg`, `wsacc`. Provide `<player_name>` if you wish to show the stats of
only a single player. See `report [<chat_mode>]` for a description of the `<chat_mode>` parameter.

#### filter show

    //sb filter show

Shows the current mob filters.

#### filter add \<mob1\> [\<mob2\> [...]]

    //sb filter add Colibri

Adds (mob(s) to the filters. These can all be substrings. Legal Lua patterns are also allowed.

#### filter clear

    //sb filter clear

Clears all mobs from the filter.

#### visible

    //sb visible

Toggles the visibility of the scoreboard. Data will continue to accumulate even while it is hidden.

#### stat \<statname\> [\<player_name\>]

    //sb stat acc
    //sb stat crit Flippant

Report specific parser stats to only yourself. This will respect the current filter settings. Valid stats are `acc`,
`racc`, `crit`, `rcrit`.
