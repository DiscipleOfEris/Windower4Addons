--Copyright (c) 2014, Byrthnoth
--All rights reserved.

--Redistribution and use in source and binary forms, with or without
--modification, are permitted provided that the following conditions are met:

--    * Redistributions of source code must retain the above copyright
--      notice, this list of conditions and the following disclaimer.
--    * Redistributions in binary form must reproduce the above copyright
--      notice, this list of conditions and the following disclaimer in the
--      documentation and/or other materials provided with the distribution.
--    * Neither the name of <addon name> nor the
--      names of its contributors may be used to endorse or promote products
--      derived from this software without specific prior written permission.

--THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
--ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
--WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
--DISCLAIMED. IN NO EVENT SHALL <your name> BE LIABLE FOR ANY
--DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
--(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
--LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
--ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
--(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
--SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


--Default settings file:
default_settings = {
    strings = {
        default = "string.format('%d/%dXP %sMerits XP/hr:%.1fk',xp.current,xp.tnl,max_color('%5.2f':format(math.floor(lp.current/lp.tnm*100)/100+lp.number_of_merits),lp.current/lp.tnm+lp.number_of_merits,lp.maximum_merits,58,147,191),math.floor(xp.rate/100)/10)",
        dynamis = "string.format('%d/%dXP %sMerits XP/hr:%.1fk %s %s',xp.current,xp.tnl,max_color('%5.2f':format(math.floor(lp.current/lp.tnm*100)/100+lp.number_of_merits),lp.current/lp.tnm+lp.number_of_merits,lp.maximum_merits,58,147,191),math.floor(xp.rate/100)/10,dynamis.KIs,dynamis.time_remaining or 0)",
        abyssea = "string.format('%d/%dXP %sMerits XP/hr:%.1fk',xp.current,xp.tnl,max_color('%5.2f':format(math.floor(lp.current/lp.tnm*100)/100+lp.number_of_merits),lp.current/lp.tnm+lp.number_of_merits,lp.maximum_merits,58,147,191),math.floor(xp.rate/100)/10)",
        },
    text_box_settings = {
        pos = {
            x = 0,
            y = 0,
        },
        bg = {
            alpha = 255,
            red = 0,
            green = 0,
            blue = 0,
            visible = true
        },
        flags = {
            right = false,
            bottom = false,
            bold = false,
            italic = false
        },
        padding = 0,
        text = {
            size = 12,
            font = 'Consolas',
            fonts = {},
            alpha = 255,
            red = 255,
            green = 255,
            blue = 255
        }
    }
}

-- Approved textbox commands:
approved_commands = S{'show','hide','pos','pos_x','pos_y','font','size','pad','color','alpha','transparency','bg_color','bg_alpha','bg_transparency'}
approved_commands = {show={n=0},hide={n=0},pos={n=2,t='number'},pos_x={n=1,t='number'},pos_y={n=1,t='number'},
    font={n=2,t='string'},size={n=1,t='number'},pad={n=1,t='number'},color={n=3,t='number'},alpha={n=1,t='number'},
    transparency={n=1,t='number'},bg_color={n=3,t='number'},bg_alpha={n=1,t='number'},bg_transparency={n=1,t='number'}}


-- Dynamis TE lists:
city_table = {Crimson=10,Azure=10,Amber=10,Alabaster=15,Obsidian=15}
other_table = {Crimson=10,Azure=10,Amber=10,Alabaster=10,Obsidian=20}

-- Mapping of zone ID to TE list:
dynamis_map = {[185]=city_table,[186]=city_table,[187]=city_table,[188]=city_table,
    [134]=other_table,[135]=other_table,[39]=other_table,[40]=other_table,[41]=other_table,[42]=other_table}

-- Not technically static, but sets the initial values for all features:
function initialize()
    cp = {
        registry = {},
        current = 0,
        rate = 0,
        total = 0,
        tnjp = 30000,
        number_of_job_points = 0,
        maximum_job_points = 500,
    }

    
    xp = {
        registry = {},
        total = 0,
        rate = 0,
        current = 0,
        tnl = 0,
        job = 0,
        job_abbr = 0,
        job_level = 0,
        sub_job = 0,
        sub_job_abbr = 0,
        sub_job_level = 0,
    }
    
    lp = {
        registry = xp.registry,
        current = 0,
        tnm = 10000,
        number_of_merits = 0,
        maximum_merits = 30,
    }

    ep = {
        registry = {},
        current = 0,
        rate = 0,
        tnml = 0,
        master_level = 0,
    }
    
    sparks = {
        current = 0,
        maximum = 99999,
    }
    
    accolades = {
        current = 0,
        maximum = 99999,
    }
    
    abyssea = {
        amber = 0,
        azure = 0,
        ruby = 0,
        pearlescent = 0,
        ebon = 0,
        silvery = 0,
        golden = 0,
        update_time = 0,
        time_remaining = 0,
    }
    
    
    local info = windower.ffxi.get_info()
    
    frame_count = 0
    
    dynamis = {
        KIs = '',
        _KIs = {},
        entry_time = 0,
        time_limit = 0,
        zone = 0,
    }
    if info.logged_in and res.zones[info.zone].english:sub(1,7) == 'Dynamis' then
        cur_func = loadstring("current_string = "..settings.strings.dynamis)
        setfenv(cur_func,_G)
        dynamis.entry_time = os.clock()
        dynamis.zone = info.zone
        windower.add_to_chat(123,'Loading PointWatch in Dynamis results in an inaccurate timer. Number of KIs is displayed.')
    elseif info.logged_in then
        cur_func = loadstring("current_string = "..settings.strings.default)
        setfenv(cur_func,_G)
    end
    
    for _, field_to_remove in ipairs(fields_to_remove.incoming[0x061]) do
        local label = field_to_remove.label
        for i, field in ipairs(packets.raw_fields.incoming[0x061]) do
            if field.label == label then
                packets.raw_fields.incoming[0x061][i] = nil
            end
        end
    end
    
    for _,id in ipairs(packet_initiators) do
        local handler = packet_handlers[id]
        if handler then
            local last = windower.packets.last_incoming(id)
            if last then
                handler(last)
            end
        end
    end
end

fields_to_remove = {}
fields_to_remove.incoming = {}

-- Char Stats
fields_to_remove.incoming[0x061] = L{
--    {ctype='unsigned int',      label='Maximum HP'},                            -- 04
--    {ctype='unsigned int',      label='Maximum MP'},                            -- 08
--    {ctype='unsigned char',     label='Main Job',           fn=job},            -- 0C
--    {ctype='unsigned char',     label='Main Job Level'},                        -- 0D
--    {ctype='unsigned char',     label='Sub Job',            fn=job},            -- 0E
--    {ctype='unsigned char',     label='Sub Job Level'},                         -- 0F
--    {ctype='unsigned short',    label='Current EXP'},                           -- 10
--    {ctype='unsigned short',    label='Required EXP'},                          -- 12
--    {ctype='unsigned short',    label='Base STR'},                              -- 14
--    {ctype='unsigned short',    label='Base DEX'},                              -- 16
--    {ctype='unsigned short',    label='Base VIT'},                              -- 18
--    {ctype='unsigned short',    label='Base AGI'},                              -- 1A
--    {ctype='unsigned short',    label='Base INT'},                              -- 1C
--    {ctype='unsigned short',    label='Base MND'},                              -- 1E
--    {ctype='unsigned short',    label='Base CHR'},                              -- 20
--    {ctype='signed short',      label='Added STR'},                             -- 22
--    {ctype='signed short',      label='Added DEX'},                             -- 24
--    {ctype='signed short',      label='Added VIT'},                             -- 26
--    {ctype='signed short',      label='Added AGI'},                             -- 28
--    {ctype='signed short',      label='Added INT'},                             -- 2A
--    {ctype='signed short',      label='Added MND'},                             -- 2C
--    {ctype='signed short',      label='Added CHR'},                             -- 2E
--    {ctype='unsigned short',    label='Attack'},                                -- 30
--    {ctype='unsigned short',    label='Defense'},                               -- 32
--    {ctype='signed short',      label='Fire Resistance'},                       -- 34
--    {ctype='signed short',      label='Wind Resistance'},                       -- 36
--    {ctype='signed short',      label='Lightning Resistance'},                  -- 38
--    {ctype='signed short',      label='Light Resistance'},                      -- 3A
--    {ctype='signed short',      label='Ice Resistance'},                        -- 3C
--    {ctype='signed short',      label='Earth Resistance'},                      -- 3E
--    {ctype='signed short',      label='Water Resistance'},                      -- 40
--    {ctype='signed short',      label='Dark Resistance'},                       -- 42
--    {ctype='unsigned short',    label='Title',           fn=title},             -- 44
--    {ctype='unsigned short',    label='Nation rank'},                           -- 46
--    {ctype='unsigned short',    label='Rank points',        fn=cap+{0xFFF}},    -- 48
--    {ctype='unsigned short',    label='Home point',         fn=zone},           -- 4A
--    {ctype='unsigned short',    label='_unknown1'},                             -- 4C   0xFF-ing this last region has no notable effect.
--    {ctype='unsigned short',    label='_unknown2'},                             -- 4E
--    {ctype='unsigned char',     label='Nation'},                                -- 50   0 = sandy, 1 = bastok, 2 = windy
    {ctype='unsigned char',     label='_unknown3'},                             -- 51   Possibly Unity ID (always 7 for me, I'm in Aldo's unity)
    {ctype='unsigned char',     label='Su Level'},                              -- 52
    {ctype='unsigned char',     label='_unknown4'},                             -- 53   Always 00 for me
    {ctype='unsigned char',     label='Maximum iLevel'},                        -- 54
    {ctype='unsigned char',     label='iLevel over 99'},                        -- 55   0x10 would be an iLevel of 115
    {ctype='unsigned char',     label='Main Hand iLevel'},                      -- 56
    {ctype='unsigned char',     label='_unknown5'},                             -- 57   Always 00 for me
    {ctype='bit[5]',            label='Unity ID'},                              -- 58   0=None, 1=Pieuje, 2=Ayame, 3=Invincible Shield, 4=Apururu, 5=Maat, 6=Aldo, 7=Jakoh Wahcondalo, 8=Naja Salaheem, 9=Flavira
    {ctype='bit[5]',            label='Unity Rank'},                            -- 58   Danger, 00ing caused my client to crash
    {ctype='bit[17]',           label='Unity Points'},                          -- 59
    {ctype='bit[5]',            label='_unknown6'},                             -- 5A   No obvious function
    {ctype='unsigned int',      label='_junk1'},                                -- 5C
    {ctype='unsigned int',      label='_junk2'},                                -- 60
    {ctype='unsigned char',     label='_unknown7'},                             -- 64
    {ctype='unsigned char',     label='Master Level'},                          -- 65
    {ctype='boolbit',           label='Master Breaker'},                        -- 66
    {ctype='bit[15]',           label='_junk3'},                                -- 66
    {ctype='unsigned int',      label='Current Exemplar Points'},               -- 68
    {ctype='unsigned int',      label='Required Exemplar Points'},              -- 6C
}