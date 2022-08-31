# Windower4Addons
Addons for FFXI using Windower4 that I (DiscipleOfEris) have written or modified. Most of these are written for
compatibility with Era (a private FFXI server) in mind. It is currently using an old version of the FFXI client.
These addons are specifically prefixed with `Era` to distinguish them.


## Installation
After downloading, extract to your Windower addons folder. Make sure the folder is called `AddonName`, rather than
-master or -v1.whatever. Your file structure should look something like this:

    addons/Addon1/Addon1.lua
    addons/Addon2/Addon2.lua

Once the addons are in your Windower addons folder, they won't show up in the Windower launcher. You need to load them
manually or add a couple lines to your `scripts/init.txt`:

    lua load Addon1
    lua load Addon2

For example if you install the SendTarget addon, there should be a folder called SendTarget in your Windower addons
folder. Directly inside that folder should be a file called `SendTarget.lua`.

    addons/SendTarget/SendTarget.lua

Then in your `scripts/init.txt`:

    lua load SendTarget

See the individual addons for more detailed instructions.
