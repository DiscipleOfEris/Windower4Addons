# EraMobLevel
Displays the level of the currently selected mob. This is fetched via widescan. The level will be color-coded based on
the challenge level of the target, and bold if the target is high enough level to aggro.

![Incredibly Tough](http://DiscipleOfEris.github.io/MobLevel_IncrediblyTough.png)
![Too Weak](http://DiscipleOfEris.github.io/MobLevel_TooWeak.png)
![Easy Prey Aggro](http://DiscipleOfEris.github.io/MobLevel_AggroEasyPrey.png)
![Easy Prey No Aggro](http://DiscipleOfEris.github.io/MobLevel_NoAggroEasyPrey.png)

The color-coding can be be changed in `addons/MobLevel/data/settings.xml` after the addon has been loaded once.  
  
This doesn't technically require Era to use, but it generally assumes you have widescan which all jobs have on Era.


## Installation
After downloading, extract to your Windower addons folder. Make sure the folder is called EraMobLevel, rather than
-master or -v1.whatever. Your file structure should look like this:

    addons/EraMobLevel/EraMobLevel.lua

Once the addon is in your Windower addons folder, it won't show up in the Windower launcher. You need to load it
manually or add a line to your `scripts/init.txt`:

    lua load EraMobLevel

## Commands
You can use `//moblevel` or `//level`. Note that `<text>` means user choice. Do not actually write `<` and `>`.
Similarly, `[text]` means that `text` is optional. `text1|text2` means choose one of `text1` *or* `text2`.

#### scan

    //level scan

Do a wide scan.

#### auto

    //level auto

Toggles auto scanning, both when targetting an unscanned mob and rescanning on an interval.

#### interval \<seconds\>

    //level interval 60
    //level interval 0

Set the autoscan interval. Will disable timed autoscan if interval is set to 0.

#### aggro [player_level]

    //level aggro
    //level aggro 35

Reports the level range that will aggro the player, or `player_level` if provided.

#### tw|ep|dc|em|t|vt|it [player_level]

    //level tw
    //level t 75

Reports the level range that will check as the given challenge rating to the current player's level, or to
`player_level` if provided.
