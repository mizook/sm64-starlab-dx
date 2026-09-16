-- Native texture lookup and code-drawn course/objective illustrations.
return function(app)
    local state = app.state
    local catalog = app.catalog
    local drawing = app.drawing
    local art = app.art

    local paintingIds = {
        { "0700A800", "0700B800" },
        { "0700E800", "0700F800" },
        { "07010800", "07011800" },
        { "0700C800", "0700D800" },
        { "boo_castle_seg6_texture_06015670", nil, true },
        { "07016800" },
        { "07013800", "07012800" },
        { "07014800", "07015800" },
        { "07017000" },
        { "0701F800", "07020800" },
        { "07017800", "07018800" },
        { "0701B800", "0701C800" },
        { "07019800", "0701A800" },
        { "0701D800", "0701E800" },
        { "texture_quarter_flying_carpet", nil, true },
    }

    local textureCache = {}

    function art.paintingTexture(id, explicit)
        local name = explicit and id or "inside_castle_seg7_texture_" .. id
        if not textureCache[name] then
            textureCache[name] = get_texture_info(name)
        end
        return textureCache[name]
    end

    -- Stylized course references drawn in Lua, not in-game screenshots.
    function art.drawCourseScene(index, x, y, size)
        local scale = size / 100
        local function box(a, b, w, h, r, g, blue)
            djui_hud_set_color(r, g, blue, 255)
            djui_hud_render_rect(x + a * scale, y + b * scale, w * scale, h * scale)
        end
        local function disk(a, b, r, cr, cg, cb)
            for row = -r, r do
                local half = math.sqrt(math.max(0, r * r - row * row))
                box(a - half, b + row, half * 2 + 1, 1, cr, cg, cb)
            end
        end
        local function roof(a, b, w, h, r, g, blue)
            for row = 0, h do
                local span = w * row / h
                box(a + (w - span) / 2, b + row, span, 1, r, g, blue)
            end
        end
        local function cloud(a, b, w)
            disk(a + w * 0.25, b, 5, 224, 236, 248)
            disk(a + w * 0.5, b - 3, 7, 237, 245, 255)
            disk(a + w * 0.75, b, 5, 224, 236, 248)
            box(a, b, w, 5, 224, 236, 248)
        end
        local function platform(a, b, w, r, g, blue)
            box(a, b, w, 4, r, g, blue)
            box(a + 2, b + 4, w - 4, 6, math.floor(r * 0.6), math.floor(g * 0.6), math.floor(blue * 0.6))
            for j = 3, w - 3, 9 do
                box(a + j, b + 4, 1, 5, 40, 35, 60)
            end
        end
        local function pipe(a, b)
            box(a + 2, b + 3, 12, 17, 35, 111, 65)
            box(a + 3, b + 3, 3, 17, 99, 203, 92)
            box(a, b, 16, 5, 63, 162, 71)
            box(a + 3, b + 1, 10, 2, 13, 63, 39)
        end
        local function carpet(a, b, w)
            box(a - 2, b + 3, w + 4, 2, 244, 191, 63)
            box(a, b, w, 10, 255, 203, 73)
            box(a + 2, b + 2, w - 4, 6, 182, 43, 113)
            box(a + 5, b + 4, w - 10, 2, 235, 100, 160)
            for j = 1, w, 4 do
                box(a + j, b + 10, 1, 3, 242, 193, 64)
            end
        end
        box(-3, -3, 106, 106, 162, 123, 68)
        box(-1, -1, 102, 102, 28, 33, 49)
        if index == 5 then
            box(0, 0, 100, 100, 24, 24, 49)
            for row = 0, 8 do
                box(0, row * 10, 100, 10, 24 + row * 3, 24 + row * 2, 49 + row * 3)
            end
            disk(80, 16, 11, 240, 227, 173)
            disk(76, 13, 10, 32, 29, 57)
            box(0, 67, 100, 33, 27, 36, 38)
            -- Mansion, pitched roofs, lit windows and iron fence.
            box(20, 43, 59, 32, 89, 84, 105)
            box(24, 48, 51, 25, 69, 66, 83)
            box(16, 34, 17, 39, 76, 72, 94)
            box(67, 34, 17, 39, 76, 72, 94)
            roof(11, 19, 27, 18, 106, 65, 108)
            roof(62, 19, 27, 18, 106, 65, 108)
            roof(26, 23, 48, 23, 116, 71, 112)
            box(39, 18, 8, 15, 62, 57, 76)
            for _, a in ipairs({ 21, 40, 54, 72 }) do
                box(a, 44, 6, 10, 255, 212, 101)
                box(a + 2, 44, 1, 10, 81, 65, 72)
                box(a, 48, 6, 1, 81, 65, 72)
            end
            box(43, 59, 13, 16, 26, 27, 38)
            box(45, 60, 3, 14, 87, 69, 86)
            for a = 4, 96, 7 do
                box(a, 72, 1, 11, 9, 15, 27)
                roof(a - 1, 68, 3, 4, 9, 15, 27)
            end
            box(2, 75, 96, 1, 9, 15, 27)
            -- Boo gives the entrance a recognizable foreground subject.
            disk(77, 65, 13, 242, 244, 250)
            box(70, 71, 13, 8, 242, 244, 250)
            disk(64, 68, 4, 242, 244, 250)
            disk(90, 68, 4, 242, 244, 250)
            box(72, 61, 3, 5, 43, 56, 109)
            box(80, 61, 3, 5, 43, 56, 109)
            box(73, 70, 10, 3, 94, 30, 60)
            box(77, 73, 5, 4, 230, 85, 127)
        elseif index == 15 then
            for row = 0, 9 do
                box(0, row * 10, 100, 10, 75 + row * 7, 135 + row * 6, 211 + row * 4)
            end
            cloud(4, 20, 29)
            cloud(66, 36, 30)
            cloud(0, 73, 37)
            -- Distant flying ship and stepped floating platforms.
            box(66, 16, 26, 5, 143, 92, 58)
            box(70, 21, 18, 4, 104, 64, 54)
            box(78, 4, 2, 14, 118, 87, 66)
            roof(80, 4, 12, 10, 243, 225, 183)
            platform(48, 39, 19, 217, 211, 185)
            platform(75, 54, 23, 225, 216, 181)
            platform(20, 76, 28, 209, 198, 171)
            carpet(10, 35, 28)
            carpet(40, 60, 31)
            carpet(73, 78, 23)
            for _, point in ipairs({ { 36, 51 }, { 38, 49 }, { 41, 48 }, { 44, 47 } }) do
                disk(point[1], point[2], 1, 255, 234, 158)
            end
        elseif index == 16 then
            for row = 0, 9 do
                box(0, row * 10, 100, 10, 22 + row * 3, 22 + row * 2, 47 + row * 5)
            end
            disk(80, 14, 8, 99, 92, 150)
            -- Dark World's isolated zigzag platforms and final pipe.
            platform(3, 73, 28, 111, 158, 77)
            platform(31, 58, 26, 148, 129, 173)
            platform(57, 41, 26, 151, 131, 184)
            platform(72, 26, 26, 111, 158, 77)
            box(26, 67, 14, 3, 133, 114, 77)
            box(51, 51, 15, 3, 133, 114, 77)
            pipe(78, 7)
            for _, a in ipairs({ { 15, 65 }, { 43, 49 }, { 67, 33 } }) do
                disk(a[1], a[2], 2, 244, 100, 99)
            end
            box(38, 35, 3, 18, 176, 149, 88)
            box(31, 32, 18, 4, 207, 180, 105)
        elseif index == 17 then
            for row = 0, 9 do
                box(0, row * 10, 100, 10, 61 + row * 7, 25 + row * 2, 37)
            end
            box(0, 65, 100, 35, 229, 70, 27)
            for row = 0, 3 do
                for col = 0, 4 do
                    box(col * 19 + row % 2 * 7, 68 + row * 7, 11, 2, 255, 166, 40)
                end
            end
            -- Fire Sea's steel lifts, narrow bridges and lava.
            box(14, 26, 4, 49, 64, 48, 46)
            box(43, 20, 4, 49, 64, 48, 46)
            for b = 27, 65, 8 do
                box(18, b, 25, 2, 110, 70, 49)
            end
            platform(6, 54, 35, 154, 143, 125)
            platform(46, 41, 25, 173, 162, 141)
            platform(69, 24, 29, 154, 143, 125)
            pipe(78, 5)
            for _, a in ipairs({ { 22, 47 }, { 57, 34 }, { 77, 17 } }) do
                disk(a[1], a[2], 2, 255, 218, 84)
            end
            roof(52, 67, 10, 18, 255, 184, 41)
            roof(86, 60, 8, 23, 255, 184, 41)
        else
            for row = 0, 9 do
                box(0, row * 10, 100, 10, 37 + row * 5, 43 + row * 5, 89 + row * 7)
            end
            cloud(0, 70, 38)
            cloud(69, 50, 31)
            -- Sky's exposed staircase and final approach above the clouds.
            for j = 0, 6 do
                platform(7 + j * 9, 78 - j * 7, 15, 180, 166, 202)
            end
            platform(69, 24, 29, 137, 122, 175)
            pipe(78, 5)
            box(15, 34, 3, 18, 188, 170, 211)
            box(7, 31, 23, 4, 217, 201, 229)
            for _, a in ipairs({ { 29, 53 }, { 48, 39 }, { 67, 26 } }) do
                disk(a[1], a[2], 2, 248, 210, 91)
            end
            local tex = art.paintingTexture("texture_hud_char_star", true)
            if tex and tex.width and tex.width > 0 then
                djui_hud_set_color(255, 255, 255, 255)
                djui_hud_render_texture(
                    tex,
                    x + 42 * scale,
                    y + 5 * scale,
                    20 * scale / tex.width,
                    20 * scale / tex.height
                )
            end
        end
        box(0, 88, 100, 12, 17, 22, 35)
        drawing.drawText(
            catalog.courses[index][1]:upper(),
            x + 4 * scale,
            y + 90 * scale,
            0.18 * scale,
            255,
            223,
            160
        )
        drawing.drawText("ILUSTRACION", x + 34 * scale, y + 91 * scale, 0.115 * scale, 183, 196, 213)
    end

    function art.drawPainting(index, x, y, size)
        if index == 5 or index == 15 or (index >= 16 and index <= 18) then
            art.drawCourseScene(index, x, y, size)
            return
        end
        if index > 18 then
            djui_hud_set_color(32, 50, 80, 255)
            djui_hud_render_rect(x, y, size, size)
            drawing.drawText(catalog.courses[index][1]:upper(), x + 6, y + size * 0.38, 0.35, 255, 224, 160)
            return
        end
        if catalog.courses[index][4] then
            djui_hud_set_color(53, 27, 38, 255)
            djui_hud_render_rect(x, y, size, size)
            djui_hud_set_color(197, 65, 42, 255)
            djui_hud_render_rect(x, y + size - 5, size, 5)
            drawing.drawText("BOWSER", x + 8, y + size * 0.22, 0.30, 255, 224, 160)
            drawing.drawText(tostring(index - 15), x + size * 0.39, y + size * 0.43, 0.8, 255, 224, 160)
            return
        end
        local ids = paintingIds[index]
        djui_hud_set_color(164, 119, 56, 255)
        djui_hud_render_rect(x - 3, y - 3, size + 6, size + 6)
        djui_hud_set_color(255, 255, 255, 255)
        local top = art.paintingTexture(ids[1], ids[3])
        local bottom = ids[2] and art.paintingTexture(ids[2], false) or nil
        if top and top.width and top.width > 0 and top.height > 0 then
            djui_hud_render_texture(top, x, y, size / top.width, (bottom and size / 2 or size) / top.height)
            if bottom then
                djui_hud_render_texture(
                    bottom,
                    x,
                    y + size / 2,
                    size / bottom.width,
                    size / 2 / bottom.height
                )
            end
        else
            drawing.drawText(catalog.courses[index][1]:upper(), x + 6, y + size / 2, 0.4)
        end
    end

    art.wfHints = {
        "Derrota al jefe en la cima.",
        "Sube hasta lo alto de la torre.",
        "Usa el canon para llegar al poste.",
        "Recoge las 8 monedas rojas.",
        "Entra en la jaula con el buho.",
        "Rompe la esquina de la pared.",
        "Reune 100 monedas del nivel.",
    }

    -- Objective illustrations, not screenshots or maps. Native textures stay in the game.
    function art.drawStarIllustration(target, x, y, size)
        local scale = size / 100
        local function box(a, b, w, h, r, g, blue)
            djui_hud_set_color(r, g, blue, 255)
            djui_hud_render_rect(x + a * scale, y + b * scale, w * scale, h * scale)
        end
        local function disk(a, b, r, cr, cg, cb)
            for row = -r, r do
                local width = math.sqrt(math.max(0, r * r - row * row))
                box(a - width, b + row, width * 2, 1, cr, cg, cb)
            end
        end
        local function native(name, a, b, w, h)
            local tex = art.paintingTexture(name, true)
            if not tex or not tex.width or tex.width <= 0 or tex.height <= 0 then
                return false
            end
            djui_hud_set_color(255, 255, 255, 255)
            djui_hud_render_texture(
                tex,
                x + a * scale,
                y + b * scale,
                w * scale / tex.width,
                h * scale / tex.height
            )
            return true
        end
        local function starAt(a, b, n)
            drawing.titleStar(x + a * scale, y + b * scale, n * scale)
        end
        local function coin(a, b, red)
            disk(a, b, 7, red and 238 or 246, red and 69 or 183, red and 65 or 43)
            box(a - 1, b - 4, 2, 8, 255, red and 163 or 237, red and 136 or 145)
        end
        local function platform(a, b, w)
            box(a, b, w, 5, 111, 185, 91)
            box(a, b + 5, w, 7, 125, 100, 77)
        end
        box(-2, -2, 104, 104, 214, 169, 70)
        box(0, 0, 100, 100, 50, 99, 155)
        box(9, 17, 22, 3, 168, 209, 228)
        box(65, 29, 25, 3, 168, 209, 228)
        if target == 1 then
            platform(12, 80, 76)
            box(25, 73, 15, 7, 127, 95, 63)
            box(61, 73, 15, 7, 127, 95, 63)
            box(16, 40, 12, 20, 179, 177, 166)
            box(73, 40, 12, 20, 179, 177, 166)
            if not native("whomp_seg6_texture_0601D360", 29, 10, 43, 68) then
                box(29, 10, 43, 68, 151, 149, 141)
                box(35, 27, 10, 8, 245, 240, 210)
                box(56, 27, 10, 8, 245, 240, 210)
                box(39, 29, 4, 7, 25, 33, 44)
                box(57, 29, 4, 7, 25, 33, 44)
                box(40, 50, 20, 7, 39, 39, 39)
            end
            starAt(70, 3, 19)
        elseif target == 2 then
            platform(10, 82, 80)
            box(34, 25, 34, 57, 151, 155, 157)
            box(60, 25, 8, 57, 111, 121, 134)
            box(29, 21, 44, 7, 201, 197, 178)
            for row = 1, 4 do
                box(34, 25 + row * 11, 34, 1, 105, 121, 139)
            end
            box(44, 60, 14, 22, 43, 60, 91)
            box(15, 68, 21, 4, 193, 185, 158)
            box(63, 49, 22, 4, 193, 185, 158)
            starAt(41, 2, 22)
        elseif target == 3 then
            platform(6, 81, 34)
            box(9, 68, 20, 13, 33, 47, 70)
            for j = 0, 12 do
                box(19 + j, 65 - j, 18, 3, 31, 43, 60)
            end
            disk(39, 50, 10, 13, 29, 50)
            box(73, 18, 3, 50, 230, 221, 181)
            platform(60, 69, 30)
            for j = 1, 3 do
                disk(43 + j * 8, 42 - j * 5, 1, 255, 226, 113)
            end
            starAt(65, 50, 20)
        elseif target == 4 then
            platform(20, 49, 60)
            box(39, 61, 20, 10, 117, 98, 83)
            for _, point in ipairs({
                { 17, 20 },
                { 39, 13 },
                { 63, 14 },
                { 85, 24 },
                { 86, 55 },
                { 75, 78 },
                {
                    40,
                    80,
                },
                {
                    14,
                    60,
                },
            }) do
                coin(point[1], point[2], true)
            end
            starAt(40, 28, 22)
        elseif target == 5 then
            platform(37, 76, 50)
            starAt(50, 40, 25)
            box(37, 27, 50, 4, 226, 222, 201)
            box(37, 72, 50, 4, 226, 222, 201)
            for j = 0, 4 do
                box(37 + j * 12, 27, 2, 49, 202, 213, 220)
            end
            box(30, 20, 64, 4, 133, 151, 173)
            box(9, 32, 18, 20, 110, 80, 51)
            box(3, 37, 6, 8, 90, 65, 44)
            box(27, 37, 6, 8, 90, 65, 44)
            disk(14, 39, 4, 245, 232, 169)
            disk(23, 39, 4, 245, 232, 169)
            box(13, 38, 2, 4, 32, 34, 38)
            box(22, 38, 2, 4, 32, 34, 38)
        elseif target == 6 then
            for row = 0, 3 do
                for col = 0, 2 do
                    if not (row == 0 and col == 2) then
                        box(30 + col * 18, 20 + row * 14, 17, 13, 185 - row * 9, 162 - row * 8, 122 - row * 6)
                    end
                end
            end
            -- Missing corner and small fragments identify the breakable wall.
            box(82, 23, 6, 6, 215, 188, 141)
            box(90, 34, 4, 4, 193, 166, 125)
            starAt(60, 6, 20)
            platform(5, 82, 90)
            disk(18, 70, 12, 31, 43, 60)
            for j = 0, 8 do
                box(18 + j, 60 - j, 12, 3, 24, 36, 50)
            end
        else
            for _, point in ipairs({
                { 21, 23 },
                { 49, 15 },
                { 77, 24 },
                { 17, 50 },
                { 83, 50 },
                { 14, 70 },
                {
                    86,
                    70,
                },
            }) do
                coin(point[1], point[2], false)
            end
            starAt(36, 31, 28)
            drawing.drawText("100", x + 31 * scale, y + 65 * scale, 0.48 * scale, 255, 240, 158)
        end
        box(0, 90, 100, 10, 20, 42, 70)
        drawing.fitted("ILUSTRACION", x + 4 * scale, y + 92 * scale, 0.20 * scale, 92 * scale, 210, 227, 245)
    end

    function art.bowserHint(index, target)
        if not catalog.courses[index][4] then
            return catalog.courses[index][2]
        end
        return target == 1 and "Entra al tubo de Bowser para terminar."
            or target == 2 and (index == 18 and "Cruza el nivel y recoge la estrella final." or "Cruza el nivel y recoge la llave de Bowser.")
            or "Recoge la estrella de las 8 monedas rojas."
    end

    function art.drawTargetPreview(index, target, x, y, size)
        art.drawPainting(index, x, y, size)
        return false
    end

    -- A run has its own emblem, rather than borrowing one course's painting.
    function art.drawRunEmblem(x, y, size)
        djui_hud_set_color(164, 119, 56, 255)
        djui_hud_render_rect(x - 3, y - 3, size + 6, size + 6)
        djui_hud_set_color(10, 26, 57, 255)
        djui_hud_render_rect(x, y, size, size)
        drawing.titleStar(x + size * 0.24, y + size * 0.12, size * 0.52)
        -- Finish-line pattern, drawn at native resolution like the N64 controls.
        for row = 0, 1 do
            for col = 0, 9 do
                local shade = (row + col) % 2 == 0 and 232 or 53
                djui_hud_set_color(shade, shade, shade, 255)
                djui_hud_render_rect(
                    x + size * 0.12 + col * size * 0.076,
                    y + size * 0.74 + row * size * 0.076,
                    size * 0.076,
                    size * 0.076
                )
            end
        end
    end
end
