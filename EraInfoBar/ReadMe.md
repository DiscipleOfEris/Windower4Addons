# EraInfoBar
FFXI Windower addon that displays a configurable bar showing information on your targets. Modified for more accuracy on
Era.


## Installation
After downloading, extract to your Windower addons folder. Make sure the folder is called EraInfoBar, rather than
-master or -v1.whatever. Your file structure should look like this:

    addons/EraInfoBar/EraInfoBar.lua
    addons/EraInfoBar/mob.lua
    addons/EraInfoBar/mob_info.db
    addons/EraInfoBar/statics.lua

Once the addon is in your Windower addons folder, it won't show up in the Windower launcher. You need to load it
manually or add a line to your `scripts/init.txt`:

    lua load EraInfoBar


## Usage

### Adding variables
To add variables, run the addon once (which will create the file), then open the `addons/EraInfoBar/data/settings.xml`
file with a text editor. Edit the text inside tags such as `<NoTarget>text</NoTarget>` (when you have no target or
target yourself), `<TargetPC>text</TargetPC>` (you target another player), `<TargetNPC>text</TargetNPC>` (you target a
npc), and `<TargetMob>text</TargetMob>` (you target a mob). You can also add normal strings to them. Here's an example:
`<TargetMob>Name: ${name}, Family: ${ecosystem}</TargetMob>`. You can show specific text if a flag is true, such as:
`${aggressive|| Will attack you}` which will only display `Will attack you` if the mob is aggressive.

### List of variables

#### Any/no target variables
If no target, default to player variables.

 * `name`           : Name of the target, or the current player if no target.
 * `id`             : Id of the target, or the current player if no target.
 * `x`              : X coordinate of the target, or the current player if no target.
 * `y`              : Y coordinate of the target, or the current player if no target.
 * `z`              : Z coordinate of the target, or the current player if no target.
 * `facing`         : The direction (from due East) the target is facing, out of 360 degrees.
 * `facing_dir`     : The direction the target is facing as a compass abbreviation (e.g. `NW`).
 
 * `main_job`       : The current player's main job (e.g. `BLM`).
 * `main_job_level` : The level of the current player's main job.
 * `sub_job`        : The current player's main sub job.
 * `sub_job_level`  : The level of the current player's sub job.
 
 * `zone_name`      : Name of the current zone.
 * `game_moon`      : The current phase of the moon.
 * `game_moon_pct`  : The current phase of the moon as a percent.
 
 * `alchemy`        : Whether the Alchemy guild is open.
 * `bonecraft`      : Whether the Bonecrafting guild is open.
 * `clothcraft`     : Whether the Clothcrafting guild is open.
 * `cooking`        : Whether the Cooking guild is open.
 * `fishing`        : Whether the Fishing guild is open.
 * `goldsmithing`   : Whether the Goldsmithing guild is open.
 * `leathercraft`   : Whether the Leathercrafting guild is open.
 * `smithing`       : Whether the Smithing guild is open.
 * `woodworking`    : Whether the Woodworking guild is open.
 
 * `notes`          : Notes on the current target that have been added with `//ib notes add <string>`.

#### Mob-only variables
Note that `[Range]` means that text is optional. For example `lvl` or `lvlRange`.

 * `family`         : The family/ecosystem of the target mob.
 * `ecosystem`      : The family/ecosystem of the target mob.
 * `job`            : The main job and sub job of the target mob.
 * `mJob`           : The main job of the target mob.
 * `sJob`           : The sub job of the target mob.
 * `respawn`        : The expected time for the mob to respawn after death.
 
 * `lvl[Range]`     : The level or level range of the target mob.
 * `hp[Range]`      : The expected hp or hp range of the target mob.
 * `mp[Range]`      : The expected mp or mp range of the target mob.
 * `str[Range]`     : The expected STR or STR range of the target mob.
 * `dex[Range]`     : The expected DEX or DEX range of the target mob.
 * `vit[Range]`     : The expected VIT or VIT range of the target mob.
 * `agi[Range]`     : The expected AGI or AGI range of the target mob.
 * `int[Range]`     : The expected INT or INT range of the target mob.
 * `mnd[Range]`     : The expected MND or MND range of the target mob.
 * `chr[Range]`     : The expected CHR or CHR range of the target mob.
 * `att[Range]`     : The expected attack or attack range of the target mob.
 * `def[Range]`     : The expected defense or defense range of the target mob.
 * `acc[Range]`     : The expected accuracy or accuracy range of the target mob.
 * `eva[Range]`     : The expected evasion or evasion range of the target mob.
 * `meva[Range]`    : The expected magic evasion or magic evasion range of the target mob.
 
 * `aggressive`     : Whether the mob is aggressive.
 * `linking`        : Whether the mob links.
 * `detects`        : What methods the mob can detect through.
 * `true_detection` : Whether the mob can see through Sneak and Invisible.
 * `nm`             : Whether the mob is an NM (untested).
 * `pet`            : Whether the mob is a pet (untested).


## Commands
You can either use `//infobar` or `//ib`. `<text>` means user choice. Do not actually write `<` and `>`.

#### help

    //ib help

Shows a list of commands.

#### notes add \<string\>

    //ib notes add <string>
    //ib notes add BALEFUL GAZE! Turn around!

Defines a note to the current target (by name). If you'd like to see your note, make sure the target type has the
`${notes}` variable.

#### notes delete

    //ib notes delete

Delete a note to the current target that was defined previously.
