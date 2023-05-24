_addon.name = 'EraMobDrops'
_addon.author = 'DiscipleOfEris'
_addon.version = '1.6.2'
_addon.commands = {'mobdrops', 'drops'}

config = require('config')
texts = require('texts')
require('tables')
require('strings')
res = require('resources')
require('logger')
require('sqlite3')

defaults = {}
defaults.header = "${mob_name} (TH: ${TH})"
defaults.subheader = "(Lv.${lvl}, Respawn: ${respawn})"
defaults.footer = ""
defaults.noDrops = "No Drops"
defaults.pageSize = 10
defaults.scrollSize = 1
defaults.scrollInvert = false
defaults.scrollHeaders = false
defaults.noDropsHideHeaders = false
defaults.maxTH = 4
defaults.verbose = true
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

zones = res.zones
items = res.items

local mobKeys = {'mob_id', 'name', 'iname', 'zone_id', 'drop_id', 'respawn', 'lvl_min', 'lvl_max'}
local dropKeys = {'drop_id', 'drop_type', 'group_id', 'group_rate', 'item_id', 'item_rate'}

local DROP_TYPE = { NORMAL=0x0, GROUPED=0x1, STEAL=0x2, DESPOIL=0x4 }
local MOUSE =
{
    MOUSEMOVE   = 0,
    LBUTTONDOWN = 1,
    LBUTTONUP   = 2,
    RBUTTONDOWN = 4,
    RBUTTONUP   = 5,
    MBUTTONDOWN = 7,
    MBUTTONUP   = 8,
    MOUSEWHEEL  = 10,
}
local CLICK_DISTANCE = 2

local state =
{
    TH_lvl         = 0,
    scroll         = 0,
    scroll_max     = 0,
    prev_TH_lvl    = 0,
    prev_target_id = nil,
    prev_scroll    = 0,
    should_update  = false,
    prevMouse      = nil,
}

windower.register_event('load',function()
  db = sqlite3.open(windower.addon_path..'/mobs_drops.db', sqlite3.OPEN_READONLY)
end)

windower.register_event('unload', function()
  db:close()
end)

windower.register_event('mouse', function(id, x, y, delta, blocked)
  -- Exit if we're just moving the mouse (drag+drop handled by text object).
  if id == MOUSE.MOUSEMOVE then return false end
  
  -- Exit if the mouse is not inside the text box
  if not box:hover(x, y) then return false end

  local mouse = {x=x, y=y, id=id}
    
  if id == MOUSE.LBUTTONDOWN or id == MOUSE.RBUTTONDOWN or id == MOUSE.MBUTTONDOWN then
    state.prevMouse = mouse
    return true
  elseif state.prevMouse and id == state.prevMouse.id + 1 and distanceWithin(mouse, state.prevMouse, CLICK_DISTANCE) then
    local success = setTH(state.TH_lvl + (id == MOUSE.LBUTTONUP and 1 or -1))
    if success and settings.verbose then
      log('Setting TH level: '..tostring(state.TH_lvl))
    end
    return true
  elseif delta ~= 0 then
    doScroll(delta > 0 and -1 or 1)
    return true
  end
  
  return false
end)

windower.register_event('prerender', function()
  local player = windower.ffxi.get_player()
  local target = windower.ffxi.get_mob_by_target('st') or windower.ffxi.get_mob_by_target('t') or player
  local target_id = target and target.id
  
  if not state.should_update and target_id == state.prev_target_id and state.TH_lvl == state.prev_TH_lvl and state.scroll == state.prev_scroll then return end
  if target_id ~= state.prev_target_id then state.scroll = 0 end
  
  state.prev_target_id = target_id
  state.prev_TH_lvl = state.TH_lvl
  state.prev_scroll = state.scroll
  state.should_update = false
  
  local info = getTargetInfo(target)
  updateInfo(info)
end)

windower.register_event('addon command', function(command, ...)
  args = L{...}
  command = command:lower()
  
  if command == 'help' or not command then
    
  elseif command == "item" then
    name = strip(windower.convert_auto_trans(args:concat(' ')))
    item = items:with('en', function(val)
      if name == strip(val) then return true end
    end)
    if item == nil then
      item = items:with('enl', function(val)
        if name == strip(val) then return true end
      end)
    end
    
    if item == nil then
      log('Could not find an item with the name: '..name)
      return
    end
    
    log(windower.to_shift_jis('Searching for mobs that drop: '..item.en))
    
    drops = dbGetDropsWithItem(item.id)
    drop_ids = T{}
    mobsProcessed = T{}
    for _, drop in pairs(drops) do drop_ids:insert(drop.drop_id) end
    mobs = dbGetMobsWithDrops(drop_ids)
    for _, mob in pairs(mobs) do
      tmp = {}
      for _, drop in pairs(drops) do
        if mob.drop_id == drop.drop_id then
          if testflag(drop.drop_type, DROP_TYPE.STEAL) then
            table.insert(tmp, 'Steal')
          else
            table.insert(tmp, string.format('%.1f%%', drop.item_rate/10))
          end
        end
      end
      mob.drops = table.concat(tmp, ', ')
      mob.lvl = getLevelStr(mob)
      
      found = false
      for _, mobProcessed in pairs(mobsProcessed) do
        if mobProcessed.zone_id == mob.zone_id and mobProcessed.mob_name == mob.mob_name and mobProcessed.drops == mob.drops and mobProcessed.lvl == mob.lvl then
          found = true
          mobProcessed.count = mobProcessed.count + 1
          break
        end
      end
      if not found then
        mobsProcessed:insert({zone_id=mob.zone_id, mob_name=mob.mob_name, drops=mob.drops, lvl=mob.lvl, count=1})
      end
    end
    
    table.sort(mobsProcessed, function(a, b)
      return a.zone_id < b.zone_id
    end)
    
    for _, mobProcessed in pairs(mobsProcessed) do
      log('%s: %s %s (Lv.%s): %s':format(zones[mobProcessed.zone_id].en, mobProcessed.count, mobProcessed.mob_name, mobProcessed.lvl, mobProcessed.drops))
    end
  elseif command == "mob" then
    local name = strip(windower.convert_auto_trans(args:concat(' ')))
    
    local mobs = dbGetMobsWithName(name)
    local drop_ids = T{}
    local mobsProcessed = T{}
    for _, mob in ipairs(mobs) do
      mob.lvl = getLevelStr(mob)

      local found = false
      for _, row in ipairs(mobsProcessed) do
        if row.zone_id == mob.zone_id and row.mob_name == mob.mob_name and row.drop_id == mob.drop_id and row.lvl == mob.lvl then
          found = true
          row.count = row.count + 1
          break
        end
      end
      if not found then
        mobsProcessed:insert({mob_name=mob.mob_name, zone_id=mob.zone_id, drop_id=mob.drop_id, lvl=mob.lvl, count=1})
        if not drop_ids:contains(mob.drop_id) then drop_ids:insert(mob.drop_id) end
      end
    end
    
    for _, drop_id in ipairs(drop_ids) do
      local drops = dbGetDrops(drop_id)
      local lines = T{}
      lines:insert('')

      for _, drop in ipairs(drops.steals) do
        drop.item_name = items[drop.item_id].en
        lines:insert('  %s: Steal':format(drop.item_name))
      end

      for _, drop in ipairs(drops.items) do
        drop.item_name = items[drop.item_id].en
        lines:insert('  %s: %.1f%%':format(drop.item_name, drop.item_rate / 10))

        if state.TH_lvl > 0 then
          lines[#lines] = lines[#lines] .. ' (TH%d: %.1f%%)':format(state.TH_lvl, applyTH(drop.item_rate) / 10)
        end
      end

      for i, group in ipairs(drops.groups) do
        lines:insert('  Group %d: %.1f%%':format(i, group.group_rate / 10))

        if state.TH_lvl > 0 then
          lines[#lines] = lines[#lines] ..  ' (TH%d: %.1f%%)':format(state.TH_lvl, applyTH(group.group_rate) / 10)
        end

        for _, drop in ipairs(group.items) do
          drop.item_name = items[drop.item_id].en
          lines:insert('    %s %.1f%%':format(drop.item_name, drop.item_rate / 10))
        end
      end

      local dropStr = lines:concat('\n')
      for _, mob in ipairs(mobsProcessed) do
        if mob.drop_id == drop_id then
          mob.drops = drops
          mob.dropStr = dropStr
        end
      end
    end
    
    if #mobsProcessed == 0 then
      log('No mobs found with that name.')
    else
      log('Results for %s:':format(mobsProcessed[1].mob_name))
    end
    
    for _, mob in ipairs(mobsProcessed) do
      log('%s (%d %s Lv.%s): %s':format(zones[mob.zone_id].en, mob.count, mob.mob_name, mob.lvl, mob.dropStr))
    end
  elseif command == "th+" then
    if setTH(state.TH_lvl + 1) then log('Setting TH level: '..tostring(state.TH_lvl)) end
  elseif command == "th-" then
    if setTH(state.TH_lvl - 1) then log('Setting TH level: '..tostring(state.TH_lvl)) end
  elseif command == "page" or command == "pagesize" then
    settings.pageSize = tonumber(args[1])
    config.save(settings)
    state.should_update = true
  end
end)

function getTargetInfo(target)
  if not target then return nil end

  if target.index < 1024 then
    local zone_id = windower.ffxi.get_info().zone
    local mob, drops = getMobInfo(target, zone_id)
    
    if not mob then return nil end
    
    return {
      mob = mob,
      drops = drops,
    }
  end
end

function getMobInfo(target, zone_id)
  if not db:isopen() then return end
  
  local idQuery = 'SELECT * FROM mobs WHERE mob_id='..target.id
  for mob in db:nrows(idQuery) do
    return mob, dbGetDrops(mob.drop_id)
  end
  
  return nil
end

function updateInfo(info)
  if not info then
    box:text('')
    box:visible(false)
    return
  end
  
  local mob = info.mob
  local drops = info.drops
  local steal_lines = T{}
  local lines = T{}
  
  for _, steal in ipairs(drops.steals) do
    steal_lines:insert(items[steal.item_id].en..': Steal')
  end
  
  for _, item in ipairs(drops.items) do
    local rate = applyTH(item.item_rate)
    lines:insert(items[item.item_id].en..string.format(': %.1f%%', rate / 10))
  end
  
  for i, group in ipairs(drops.groups) do
    lines:insert('Group %d (%.1f%%):':format(i, applyTH(group.group_rate) / 10))

    for _, item in ipairs(group.items) do
      lines:insert('  %s: %.1f%%':format(items[item.item_id].en, item.item_rate / 10))
    end
  end
  
  local str = ""
  
  lines = steal_lines:extend(lines)
  dropCount = #lines
  maxWidth = math.max(1, --[[#settings.header, #settings.subheader, #settings.footer, ]]table.reduce(lines, function(a, b)
    if type(a) == 'number' then return math.max(a, #b)
    else return math.max(#a, #b) end
  end, 1))
  state.scroll_max = math.max(0, #lines - settings.pageSize)
  
  if settings.scrollHeaders then
    if #settings.subheader > 0 then lines:insert(1, settings.subheader) end
    if #settings.header > 0 then lines:insert(1, settings.header) end
    if #settings.footer > 0 then lines:insert(settings.footer) end
    lines = lines:slice(state.scroll+1, state.scroll + settings.pageSize)
    if state.scroll > 0 then
      lines[1] = lines[1]:rpad(' ', maxWidth).." ▲"
    end
    if state.scroll_max > 0 and state.scroll < state.scroll_max then
      lines[#lines] = lines[#lines]:rpad(' ', maxWidth).." ▼"
    end
  else
    lines = lines:slice(state.scroll+1, state.scroll + settings.pageSize)
    if state.scroll > 0 then
      lines[1] = lines[1]:rpad(' ', maxWidth).." ▲"
    end
    if state.scroll_max > 0 and state.scroll < state.scroll_max then
      lines[#lines] = lines[#lines]:rpad(' ', maxWidth).." ▼"
    end
    if #settings.subheader > 0 then lines:insert(1, settings.subheader) end
    if #settings.header > 0 then lines:insert(1, settings.header) end
    if #settings.footer > 0 then lines:insert(settings.footer) end
  end
  
  if dropCount > 0 then
    str = lines:concat('\n')
  else
    if settings.noDropsHideHeaders then str = settings.noDrops
    else str = lines:concat('\n')..'\n'..settings.noDrops end
  end
  
  box:text(str)
  
  local update = table.update(mob, {
    TH = state.TH_lvl,
    name = mob.mob_name,
    lvl = getLevelStr(mob),
    respawn = getRespawnStr(mob)
  })
  
  box:update(update)
  box:visible(true)
end

function dbGetDrops(drop_id)
  local query = 'SELECT * FROM drops WHERE drop_id='..drop_id
  local drops = {steals={}, items={}, groups={}}
  for row in db:nrows(query) do
    if row.drop_type == 1 then
      while row.group_id > #drops.groups do
        table.insert(drops.groups, {group_rate=1000, items={}})
      end
      local group = drops.groups[row.group_id]
      
      group.group_rate = row.group_rate
      table.insert(group.items, row)
    elseif row.drop_type == 0 then
      table.insert(drops.items, row)
    elseif row.drop_type == 2 then
      table.insert(drops.steals, row)
    end
  end
  
  -- Normalize group item_rates so they don't always need to sum to 1000.
  for _, group in ipairs(drops.groups) do
    local total_rate = 0
    for _, item in ipairs(group.items) do
      total_rate = total_rate + item.item_rate
    end
    
    for _, item in ipairs(group.items) do
      if item.item_rate > 0 then
        item.item_rate = item.item_rate * (1000 / total_rate)
      end
    end
  end
  return drops
end

function dbGetDropsWithItem(item_id)
  local query = 'SELECT * FROM drops WHERE item_id='..item_id
  local drops = {}
  for row in db:nrows(query) do
    if row.drop_type == 2 then
      local group = dbGetDropGroup(row.drop_id, row.group_id, false)
      
      local total_rate = 0
      for _, item in ipairs(group.items) do
        total_rate = total_rate + item.item_rate
      end
      
      if row.item_rate > 0 then
        row.item_rate = row.item_rate * (1000 / total_rate)
      end
    end
    table.insert(drops, row)
  end
  
  return drops
end

function dbGetDropGroup(drop_id, group_id, normalize)
  local query = 'SELECT * FROM drops WHERE drop_id='..drop_id..' AND group_id='..group_id
  local group = {group_rate=1000, items={}}
  for row in db:nrows(query) do
    group.group_rate = row.group_rate
    table.insert(group.items, row)
  end
  
  if not normalize then return group end
  
  -- Normalize group item_rates so they don't always need to sum to 1000.
  local total_rate = 0
  for i, item in ipairs(group.items) do
    total_rate = total_rate + item.item_rate
  end
  
  for _, item in ipairs(group.items) do
    if item.item_rate > 0 then
      item.item_rate = item.item_rate * (1000 / total_rate)
    end
  end
  
  return group
end

function dbGetMobsWithDrops(drop_ids)
  local query = 'SELECT * FROM mobs WHERE drop_id IN ('..table.concat(drop_ids, ',')..')'
  mobs = {}
  for row in db:nrows(query) do
    table.insert(mobs, row)
  end
  
  return mobs
end

function dbGetMobsWithName(name)
  name = strip(name)
  local query = 'SELECT * FROM mobs WHERE mob_iname="'..name..'" ORDER BY zone_id, drop_id'
  local mobs = {}
  for row in db:nrows(query) do
    table.insert(mobs, row)
  end
  
  return mobs
end

function applyTH(item_rate)
  rate = math.min(1, math.max(0, item_rate/1000))
  
  if state.TH_lvl > 2 then
    rate = rate + (state.TH_lvl-2)*0.01
  end
  
  if state.TH_lvl > 1 then
    rate = 1-(1-rate)^3
  elseif state.TH_lvl > 0 then
    rate = 1-(1-rate)^2
  end
  
  return math.min(math.floor(rate*1000),1000)
end

function setTH(newTH)
  state.TH_lvl = newTH
  
  if state.TH_lvl < 0 then
    state.TH_lvl = 0
    return false
  elseif state.TH_lvl > settings.maxTH then
    state.TH_lvl = settings.maxTH
    return false
  end
  
  return true
end

function doScroll(dir)
  if dir < 0 then dir = -1
  else dir = 1 end
  
  if settings.scrollInvert then dir = dir * -1 end
  
  state.scroll = state.scroll + settings.scrollSize * dir
  
  if state.scroll > state.scroll_max then
    state.scroll = state.scroll_max
    return false
  elseif state.scroll < 0 then
    state.scroll = 0
    return false
  end
  
  return true
end

function values(t, keys)
  list = {}
  
  if type(keys) == 'table' then
    for i=1, #keys do
      table.insert(list, t[keys[i]])
    end
  else
    for k, v in pairs(t) do
      table.insert(list, v)
    end
  end
  
  return list
end

function testflag(set, flag)
  return set % (2*flag) >= flag
end

-- Return an associative array that takes two lists and uses the first for its keys and the second for its values.
function kvZip(keys, values)
  len = math.min(#keys, #values)
  t = {}
  
  for i=1, len do
    t[keys[i]] = values[i]
  end
  
  return t
end

function distanceWithin(A, B, within)
    local dX = B.x - A.x
    local dY = B.y - A.y
    
    return (dX * dX + dY * dY) <= within * within
end


function strip(str)
  return str:lower():gsub(' ',''):gsub('-',''):gsub('%.',''):gsub('\'',''):gsub(':',''):gsub('"',''):gsub('♂','m'):gsub('♀','f'):gsub('%(',''):gsub('%)',''):gsub('♪','')
end

function getLevelStr(mob)
  if not mob or not mob.lvl_min then return '?' end
  local str = tostring(mob.lvl_min)
  if mob.lvl_max > mob.lvl_min then str = str..'-'..tostring(mob.lvl_max) end
  return str
end

function getRespawnStr(mob)
    local respawn = mob.respawn
    
    respawn = respawn and respawn / 60 or 0
    if respawn > 60 then
        respawn = string.format('%.1fh', respawn / 60)
    else
        respawn = string.format('%.1fm', respawn)
    end
    
    return respawn
end
