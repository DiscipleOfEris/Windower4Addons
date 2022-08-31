_addon.name = 'FastFollow'
_addon.author = 'DiscipleOfEris'
_addon.version = '1.1.0'
_addon.commands = {'fastfollow', 'ffo'}

-- TODO: pause on ranged attacks.

require('strings')
require('tables')
require('sets')
require('coroutine')
packets = require('packets')
res = require('resources')
spells = require('spell_cast_times')
items = res.items
config = require('config')
texts = require('texts')
require('logger')

defaults = {}
defaults.show = false
defaults.min = 0.5
defaults.zone_poke = 0.2
defaults.display = {}
defaults.display.pos = {}
defaults.display.pos.x = 0
defaults.display.pos.y = 0
defaults.display.bg = {}
defaults.display.bg.red = 0
defaults.display.bg.green = 0
defaults.display.bg.blue = 0
defaults.display.bg.alpha = 102
defaults.display.text = {}
defaults.display.text.font = 'Consolas'
defaults.display.text.red = 255
defaults.display.text.green = 255
defaults.display.text.blue = 255
defaults.display.text.alpha = 255
defaults.display.text.size = 10

settings = config.load(defaults)
box = texts.new("", settings.display, settings)

follow_me = 0
following = false
target = nil
last_target = nil
min_dist = settings.min^2
max_dist = 50.0^2
spell_dist = 20.4^2
repeated = false
last_self = nil
zone_walk_duration = settings.zone_poke
zone_walk_end = 0
zoned = false
running = false
casting = nil
pause_delay = 0.1
pause_dismount_delay = 0.5
pauseon = S{'spell','item','dismount'}
co = nil

track_info = T{}

windower.register_event('addon command', function(command, ...)
  command = command and command:lower() or nil
  args = T{...}
  
  if not command then
    log('Provide a name to follow, or "me" to make others follow you.')
    log('Stop following with "stop" on a single character, or "stopall" on all characters.')
    log('Can configure auto-pausing with pauseon|pausedelay commands.')
  elseif command == 'followme' or command == 'me' then
    self = windower.ffxi.get_mob_by_target('me')
    if not self and not repeated then
      repeated = true
      windower.send_command('@wait 1; ffo followme')
      return
    end
    
    repeated = false
    windower.send_ipc_message('follow '..self.name)
    windower.send_ipc_message('track '..(settings.show and 'on' or 'off'))
  elseif command == 'stop' then
    following = false
  elseif command == 'stopall' then
    follow_me = 0
    following = false
    windower.send_ipc_message('stop')
  elseif command == 'follow' then
    if #args == 0 then
      return windower.add_to_chat(0, 'FastFollow: You must provide a player name to follow.')
    end
    casting = nil
    following = args[1]:lower()
    windower.send_ipc_message('following '..following)
    windower.ffxi.follow()
  elseif command == 'pauseon' then
    if #args == 0 then
      return windower.add_to_chat(0, 'FastFollow: To change pausing behavior, provide spell|item|any to pauseon.')
    end
    
    local arg = args[1]:lower()
    if arg == 'spell' or arg == 'any' then
      if pauseon:contains('spell') then pauseon:remove('spell')
      else pauseon:add('spell') end
    end
    if arg == 'item' or arg == 'any' then
      if pauseon:contains('item') then pauseon:remove('item')
      else pauseon:add('item') end
    end
    if arg == 'dismount' or arg == 'any' then
      if pauseon:contains('dismount') then pauseon:remove('dismount')
      else pauseon:add('dismount') end
    end
    
    windower.add_to_chat(0, 'FastFollow: Pausing on Spell: '..tostring(pauseon:contains('spell'))..', Item: '..tostring(pauseon:contains('item')))
    -- TODO: Save settings.
  elseif command == 'pausedelay' then
    pause_delay = tonumber(args[1])
    windower.add_to_chat(0, 'FastFollow: Setting item/spell pause delay to '..tostring(pause_delay)..' seconds.')
  elseif command == 'info' then
    if not args[1] then
      settings.show = not settings.show
    elseif args[1] == 'on' then
      settings.show = true
    elseif args[2] == 'off' then
      settings.show = false
    end
    
    windower.send_ipc_message('track '..(settings.show and 'on' or 'off'))
    
    config.save(settings)
  elseif command == 'min' then
    local dist = tonumber(args[1])
    if not dist then return end
    
    dist = math.min(math.max(0.2, dist), 10)
    
    settings.min = dist
    min_dist = settings.min^2
    config.save(settings)
  elseif command == 'zone' then
    local dur = tonumber(args[1])
    if not dur then return end
    
    dur = math.min(math.max(0, dur), 10)
    
    settings.zone_poke = dur
    zone_walk_duration = dur
    config.save(settings)
  elseif command then
    windower.send_command('ffo follow '..command)
  end
end)

windower.register_event('ipc message', function(msgStr)
  args = msgStr:lower():split(' ')
  
  if args[1] == 'stop' then
    follow_me = 0
    following = false
    tracking = false
  elseif args[1] == 'follow' then
    if following then windower.send_ipc_message('stopfollowing '..following) end
    following = args[2]
    casting = nil
    target_pos = nil
    last_target_pos = nil
    windower.send_ipc_message('following '..following)
    windower.ffxi.follow()
  elseif args[1] == 'following' then
    self = windower.ffxi.get_player()
    if not self or self.name:lower() ~= args[2] then return end
    follow_me = follow_me + 1
  elseif args[1] == 'stopfollowing' then
    self = windower.ffxi.get_player()
    if not self or self.name:lower() ~= args[2] then return end
    follow_me = math.max(follow_me - 1, 0)
  elseif args[1] == 'update' then
    local pos = {x=tonumber(args[4]), y=tonumber(args[5])}
    track_info[args[2]] = pos
    
    if not following or args[2] ~= following then return end
    
    zoned = false
    target = {x=pos.x, y=pos.y, zone=tonumber(args[3])}
    
    if not last_target then last_target = target end
    
     if target.zone ~= -1 and (target.x ~= last_target.x or target.y ~= last_target.y or target.zone ~= last_target.zone) then
      last_target = target
    end
  elseif args[1] == 'track' then
    tracking = args[2] == 'on' and true or false
  end
end)

windower.register_event('prerender', function()
  updateInfo()
  
  if not follow_me and not following then return end
  
  if follow_me > 0 then
    local self = windower.ffxi.get_mob_by_target('me')
    local info = windower.ffxi.get_info()
    
    if not self and last_self then
      windower.send_ipc_message('update '..last_self.name..' -1 0 0')
    end
    
    last_self = self
    
    if not self or not info then return end
    
    args = T{'update', self.name , info.zone, self.x, self.y}
    windower.send_ipc_message(args:concat(' '))
  elseif following then
    local self = windower.ffxi.get_mob_by_target('me')
    local info = windower.ffxi.get_info()
    
    if not self or not info then return end
    
    if tracking then
      if target and tracking then windower.send_ipc_message('update '..following..' '..target.zone..' '..target.x..' '..target.y) end
      windower.send_ipc_message('update '..self.name..' '..info.zone..' '..self.x..' '..self.y)
    end
    
    if casting then
      windower.ffxi.run(false)
      running = false
      return
    end
    if not target and running then
      windower.ffxi.run(false)
      running = false
      return
    end
    
    if os.time() < zone_walk_end then return end
    if not zoned and target.zone == -1 and info.zone == last_target.zone then
      zone_walk_end = os.time() + zone_walk_duration
      zoned = true
      distSq = distanceSquared(last_target, self)
      len = math.sqrt(distSq)
      windower.ffxi.run(last_target.x - self.x, last_target.y - self.y)
      running = true
      return
    end
    
    distSq = distanceSquared(target, self)
    len = math.sqrt(distSq)
    if len < 1 then len = 1 end
    
    if target.zone == info.zone and distSq > min_dist and distSq < max_dist then
      windower.ffxi.run((target.x - self.x)/len, (target.y - self.y)/len)
      running = true
    elseif target.zone == info.zone and distSq <= min_dist then
      windower.ffxi.run(false)
      running = true
    elseif running then
      windower.ffxi.run(false)
      running = false
    end
  end
end)

local PACKET_ID = { ACTION = 0x01A, USE_ITEM = 0x037 }
local PACKET_ACTION_CATEGORY = { MAGIC_CAST = 0x03, DISMOUNT = 0x12 }
local EVENT_ACTION_CATEGORY = { SPELL_FINISH = 4, ITEM_FINISH = 5, SPELL_BEGIN_OR_INTERRUPT = 8, ITEM_BEGIN_OR_INTERRUPT = 9 }
local EVENT_ACTION_PARAM = { BEGIN = 24931, INTERRUPT = 28787 }

windower.register_event('outgoing chunk', function(id, original, modified, injected, blocked)
  if blocked or casting or (id ~= PACKET_ID.ACTION and id ~= PACKET_ID.USE_ITEM) then return end
  
  if id == PACKET_ID.ACTION then
    if not pauseon:contains('spell') and not pauseon:contains('dismount') then return end
    
    local packet = packets.parse('outgoing', modified)
    if packet.Category ~= PACKET_ACTION_CATEGORY.MAGIC_CAST and packet.CATEGORY ~= PACKET_ACTION_CATEGORY.DISMOUNT then return end
    if packet.Category == PACKET_ACTION_CATEGORY.MAGIC_CAST and not pauseon:contains('spell') then return end
    if packet.Category == PACKET_ACTION_CATEGORY.DISMOUNT and not pauseon:contains('dismount') then return end
    
    local cast_time = os.time()
    casting = cast_time
    if pause_delay <= 0 then return end
    
    coroutine.schedule(function()
      packets.inject(packet)
    end, pause_delay)
    
    local delay = pause_dismount_delay
    if packet.Category == PACKET_ACTION_CATEGORY.MAGIC_CAST then
      -- TODO: Maybe get a little smarter, such as checking if the target is within range, we have sufficient mp, etc.
      local spell = spells[packet.Param]
      delay = spell.cast_time + 0.5
    end
    
    if co then coroutine.close(co) end
    co = coroutine.schedule(function()
      if casting ~= cast_time then return end
      casting = false
    end, pause_delay+delay)
    
    return true
  elseif id == PACKET_ID.USE_ITEM then
    if not pauseon:contains('item') then return end
    
    casting = os.time()
    if pause_delay <= 0 then return end
    
    local packet = packets.parse('outgoing', modified)
    
    local item = items[packet.Param]
    if not item or not item.cast_time then return end
    
    local cast_time = os.time()
    casting = cast_time
    
    coroutine.schedule(function()
      packets.inject(packets.parse('outgoing', modified))
    end, pause_delay)
    
    if co then coroutine.close(co) end
    co = coroutine.schedule(function()
      if casting ~= cast_time then return end
      casting = false
    end, pause_delay+item.cast_time)
    
    return true
  end
end)

windower.register_event('action', function(action)
  local player = windower.ffxi.get_player()
  if not player or action.actor_id ~= player.id then return end

  if action.category == EVENT_ACTION_CATEGORY.SPELL_FINISH or (action.category == EVENT_ACTION_CATEGORY.SPELL_BEGIN_OR_INTERRUPT and action.param == EVENT_ACTION_PARAM.INTERRUPT) then
    casting = false
  elseif action.category == EVENT_ACTION_CATEGORY.ITEM_FINISH or (action.category == EVENT_ACTION_CATEGORY.ITEM_BEGIN_OR_INTERRUPT and action.param == EVENT_ACTION_PARAM.INTERRUPT) then
    casting = false
  end
end)

function updateInfo()
  box:visible(settings.show)
  
  if not settings.show then return end
  
  local self = windower.ffxi.get_mob_by_target('me')
  
  if not self then
    box:visible(false)
    return
  end
  
  lines = T{string.format('me 0.00')} -- 'me 0.00 (%.3f %.3f)', self.x, self.y)}
  for char,pos in pairs(track_info) do
    local dist = math.sqrt(distanceSquared(self, pos))
    lines:insert(string.format('%s %.2f', char, dist)) -- '%s %.2f (%.3f %.3f)', char, dist, pos.x, pos.y))
  end
  
  local maxWidth = math.max(1, table.reduce(lines, function(a, b) return math.max(a, #b) end, '1'))
  for i,line in ipairs(lines) do lines[i] = lines[i]:lpad(' ', maxWidth) end
  box:text(lines:concat('\n'))
end

function distanceSquared(A, B)
  local dx = B.x-A.x
  local dy = B.y-A.y
  return dx*dx + dy*dy
end