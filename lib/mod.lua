local mod = require 'core/mods'
local nb = require('nbout/lib/nb/lib/nb')

local channel_is_set_up = false

local my_midi = {
    name="nb",
    connected=true,
}
function my_midi:send(data) end
function my_midi:note_on(note, vel, ch)
    if ch == 1 then
        if not channel_is_set_up then
            print("nbout received note_on before initialization")
            return
        end
        local p = params:lookup_param("nbout_chan_1"):get_player()
        -- some sequencers (e.g. jala) seem to send nil for vel.
        -- assume they want a default velocity
        if vel == nil then
            vel = 80
        end
        p:note_on(note, vel/127)
    end
end
function my_midi:note_off(note, vel, ch)
    if ch == 1 then
        if not channel_is_set_up then
            print("nbout received note_on before initialization")
            return
        end
        local p = params:lookup_param("nbout_chan_1"):get_player()
        p:note_off(note)
    end
end
function my_midi:pitchbend(val, ch)
    -- TODO
end
function my_midi:cc(cc, val, ch)
    if ch == 1 and cc == 72 then
        if not channel_is_set_up then
            print("nbout received note_on before initialization")
            return
        end
        local p = params:lookup_param("nbout_chan_1"):get_player()
        p:modulate(val/127)
    end
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
        for k, d in pairs(t.real_midi.devices) do
            ret[k] = d
        end
        ret[-1] = {
            name="nb",
            port=17,
            id=-1,
        }
        return ret
    end
    if key == 'connect' then
        return function(idx)
            if idx == nil then
                idx = 1
            end
            if idx <= 16 then
                if t.real_midi.vports[idx].name == "nb" then
                  print("Connecting to nbout")
                  return my_midi
                end
                return t.real_midi.connect(idx)
            end
            if idx == #t.real_midi.vports + 1 then
                return my_midi
            end
            return nil
        end
    end
    return t.real_midi[key]
end

mod.hook.register("script_pre_init", "nbout pre init", function()
    midi = fake_midi
    local old_init = init
    nb:init()
    init = function()
        old_init()
        params:add_separator("nbout")
        nb:add_param("nbout_chan_1", "nb midi ch 1")
        nb:add_player_params()
        channel_is_set_up = true
    end
end)

mod.hook.register("script_post_cleanup", "nbout post cleanup", function()
    channel_is_set_up = false
    midi = fake_midi.real_midi
end)
