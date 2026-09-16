-- Controller input consumption.
return function(app)
    local input = app.input

    function input.consumeInput(c)
        c.buttonPressed, c.buttonDown = 0, 0
        c.stickX, c.stickY, c.stickMag = 0, 0, 0
    end
end
