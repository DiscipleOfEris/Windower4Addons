# SendTarget
FFXI Windower addon that allows multiboxers to more easily send commands. You can capture targets and subtargets.


## Installation
After downloading, extract to your Windower addons folder. Make sure the folder is called SendTarget, rather than
-master or -v1.whatever. Your file structure should look like this:

    addons/SendTarget/SendTarget.lua
    addons/SendTarget/statics.lua

Once the addon is in your Windower addons folder, it won't show up in the Windower launcher. You need to load it
manually or add a line to your `scripts/init.txt`:

    lua load SendTarget

### Compatibility with the GearSwap addon

Note that this addon has some compatibility issues with GearSwap, requiring a more complex setup if you're using that
addon.  
  
You'll need SendTarget loaded before GearSwap (for example, put `lua load GearSwap` or `lua reload GearSwap`
*after* `lua load SendTarget` in your `scripts/init.txt` file).

    lua load SendTarget
    lua load GearSwap

If you already loaded GearSwap you can do `lua reload GearSwap` instead.  
  
You'll also need to some extra setup in your GearSwap profiles. Namely, running
`windower.send_command('sta !packets on')` in your GearSwap profile's `equip_sets()` function and
`windower.send_command('sta !packets off')` in your GearSwap profile's `file_unload()` function. You must do this for
*EVERY SINGLE GEARSWAP PROFILE!*

```Lua
-- addons/GearSwap/data/Maruru_BLM.lua

function get_sets()
    windower.send_command('sta !packets off')
    
    -- Do the actual configuration of your sets as per normal.
end

function file_unload()
    windower.send_command('sta !packets on')
end
```

## Usage
Basic usage looks like `//sta CHARACTER_NAME /ma "Cure III" <stpc>`.
  
For a more specific example, let's say you have an alt named Maruru and you wanted to make a macro to have them heal
based on your \<st\> choice. To use commands from a macro, you must use `/con` instead of `//`. For example,
`/con sta Maruru /ma "Cure III" <stpc>`  
  
If you need to put additional commands after an \<st\> line in a macro, you can use the `!capture` command like so
(this example uses the Send addon):

    /con sta !capture Maruru
    /ma "Cure III" <stpc>
    /con send Maruru equip main "Light Staff"
    /wait 4
    /con send Maruru equip main "Earth Staff"

I highly recommend uses aliases to make your life easier and not have to type as many characters. For example, in your
`scripts/init.txt` you could add:

    alias mt sta Maruru
    alias et sta @all
    alias ot sta @others

Then do macros like `/con mt /ma "Cure III" <stpc>`.

### General compatibility

This addon cannot capture subtargeting with the \<stpt\> and \<stal\> targets.

### Compatibility with Shortcuts

To use with Shortcuts, *make sure that Shortcuts is loaded first.* Once done, these addons work absolutely amazing
together!  
  
You could make an alias `//alias all sta @all` and then type `//all c3 st`. This will give you subtarget
selection, and then upon selecting a target all of your characters will cast Cure III on the chosen target.
Similarly, you could do `//all thunder4` and all of your characters will cast Thunder IV on your current target,
regardless of their target. No `/assist` necessary!

### Compatibility with the Send addon

This addon works fine with the Send addon, though it terms of casting spells or using abilities it makes Send redundant. However, SendTarget only captures commands with targets, so Send is still needed to order alts to do commands with no targets (such as `/join` or `/heal`). Additionally, there might be times when intuitively the Send addon will do what you want. For example, let's
imagine we're playing on Kaiyra and have Maruru running in the background. Writing (with the Shortcuts addon)
`//sta maruru cure me` will make Maruru heal Kaiyra. But doing `//send maruru cure me` will make Maruru heal herself.  
  
It's up to you which behavior is more intuitive.

### Compatibility with the SubTarget addon

This cannot be used with the SubTarget addon. You must disable that addon.

## Commands
You can use `//sendtarget` or `//sta`. Note `text1|text2` means choose one of `text1` *or* `text2`. Do not actually
write the `|` character. Similarly, `[text]` means `text` is optional.

#### CHARACTER_NAME|@all|@everyone|@others INPUT

    //sta Maruru /ja "Provoke" <stnpc>
    //sta @all /ma "Thunder 4" <t>
    //sta @others /ma "Cure III" <me>
    //sta Maruru provoke stnpc
    //sta @all thunder4
    //sta @others c3 me

Sends the given input to the specified character or group of characters. This will capture targets, so you can use
`<t>`, `<st>`, `<lastst>`, etc. `@all` and `@everyone` means to send to all characters *including* the current
character. `@others` means to send to all characters *excluding* the current character. Some of the examples assume the
Shortcuts addon is loaded.

#### !capture CAPTURE_TARGET

    //sta !capture Maruru
    //sta !capture @all
    //sta !capture @others

Will capture the next command and send it through SendTarget. Useful specifically in macros.

#### !mirror

    //sta !mirror


#### !packets [on|off]

    //sta !packets
    //sta !packets on
    //sta !packets off

Toggle, enable, or disable packet injection. This is specifically for compatibility with GearSwap. Remember that
GearSwap must be loaded *after* SendTarget!
