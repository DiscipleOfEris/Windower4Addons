--[[Copyright © 2018, Kenshi
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of InfoBar nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL KENSHI BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.]]

_addon.name = 'EraInfoBar'
_addon.author = 'DiscipleOfEris'
_addon.version = '1.1.1'
_addon.commands = {'ib', 'infobar'}

config = require('config')
texts = require('texts')
require('vectors')
packets = require('packets')
res = require('resources')
require('sqlite3')
require('logger')
require('mob')

defaults = {}
defaults.NoTarget = "${zone_name} ${name} (${main_job}${main_job_level}/${sub_job}${sub_job_level}) (${x||%.3f},${y||%.3f},${z||%.3f}) ${facing||%.0f}° (${facing_dir})"
defaults.TargetPC = "${name}"
defaults.TargetNPC = "${name}"
defaults.TargetMOB = "${name} (Lv.${lvl} ${job}${respawn||, Respawn:%s})${aggressive|| Aggressive}${linking|| Linking}${true_detection|| True}${detects|| %s}${resistances|| %s}${immunities|| Immune: %s}"
defaults.shouldScan = true
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
defaults.display.text.size = 12

settings = config.load(defaults)

box = texts.new("", settings.display, settings)

local infobar = {}
infobar.new_line = '\n'

local last_target_id = 0

local target_idx_table = T{}
local scanning = 0
local max_scan_wait = 15
local mob = nil
local rescan = 300

windower.register_event('load',function()
    db = sqlite3.open(windower.addon_path..'/mob_info.db')
    notesdb = sqlite3.open(windower.addon_path..'/data/notes.db')
    notesdb:exec('CREATE TABLE IF NOT EXISTS notes(name TEXT primary key, note TEXT)')
    if not windower.ffxi.get_info().logged_in then return end
    local target = windower.ffxi.get_mob_by_target('st') or windower.ffxi.get_mob_by_target('t') or windower.ffxi.get_player()
    get_target(target.index)
end)

windower.register_event('unload',function()
    db:close()
    notesdb:close()
end)

function getDegrees(value)
    return math.round(360 / math.tau * value)
end

local dir_sets = L{'W', 'WNW', 'NW', 'NNW', 'N', 'NNE', 'NE', 'ENE', 'E', 'ESE', 'SE', 'SSE', 'S', 'SSW', 'SW', 'WSW', 'W'}
function DegreesToDirection(val)
    return dir_sets[math.round((val + math.pi) / math.pi * 8) + 1]
end

function get_notes(target)
    local statement = notesdb:prepare('SELECT * FROM "notes" WHERE name = ?;')
    if notesdb:isopen() and statement then
        statement:bind(1, target)
        for name, note in statement:urows(query, { target }) do
            if name == target then
                return note or nil
            end
        end
    end
end

function get_target(index)
    local player = windower.ffxi.get_player()
    local target = windower.ffxi.get_mob_by_target('st') or windower.ffxi.get_mob_by_target('t') or player
    if target.id == last_target_id then
        if target.id == player.id then
            infobar.main_job = player.main_job
            infobar.main_job_level = player.main_job_level
            infobar.sub_job = player.sub_job
            infobar.sub_job_level = player.sub_job_level
            box:update(infobar)
        end
        return
    end
    last_target_id = target.id
    infobar.name = target.name
    infobar.id = target.id
    infobar.index = target.index
    infobar.notes = get_notes(target.name)
    if index == 0 or index == player.index then
        infobar.main_job = player.main_job
        infobar.main_job_level = player.main_job_level
        infobar.sub_job = player.sub_job
        infobar.sub_job_level = player.sub_job_level
        box:color(255,255,255)
        box:bold(false)
        box:text(settings.NoTarget)
        box:update(infobar)
    else
        -- spawn_type is no longer being set the same way.
        -- Instead, use index.
        -- index < 1024 (0x400) means either mob, npc, or ship.
        -- index < 1792 (0x700) means pc.
        -- index < 2048 (0x800) means pet, trust, or fellow

        if target.index < 1024 then -- mob or NPC
            mob = Mob:new(target.id)
            if mob then -- is a mob
                box:color(255,255,128)

                if target_idx_table:containskey(target.index) then
                    local t = target_idx_table[target.index]
                    if os.clock() < t.expires then Mob.setLvl(mob, t.lvl)
                    elseif settings.shouldScan and os.clock() >= t.expires then scan() end
                elseif settings.shouldScan then scan() end

                box:bold(mob.aggressive and Mob.canAggro(mob, player.main_job_level))
                box:text(settings.TargetMOB)
                box:update(mob)
            else -- is an NPC
                box:color(128,255,128)
                box:text(settings.TargetNPC)
                box:bold(false)
                box:update(infobar)
            end
        else --if target.index < 1792 then -- is a PC
            box:bold(false)
            if target.spawn_type == 1 then
                box:color(255,255,255)
            else
                box:color(128,255,255)
            end
            box:text(settings.TargetPC)
            box:update(infobar)
        end
    end
end

PACKET_WIDESCAN = 0x0F4

windower.register_event('incoming chunk',function(id,org,modi,is_injected,is_blocked)
    if id == 0xB then
        zoning_bool = true
    elseif id == 0xA then
        zoning_bool = false
    elseif id == PACKET_WIDESCAN then
        scanning = 0
        local packet = packets.parse('incoming', org)
        target_idx_table[packet.Index] = {lvl=packet.Level, expires=os.clock()+rescan}
        local target = windower.ffxi.get_mob_by_index(packet.Index)
        if target and target.id == last_target_id and mob then
            Mob.setLvl(mob, packet.Level)
            local player = windower.ffxi.get_player()
            if player then box:bold(mob.aggressive and Mob.canAggro(mob, player.main_job_level)) end
            box:update(mob)
        end
    end
end)

windower.register_event('prerender', function()
    local info = windower.ffxi.get_info()
    local target = windower.ffxi.get_mob_by_target('st') or windower.ffxi.get_mob_by_target('t') or windower.ffxi.get_mob_by_target('me')

    if not info.logged_in or not windower.ffxi.get_player() or zoning_bool or not target then
        box:hide()
        return
    end

    infobar.game_moon = res.moon_phases[info.moon_phase].name
    infobar.game_moon_pct = info.moon..'%'
    infobar.zone_name = res.zones[info.zone].name

    infobar.x = target.x
    infobar.y = target.y
    infobar.z = target.z
    infobar.facing = tostring(getDegrees(target.facing))
    infobar.facing_dir = DegreesToDirection(target.facing)

    get_target(target.index)
    box:show()
end)

--windower.register_event('target change', get_target)
windower.register_event('job change', function()
    get_target(windower.ffxi.get_player().index)
end)

windower.register_event('time change', function(new, old)
    local alchemy = new >= 8*60 and new <= 23*60 and 'Open' or 'Closed'
    infobar.alchemy = alchemy == "Closed" and '\\cs(255,0,0)'..alchemy..'\\cr' or '\\cs(0,255,0)'..alchemy..'\\cr'
    local bonecraft = new >= 8*60 and new <= 23*60 and 'Open' or 'Closed'
    infobar.bonecraft = bonecraft == "Closed" and '\\cs(255,0,0)'..bonecraft..'\\cr' or '\\cs(0,255,0)'..bonecraft..'\\cr'
    local clothcraft = new >= 6*60 and new <= 21*60 and 'Open' or 'Closed'
    infobar.clothcraft = clothcraft == "Closed" and '\\cs(255,0,0)'..clothcraft..'\\cr' or '\\cs(0,255,0)'..clothcraft..'\\cr'
    local cooking = new >= 5*60 and new <= 20*60 and 'Open' or 'Closed'
    infobar.cooking = cooking == "Closed" and '\\cs(255,0,0)'..cooking..'\\cr' or '\\cs(0,255,0)'..cooking..'\\cr'
    local fishing = new >= 3*60 and new <= 18*60 and 'Open' or 'Closed'
    infobar.fishing = fishing == "Closed" and '\\cs(255,0,0)'..fishing..'\\cr' or '\\cs(0,255,0)'..fishing..'\\cr'
    local goldsmithing = new >= 8*60 and new <= 23*60 and 'Open' or 'Closed'
    infobar.goldsmithing = goldsmithing == "Closed" and '\\cs(255,0,0)'..goldsmithing..'\\cr' or '\\cs(0,255,0)'..goldsmithing..'\\cr'
    local leathercraft = new >= 3*60 and new <= 18*60 and 'Open' or 'Closed'
    infobar.leathercraft = leathercraft == "Closed" and '\\cs(255,0,0)'..leathercraft..'\\cr' or '\\cs(0,255,0)'..leathercraft..'\\cr'
    local smithing = new >= 8*60 and new <= 23*60 and 'Open' or 'Closed'
    infobar.smithing = smithing == "Closed" and '\\cs(255,0,0)'..smithing..'\\cr' or '\\cs(0,255,0)'..smithing..'\\cr'
    local woodworking = new >= 6*60 and new <= 21*60 and 'Open' or 'Closed'
    infobar.woodworking = woodworking == "Closed" and '\\cs(255,0,0)'..woodworking..'\\cr' or '\\cs(0,255,0)'..woodworking..'\\cr'
    local target = windower.ffxi.get_mob_by_target('st') or windower.ffxi.get_mob_by_target('t') or windower.ffxi.get_mob_by_target('me')
    if target then get_target(target.index) end
end)

windower.register_event('addon command', function(command, ...)
    command = command and command:lower()
    local args = T{...}
    if not command then
        windower.add_to_chat(207,"First argument not specified, use '//ib|infobar help' for info.")
    elseif command == 'help' then
        windower.add_to_chat(207,"Infobar Commands:")
        windower.add_to_chat(207,"//ib|infobar notes add 'string'")
        windower.add_to_chat(207,"//ib|infobar notes delete")
    elseif command == 'notes' then
        local target = windower.ffxi.get_mob_by_target('t')
        local tname = string.gsub(target.name, ' ', '_')
        if not args[1] then
            windower.add_to_chat(207,"Second argument not specified, use '//ib|infobar help' for info.")
        elseif args[1]:lower() == 'add' then
            if not target then windower.add_to_chat(207,"No target selected") return end
            for i,v in pairs(args) do args[i]=windower.convert_auto_trans(args[i]) end
            local str = table.concat(args," ",2)
            notesdb:exec('INSERT OR REPLACE INTO notes VALUES ("'..target.name..'","'..str..'")')
            get_target(target.index)
        elseif args[1]:lower() == 'delete' then
            if not target then windower.add_to_chat(207,"No target selected") return end
            notesdb:exec('DELETE FROM notes WHERE name = "'..target.name..'"')
            get_target(target.index)
        else
            windower.add_to_chat(207,"Second argument wrong, use '//ib|infobar help' for info.")
        end
    elseif command == 'mob' or command == 'prop' or command == 'property' then
        local target = windower.ffxi.get_mob_by_target('t')
        if not args[1] then windower.add_to_chat(207,'No property specified.') return
        elseif not target or target.spawn_type ~= 16 then windower.add_to_chat(207,'No mob selected.') return end

        windower.add_to_chat(207, '%s %s:%s':format(mob.name, args[1], tostring(mob[args[1]]) or ''))
    else
        windower.add_to_chat(207,"First argument wrong, use '//ib|infobar help' for info.")
    end
end)

function scan()
    if scanning + max_scan_wait > os.clock() then return end

    -- Check if in zone
    local info = windower.ffxi.get_info()
    local self = windower.ffxi.get_mob_by_target('me')
    if not self or not info or invalid_zones:contains(res.zones[info.zone].en) then return end

    scanning = os.clock()

    packet = packets.new('outgoing', PACKET_WIDESCAN, {
        ['Flags'] = 1,
        ['_unknown1'] = 0,
        ['_unknown2'] = 0,
    })
    packets.inject(packet)
end
