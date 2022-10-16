_addon.name = 'Assist'
_addon.author = 'DiscipleOfEris'
_addon.version = '2.0.0pre'
_addon.command = 'assist'

require('tables')
require('strings')
require('logger')
packets = require('packets')
config = require('config')

defaults = {}
defaults.delock_target = true
defaults.delock_attack = false
defaults.verbose = false

settings = config.load(defaults)

local delock_target_id = nil
local delock_attack_id = nil

local last_target_id = nil

local mirroring = {
    attack = {
        isLeader = false,
        followers = {},
        leader = nil,
    },
    target = {
        isLeader = false,
        followers = {},
        leader = nil,
    },
}

local PACKET = {
    OUTGOING = {
        ACTION = 0x01A,
    },
    INCOMING = {
        LOCK_TARGET = 0x058,
    }
}

local ACTION = {
    ENGAGE = 0x02,
    DISENGAGE = 0x04,
    SWITCH_TARGET = 0x0F,
}

local STATUS = {
    ENGAGED = 0x01,
}

windower.register_event('addon command', function(command, ...)
    args = L{...}
  
    if command then command = string.lower(command) end
    if args[1] then args[1] = string.lower(args[1]) end
    if args[2] then args[2] = string.lower(args[2]) end

    -- Display the addon help.
    if not command or command == 'help' then
        log('Make alts assist you, or attack when you attack.')
        log('This addon supports the same @shortcuts as send (e.g. @all, @others, @job).')
        log('//assist <char_name>                          : Set your target to that of the specified alt.')
        log('//assist me [<@shortcut|char_name>]           : Tell the specified alt(s) (default @others) to set their target to yours.')
        log('//assist delock [all|target|attack] on|off|t  : Enable/disable/toggle delock on this character. Prevents the normal /lockon effect from assist/attack.')
        log('//assist verbose on|off|t                     : Enable/disable/toggle verbose mode. Displays more messages while the addon is active.')
        log('//assist a [<@shortcut|char_name>]')
        log('//assist attack [<@shortcut|char_name>]       : Tell alts (default @all) to attack your current target.')
        log('//assist d [<@shortcut|char_name>]')
        log('//assist disengage [<@shortcut|char_name>]    : Tell alts (default @all) to disengage.')
        log('//assist aw <char_name>')
        log('//assist attackwith <char_name>               : Maintain your attack target to be the same as the specified alt.')
        log('//assist awm [<@shortcut|char_name>]')
        log('//assist attackwithme [<@shortcut|char_name>] : Tell the specified alt(s) (default @others) to maintain their attack target with yours.')
        log('//assist sa [<@shortcut|char_name>]')
        log('//assist stopattack [<@shortcut|char_name>]   : Tell the specified alt(s) (default @all) to stop doing attackwith.')
        log('//assist t <@shortcut|char_name> <id>')
        log('//assist target <@shortcut|char_name> <id>    : Tell the specified alt(s) to target the entity with the specified id.')
        log('//assist tw <char_name>')
        log('//assist targetwith <char_name>               : Maintain your target to be the same as the specified alt.')
        log('//assist twm [<@shortcut|char_name>]')
        log('//assist targetwithme [<@shortcut|char_name>] : Tell the specified alt(s) (default @others) to maintain their target with yours.')
        log('//assist st [<@shortcut|char_name>]')
        log('//assist stoptarget [<@shortcut|char_name>]   : Tell the specified alt(s) (default @all) to stop doing targetwith.')
    -- Tell the specified alt(s) to target the entity with the specified id.
    elseif command == 'target' or command == 't' then
        local char_arg = args[1]
        local target_id = tonumber(args[2])

        if not char_arg then
            log('target: An alt name or shortcut must be provided. See the ReadMe or //assist help for details.')
            return       
        end

        if not target_id then
            log('target: A valid target id must be provided. See the ReadMe or //assist help for details.')
            return
        end
        
        local player = windower.ffxi.get_player()
        if not player then return end
    
        if should_send_self(char_arg) then
            set_target(target_id)
        end

        windower.send_ipc_message('target '..char_arg..' '..target_id)
    -- Enable/disable/toggle delock on this character. Prevents the normal /lockon effect from assist/attack.
    elseif command == 'delock' then
        local delock_type = args[2] and args[1] or 'all'
        local delock_setting = args[2] and args[2] or args[1]
        
        if not get_index_by_value({'target', 'attack', 'all'}, delock_type) then
            log('delock: Invalid argument. See the ReadMe or //assist help for details.')
            return
        end
        
        if delock_type == 'target' or delock_type == 'all' then
            local setting, valid = handle_booltoggle_arg(delock_setting, settings.delock_target)
            
            if not valid then
                log('delock: Invalid argument. See the ReadMe or //assist help for details.')
                return
            end
            
            settings.delock_target = setting
            log('Setting target delock to '..(settings.delock_target and 'on' or 'off')..'.')
        end
        
        if delock_type == 'attack' or delock_type == 'all' then
            local setting, valid = handle_booltoggle_arg(delock_setting, settings.delock_attack)
            
            if not valid then
                log('delock: Invalid argument. See the ReadMe or //assist help for details.')
                return
            end
            
            settings.delock_attack = setting
            log('Setting attack delock to '..(settings.delock_attack and 'on' or 'off')..'.')
        end
        
        config.save(settings)
    -- Enable/disable/toggle verbose mode. Displays more messages while the addon is active.
    elseif command == 'verbose' then
        local verbose_setting = args[1]
        
        local setting, valid = handle_booltoggle_arg(verbose_setting, settings.verbose)
        
        if not valid then
            log('verbose: Invalid argument. See the ReadMe or //assist help for details.')
            return
        end
        
        settings.verbose = setting
        log('Setting verbose mode to '..(settings.verbose and 'on' or 'off')..'.')
        config.save(settings)
    -- Tell alts (default @all) to attack your current target.
    elseif command == 'attack' or command == 'a' then
        local char_arg = args[1] or '@all'
        
        local target = windower.ffxi.get_mob_by_target('t')
        if not target then return end
        
        if should_send_self(char_arg) then engage_target(target.id) end
        
        windower.send_ipc_message('attack '..char_arg..' '..target.id)
    -- Tell alts (default @all) to disengage.
    elseif command == 'disengage' or command == 'd' then
        local char_arg = args[1] or '@all'
        
        if should_send_self(char_arg) then disengage() end
        
        windower.send_ipc_message('disengage '..char_arg)
    -- Maintain your target/attack target to be the same as the specified alt.
    elseif get_index_by_value({'attackwithme', 'awm', 'targetwithme', 'twm'}, command) then
        local char_arg = args[1] or '@others'
        
        local mirror_type = get_index_by_value({'attackwithme', 'awm'}, command) and 'attack' or 'target'
        local mirror_settings = mirroring[mirror_type]
        
        local player = windower.ffxi.get_player()
        if not player then return end
        
        mirror_settings.isLeader = true
        
        if mirror_settings.leader then
            windower.send_ipc_message('stopped'..mirror_type..'with '..mirror_settings.leader..' '..string.lower(player.name))
            mirror_settings.leader = false
        end
        
        windower.send_ipc_message(mirror_type..'withme '..char_arg..' '..string.lower(player.name))
        
        log('Alts will now '..mirror_type..' with this character.')
    -- Maintain your target/attack target to be the same as the specified alt.
    elseif get_index_by_value({'attackwith', 'aw', 'targetwith', 'tw'}, command) then
        local char_name = args[1]
        
        local mirror_type = get_index_by_value({'attackwith', 'aw'}, command) and 'attack' or 'target'
        local mirror_settings = mirroring[mirror_type]
        
        local player = windower.ffxi.get_player()
        if not player then return end
        
        if not char_name or string.sub(char_name, 1, 1) == '@' then
            log(mirror_type..'with: A character name must be provided. See the ReadMe or //assist help for details.')
            return
        end
        
        if mirror_settings.isLeader then
            mirror_settings.isLeader = false
            mirror_settings.followers = {}
            windower.send_ipc_message('stop'..mirror_type..'ingwithme @all '..string.lower(player.name))
        end
        
        windower.send_ipc_message(mirror_type..'with '..char_name..' '..string.lower(player.name))
        
        log('This character will now start '..mirror_type..'ing with '..char_name..'.')
    -- Tell the specified alt(s) (default @all) to stop doing targetwith/attackwith.
    elseif get_index_by_value({'stopattack', 'sa', 'stoptarget', 'st'}, command) then
        local char_arg = args[1] or '@all'
        
        local mirror_type = get_index_by_value({'stopattack', 'sa'}, command) and 'attack' or 'target'
        local mirror_settings = mirroring[mirror_type]
        
        local player = windower.ffxi.get_player()
        if not player then return end
        
        if should_send_self(char_arg) and mirror_settings.leader then
            windower.send_ipc_message('stopped'..mirror_type..'with '..mirror_settings.leader..' '..string.lower(player.name))
            mirror_settings.leader = nil
        end
        
        windower.send_ipc_message('stop'..mirror_type..'withme '..char_arg..' @all')
    -- Tell the specified alt(s) (default @others) to set their target to yours.
    elseif command == 'me' then
        if not args[1] then args[1] = '@others' end
        
        local target = windower.ffxi.get_mob_by_target('t')
        if target then windower.send_ipc_message('target '..args[1]..' '..target.id) end
    -- Set your target to that of the specified alt.
    else -- <char_name>
        local player = windower.ffxi.get_player()
        if not player then return end
        
        windower.send_ipc_message('assist '..command..' '..string.lower(player.name))
    end
end)

windower.register_event('ipc message', function(message)
    args = message:lower():split(' ')
    local command = args[1]
        
    if settings.verbose then log(message) end
    
    if command == 'target' then
        local char_arg = args[2]
        local target_id = tonumber(args[3])
        
        if not should_send_self(char_arg, true) then return end
        
        set_target(target_id)
    elseif command == 'assist' then
        local char_name = args[2]
        local char_origin = args[3]
    
        local player = windower.ffxi.get_player()
        if not player or char_name ~= string.lower(player.name) then return end
        
        local target = windower.ffxi.get_mob_by_target('t')
        if not target then return end
        
        windower.send_ipc_message('target '..char_origin..' '..target.id)
    elseif command == 'attack' then
        local char_arg = args[2]
        local target_id = tonumber(args[3])
        
        if not should_send_self(char_arg, true) then return end
        
        engage_target(target_id)
    elseif command == 'disengage' then
        local char_arg = args[2]
        
        if not should_send_self(char_arg, true) then return end
        
        disengage()
    elseif command == 'attackingwith' or command == 'targetingwith' then
        local char_name = args[2]
        local char_origin = args[3]
        
        local mirror_type = command == 'attackingwith' and 'attack' or 'target'
        local mirror_settings = mirroring[mirror_type]
        
        local player = windower.ffxi.get_player()
        if not player or char_name ~= string.lower(player.name) then return end
        
        if mirror_settings.leader then
            windower.send_ipc_message('stopped'..mirror_type..'with '..mirror_settings.leader..' '..string.lower(player.name))
            mirror_settings.leader = nil
        end
        
        mirror_settings.isLeader = true
        table.insert(mirror_settings.followers, char_origin)
    elseif command == 'attackwithme' or command == 'targetwithme' then
        local char_arg = args[2]
        local char_origin = args[3]
        
        local mirror_type = command == 'attackwithme' and 'attack' or 'target'
        local mirror_settings = mirroring[mirror_type]
        
        if not should_send_self(char_arg, true) then return end
        
        local player = windower.ffxi.get_player()
        if not player then return end
        
        if mirror_settings.isLeader then
            windower.send_ipc_message('stop'..mirror_type..'withme @all '..string.lower(player.name))
            mirror_settings.isLeader = false
            mirror_settings.followers = {}
        end
        
        if mirror_settings.leader and mirror_settings.leader ~= char_origin then
            windower.send_ipc_message('stopped'..mirror_type..'with '..mirror_settings.leader..' '..string.lower(player.name))
        end
        
        mirror_settings.leader = char_origin
        windower.send_ipc_message(mirror_type..'ingwith '..char_origin)
        
        log('This character will now start '..mirror_type..'ing with '..char_origin..'.')
    elseif command == 'stoppedattackwith' or command == 'stoppedtargetwith' then
        local char_name = args[2]
        local char_origin = args[3]
        
        local mirror_type = command == 'stoppedattackwith' and 'attack' or 'target'
        local mirror_settings = mirroring[mirror_type]
        
        if not mirror_settings.isLeader then return end
        
        local player = windower.ffxi.get_player()
        if not player or char_name ~= string.lower(player.name) then return end
        
        remove_all_by_value(mirror_settings.followers, char_origin)
        
        if #mirror_settings.followers == 0 then
            mirror_settings.isLeader = false
        end
    elseif command == 'stopattackwithme' or command == 'stoptargetwithme' then
        local char_arg = args[2]
        local char_origin = args[3]
        
        local mirror_type = command == 'stopattackwithme' and 'attack' or 'target'
        local mirror_settings = mirroring[mirror_type]
        
        if not mirror_settings.leader or not should_send_self(char_arg, true) then return end
        
        if char_origin ~= '@all' and char_origin ~= mirror_settings.leader then return end
        
        local player = windower.ffxi.get_player()
        if not player then return end
        
        windower.send_ipc_message('stopped'..mirror_type..'with '..mirror_settings.leader..' '..string.lower(player.name))
        mirror_settings.leader = false
    elseif command == 'action' then
        local action = args[2]
        local char_origin = args[3]
        local target_id = tonumber(args[4])
        
        if action == 'attack' and char_origin == mirroring.attack.leader then
            engage_target(target_id)
        elseif action == 'disengage' and char_origin == mirroring.attack.leader then
            disengage()
        elseif action == 'target' and char_origin == mirroring.target.leader then
            set_target(target_id)
        end
    end
end)

windower.register_event('prerender', function()
    local target = windower.ffxi.get_mob_by_target('t')
    local player = windower.ffxi.get_player()
    
    if not player then return end

    if settings.delock_target and target and target.id == delock_target_id then
        windower.send_command('@input /lockon')
        delock_target_id = nil
    end
    
    if mirroring.target.isLeader and target and target.id ~= last_target_id then
        if settings.verbose then log('action target '..string.lower(player.name)..' '..tostring(target.id)) end
        windower.send_ipc_message('action target '..string.lower(player.name)..' '..tostring(target.id))
    end
    
    last_target_id = target and target.id or nil
end)

windower.register_event('outgoing chunk', function(id, original, modified, injected, blocked)
    if not mirroring.attack.isLeader then return end
    
    if id == PACKET.OUTGOING.ACTION then
        local player = windower.ffxi.get_player()
        if not player then return end
        
        local name = string.lower(player.name)
        local packet = packets.parse('outgoing', original)
        
        if settings.verbose then log('outgoing chunk action') end
        
        if packet['Category'] == ACTION.ENGAGE then
            if settings.verbose then log('action attack '..name..' '..tostring(packet['Target'])) end
            windower.send_ipc_message('action attack '..name..' '..tostring(packet['Target']))
        elseif packet['Category'] == ACTION.DISENGAGE then
            if settings.verbose then log('action disengage '..name) end
            windower.send_ipc_message('action disengage '..name)
        elseif packet['Category'] == ACTION.SWITCH_TARGET then
            if settings.verbose then log('action attack '..name..' '..tostring(packet['Target'])) end
            windower.send_ipc_message('action attack '..name..' '..tostring(packet['Target']))
        end
    end
end)

windower.register_event('incoming chunk', function(id, original, modified, injected, blocked)
    if not mirroring.attack.isLeader then return end
    
    if id == PACKET.INCOMING.LOCK_TARGET then
        local player = windower.ffxi.get_player()
        if not player then return end
        
        local name = string.lower(player.name)
        
        if settings.verbose then log('incoming chunk lock target') end
        
        if player.status == STATUS.ENGAGED then
            local packet = packets.parse('incoming', original)
            if settings.verbose then log('action attack '..name..' '..tostring(packet['Target'])) end
            windower.send_ipc_message('action attack '..name..' '..tostring(packet['Target']))
        end
    end 
end)

--- Set the player's target to the specified entity.
-- @int target_id The id of the entity to target
function set_target(target_id)
    local player = windower.ffxi.get_player()
    local target = windower.ffxi.get_mob_by_id(target_id)
    local current = windower.ffxi.get_mob_by_target('t')
    
    if not target or not player then return end

    -- Only mobs are locked on with /assist. This isn't perfect because some enemy pet mobs have a target.index in the pet range.
    -- TODO: Fix this when I update client. The spawn_type and entity_type fields aren't populated correctly on outdated client.
    if target.index < 1024 and settings.delock then
        delock_target_id = target_id
    end

    local packet = packets.new('incoming', PACKET.INCOMING.LOCK_TARGET, {
        ['Player'] = player.id,
        ['Target'] = target.id,
        ['Player Index'] = player.index,
    })

    packets.inject(packet)
end

--- Have the player draw their weapon on the specified entity, or switch targets if already engaged.
-- @int target_id The id of the entity to attack
function engage_target(target_id)
    local player = windower.ffxi.get_player()
    local target = windower.ffxi.get_mob_by_id(target_id)
    
    if not target or not player then return end
    
    local packet = packets.new('outgoing', PACKET.OUTGOING.ACTION, {
        ['Target'] = target.id,
        ['Target Index'] = target.index,
        ['Category'] = (player.status == STATUS.ENGAGED and ACTION.SWITCH_TARGET or ACTION.ENGAGE),
    })
    
    packets.inject(packet)
end

--- Have the player put disengage.
function disengage()
    local player = windower.ffxi.get_player()
    
    if not player then return end
    
    local packet = packets.new('outgoing', PACKET.OUTGOING.ACTION, {
        ['Target'] = player.id,
        ['Target Index'] = player.index,
        ['Category'] = ACTION.DISENGAGE,
    })
    
    packets.inject(packet)
end

--- Determine whether the command should also be directed to the current alt.
-- @string char_arg The string containing the character argument, such as @all, @job, a character name, etc.
-- @bool[opt=false] incoming If true, will interpret @others as true and @self as false, and vice versa if false
-- @treturn bool True if the command should apply to the current character, false otherwise
function should_send_self(char_arg, incoming)
    local player = windower.ffxi.get_player()
    
    if not player then return false end
    
    char_arg = string.lower(char_arg)
    
    if char_arg == '@all' then return true
    elseif char_arg == '@self' and not incoming then return true
    elseif char_arg == '@others' and incoming then return true
    elseif char_arg == string.lower(player.name) then return true
    elseif char_arg == string.lower('@'..player.main_job) then return true end
    
    return false
end

--- Get the first index of the value in the table.
-- @param t The table to search
-- @param value The non-table value to check against
-- @return The lowest index where the value occurs in the table, or false if it doesn't exist
function get_index_by_value(t, value)
    for i, val in ipairs(t) do
        if val == value then return i end
    end
    
    return false
end

--- Remove all occurences of the value from the table.
-- @param t The table to modify
-- @param value The non-table value to check against
-- @treturn int The number of entries that were removed
function remove_all_by_value(t, value)
    local count = 0
    
    repeat
        local i = get_index_by_value(t, value)
        if i then
            table.remove(t, i)
            count = count + 1
        end
    until (not i)
    
    return count
end

function handle_booltoggle_arg(arg, orig)
    if arg == 't' then
        return not orig, true
    elseif arg == 'on' then
        return true, true
    elseif arg == 'off' then
        return false, true
    end
    
    return orig, false
end
