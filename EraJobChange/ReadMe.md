# EraJobChange
FFXI Windower addon that allows you to change your job with a command. Modified from Sammeh's original jobchange addon
for compatibility with Era.


## Installation
After downloading, extract to your Windower addons folder. Make sure the folder is called EraJobChange, rather than
-master or -v1.whatever. Your file structure should look like this:

    addons/EraJobChange/EraJobChange.lua

Once the addon is in your Windower addons folder, it won't show up in the Windower launcher. You need to load it
manually or add a line to your `scripts/init.txt`:

    lua load EraJobChange


## Commands

You can use either `//jobchange` or `//jc`. All job names should be their abbreviated forms (e.g. `BLM` rather than
`Black Mage`). `<text>` means user choice. Do not actually write `<` and `>`. You can use this command in your moghouse
or anywhere Era allows you to access your moghouse with the `!mh` command.

#### main \<job\>

    //jc main <job>
    //jc main drg

Change your main job to the specified <job>.

#### sub \<job\>

    //jc sub <job>
    //jc sub dnc

Change your sub job to the specified <job>.

#### \<main_job\>/\<sub_job\>

    //jc <main_job>/<sub_job>
    //jc blm/whm

Change your main and sub job at the same time.
