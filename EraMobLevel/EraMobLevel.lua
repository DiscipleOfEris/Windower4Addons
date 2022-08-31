_addon.name = 'EraMobLevel'
_addon.author = 'DiscipleOfEris'
_addon.version = '1.2.2'
_addon.commands = {'moblevel', 'level'}

-- Stores the level of mobs from widescan, and then displays the level of your current target.

require('tables')
require('sets')
packets = require('packets')
texts = require('texts')
require('coroutine')
config = require('config')
zones = require('resources').zones

require('statics')

PACKET_WIDESCAN = 0x0F4
SPAWN_TYPE_ENEMY = 16

level = texts.new('${level}', {
    pos = {
        x = -18,
    },
    bg = {
        alpha = 63, red=0, green=0, blue=0,
    },
    flags = {
        right = true,
        bottom = true,
        bold = true,
        draggable = false,
        italic = true,
    },
    text = {
        size = 10,
        alpha = 185,
        red = 255,
        green = 255,
        blue = 255,
    },
})

target_idx_table = T{}
scanning = 0
max_scan_wait = 15
co = nil

defaults = {}
defaults.auto = true
defaults.interval = 300
--defaults.bg = { visible=false }
defaults.bg = { alpha=63, red=0, green=0, blue=0 }
defaults.text = { size=10, alpha=185 }
defaults.ranks = {}
defaults.ranks.tooweak = { text={red=160, blue=160, green=160} }
defaults.ranks.easyprey = { text={red=40, blue=240, green=128} }
defaults.ranks.decentchallenge = { text={red=128, blue=128, green=255} }
defaults.ranks.evenmatch = { text={red=255, blue=255, green=255} }
defaults.ranks.tough = { text={red=240, blue=240, green=128} }
defaults.ranks.verytough = { text={red=240, blue=160, green=80} }
defaults.ranks.incrediblytough = { text={red=255, blue=80, green=80} }

settings = config.load(defaults)

windower.register_event('load', function()
  if settings.auto then
    routine()
  end
end)

windower.register_event('incoming chunk', function(id, original, modified, injected, blocked)
  if id ~= PACKET_WIDESCAN then return end
  
  scanning = 0
  packet = packets.parse('incoming', original)
  target_idx_table[packet.Index] = {lvl=packet.Level, expires=os.time()+settings.interval}
end)

windower.register_event('prerender', function()
  local target = windower.ffxi.get_mob_by_target('st') or windower.ffxi.get_mob_by_target('t')
  
  if target == nil or target.index > 1024 then
    level:hide()
    return
  end
  
  if not target_idx_table:containskey(target.index) then
    if settings.auto then scan() end
    level:hide()
    return
  end
  
  t = target_idx_table[target.index]
  if t.lvl <= 0 or os.time() >= t.expires then
    if settings.auto then scan() end
    level:hide()
    return
  end
    
  local party_info = windower.ffxi.get_party_info()

  -- Adjust position for party member count
  level:pos_y(-76 - 20 * party_info.party1_count)
  
  local player = windower.ffxi.get_player()
  local aggro = canAggro(t.lvl, player.main_job_level)
  
  apply_settings(level, getSettingsByLevel(t.lvl, player.main_job_level), settings)
  level:bold(aggro)
  level:size(aggro and 11 or 10)
  level:update({level=t.lvl})
  level:show()
end)

windower.register_event('addon command', function(command, ...)
  args = L{...}
  if not command then
    
  elseif command == 'ws' or command == 'scan' then
    scan()
  elseif command == 'auto' or command == 'autoscan' then
    settings.auto = not settings.auto
    config.save(settings)
    
    if not settings.auto then
      if co then
        coroutine.close(co)
        co = nil
      end
    else
      routine()
    end
  elseif command == 'interval' then
    if not args[1] then
      windower.add_to_chat(0, 'MobLevel: Current autoscanning interval is '..settings.interval..'s.')
      return
    end
    local interval = tonumber(args[1])
    
    if interval == 0 and co then
        coroutine.close(co)
        co = nil
    elseif interval > 0 then
        if co then
            coroutine.close(co)
        end
        
        if settings.auto then
            co = coroutine.schedule(routine, interval)
        end
    end
    
    settings.interval = interval
    config.save(settings)
  elseif challenges:contains(command) or initials[command] then
    if initials[command] then command = initials[command] end
    local level = 0
    if args[1] then level = tonumber(args[1])
    else level = windower.ffxi.get_player().main_job_level end
    
    local low, high = getLevelByChallenge(command, level)
    windower.add_to_chat(0, 'MobLevel: '..command..': '..low..'-'..high..'.')
  elseif command == 'aggro' then
    local level = 0
    if args[1] then level = tonumber(args[1])
    else level = windower.ffxi.get_player().main_job_level end
    
    local low = getMinAggro(level)
    windower.add_to_chat(0, 'MobLevel: Aggro range is '..low..'-'..(math.huge)..'.')
  end
end)

function routine()
  scan()
  
  if settings.auto and settings.interval > 0 then
    if co then
        coroutine.close(co)
    end
    
    co = coroutine.schedule(routine, settings.interval)
  end
end

function scan()
  if scanning + max_scan_wait > os.time() then return end
  
  -- Check if in zone
  local info = windower.ffxi.get_info()
  local self = windower.ffxi.get_mob_by_target('me')
  if not self or not info or invalid_zones:contains(zones[info.zone].en) then return end
  
  scanning = os.time()
  
  packet = packets.new('outgoing', PACKET_WIDESCAN, {
    ['Flags'] = 1,
    ['_unknown1'] = 0,
    ['_unknown2'] = 0,
  })
  packets.inject(packet)
end

function getSettingsByLevel(mobLevel, playerLevel)
  return settings.ranks[getChallengeByLevel(mobLevel, playerLevel)]
end

function getChallengeByLevel(mobLevel, playerLevel)
  if mobLevel == playerLevel then return 'evenmatch' end

  local xp = getExp(mobLevel, playerLevel)

  if xp == 0 then return 'tooweak' end

  if     xp >= expRanges.incrediblytough[1] then return 'incrediblytough'
  elseif xp >= expRanges.verytough[1]       then return 'verytough'
  elseif xp >= expRanges.tough[1]           then return 'tough'
  elseif xp >= expRanges.decentchallenge[1] then return 'decentchallenge'
  elseif xp >= expRanges.easyprey[1]        then return 'easyprey' end
end

function getLevelByChallenge(challenge, playerLevel)
  if not challenges:contains(challenge) then return false end
  if challenge == 'evenmatch' then return playerLevel,playerLevel end
  
  local xpMin = expRanges[challenge][1]
  local xpMax = expRanges[challenge][2]
  
  local xpCol = math.floor((playerLevel-1)/5)+1
  local diffMax = 15
  local diffMin = -34

  for diff=-34,15,1 do
    local xp = expTable[diff][xpCol]
    if xp > xpMax then break end
    diffMax = diff
  end
  for diff=15,-34,-1 do
    local xp = expTable[diff][xpCol]
    if xp < xpMin then break end
    diffMin = diff
  end

  local lvlMin = playerLevel+diffMin
  local lvlMax = playerLevel+diffMax

  if lvlMax < 1 then return 0,0 end
  if lvlMax == 1 then return 1,1 end
  
  if diffMax == 15 then lvlMax = math.huge end
  if diffMin == -34 then lvlMin = 1 end
  if lvlMin < 1 then lvlMin = 1 end

  return lvlMin,lvlMax
end

function canAggro(mobLevel, playerLevel)
  -- This formula isn't perfect on retail (according to wiki), but it is what DarkstarProject uses.
  return getExp(mobLevel, playerLevel) > 50
end

function getMinAggro(playerLevel)
  local xpCol = math.floor((playerLevel-1)/5)+1
  local diffMin = -34
  for diff=-34,15,1 do
    if expTable[diff][xpCol] > 50 then return clamp(playerLevel+diff, 1, 75) end
  end
end

function getExp(mobLevel, playerLevel)
  local diff = clamp(mobLevel - playerLevel, -34, 15)
  
  return expTable[diff][math.floor((playerLevel-1)/5)+1]
end

function apply_settings(box, settings, default)
    bg = settings.bg and settings.bg.red and settings.bg or default.bg
    bg_alpha = settings.bg and settings.bg.alpha and settings.bg.alpha or default.bg.alpha
    text = settings.text and settings.text.red and settings.text or default.text
    text_alpha = settings.text and settings.text.alpha and settings.text.alpha or default.text.alpha
    
    box:bg_alpha(bg_alpha)
    box:bg_color(bg.red, bg.green, bg.blue)
    box:color(text.red, text.green, text.blue)
    box:alpha(text_alpha)
end

function clamp(value, min, max)
  if     value > max then return max
  elseif value < min then return min
  else                    return value end
end
