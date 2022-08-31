_addon.name = 'EraMobDrops'
_addon.author = 'DiscipleOfEris'
_addon.version = '1.6.0'
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
--defaults.Steal = "${item.name}"
defaults.pageSize = 10
defaults.scrollSize = 1
defaults.scrollInvert = false
defaults.scrollHeaders = false
defaults.noDropsHideHeaders = false
defaults.maxTH = 4
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

DROP_TYPE = { NORMAL=0x0, GROUPED=0x1, STEAL=0x2, DESPOIL=0x4 }

TH_lvl = 0
prevMouse = {x=-1,y=-1}
CLICK_DISTANCE = 2.0^2
scroll = 0
scroll_max = 0

prev_TH_lvl = 0
prev_target_id = -1
prev_scroll = 0
should_update = false

windower.register_event('load',function()
  db = sqlite3.open(windower.addon_path..'/mobs_drops.db', sqlite3.OPEN_READONLY)
  
  if not windower.ffxi.get_info().logged_in then return end
  
  local player = windower.ffxi.get_player()
  local target = windower.ffxi.get_mob_by_target('st') or windower.ffxi.get_mob_by_target('t') or player
  local info = getTargetInfo(target)

  updateInfo(info)
end)

windower.register_event('unload', function()
  db:close()
end)

windower.register_event('mouse', function(type, x, y, delta, blocked)
  if not box:hover(x,y) or type == 0 then return end

  mouse = {x=x,y=y}
  clicked = false
  
  --log(tostring(type)..': '..x..','..y..' delta: '..delta..' blocked: '..tostring(blocked))
  
  if type == 1 then
    prevMouse = mouse
  elseif type == 2 and distanceSquared(mouse, prevMouse) < CLICK_DISTANCE then
    -- left clicked
    if setTH(TH_lvl+1) then log('Setting TH level: '..tostring(TH_lvl)) end
    clicked = true
  elseif type == 4 then
    prevMouse = mouse
  elseif type == 5 and distanceSquared(mouse, prevMouse) < CLICK_DISTANCE then
    -- right clicked
    if setTH(TH_lvl-1) then log('Setting TH level: '..tostring(TH_lvl)) end
    clicked = true
  elseif type == 7 then
    prevMouse = mouse
  elseif type == 8 and distanceSquared(mouse, prevMouse) < CLICK_DISTANCE then
    -- middle clicked
    if setTH(TH_lvl-1) then log('Setting TH level: '..tostring(TH_lvl)) end
    clicked = true
  elseif delta > 0 then
    -- scrolled up
    doScroll(-1)
  elseif delta < 0 then
    -- scrolled down
    doScroll(+1)
  end
  
  return true
end)

windower.register_event('prerender', function()
  local player = windower.ffxi.get_player()
  local target = windower.ffxi.get_mob_by_target('st') or windower.ffxi.get_mob_by_target('t') or player
  local target_id = target and target.id or -1
  
  if not should_update and target_id == prev_target_id and TH_lvl == prev_TH_lvl and scroll == prev_scroll then return end
  if target_id ~= prev_target_id then scroll = 0 end
  
  prev_target_id = target_id
  prev_TH_lvl = TH_lvl
  prev_scroll = scroll
  should_update = false
  
  local info = getTargetInfo(target)
  updateInfo(info)
end)

windower.register_event('addon command', function(command, ...)
  args = L{...}
  command = command:lower()
  
  if command == "item" then
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
        mobsProcessed:insert({name=mob.mob_name, zone_id=mob.zone_id, drop_id=mob.drop_id, lvl=mob.lvl, count=1})
        if not drop_ids:contains(mob.drop_id) then drop_ids:insert(mob.drop_id) end
      end
    end
    
    for _, drop_id in ipairs(drop_ids) do
      local drops = dbGetDrops(drop_id)
      local tmp = T{}
      for _, drop in ipairs(drops) do
        drop.item_name = items[drop.item_id].en
        
        if testflag(drop.drop_type, DROP_TYPE.STEAL) then
          tmp:insert('%s (Steal)':format(drop.item_name))
        else
          tmp:insert('%s %.1f%%':format(drop.item_name, drop.item_rate/10))
        end
      end
      
      local dropStr = tmp:concat(', ')
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
      log('%s (%s Lv.%s): %s':format(zones[mob.zone_id].en, mob.count, mob.lvl, mob.dropStr))
    end
  elseif command == "th+" then
    if setTH(TH_lvl+1) then log('Setting TH level: '..tostring(TH_lvl)) end
  elseif command == "th-" then
    if setTH(TH_lvl-1) then log('Setting TH level: '..tostring(TH_lvl)) end
  elseif command == "page" or command == "pagesize" then
    settings.pageSize = tonumber(args[1])
    config.save(settings)
    should_update = true
  end
end)

function getTargetInfo(target)
  local info = {}

  if target == nil then return {type='none'} end
  
  if target.index < 1024 then
    local zone_id = windower.ffxi.get_info().zone
    local mob, drops = getMobInfo(target, zone_id)
    
    if mob then
      info.type = 'mob'
      info.mob = mob
      info.drops = drops
    end
  end
  
  return info
end

function getMobInfo(target, zone_id)
  if not db:isopen() then return end
  
  local mob = false
  local drops = {}
  
  local idQuery = 'SELECT * FROM mobs WHERE mob_id='..target.id..''
  for mobRow in db:nrows(idQuery) do
    mob = mobRow
    drops = dbGetDrops(mob.drop_id)
    break
  end
  
  return mob, drops
end

function updateInfo(info)
  if info.type ~= 'mob' then
    prev_target_id = 0
    box:text('')
    box:visible(false)
    return
  end
  
  local mob = (info and info.mob) and info.mob or {}
  local steal_lines = T{}
  local lines = T{}
  local drops = info and info.drops or {}
  
  for _, steal in ipairs(drops.steals) do
    steal_lines:insert(items[steal.item_id].en..': Steal')
  end
  
  for i, group in ipairs(drops.groups) do
    if group.group_rate > 0 then
      for _, item in ipairs(group.items) do
        if item.item_rate > 0 then
          rate = applyTH(group.group_rate) * item.item_rate / 1000
          lines:insert(i..': '..items[item.item_id].en..string.format(': %.1f%%', rate / 10))
        end
      end
    end
  end
  
  for _, item in ipairs(drops.items) do
    if item.item_rate > 0 then
      rate = applyTH(item.item_rate)
      lines:insert(items[item.item_id].en..string.format(': %.1f%%', rate / 10))
    end
  end
  
  local str = ""
  
  lines = steal_lines:extend(lines)
  dropCount = #lines
  maxWidth = math.max(1, --[[#settings.header, #settings.subheader, #settings.footer, ]]table.reduce(lines, function(a, b)
    if type(a) == 'number' then return math.max(a, #b)
    else return math.max(#a, #b) end
  end, 1))
  scroll_max = math.max(0, #lines - settings.pageSize)
  
  if settings.scrollHeaders then
    if #settings.subheader > 0 then lines:insert(1, settings.subheader) end
    if #settings.header > 0 then lines:insert(1, settings.header) end
    if #settings.footer > 0 then lines:insert(settings.footer) end
    lines = lines:slice(scroll+1, scroll + settings.pageSize)
    if scroll > 0 then
      lines[1] = lines[1]:rpad(' ', maxWidth).." ▲"
    end
    if scroll_max > 0 and scroll < scroll_max then
      lines[#lines] = lines[#lines]:rpad(' ', maxWidth).." ▼"
    end
  else
    lines = lines:slice(scroll+1, scroll + settings.pageSize)
    if scroll > 0 then
      lines[1] = lines[1]:rpad(' ', maxWidth).." ▲"
    end
    if scroll_max > 0 and scroll < scroll_max then
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
  
  lvl = mob.lvl_min and getLevelStr(mob) or '?'
  update = table.update({TH=TH_lvl, lvl=lvl}, mob)
  update.name = update.mob_name
  update.respawn = update.respawn and (update.respawn / 60) or 0
  if update.respawn > 60 then
    update.respawn = string.format('%.1fh', update.respawn/60)
  else
    update.respawn = string.format('%.1fm', update.respawn)
  end
  
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
  rate = item_rate/1000
  
  if TH_lvl > 2 then
    rate = rate + (TH_lvl-2)*0.01
  end
  
  if TH_lvl > 1 then
    rate = 1-(1-rate)^3
  elseif TH_lvl > 0 then
    rate = 1-(1-rate)^2
  end
  
  return math.min(math.floor(rate*1000),1000)
end

function setTH(newTH)
  TH_lvl = newTH
  
  if TH_lvl < 0 then
    TH_lvl = 0
    return false
  elseif TH_lvl > settings.maxTH then
    TH_lvl = settings.maxTH
    return false
  end
  
  return true
end

function doScroll(dir)
  if dir < 0 then dir = -1
  else dir = 1 end
  
  if settings.scrollInvert then dir = dir * -1 end
  
  scroll = scroll + settings.scrollSize * dir
  
  if scroll > scroll_max then
    scroll = scroll_max
    return false
  elseif scroll < 0 then
    scroll = 0
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

function distanceSquared(A, B)
  return (A.x - B.x)^2 + (A.y - B.y)^2
end

function strip(str)
  return str:lower():gsub(' ',''):gsub('-',''):gsub('%.',''):gsub('\'',''):gsub(':',''):gsub('"',''):gsub('♂','m'):gsub('♀','f'):gsub('%(',''):gsub('%)',''):gsub('♪','')
end

function getLevelStr(mob)
  str = tostring(mob.lvl_min)
  if mob.lvl_max > mob.lvl_min then str = str..'-'..tostring(mob.lvl_max) end
  return str
end
