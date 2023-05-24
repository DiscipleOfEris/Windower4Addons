
import os
import re
import sqlite3

sqlPath = r'C:\Users\ofsha\Documents\GitHub\ffera\sql'
ignoreZones = (0, 15, 45, 49, 132, 133, 183, 215, 216, 217, 218, 229, 253, 254, 255, 258, 259, 260, 261, 262, 263, 264, 265, 266, 267, 268, 269, 270, 271, 272, 273, 274, 275, 276, 277, 278, 279, 286, 287, 288, 289, 290, 291, 292, 293, 294, 295, 296, 297, 298 )

con = sqlite3.connect('mob_info.db')
cur = con.cursor()

conTemp = sqlite3.connect(':memory:')
conTemp.row_factory = sqlite3.Row
curTemp = conTemp.cursor()

cur.executescript('''
DROP TABLE IF EXISTS mobs;
DROP INDEX IF EXISTS idx_mobs_groupid;
CREATE TABLE mobs (
    mob_id INTEGER,
    group_id INTEGER,
    name TEXT,
    pet TINYINT,
    ph_id INTEGER,
    ph_name TEXT,
    PRIMARY KEY (mob_id));
CREATE INDEX idx_mobs_groupid on mobs(group_id);''')
cur.executescript('''
DROP TABLE IF EXISTS groups;
CREATE TABLE groups (
    group_id INTEGER,
    pool_id INTEGER,
    zone_id INTEGER,
    respawn SMALLINT,
    hp SMALLINT,
    mp SMALLINT,
    lvl_min TINYINT,
    lvl_max TINYINT,
    true_detection TINYINT,
    PRIMARY KEY (zone_id, group_id));''')
cur.executescript('''
DROP TABLE IF EXISTS pools;
CREATE TABLE pools (
    pool_id INTEGER,
    family_id INTEGER,
    mJob TINYINT,
    sJob TINYINT,
    aggressive TINYINT,
    linking TINYINT,
    nm TINYINT,
    immunities SMALLINT,
    PRIMARY KEY (pool_id))''')
cur.executescript('''
DROP TABLE IF EXISTS families;
CREATE TABLE families (
    family_id INTEGER,
    ecosystem TINYINT,
    hp TINYINT,
    mp TINYINT,
    str TINYINT,
    dex TINYINT,
    vit TINYINT,
    agi TINYINT,
    int TINYINT,
    mnd TINYINT,
    chr TINYINT,
    att TINYINT,
    def TINYINT,
    acc TINYINT,
    eva TINYINT,
    slash SMALLINT,
    pierce SMALLINT,
    h2h SMALLINT,
    impact SMALLINT,
    fire SMALLINT,
    ice SMALLINT,
    wind SMALLINT,
    earth SMALLINT,
    lightning SMALLINT,
    water SMALLINT,
    light SMALLINT,
    dark SMALLINT,
    detects SMALLINT,
    charmable TINYINT,
    PRIMARY KEY (family_id));''')

DynamisZones = [39,40,41,42,134,135,185,186,187,188,294,295,296,297]

with open(os.path.join(sqlPath, r'mob_family_system.sql')) as file:
    fileContents = file.read()
    fileContents = re.sub(r"^CREATE DATABASE[^;]*;", "", fileContents, flags=re.IGNORECASE | re.MULTILINE)
    fileContents = re.sub(r"^USE[^;]*;", "", fileContents, flags=re.IGNORECASE | re.MULTILINE)
    fileContents = re.sub(r"(`\w+`[^,]*)unsigned([^,]*,)", r"\1\2", fileContents, flags=re.IGNORECASE)
    fileContents = re.sub(r"ENGINE\s?=[^;]*;", ";", fileContents, flags=re.IGNORECASE)
    fileContents = re.sub(r"\\'", "''", fileContents)
    #print(fileContents)
    curTemp.executescript(fileContents)

with open(os.path.join(sqlPath, r'mob_pools.sql')) as file:
    fileContents = file.read()
    fileContents = re.sub(r"^CREATE DATABASE[^;]*;", "", fileContents, flags=re.IGNORECASE | re.MULTILINE)
    fileContents = re.sub(r"^USE[^;]*;", "", fileContents, flags=re.IGNORECASE | re.MULTILINE)
    fileContents = re.sub(r"(`\w+`[^,]*)unsigned([^,]*,)", r"\1\2", fileContents, flags=re.IGNORECASE)
    fileContents = re.sub(r"ENGINE\s?=[^;]*;", ";", fileContents, flags=re.IGNORECASE)
    fileContents = re.sub(r"\\'", "''", fileContents)
    fileContents = re.sub(r"`modelid`\s*binary", "`modelid` VARCHAR", fileContents, flags=re.IGNORECASE)
    fileContents = re.sub(r"_binary ([^,]+),", r"'\1',", fileContents, flags=re.IGNORECASE)
    curTemp.executescript(fileContents)

with open(os.path.join(sqlPath, r'mob_groups.sql')) as file:
    fileContents = file.read()
    fileContents = re.sub(r"^CREATE DATABASE[^;]*;", "", fileContents, flags=re.IGNORECASE | re.MULTILINE)
    fileContents = re.sub(r"^USE[^;]*;", "", fileContents, flags=re.IGNORECASE | re.MULTILINE)
    fileContents = re.sub(r"(`\w+`[^,]*)unsigned([^,]*,)", r"\1\2", fileContents, flags=re.IGNORECASE)
    fileContents = re.sub(r"ENGINE\s?=[^;]*;", ";", fileContents, flags=re.IGNORECASE)
    fileContents = re.sub(r"\\'", "''", fileContents)
    curTemp.executescript(fileContents)

with open(os.path.join(sqlPath, r'mob_pets.sql')) as file:
    fileContents = file.read()
    fileContents = re.sub(r"^CREATE DATABASE[^;]*;", "", fileContents, flags=re.IGNORECASE | re.MULTILINE)
    fileContents = re.sub(r"^USE[^;]*;", "", fileContents, flags=re.IGNORECASE | re.MULTILINE)
    fileContents = re.sub(r"(`\w+`[^,]*)unsigned([^,]*,)", r"\1\2", fileContents, flags=re.IGNORECASE)
    fileContents = re.sub(r"ENGINE\s?=[^;]*;", ";", fileContents, flags=re.IGNORECASE)
    fileContents = re.sub(r"\\'", "''", fileContents)
    curTemp.executescript(fileContents)

with open(os.path.join(sqlPath, r'mob_spawn_points.sql')) as file:
    fileContents = file.read()
    fileContents = re.sub(r"^CREATE DATABASE[^;]*;", "", fileContents, flags=re.IGNORECASE | re.MULTILINE)
    fileContents = re.sub(r"^USE[^;]*;", "", fileContents, flags=re.IGNORECASE | re.MULTILINE)
    fileContents = re.sub(r"(`\w+`[^,]*)unsigned([^,]*,)", r"\1\2", fileContents, flags=re.IGNORECASE)
    fileContents = re.sub(r"ENGINE\s?=[^;]*;", ";", fileContents, flags=re.IGNORECASE)
    fileContents = re.sub(r"\\'", "''", fileContents)
    curTemp.executescript(fileContents)

with open(os.path.join(sqlPath, r'mob_pets.sql')) as file:
    fileContents = file.read()
    fileContents = re.sub(r"^CREATE DATABASE[^;]*;", "", fileContents, flags=re.IGNORECASE | re.MULTILINE)
    fileContents = re.sub(r"^USE[^;]*;", "", fileContents, flags=re.IGNORECASE | re.MULTILINE)
    fileContents = re.sub(r"(`\w+`[^,]*)unsigned([^,]*,)", r"\1\2", fileContents, flags=re.IGNORECASE)
    fileContents = re.sub(r"ENGINE\s?=[^;]*;", ";", fileContents, flags=re.IGNORECASE)
    fileContents = re.sub(r"\\'", "''", fileContents)
    curTemp.executescript(fileContents)

with open(os.path.join(sqlPath, r'zone_settings.sql')) as file:
    fileContents = file.read()
    fileContents = re.sub(r"^CREATE DATABASE[^;]*;", "", fileContents, flags=re.IGNORECASE | re.MULTILINE)
    fileContents = re.sub(r"^USE[^;]*;", "", fileContents, flags=re.IGNORECASE | re.MULTILINE)
    fileContents = re.sub(r"(`\w+`(?:(?:(?<=\(\d),(?=\d\)))|[^,])*)unsigned([^,]*,)", r"\1\2", fileContents, flags=re.IGNORECASE)
    fileContents = re.sub(r"ENGINE\s?=[^;]*;", ";", fileContents, flags=re.IGNORECASE)
    fileContents = re.sub(r"\\'", "''", fileContents)
    curTemp.executescript(fileContents)

conTemp.commit()

con.commit()
families = dict()
pools = dict()
groups = dict()
mobs = dict()

count = 0
errorCount = 0

def family_generator():
    global count, errorCount
    count = errorCount = 0
    for row in curTemp.execute('SELECT * FROM mob_family_system'):
        count += 1

        families[row['familyid']] = True
        
        yield (row['familyid'], row['systemid'], row['HP'], row['MP'], row['STR'], row['DEX'], row['VIT'], row['AGI'], row['INT'], row['MND'], row['CHR'], row['ATT'], row['DEF'], row['ACC'], row['EVA'], row['Slash']*1000, row['Pierce']*1000, row['H2H']*1000, row['Impact']*1000, row['Fire']*1000, row['Ice']*1000, row['Wind']*1000, row['Earth']*1000, row['Lightning']*1000, row['Water']*1000, row['Light']*1000, row['Dark']*1000, row['detects'], row['charmable'])

cur.executemany('INSERT INTO families (family_id, ecosystem, hp, mp, str, dex, vit, agi, int, mnd, chr, att, def, acc, eva, slash, pierce, h2h, impact, fire, ice, wind, earth, lightning, water, light, dark, detects, charmable) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', family_generator())
con.commit()

print('families success', (count-errorCount), 'fail', errorCount)

def pool_generator():
    global count, errorCount
    count = errorCount = 0
    for row in curTemp.execute('SELECT * FROM mob_pools'):
        count += 1

        if not (row['familyid'] in families):
            errorCount += 1
            print('pool fail', row['poolid'], row['familyid'], row['name'])
            continue

        pools[row['poolid']] = row['true_detection']
        
        yield (row['poolid'], row['familyid'], row['mJob'], row['sJob'], row['aggro'], row['links'], row['mobType'] & 0x02, row['immunity'])

cur.executemany('INSERT INTO pools (pool_id, family_id, mJob, sJob, aggressive, linking, nm, immunities) VALUES (?, ?, ?, ?, ?, ?, ?, ?)', pool_generator())
con.commit()

print('pools success', (count-errorCount), 'fail', errorCount)

def group_generator():
    global count, errorCount
    count = errorCount = 0
    for row in curTemp.execute('SELECT * FROM mob_groups'):
        if row['zoneid'] in ignoreZones:
            continue

        count += 1

        if not (row['poolid'] in pools):
            errorCount += 1
            print('group fail', row['groupid'], row['poolid'])
            continue

        groups[(row['zoneid'], row['groupid'])] = True
        
        true_detection = pools[row['poolid']]
        if row['zoneid'] in DynamisZones:
            true_detection = 1
        
        yield (row['groupid'], row['poolid'], row['zoneid'], row['respawntime'], row['HP'], row['MP'], row['minLevel'], row['maxLevel'], true_detection)

cur.executemany('INSERT INTO groups (group_id, pool_id, zone_id, respawn, hp, mp, lvl_min, lvl_max, true_detection) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)', group_generator())
con.commit()

print('groups success', (count-errorCount), 'fail', errorCount)

def mob_generator():
    global count, errorCount
    count = errorCount = 0
    for row in curTemp.execute('SELECT * FROM mob_spawn_points'):
        zoneid = (row['mobid'] >> 12) & 0xFFF

        if zoneid in ignoreZones:
            continue

        count += 1

        if (zoneid, row['groupid']) not in groups:
            errorCount += 1
            print('mob fail', row['mobid'], row['groupid'], row['mobname'])
            continue
        
        mobs[row['mobid']] = True
        
        alt_name = row['mobname'].replace('_', ' ')
        mob_name = row['polutils_name']
        
        if len(mob_name) == 0:
            mob_name = alt_name
        
        yield (row['mobid'], row['groupid'], mob_name)

cur.executemany('INSERT INTO mobs (mob_id, group_id, name) VALUES (?, ?, ?)', mob_generator())
con.commit()

print('mobs success', (count-errorCount), 'fail', errorCount)

def pet_generator():
    global count, errorCount
    count = errorCount = 0
    for row in curTemp.execute('SELECT * FROM mob_pets'):
        count += 1

        master_id = row['mob_mobid']
        pet_id = row['pet_offset'] + master_id

        if master_id == pet_id or not (master_id in mobs or pet_id in mobs):
            errorCount += 1
            print('pet fail', master_id, pet_id)
            continue
        
        yield (pet_id,)

cur.executemany('UPDATE mobs SET pet=1 WHERE mob_id = ?', pet_generator())
con.commit()

print('pets success', (count-errorCount), 'fail', errorCount)

def ph_generator():
    global count, errorCount
    count = errorCount = 0
    for row in curTemp.execute('SELECT * FROM zone_settings').fetchall():
        if row['zoneid'] in ignoreZones:
            continue

        phGroupRegex = re.compile(r"        \w+_PH\s*=(?:\s*--[^\n]*)?\s*{(?:\s*--[^\n]*)?\n(.*?)        }", flags = re.MULTILINE | re.DOTALL)
        phLineRegex = re.compile(r"^\s*\[(\d+)\]\s*=\s*(\d+)", flags = re.MULTILINE)

        with open(os.path.join(sqlPath, rf"../scripts/zones/{row['name']}/IDs.lua")) as file:
            fileContents = file.read()
            for phLines in re.findall(phGroupRegex, fileContents):
                for (mobid, phTarget) in re.findall(phLineRegex, phLines):
                    count += 1
                    mobid = int(mobid)
                    phTarget = int(phTarget)
                    curTemp.execute('SELECT * FROM mob_spawn_points WHERE mobid = ?', (phTarget,))
                    row = curTemp.fetchone()
                    if row is None:
                        errorCount += 1
                        print('ph fail', mobid, phTarget)
                        continue

                    yield (phTarget, row['polutils_name'], mobid)

cur.executemany('UPDATE mobs SET ph_id = ?, ph_name = ? WHERE mob_id = ?', ph_generator())
con.commit()

print('ph success', (count - errorCount), 'fail', errorCount)
