
import re
import sqlite3

con = sqlite3.connect('mobs_drops.db')
cur = con.cursor()

conTemp = sqlite3.connect(':memory:')
conTemp.row_factory = sqlite3.Row
curTemp = conTemp.cursor()

cur.executescript('''
DROP TABLE IF EXISTS mobs;
DROP INDEX IF EXISTS idx_mobs_dropid;
DROP INDEX IF EXISTS idx_mobs_mobiname_zone_drop;
CREATE TABLE mobs (
  mob_id INTEGER,
  mob_name TEXT,
  mob_iname TEXT,
  zone_id INTEGER,
  drop_id INTEGER,
  respawn INTEGER,
  lvl_min INTEGER,
  lvl_max INTEGER,
  PRIMARY KEY (mob_id));
CREATE INDEX idx_mobs_dropsid on mobs(drop_id);
CREATE INDEX idx_mobs_mobiname_zone_drop on mobs(mob_iname, zone_id, drop_id);''')
cur.executescript('''
DROP TABLE IF EXISTS drops;
DROP INDEX IF EXISTS idx_drops_dropid;
DROP INDEX IF EXISTS idx_drops_itemid;
CREATE TABLE drops (
  drop_id INTEGER,
  drop_type INTEGER,
  group_id INTEGER,
  group_rate INTEGER,
  item_id INTEGER,
  item_rate INTEGER);
CREATE INDEX idx_drops_dropid ON drops(drop_id);
CREATE INDEX idx_drops_itemid ON drops(item_id);''')

con.commit()


with open('sql/mob_groups.sql') as file:
    fileContents = file.read()
    fileContents = re.sub(r"^CREATE DATABASE[^;]*;", "", fileContents, flags=re.IGNORECASE | re.MULTILINE)
    fileContents = re.sub(r"^USE[^;]*;", "", fileContents, flags=re.IGNORECASE | re.MULTILINE)
    fileContents = re.sub(r"(`\w+`[^,]*)unsigned([^,]*,)", r"\1\2", fileContents, flags=re.IGNORECASE)
    fileContents = re.sub(r"ENGINE\s?=[^;]*;", ";", fileContents, flags=re.IGNORECASE)
    fileContents = re.sub(r"\\'", "''", fileContents)
    curTemp.executescript(fileContents)

with open('sql/mob_spawn_points.sql') as file:
    fileContents = file.read()
    fileContents = re.sub(r"^CREATE DATABASE[^;]*;", "", fileContents, flags=re.IGNORECASE | re.MULTILINE)
    fileContents = re.sub(r"^USE[^;]*;", "", fileContents, flags=re.IGNORECASE | re.MULTILINE)
    fileContents = re.sub(r"(`\w+`[^,]*)unsigned([^,]*,)", r"\1\2", fileContents, flags=re.IGNORECASE)
    fileContents = re.sub(r"ENGINE\s?=[^;]*;", ";", fileContents, flags=re.IGNORECASE)
    fileContents = re.sub(r"\\'", "''", fileContents)
    curTemp.executescript(fileContents)

with open('sql/mob_droplist.sql') as file:
    fileContents = file.read()
    fileContents = re.sub(r"^CREATE DATABASE[^;]*;", "", fileContents, flags=re.IGNORECASE | re.MULTILINE)
    fileContents = re.sub(r"^USE[^;]*;", "", fileContents, flags=re.IGNORECASE | re.MULTILINE)
    fileContents = re.sub(r"(`\w+`[^,]*)unsigned([^,]*,)", r"\1\2", fileContents, flags=re.IGNORECASE)
    fileContents = re.sub(r"ENGINE\s?=[^;]*;", ";", fileContents, flags=re.IGNORECASE)
    fileContents = re.sub(r"\\'", "''", fileContents)
    fileContents = re.sub(',\s+KEY `dropId` \(`dropId`\)', '', fileContents, flags=re.IGNORECASE)
    curTemp.executescript(fileContents)

conTemp.commit()

def mob_generator():
  count = 0
  for row in curTemp.execute('SELECT * FROM mob_spawn_points INNER JOIN mob_groups ON mob_spawn_points.groupid = mob_groups.groupid'):
    count += 1
    
    alt_name = row['mobname'].replace('_', ' ')
    mob_name = row['polutils_name']

    if len(mob_name) == 0:
      mob_name = alt_name
    
    mob_iname = re.sub('[\'\"\-\(\)\,\. ]', '', mob_name.lower())
    
    if count % 1000 == 0: print(count, 'mob:', row['mobid'], mob_name, mob_iname, row['zoneid'], row['dropid'], row['respawntime'], row['minLevel'], row['maxLevel'])
      
    yield (row['mobid'], mob_name, mob_iname, row['zoneid'], row['dropid'], row['respawntime'], row['minLevel'], row['maxLevel'])

cur.executemany('INSERT INTO mobs (mob_id, mob_name, mob_iname, zone_id, drop_id, respawn, lvl_min, lvl_max) VALUES (?, ?, ?, ?, ?, ?, ?, ?)', mob_generator())

con.commit()

def drop_generator():
  count = 0
  for row in curTemp.execute('SELECT * FROM mob_droplist'):
    count += 1
    
    if count % 1000 == 0: print(count, 'drop:', row['dropId'], row['dropType'], row['itemId'], row['itemRate'])
    
    yield (row['dropId'], row['dropType'], row['groupId'], row['groupRate'], row['itemId'], row['itemRate'])

cur.executemany('INSERT INTO drops (drop_id, drop_type, group_id, group_rate, item_id, item_rate) VALUES (?, ?, ?, ?, ?, ?)', drop_generator())

con.commit()