
require('lists')
require('strings')

require('statics')

Mob = {}

Mob.dbKeys = L{
  'mob_id', 'group_id', 'pool_id', 'family_id', 'name',
  'respawnSec', 'hpRaw', 'mpRaw', 'lvl_min', 'lvl_max',
  'mJobRaw', 'sJobRaw', 'aggressive', 'linking', 'true_detection', 'nm', 'pet', 'immunitiesRaw',
  'ecosystemRaw',
  'hpScale', 'mpScale', 'strRank', 'dexRank', 'vitRank', 'agiRank', 'intRank', 'mndRank', 'chrRank', 'attRank', 'defRank', 'accRank', 'evaRank',
  'slash', 'pierce', 'h2h', 'impact',
  'fire', 'ice', 'wind', 'earth', 'lightning', 'water', 'light', 'dark',
  'detectsRaw',
  'charmable'}

Mob.dbQuery = "SELECT \
  mob_id, groups.group_id, pools.pool_id, families.family_id, name, \
  respawn, groups.hp, groups.mp, lvl_min, lvl_max, \
  mJob, sJob, aggressive, linking, true_detection, nm, pet, immunities, \
  ecosystem, \
  (families.hp / 100.0), (families.mp / 100.0), str, dex, vit, agi, `int`, mnd, chr, att, def, acc, eva, \
  (slash / 1000.0)-1, (pierce / 1000.0)-1, (h2h / 1000.0)-1, (impact / 1000.0)-1, \
  (fire / 1000.0)-1, (ice / 1000.0)-1, (wind / 1000.0)-1, (earth / 1000.0)-1, (lightning / 1000.0)-1, (water / 1000.0)-1, (light / 1000.0)-1, (dark / 1000.0)-1, \
  detects, \
  charmable \
  FROM mobs \
  INNER JOIN groups ON mobs.group_id = groups.group_id \
  INNER JOIN pools ON groups.pool_id = pools.pool_id \
  INNER JOIN families ON pools.family_id = families.family_id \
  WHERE mob_id = ?;"

Mob.boolKeys = T{ 'aggressive', 'linking', 'true_detection', 'nm', 'pet', 'charmable' }

Mob.dbStatement = false

Mob.Ecosystems = T{ [0] = 'Error', 'Amorph', 'Aquan', 'Arcana', 'ArchaicMachine', 'Avatar', 'Beast', 'Beastmen',
  'Bird', 'Demon', 'Dragon', 'Elemental', 'Empty', 'Humanoid', 'Lizard', 'Lumorian', 'Luminion', 'Plantoid',
  'Unclassified', 'Undead', 'Vermin', 'Voragean' }

Mob.Jobs = T{ [0] = 'NON', 'WAR', 'MNK', 'WHM', 'BLM', 'RDM', 'THF', 'PLD', 'DRK', 'BST', 'BRD', 'RNG', 'SAM', 'NIN',
  'DRG', 'SMN', 'BLU', 'COR', 'PUP', 'DNC', 'SCH', 'GEO', 'RUN' }

Mob.DetectFlags = T{ Sight = 0x01, Sound = 0x02, LowHP = 0x04, --[[None1 = 0x08, None2 = 0x10,--]] Magic = 0x20,
  WeaponSkill = 0x40, JobAbility = 0x80, Scent = 0x100 }

Mob.ImmunityFlags = T{ Sleep = 0x01, Gravity = 0x02, Bind = 0x04, Stun = 0x08, Silence = 0x10,
  Paralyze = 0x20, Blind = 0x40, Slow = 0x80, Poison = 0x100, Elegy = 0x200, Requiem = 0x0400}

Mob.Attributes = T{ str=1, dex=2, vit=3, agi=4, int=5, mnd=6, chr=7 }
Mob.Stats = T{ 'att', 'def', 'acc', 'eva', 'meva' }
Mob.Resistances = T{'Slash', 'Pierce', 'H2H', 'Impact', 'Fire', 'Ice', 'Wind', 'Earth', 'Lightning', 'Water', 'Light', 'Dark'}

Mob.JobRanks = T{
-- STR,DEX,VIT,AGI,INT,MND,CHR
  [0]={0, 0, 0, 0, 0, 0, 0}, --NON
      {1, 3, 4, 3, 6, 6, 5}, --WAR
      {3, 2, 1, 6, 7, 4, 5}, --MNK
      {4, 6, 4, 5, 5, 1, 3}, --WHM
      {6, 3, 6, 3, 1, 5, 4}, --BLM
      {4, 4, 5, 5, 3, 3, 4}, --RDM
      {4, 1, 4, 2, 3, 7, 7}, --THF
      {2, 5, 1, 7, 7, 3, 3}, --PLD
      {1, 3, 3, 4, 3, 7, 7}, --DRK
      {4, 3, 4, 6, 5, 5, 1}, --BST
      {4, 4, 4, 6, 4, 4, 2}, --BRD
      {5, 4, 4, 1, 5, 4, 5}, --RNG
      {3, 3, 3, 4, 5, 5, 4}, --SAM
      {3, 2, 3, 2, 4, 7, 6}, --NIN
      {2, 4, 3, 4, 6, 5, 3}, --DRG
      {6, 5, 6, 4, 2, 2, 2}, --SMN
      {5, 5, 5, 5, 5, 5, 5}, --BLU
      {5, 3, 5, 2, 3, 5, 5}, --COR
      {5, 2, 4, 3, 5, 6, 3}, --PUP
      {4, 3, 5, 2, 6, 6, 2}, --DNC
      {6, 4, 5, 4, 3, 4, 3}, --SCH
      {0, 0, 0, 0, 0, 0, 0}, --GEO (NYI)
      {0, 0, 0, 0, 0, 0, 0}  --RUN (NYI)
}

function Mob:new(mob_id, lvl)
  local mob = {}
  if not db:isopen() then return end
  if not Mob.dbStatement then Mob.dbStatement = db:prepare(Mob.dbQuery) end
  
  local success = false
  
  Mob.dbStatement:bind(1, mob_id)
  for a in Mob.dbStatement:rows() do
    mob._props = kvZip(Mob.dbKeys, a)
    success = true
  end
  Mob.dbStatement:reset()
  
  if not success then return end
  
  local props = mob._props
  
  props.lvlRange = props.lvl_min..'-'..props.lvl_max
  props.lvl = props.lvlRange
  
  props.mJob = Mob.Jobs[props.mJobRaw]
  props.sJob = Mob.Jobs[props.sJobRaw]
  props.job = props.mJob
  
  if props.sJob ~= 'NON' then props.job = props.job..'/'..props.sJob end
  
  for _, key in ipairs(Mob.boolKeys) do
    if props[key] == 1 then props[key] = true
    else props[key] = nil end
  end
  
  local hpMin = calcHP(mob, props.lvl_min)
  local hpMax = calcHP(mob, props.lvl_max)
  if hpMin == hpMax then props.hpRange = hpMin
  else props.hpRange = '%d-%d':format(hpMin, hpMax) end
  props.hp = props.hpRange
  
  local mpMin = calcMP(mob, props.lvl_min)
  local mpMax = calcMP(mob, props.lvl_max)
  if mpMin == mpMax then props.mpRange = mpMin
  else props.mpRange = '%d-%d':format(mpMin, mpMax) end
  if props.mpRange == 0 then props.mpRange = nil end
  props.mp = props.mpRange
  
  for attr, i in pairs(Mob.Attributes) do
    props[attr..'Range'] = '%d-%d':format(calcAttr(mob, attr, props.lvl_min), calcAttr(mob, attr, props.lvl_max))
    props[attr] = props[attr..'Range']
  end
  
  for _, stat in ipairs(Mob.Stats) do
    props[stat..'Range'] = '%d-%d':format(calcStat(mob, stat, props.lvl_min), calcStat(mob, stat, props.lvl_max))
    props[stat] = props[stat..'Range']
  end
  
  props.detects = T{}
  for name, flag in pairs(Mob.DetectFlags) do
    if testflag(props.detectsRaw, flag) then
      props.detects:insert(name)
      props['detect'..name] = true
    end
  end
  props.detects = #props.detects>0 and props.detects:concat(' ') or nil
  
  props.immunities = T{}
  for name, flag in pairs(Mob.ImmunityFlags) do
    if testflag(props.immunitiesRaw, flag) then props.immunities:insert(name) end
  end
  props.immunities = #props.immunities>0 and props.immunities:concat(' ') or nil
  
  props.resistances = T{}
  for _, name in ipairs(Mob.Resistances) do
    local resist = props[name:lower()]*100
    if resist ~= 0 then
      -- Use tostring as an alternative to EPSILON comparison.
      local p = tostring(math.floor(resist)) ~= tostring(resist) and '%.1f' or '%.0f'
      props.resistances:insert(('%s%s'..p..'%%'):format(name, resist>0 and '+' or '', resist))
      props['resist'..name] = ('%s'..p..'%%'):format(resist>0 and '+' or '', resist)
    end
  end
  props.resistances = #props.resistances>0 and props.resistances:concat(' ') or nil
  
  props.respawn = props.respawnSec
  if props.respawn > 60 then
    props.respawn = props.respawn / 60
    if props.respawn > 60 then props.respawn = '%.1fh':format(props.respawn/60)
    else                       props.respawn = '%.1fm':format(props.respawn) end
  else                         props.respawn = '%ds':format(props.respawn) end
  if props.respawn == '0s' then props.respawn = nil end
  
  props.ecosystem = Mob.Ecosystems[props.ecosystemRaw]
  props.family = props.ecosystem
  
  setmetatable(mob, self)
  
  if lvl then mob:setLvl(lvl) end
  
  return mob
end

function Mob:__index(key)
  if rawget(self, '_props')[key] ~= nil then
    return rawget(self, '_props')[key]
  else
    return rawget( self, key )
  end
end

function Mob:__newindex(key, value)
  if key == 'lvl' then
    self:setLvl(value)
  else
    rawset(self, key, value)
  end
end

function Mob:setLvl(lvl)
  self._props.lvl = lvl
  
  self.hp = calcHP(self, lvl)
  self.mp = calcMP(self, lvl)
  
  for attr, i in pairs(Mob.Attributes) do
    self[attr] = calcAttr(self, attr, lvl)
  end
  for _, stat in ipairs(Mob.Stats) do
    self[stat] = calcStat(self, stat, lvl)
  end
end

function Mob:canAggro(playerLevel)
  local mobLevel = self._props.lvl_max
  if self._props.lvl ~= self._props.lvlRange then mobLevel = self._props.lvl end
  
  return canAggro(mobLevel, playerLevel)
end

function calcAttr(mob, attr, lvl)
  local i = Mob.Attributes[attr]
  local sLvl = math.max(1, math.floor(lvl*0.5))
  local rAttr = calcAttrFromRank(mob._props[attr..'Rank'], lvl)
  local mAttr = calcAttrFromRank(Mob.JobRanks[mob._props.mJobRaw][i], lvl)
  local sAttr = math.floor(sLvl > 15 and 0.5 * calcAttrFromRank(Mob.JobRanks[mob._props.sJobRaw][i], sLvl) or 0)
  local mult = mob._props.nm and 1.5 or 1
  return math.floor((rAttr + mAttr + sAttr)*mult)
end

function calcAttrFromRank(rank, lvl)
  if     rank == 1 then return math.floor(5+((lvl-1)*50)/100) -- A
  elseif rank == 2 then return math.floor(4+((lvl-1)*45)/100) -- B
  elseif rank == 3 then return math.floor(4+((lvl-1)*40)/100) -- C
  elseif rank == 4 then return math.floor(3+((lvl-1)*35)/100) -- D
  elseif rank == 5 then return math.floor(3+((lvl-1)*30)/100) -- E
  elseif rank == 6 then return math.floor(2+((lvl-1)*25)/100) -- F
  elseif rank == 7 then return math.floor(2+((lvl-1)*20)/100) -- G
  else return 0 end
end

function calcStat(mob, stat, lvl)
  if stat == 'eva' then return calcEvasion(mob._props[stat..'Rank'], mob._props.mJob, lvl)
  elseif stat == 'meva' then return calcStatFromRank(3, lvl) end
  
  return calcStatFromRank(mob._props[stat..'Rank'], lvl)
end

function calcStatFromRank(rank, lvl)
  if lvl > 50 then
    if     rank == 1 then return math.floor(153 + (lvl-50)*5.0) -- A
    elseif rank == 2 then return math.floor(147 + (lvl-50)*4.9) -- B
    elseif rank == 3 then return math.floor(136 + (lvl-50)*4.8) -- C
    elseif rank == 4 then return math.floor(126 + (lvl-50)*4.7) -- D
    elseif rank == 5 then return math.floor(116 + (lvl-50)*4.5) -- E
    elseif rank == 6 then return math.floor(106 + (lvl-50)*4.4) -- F
    elseif rank == 7 then return math.floor(96  + (lvl-50)*4.3) -- G
    end
  else
    if     rank == 1 then return math.floor(6 + (lvl-1)*3.0) -- A
    elseif rank == 2 then return math.floor(5 + (lvl-1)*2.9) -- B
    elseif rank == 3 then return math.floor(5 + (lvl-1)*2.8) -- C
    elseif rank == 4 then return math.floor(4 + (lvl-1)*2.7) -- D
    elseif rank == 5 then return math.floor(4 + (lvl-1)*2.5) -- E
    elseif rank == 6 then return math.floor(3 + (lvl-1)*2.4) -- F
    elseif rank == 7 then return math.floor(3 + (lvl-1)*2.3) -- G
    end
  end
  return 0
end

function calcEvasion(rank, mJob, lvl)
  if     T{'THF', 'NIN'}:contains(mJob)                      then rank = 1
  elseif T{'MNK', 'DNC', 'SAM', 'PUP', 'RUN'}:contains(mJob) then rank = 2
  elseif T{'RDM', 'BRD', 'GEO', 'COR'}:contains(mJob)        then rank = 4
  elseif T{'WHM', 'SCH', 'RNG', 'SMN', 'BLM'}:contains(mJob) then rank = 5 end

  return calcStatFromRank(rank, lvl);
end

function calcHP(mob, lvl)
  if mob._props.hpRaw > 0 then return mob._props.hpRaw end
  
  local growth = 1.06
  local petGrowth = 0.75
  local base = 18.0
  
  if lvl > 75 then
    growth = 1.28
    petGrowth = 1.03
  elseif lvl > 65 then
    growth = 1.27
    petGrowth = 1.02
  elseif lvl > 55 then
    growth = 1.25
    petGrowth = 0.99
  elseif lvl > 50 then
    growth = 1.21
    petGrowth = 0.96
  elseif lvl > 45 then
    growth = 1.17
    petGrowth = 0.95
  elseif lvl > 35 then
    growth = 1.14
    petGrowth = 0.92
  elseif lvl > 25 then
    growth = 1.10
    petGrowth = 0.82
  end
  
  if mob._props.pet then growth = petGrowth end
  
  local hp = math.floor(base * math.pow(lvl, growth) * mob._props.hpScale)
  
  if mob._props.nm then
    hp = hp * 2
    if lvl > 75 then hp = math.floor(hp * 2.5) end
  end
  
  return hp
end

function calcMP(mob, lvl)
  local hasMP = false
  local mpJobs = T{ 'PLD', 'WHM', 'BLM', 'RDM', 'DRK', 'BLU', 'SCH', 'SMN' }
  
  if mpJobs:contains(mob._props.mJob) or mpJobs:contains(mob._props.sJob) then hasMP = true end
  
  if not hasMP then return 0 end
  
  if mob._props.mpRaw > 0 then return mob._props.mpRaw end
  
  local mp = math.floor(18.2 * math.pow(lvl, 1.1075) * mob._props.mpScale) + 10
  
  if mob._props.nm then
    mp = math.floor(mp * 1.5)
    if lvl > 75 then mp = math.floor(mp * 1.5) end
  end
  
  return mp
end

function canAggro(mobLevel, playerLevel)
  -- This formula isn't perfect on retail (according to wiki), but it is what DarkstarProject uses.
  return getExp(mobLevel, playerLevel) > 50
end

function getExp(mobLevel, playerLevel)
  local diff = clamp(mobLevel - playerLevel, -34, 15)
  
  return expTable[diff][math.floor((playerLevel-1)/5)+1]
end

function testflag(container, flag)
  return container % (2*flag) >= flag
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

function dump(obj, levelsDeep, level)
  levelsDeep = levelsDeep or 0
  level = level or ''

  for k,v in pairs(obj) do
    log(level..k..' '..tostring(v))
    if levelsDeep > 0 and type(v) == 'table' then
      dump(v, levelsDeep-1, level..'  ')
    end
  end
end
