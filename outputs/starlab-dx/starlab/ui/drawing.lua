-- HUD primitives, text layout and N64 button icons.
return function(app)
    local i18n = app.i18n
    local drawing = app.drawing
    local art = app.art
    local iconColor = djui_hud_set_color

    function drawing.drawText(text, x, y, scale, r, g, b)
        djui_hud_set_color(r or 240, g or 243, b or 246, 255)
        i18n.printText(text, x, y, scale)
    end

    function drawing.fitted(text, x, y, scale, width, r, g, b)
        local translated = i18n.tr(text)
        local measured = djui_hud_measure_text(translated)
        if measured and measured * scale > width then
            scale = width / measured
        end
        drawing.drawText(text, x, y, scale, r, g, b)
    end

    -- Wrap supporting copy at a readable size; never compress paragraphs into one line.
    function drawing.wrapped(text, x, y, scale, width, maxLines, r, g, b)
        local lines, line = {}, ""
        for word in i18n.tr(text):gmatch("%S+") do
            local candidate = line == "" and word or line .. " " .. word
            if line ~= "" and djui_hud_measure_text(candidate) * scale > width then
                lines[#lines + 1] = line
                line = word
            else
                line = candidate
            end
        end
        if line ~= "" then
            lines[#lines + 1] = line
        end
        for i = 1, math.min(#lines, maxLines) do
            local value = lines[i]
            if i == maxLines and #lines > maxLines then
                value = value .. "..."
            end
            drawing.fitted(value, x, y + (i - 1) * 11, scale, width, r, g, b)
        end
    end

    function drawing.buttonIcon(key, x, y, size, enabled)
        -- Scope color changes to this icon so disabled hints dim as a whole.
        local function djui_hud_set_color(r, g, b, a)
            local color = iconColor
            if enabled == false then
                color(105, 112, 125, 110)
            else
                color(r, g, b, a)
            end
        end
        if key == "stick" then
            djui_hud_set_color(118, 130, 158, 255)
            djui_hud_render_rect(x + 1, y + 3, size - 2, size - 4)
            djui_hud_set_color(224, 231, 242, 255)
            djui_hud_render_rect(x + 5, y + 1, size - 10, size - 3)
            djui_hud_render_rect(x + 2, y, size - 4, 4)
            return
        end
        if key == "down" or key == "up" or key == "left" or key == "right" or key == "dpad" then
            djui_hud_set_color(179, 190, 211, 255)
            djui_hud_render_rect(x + size * 0.35, y, size * 0.3, size)
            djui_hud_render_rect(x, y + size * 0.35, size, size * 0.3)
            djui_hud_set_color(52, 65, 94, 255)
            if key == "down" then
                djui_hud_render_rect(x + size * 0.42, y + size * 0.7, size * 0.16, size * 0.2)
            elseif key == "up" then
                djui_hud_render_rect(x + size * 0.42, y + size * 0.1, size * 0.16, size * 0.2)
            elseif key == "right" then
                djui_hud_render_rect(x + size * 0.7, y + size * 0.42, size * 0.2, size * 0.16)
            elseif key == "left" then
                djui_hud_render_rect(x + size * 0.1, y + size * 0.42, size * 0.2, size * 0.16)
            end
            return
        end
        if key == "L" then
            djui_hud_set_color(173, 185, 209, 255)
            djui_hud_render_rect(x, y + 2, size, size - 4)
            djui_hud_set_color(223, 232, 245, 255)
            djui_hud_render_rect(x + 1, y + 1, size - 2, 2)
            local scale = size / 44
            drawing.drawText(
                "L",
                x + (size - djui_hud_measure_text("L") * scale) / 2,
                y + 1,
                scale,
                24,
                39,
                70
            )
            return
        end
        local r, g, b =
            key == "A" and 45 or key == "B" and 30 or 161,
            key == "A" and 112 or key == "B" and 159 or 174,
            key == "A" and 235 or key == "B" and 89 or 197
        -- Scanlines keep circular N64 buttons crisp at native HUD resolution.
        for row = 0, size - 1 do
            local dy = row + 0.5 - size / 2
            local dx = math.sqrt(math.max(0, (size / 2) ^ 2 - dy ^ 2))
            djui_hud_set_color(r, g, b, 255)
            djui_hud_render_rect(x + size / 2 - dx, y + row, dx * 2, 1)
        end
        local scale = size / 40
        drawing.drawText(
            key,
            x + (size - djui_hud_measure_text(key) * scale) / 2,
            y + size * 0.09,
            scale,
            255,
            255,
            255
        )
    end

    function drawing.titleStar(x, y, size)
        local texture = art.paintingTexture("texture_hud_char_star", true)
        if texture and texture.width and texture.width > 0 and texture.height > 0 then
            djui_hud_set_color(255, 255, 255, 255)
            djui_hud_render_texture(texture, x, y, size / texture.width, size / texture.height)
        else
            local pixels =
                { "000010000", "000111000", "111111111", "011111110", "001111100", "011101110", "011000110" }
            for row, line in ipairs(pixels) do
                for col = 1, #line do
                    if line:sub(col, col) == "1" then
                        djui_hud_set_color(255, 213, 65, 255)
                        djui_hud_render_rect(
                            x + (col - 1) * size / 9,
                            y + (row - 1) * size / 7,
                            size / 9,
                            size / 7
                        )
                    end
                end
            end
            djui_hud_set_color(30, 33, 55, 255)
            djui_hud_render_rect(x + size * 0.38, y + size * 0.37, 1, size * 0.2)
            djui_hud_render_rect(x + size * 0.61, y + size * 0.37, 1, size * 0.2)
        end
    end

    function drawing.fittedName(text, x, y, scale, width, r, g, b)
        scale = math.min(scale, width / math.max(1, djui_hud_measure_text(text)))
        djui_hud_set_color(r or 255, g or 245, b or 210, 255)
        djui_hud_print_text(text, x, y, scale)
    end
end
