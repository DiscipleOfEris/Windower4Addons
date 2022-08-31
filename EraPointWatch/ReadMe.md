# EraPointWatch
FFXI Windower addon that allows you to monitor your XP gains. Modified from Byrth's original pointwatch addon for compatibility with Era.

## Installation
After downloading, extract to your Windower addons folder. Make sure the folder is called EraPointWatch, rather than -master or -v1.whatever. Your file structure should look like this:

    addons/EraPointWatch/EraPointWatch.lua
    addons/EraPointWatch/message_ids.lua
    addons/EraPointWatch/statics.lua

Once the addon is in your Windower addons folder, it won't show up in the Windower launcher. You need to load it manually or add a line to your `scripts/init.txt`:

    lua load EraPointWatch

## Usage

### Adding variables

To add variables open the `addons/EraPointWatch/data/settings.xml` with a text editor and add the variables as you wish
to the `default` (in most zones) or `dynamis` tags.
You can also add normal strings to them, for example `Name: ${name}`

### List of variables

 * `xp.current`             : Current Experience Points (number from 0 to 55,999 XP)
 * `xp.tnl`                 : Number of Experience Points in your current level (number from 500 to 56,000)
 * `xp.rate`                : Current XP gain rate per hour. This is calculated over a 10 minute window and requires at least two gains within the window.
 * `xp.total`               : Total Experience Points gained since the last time the addon was loaded/reset (number)
 * `xp.job`                 : Your current main job.
 * `xp.job_abbr`            : The three-letter abbreviation of your current main job.
 * `xp.job_level`           : Level of your current job.
 * `xp.sub_job`             : Your current subjob.
 * `xp.sub_job_abbr`        : The three-letter abbreviation of your current subjob.
 * `xp.sub_job_level`       : Level of your current support job.

 * `lp.current`             : Current Limit Points (number from 0 to 9,999 LP)
 * `lp.tnm`                 : Similar to a "To Next Level", but this value is always 10,000 because that's always the number of Limit Points per merit point.
 * `lp.number_of_merits`    : Number of merit points you have.
 * `lp.maximum_merits`      : Maximum number of merits you can store.

 * `dynamis.KIs`            : Series of Xs and Os indicating whether or not you have the 5 KIs.
 * `dynamis.entry_time`     : Your Dynamis entry time, in seconds. If the addon is loaded/reset in dynamis, this will be the time of addon load.
 * `dynamis.time_limit`     : Your current Dynamis time limit, in seconds. If the addon is loaded/reset in dynamis, you will need to gain a KI for this to be accurate.
 * `dynamis.time_remaining` : The current dynamis time remaining, in seconds. Will not be accurate if the addon is loaded/reset in dynamis.

## Commands
You can either use `//pointwatch` or `pw`.
`<text>` means user choice. Do not actually write `<` and `>`.
You can move the text box by clicking and dragging with your mouse.

#### reset

    //pw reset

Restarts the calculations and timers.

#### show

    //pw show

Shows the text box.

#### hide

    //pw hide

Hides the text box. The experience rate will still be calculated in the background.
