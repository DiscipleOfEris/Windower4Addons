# EraMobDrops
FFXI Windower addon that displays the drop table of the currently targeted mob, along with a Treasure Hunter
calculator. Draws from the FFEra.com drop tables.

## Installation
After downloading, extract to your Windower addons folder. Make sure the folder is called EraMobDrops, rather than
-master or -v1.whatever. Your file structure should look like this:

    addons/EraMobDrops/EraMobDrops.lua
    addons/EraMobDrops/mob_drops.db

Once the addon is in your Windower addons folder, it won't show up in the Windower launcher. You need to load it
manually or add a line to your scripts/init.txt:

    lua load EraMobDrops

## Commands
You can use either `//mobdrops` or `//drops`.
Note that you can relocate the drops textbox by dragging and dropping with your mouse.
You can also scroll the drop window with the mousewheel.
`<text>` means user choice. Do not actually write `<` and `>`.

#### item \<item_name\>

    //drops item <item_name>

Will show the drop chances for all mobs that drop the specified item.

#### mob

    //drops mob <mob_name>

Will show the drops of all mobs with that name.

#### th+

    //drops th+

Increase TH calculator level. Left clicking the display will also work.

#### th-

    //drops th-

Decrease TH calculator level. Middle/right clicking the display will also work.

#### page

    //drops page <size>

Set the page size. Scroll with the mouse wheel.
