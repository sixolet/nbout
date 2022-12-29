local mod = require 'core/mods'

local my_midi = {
    name="nb",
    connected=true,
}
function my_midi:send(data) end
function my_midi:note_on(note, vel, ch)
    -- TOODO
end
function my_midi:note_off(note, vel, ch)
    -- TODO
end
function my_midi:pitchbend(val, ch)
    -- TODO
end
function my_midi:cc(cc, val, ch)
end
function my_midi:key_pressure(note, val, ch) end
function my_midi:channel_pressure(val, ch) end
function my_midi:program_change(val, ch) end
function my_midi:stop()	end
function my_midi:continue()	end
function my_midi:clock() end

local fake_midi = {
    real_midi = midi,
}

local meta_fake_midi = {}

setmetatable(fake_midi, meta_fake_midi)

meta_fake_midi.__index = function(t, key)
    if key == 'vports' then
        local ret = {}
        for _, v in ipairs(t.real_midi.vports) do
            table.insert(ret, v)
        end
        table.insert(ret, my_midi)
        return ret
    end
    if key == 'devices' then
        local ret = {}
        for _, d in ipairs(t.real_midi.devices) do
            table.insert(ret, d)
        end
        table.insert(ret, {
            name="nb",
            port=17,
            id=-1,
        })
        return ret
    end
    return t.real_midi[key]
end

mod.hook.register("script_pre_init", "etc pre init", function()
    midi = fake_midi
end)

mod.hook.register("script_post_cleanup", "etc post cleanup", function()
    midi = fake_midi.real_midi
end)