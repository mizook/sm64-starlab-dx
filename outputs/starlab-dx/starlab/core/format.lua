-- Shared 30 Hz time formatting.
return function(app)
    local format = app.format

    function format.fmt(value)
        if not value then
            return "--:--.--"
        end
        local cs = math.floor(value * 100 / 30)
        return string.format("%02d:%02d.%02d", math.floor(cs / 6000), math.floor(cs / 100) % 60, cs % 100)
    end
end
