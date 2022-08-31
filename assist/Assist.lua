_addon.name = 'Assist'
_addon.author = 'DiscipleOfEris'
_addon.version = '1.1.0'
_addon.command = 'assist'

require('tables')
require('strings')
require('logger')
packets = require('packets')
config = require('config')

defaults = {}
defaults.delock = true

settings = config.load(defaults)

delock_id = nil

PACKET_LOCK_TARGET = 0x058

windower.register_event('addon command', function(command, ...)
  args = L{...}
  if not command or command == 'help' then
    log('Use to set target or tell alts to set their target to you.')
    log('//assist target <id>     : Set your target to the entity specified by <id>.')
    log('//assist me              : Tell all alts to set their target to yours.')
    log('//assist delock [on|off] : Enable/disable delock. Prevents the normal /lockon effect from assist.')
  elseif command == 'target' then
    local target_id = tonumber(args[1])
    if not target_id then return end
    set_target(target_id)
  elseif command == 'me' then
    local target = windower.ffxi.get_mob_by_target('t')
    if target then windower.send_ipc_message('target '..target.id) end
  elseif command == 'delock' then
    if #args == 0 then
        settings.delock = not settings.delock
    elseif args[1] == 'on' then
        settings.delock = true
    elseif args[1] == 'off' then
        settings.delock = false
    else
        log('Assist: invalid argument to delock command. Usage is //assist delock [on|off]')
        return
    end
    
    log('Setting delock to', settings.delock and 'on' or 'off')
    config.save(settings)
  end
end)

windower.register_event('ipc message', function(message)
  args = message:split(' ')
  if args[1] == 'target' then
    local target_id = tonumber(args[2])
    set_target(target_id)
  end
end)

windower.register_event('prerender', function()
  local target = windower.ffxi.get_mob_by_target('t')
  
  if settings.delock and target and target.id == delock_id then
    windower.send_command('@input /lockon')
    delock_id = nil
  end
end)

function set_target(target_id)
  local self = windower.ffxi.get_player()
  local target = windower.ffxi.get_mob_by_id(target_id)
  local current = windower.ffxi.get_mob_by_target('t')
  if not target or (current and target.id == current.id) then return end
  
  if target.index < 512 and settings.delock then
    delock_id = target_id
  end
  
  local packet = packets.new('incoming', PACKET_LOCK_TARGET, {
    ['Player'] = self.id,
    ['Target'] = target.id,
    ['Player Index'] = self.index,
  })
  
  packets.inject(packet)
end
