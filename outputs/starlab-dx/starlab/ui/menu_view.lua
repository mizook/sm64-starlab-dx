-- Menu rendering. Reads state and invokes drawing helpers.
return function(app)
    local state = app.state
    local catalog = app.catalog
    local format = app.format
    local records = app.records
    local routes = app.routes
    local runs = app.runs
    local menu = app.menu
    local drawing = app.drawing
    local art = app.art
    local menuView = app.menuView
    local flow, help = app.runFlow, app.help

    -- Selectors first, a distinct primary action, then compact utilities.
    local function trainingRows(labels, values, x, y, width)
        local practice = state.menu.screen == "practice"
        local offsets = practice and { -3, 27, 65, 117, 138 } or { -3, 22, 47, 72 }
        local heights = practice and { 27, 35, 30, 18, 12 } or { 23, 23, 23, 23 }
        local primary = practice and 3 or 4
        for row, label in ipairs(labels) do
            local ry, h = y + offsets[row], heights[row]
            local selected = row == state.menu.row
            local disabled = practice and row == 4 and not state.checkpoints.saved
                or not practice and (row == 2 or row == 3) and #state.editor.route == 0
            local utility = practice and row >= 4 or not practice and row == 5
            if practice and row >= 4 then
                local bw, by = (width - 6) / 2, y + 122
                local bx = x + (row - 4) * (bw + 6)
                djui_hud_set_color(
                    selected and 255 or 68,
                    selected and 211 or 91,
                    selected and 78 or 138,
                    255
                )
                djui_hud_render_rect(bx, by, bw, 28)
                djui_hud_set_color(selected and 42 or 25, selected and 88 or 57, selected and 159 or 110, 255)
                djui_hud_render_rect(bx + 1, by + 1, bw - 2, 26)
                drawing.fitted(
                    label,
                    bx + 5,
                    by + 4,
                    0.22,
                    bw - 10,
                    disabled and 139 or 240,
                    disabled and 157 or 243,
                    disabled and 183 or 246
                )
                drawing.buttonIcon("A", bx + 5, by + 16, 8, not disabled)
                drawing.fitted(
                    disabled and "Sin checkpoint"
                        or row == 4 and "Borrar punto guardado"
                        or "Ajustes y guardado",
                    bx + 17,
                    by + 16,
                    0.17,
                    bw - 22,
                    181,
                    200,
                    222
                )
            else
                if row == primary then
                    djui_hud_set_color(255, selected and 220 or 203, selected and 104 or 70, 255)
                    djui_hud_render_rect(x, ry, width, h)
                elseif selected then
                    djui_hud_set_color(42, 88, 159, 255)
                    djui_hud_render_rect(x, ry, width, h)
                    djui_hud_set_color(255, 211, 78, 255)
                    djui_hud_render_rect(x, ry, 2, h)
                end
                local adjustable = row == 1 or practice and row == 2
                local icon = selected and (adjustable and "dpad" or "A") or nil
                if icon then
                    drawing.buttonIcon(icon, x + width - 17, ry + (h - 10) / 2, 10, not disabled)
                end
                local maxWidth = width - 31
                if row == primary then
                    drawing.fitted(label, x + 8, ry + 3, 0.30, maxWidth, 25, 35, 58)
                    drawing.fitted(
                        values[row],
                        x + 8,
                        ry + (practice and 17 or 14),
                        practice and 0.21 or 0.19,
                        maxWidth,
                        46,
                        57,
                        75
                    )
                elseif utility then
                    drawing.fitted(
                        disabled and (label .. " / " .. values[row]) or label,
                        x + 8,
                        ry + 4,
                        0.24,
                        maxWidth,
                        disabled and 139 or 198,
                        disabled and 157 or 214,
                        disabled and 183 or 237
                    )
                else
                    drawing.fitted(label, x + 8, ry + 1, 0.19, maxWidth, 160, 182, 211)
                    if practice and row == 2 then
                        drawing.wrapped(values[row], x + 8, ry + 13, 0.28, maxWidth, 2, 255, 232, 160)
                    elseif not practice and row == 1 then
                        drawing.fittedName(values[row], x + 8, ry + 13, 0.31, maxWidth)
                    else
                        drawing.fitted(
                            values[row],
                            x + 8,
                            ry + 12,
                            0.27,
                            maxWidth,
                            disabled and 139 or 240,
                            disabled and 157 or 243,
                            disabled and 183 or 246
                        )
                    end
                end
            end
        end
    end

    function menuView.menuRows(labels, values, x, y, width)
        if state.menu.screen == "practice" or state.menu.screen == "runs" then
            trainingRows(labels, values, x, y, width)
            return
        end
        local primary = (state.menu.screen == "practice" or state.menu.screen == "builder") and 3
            or state.menu.screen == "runs" and (#state.editor.route == 0 and 2 or 4)
            or (state.menu.screen == "session" or state.menu.screen == "recordHelp") and 1
            or state.menu.screen == "runPlan" and 2
            or state.menu.screen == "runReview" and 2
            or nil
        local builder = state.menu.screen == "builder"
        local rowHeight, rowStep = builder and 32 or 27, builder and 33 or 29
        if builder then
            y = y - 3
        end
        local textOffset = builder and 3 or 0
        local targetY = y + (state.menu.row - 1) * rowStep
        if state.menu.focusScreen ~= state.menu.screen then
            state.menu.focusY, state.menu.focusScreen = targetY, state.menu.screen
        end
        state.menu.focusY = state.menu.focusY + (targetY - state.menu.focusY) * 0.35
        if primary then
            djui_hud_set_color(25, 100, 119, 255)
            djui_hud_render_rect(x, y + (primary - 1) * rowStep, width, rowHeight)
        end
        djui_hud_set_color(42, 88, 159, 255)
        djui_hud_render_rect(x, state.menu.focusY, width, rowHeight)
        djui_hud_set_color(255, 210, 83, 255)
        djui_hud_render_rect(x, state.menu.focusY, 2, rowHeight)
        for row, label in ipairs(labels) do
            local ry = y + (row - 1) * rowStep
            local danger = state.menu.screen == "settings" and row == 4
                or state.menu.screen == "route" and row == 3
            drawing.fitted(
                label,
                x + 8,
                ry + 2 + textOffset,
                0.21,
                width - 24,
                danger and 255 or 166,
                danger and 166 or 188,
                danger and 146 or 201
            )
            if (state.menu.screen == "runs" or state.menu.screen == "manage") and row == 1 then
                drawing.fittedName(values[row], x + 8, ry + 12 + textOffset, 0.29, width - 24)
            else
                drawing.fitted(
                    values[row],
                    x + 8,
                    ry + 12 + textOffset,
                    0.29,
                    width - 24,
                    row == primary and 194 or 240,
                    row == primary and 237 or 243,
                    row == primary and 217 or 246
                )
            end
            if row == state.menu.row then
                drawing.drawText(">", x + width - 11, ry + 10 + textOffset, 0.27, 255, 210, 83)
            end
        end
    end

    function menuView.drawMenu()
        local w, h = djui_hud_get_screen_width(), djui_hud_get_screen_height()
        local x, y = (w - 300) / 2, (h - 230) / 2
        djui_hud_set_color(6, 10, 17, 190)
        djui_hud_render_rect(0, 0, w, h)
        djui_hud_set_color(20, 42, 94, 250)
        djui_hud_render_rect(x, y, 300, 230)
        djui_hud_set_color(173, 39, 51, 255)
        djui_hud_render_rect(x, y, 300, 28)
        drawing.titleStar(x + 11, y + 5, 19)
        drawing.drawText("STARLAB", x + 36, y + 6, 0.44, 255, 235, 158)
        drawing.drawText("DX / " .. app.version, x + 238, y + 6, 0.21, 255, 226, 206)
        drawing.fittedName("by carlo ignacio", x + 238, y + 18, 0.17, 52, 255, 226, 206)
        drawing.drawText(
            state.menu.screen == "home" and "INICIO"
                or state.menu.screen == "manage" and "OPCIONES DE RUN"
                or state.menu.screen == "rename" and "NOMBRE DE RUN"
                or state.menu.screen == "builder" and "2 / 4  ANADIR ESTRELLAS"
                or state.menu.screen == "route" and "3 / 4  ORDENAR RUTA"
                or state.menu.screen == "runPlan" and "1 / 4  CREAR RUN"
                or state.menu.screen == "runReview" and "COMENZAR RUN"
                or state.menu.screen == "timingHelp" and "TIEMPOS Y CHECKPOINTS"
                or state.menu.screen == "recordHelp" and "COMO GRABAR"
                or (state.menu.screen == "runs" or state.menu.screen == "route") and "RUNS / AUTO SPLITS"
                or state.menu.screen == "settings" and "AJUSTES"
                or state.menu.screen == "session" and "SESION DE PRACTICA"
                or "PRACTICA DE ESTRELLAS",
            x + 12,
            y + 30,
            0.25,
            160,
            176,
            193
        )
        if flow.draw(x, y) or help.draw(x, y) then
            -- Dedicated guided-flow/help views share the standard footer.
        elseif state.menu.screen == "home" then
            -- Equal-height preview/action pairs, with a clear gutter between columns.
            local course = catalog.courses[state.editor.courseIndex]
            local function homeAction(row, label, value, bx, by, width, height)
                local selected = state.menu.row == row
                djui_hud_set_color(selected and 42 or 25, selected and 88 or 54, selected and 159 or 111, 255)
                djui_hud_render_rect(bx, by, width, height)
                if selected then
                    djui_hud_set_color(255, 210, 83, 255)
                    djui_hud_render_rect(bx, by, 2, height)
                    drawing.drawText(">", bx + width - 10, by + (height - 9) / 2, 0.27, 255, 210, 83)
                end
                if row == 3 then
                    drawing.fitted(value, bx + 7, by + 5, 0.22, width - 20)
                else
                    drawing.fitted(label, bx + 9, by + 9, 0.21, width - 24, 166, 188, 201)
                    drawing.fitted(value, bx + 9, by + 23, 0.29, width - 24)
                end
            end
            for row = 1, 2 do
                local py = y + 55 + (row - 1) * 56
                djui_hud_set_color(13, 31, 72, 255)
                djui_hud_render_rect(x + 12, py, 126, 46)
            end
            art.drawPainting(state.editor.courseIndex, x + 18, y + 64, 28)
            drawing.fitted("PRACTICA", x + 55, y + 60, 0.18, 77, 255, 211, 78)
            drawing.fitted(
                course[1]:upper() .. " / " .. state.editor.target,
                x + 55,
                y + 70,
                0.22,
                77,
                235,
                241,
                250
            )
            drawing.wrapped(
                catalog.starName(state.editor.courseIndex, state.editor.target),
                x + 55,
                y + 81,
                0.18,
                77,
                2,
                181,
                200,
                222
            )
            art.drawRunEmblem(x + 18, y + 120, 28)
            drawing.fitted("RUN ELEGIDA", x + 55, y + 116, 0.18, 77, 255, 211, 78)
            drawing.fittedName(routes.runName(), x + 55, y + 126, 0.22, 77, 235, 241, 250)
            drawing.wrapped(
                #state.editor.route > 0 and routes.routeSummary(state.editor.route) or "Sin objetivos todavia",
                x + 55,
                y + 137,
                0.16,
                77,
                2,
                181,
                200,
                222
            )
            homeAction(1, "PRACTICA INDIVIDUAL", "Elegir nivel y estrella", x + 150, y + 55, 138, 46)
            homeAction(2, "RUNS", "Crear y correr rutas", x + 150, y + 111, 138, 46)
            homeAction(3, "", "Ajustes y guardado", x + 202, y + 176, 86, 19)
        elseif state.menu.screen == "rename" then
            drawing.fittedName(state.editor.nameDraft .. "_", x + 12, y + 49, 0.48, 276)
            drawing.drawText(#state.editor.nameDraft .. " / 20", x + 245, y + 70, 0.22, 180, 201, 230)
            for i, key in ipairs(menu.nameKeys) do
                local col, row = (i - 1) % 10, math.floor((i - 1) / 10)
                local kx, ky = x + 12 + col * 28, y + 91 + row * 24
                djui_hud_set_color(
                    i == state.editor.nameKey and 55 or 28,
                    i == state.editor.nameKey and 100 or 58,
                    i == state.editor.nameKey and 165 or 118,
                    255
                )
                djui_hud_render_rect(kx, ky, 25, 20)
                if i == state.editor.nameKey then
                    djui_hud_set_color(255, 213, 75, 255)
                    djui_hud_render_rect(kx, ky + 19, 25, 2)
                end
                drawing.fittedName(key == "SPACE" and "SP" or key, kx + 3, ky + 3, 0.34, 20)
            end
            drawing.fitted(
                state.editor.manageNotice ~= "" and state.editor.manageNotice or "Maximo 20 caracteres",
                x + 12,
                y + 190,
                0.23,
                276,
                190,
                210,
                235
            )
        elseif state.menu.screen == "manage" then
            local help = {
                "El nombre se muestra al elegir y correr esta ruta.",
                "Copia a un espacio vacio. No reemplaza otras runs.",
                "Deshace una adicion de esta sesion, si la ruta no fue editada despues.",
                "Muestra u oculta los splits. El cronometro sigue funcionando.",
            }
            drawing.wrapped(help[state.menu.row], x + 12, y + 52, 0.28, 94, 9)
            drawing.wrapped(state.editor.manageNotice, x + 12, y + 160, 0.25, 94, 3, 181, 244, 190)
            menuView.menuRows({ "NOMBRE", "DUPLICAR", "DESHACER", "OVERLAY DE RUN" }, {
                routes.runName(),
                "Copiar a un espacio libre",
                routes.canUndoAddition() and "Quitar la ultima agregada" or "No hay nada que deshacer",
                state.settings.runOverlay and "Visible / arriba izquierda" or "Oculto / sigue contando",
            }, x + 112, y + 49, 176)
        elseif state.menu.screen == "session" then
            local wins, mean, median, best = records.sessionStats()
            drawing.fitted(catalog.title(), x + 12, y + 49, 0.34, 275, 173, 221, 208)
            drawing.drawText("Completados " .. wins .. "/" .. #state.session.values, x + 12, y + 72, 0.3)
            drawing.drawText("Mejor " .. format.fmt(best), x + 12, y + 91, 0.3)
            drawing.drawText("Media " .. format.fmt(mean), x + 12, y + 111, 0.29)
            drawing.drawText("Mediana " .. format.fmt(median), x + 12, y + 130, 0.29)
            local advice = #state.session.values < 5 and "Completa mas intentos para comparar."
                or wins / #state.session.values < 0.8 and "Prioriza completar; usa una estrategia segura."
                or "Buena consistencia. Trabaja en recortar tiempo."
            drawing.fitted(advice, x + 12, y + 174, 0.27, 276, 173, 221, 208)
            menuView.menuRows(
                { state.session.done and "PRACTICAR" or "CONTINUAR", "NUEVA SESION", "VOLVER" },
                {
                    state.session.done and "Practica libre" or "Continuar sesion",
                    "Nueva sesion de 10",
                    "Volver al apartado anterior",
                },
                x + 152,
                y + 70,
                136
            )
            for i = 1, 10 do
                local value = state.session.values[i]
                djui_hud_set_color(
                    value and value > 0 and 173 or value and 255 or 85,
                    value and value > 0 and 221 or value and 166 or 95,
                    value and value > 0 and 208 or value and 146 or 107,
                    255
                )
                local barHeight = value and (value > 0 and 8 or 5) or 2
                djui_hud_render_rect(x + 12 + (i - 1) * 12, y + 159 - barHeight, 9, barHeight)
            end
            drawing.fitted("Completado / fallo / pendiente", x + 12, y + 163, 0.20, 276, 160, 176, 193)
        elseif state.menu.screen == "recordHelp" then
            drawing.wrapped("1. Recoge las estrellas en el orden de tu ruta.", x + 12, y + 50, 0.28, 126, 4)
            drawing.wrapped("2. L + arriba guarda y vuelve a Runs.", x + 12, y + 103, 0.28, 126, 3)
            drawing.buttonIcon("L", x + 12, y + 135, 10)
            drawing.buttonIcon("up", x + 25, y + 135, 10)
            drawing.wrapped("3. Elige Comenzar run para cronometrarla.", x + 12, y + 147, 0.28, 126, 4)
            menuView.menuRows(
                { "EMPEZAR GRABACION", "VOLVER", "LISTO" },
                { "Seguir jugando", "Volver al apartado anterior", "Ver mi ruta" },
                x + 150,
                y + 49,
                138
            )
            drawing.wrapped(
                "Bloques por nivel; llaves separadas.",
                x + 156,
                y + 151,
                0.25,
                128,
                3,
                255,
                226,
                148
            )
        elseif state.menu.screen == "builder" then
            art.drawPainting(state.editor.courseIndex, x + 13, y + 49, 92)
            local bowser = catalog.courses[state.editor.courseIndex][4]
            local choice = bowser
                    and (state.editor.count == 1 and "1 estrella roja" or state.editor.count == 2 and (state.editor.courseIndex == 18 and "Estrella final de Bowser" or state.editor.courseIndex == 16 and "Llave de Bowser 1" or "Llave de Bowser 2") or "Recorrido hasta el tubo")
                or (
                    state.editor.count
                    .. " / "
                    .. catalog.starCapacity(state.editor.courseIndex)
                    .. " estrellas"
                )
            local hint = bowser
                    and (state.editor.count == 2 and "Bloques por nivel; llaves separadas." or state.editor.count == 3 and "Entra al tubo de Bowser para terminar." or "Recoge la estrella de las 8 monedas rojas.")
                or state.editor.courseIndex == 19 and "Toad y MIPS cuentan aqui. Cada estrella una vez."
                or "Cualquier estrella distinta de este nivel."
            drawing.wrapped(hint, x + 12, y + 145, 0.24, 94, 3)
            drawing.fitted(routes.routeSummary(state.editor.route), x + 12, y + 178, 0.21, 94, 255, 226, 148)
            drawing.fitted(state.editor.builderNotice, x + 12, y + 190, 0.20, 94, 181, 244, 190)
            menuView.menuRows({
                "1. NIVEL",
                bowser and "2. CHECKPOINT" or "2. CANTIDAD",
                "3. AGREGAR A LA RUTA",
            }, {
                catalog.courses[state.editor.courseIndex][1]:upper()
                    .. " / "
                    .. state.editor.courseIndex
                    .. " de "
                    .. #catalog.courses,
                choice,
                #state.editor.route >= routes.MAX_ROUTE and "Ruta llena: 64 bloques"
                    or "Agrega este objetivo",
            }, x + 112, y + 49, 176)
        elseif state.menu.screen == "practice" then
            local preview =
                art.drawTargetPreview(state.editor.courseIndex, state.editor.target, x + 13, y + 49, 92)
            drawing.wrapped(
                preview and art.wfHints[state.editor.target]
                    or art.bowserHint(state.editor.courseIndex, state.editor.target),
                x + 12,
                y + 145,
                0.24,
                94,
                3
            )
            drawing.drawText("MEJOR TIEMPO", x + 12, y + 176, 0.20, 160, 176, 193)
            local pk = "tick_v1_"
                .. state.settings.profile
                .. "_"
                .. catalog.courses[state.editor.courseIndex][1]
                .. "_s"
                .. state.editor.target
                .. "_a"
                .. catalog.effectiveAct()
            drawing.drawText(
                "PB " .. format.fmt(tonumber(mod_storage_load(pk .. "_pb"))),
                x + 12,
                y + 183,
                0.41,
                255,
                211,
                78
            )
            menuView.menuRows({
                "NIVEL",
                catalog.courses[state.editor.courseIndex][4] and "OBJETIVO" or "ESTRELLA",
                "PRACTICAR",
                "BORRAR PUNTO",
                "OPCIONES",
            }, {
                catalog.courses[state.editor.courseIndex][1]:upper()
                    .. " / "
                    .. state.editor.courseIndex
                    .. " de "
                    .. #catalog.courses,
                tostring(state.editor.target)
                    .. ". "
                    .. catalog.starName(state.editor.courseIndex, state.editor.target),
                state.settings.sessionMode and "Sesion de 10 intentos" or "Practica libre",
                state.checkpoints.saved and "Borrar punto guardado" or "Sin checkpoint",
                "Ajustes y guardado",
            }, x + 112, y + 49, 176)
        elseif state.menu.screen == "runs" or state.menu.screen == "route" then
            if state.menu.screen == "route" then
                -- Separate route contents from the actions that edit them.
                djui_hud_set_color(13, 31, 72, 255)
                djui_hud_render_rect(x + 10, y + 46, 98, 147)
                djui_hud_set_color(25, 54, 111, 255)
                djui_hud_render_rect(x + 122, y + 46, 166, 147)
                drawing.drawText(
                    "RUTA " .. state.editor.slot .. " / " .. #state.editor.route .. " SPLITS",
                    x + 12,
                    y + 48,
                    0.25,
                    173,
                    221,
                    208
                )
            end
            if state.menu.screen == "runs" then
                local help = {
                    #state.editor.route == 0
                            and "1. Agrega estrellas. 2. Ordena tu ruta. 3. Comienza la run."
                        or "Elige un espacio con izquierda / derecha. Cada run guarda su propia ruta.",
                    "Cantidad de estrellas. No importa cual recoges primero.",
                    "Cambia el orden o elimina bloques de esta ruta.",
                    #state.editor.route == 0 and "Primero agrega estrellas"
                        or state.settings.runFromIntro and "Partida nueva con intro. Se reinicia el progreso de entrenamiento."
                        or "Cada cantidad completada marca un split. Las llaves van aparte.",
                    "Elige una estrella para seguir practicando.",
                }
                art.drawRunEmblem(x + 13, y + 49, 92)
                drawing.fittedName(routes.runName(), x + 12, y + 150, 0.32, 94, 255, 232, 160)
                drawing.fitted(
                    routes.routeSummary(state.editor.route),
                    x + 12,
                    y + 170,
                    0.25,
                    94,
                    255,
                    211,
                    78
                )
                drawing.wrapped(help[state.menu.row], x + 120, y + 157, 0.24, 160, 3, 190, 210, 233)
            else
                if #state.editor.route == 0 then
                    drawing.wrapped("Primero agrega estrellas", x + 12, y + 72, 0.28, 94, 3)
                end
                local first = math.max(1, math.min(state.editor.cursor - 2, #state.editor.route - 5))
                for i = first, math.min(#state.editor.route, first + 5) do
                    local cp = state.editor.route[i]
                    local ry = y + 67 + (i - first) * 17
                    if i == state.editor.cursor then
                        djui_hud_set_color(34, 49, 60, 255)
                        djui_hud_render_rect(x + 10, ry - 2, 94, 16)
                    end
                    drawing.fitted(i .. ". " .. routes.checkpointLabel(cp), x + 14, ry, 0.29, 88)
                end
                if #state.editor.route > 6 then
                    drawing.drawText(
                        first
                            .. "-"
                            .. math.min(#state.editor.route, first + 5)
                            .. " / "
                            .. #state.editor.route,
                        x + 14,
                        y + 178,
                        0.24,
                        160,
                        176,
                        193
                    )
                end
            end
            if state.menu.screen == "route" then
                menuView.menuRows({ "CHECKPOINT", "MOVER", "ELIMINAR", "GRABAR" }, {
                    state.editor.cursor .. " / " .. #state.editor.route,
                    "Mover en la ruta",
                    "Eliminar seleccionado",
                    "Ver instrucciones",
                }, x + 122, y + 49, 166)
            else
                menuView.menuRows({
                    "ESPACIO / OPCIONES",
                    "ANADIR ESTRELLAS",
                    "ORDENAR RUTA",
                    #state.editor.route == 0 and "CREAR RUN" or "COMENZAR RUN",
                }, {
                    routes.runName() .. " / " .. state.editor.slot .. "/5",
                    "Estrellas por nivel / llaves",
                    "Ordenar / quitar bloques",
                    #state.editor.route == 0 and "Estrellas por nivel / llaves" or "Elegir inicio y comenzar",
                }, x + 112, y + 49, 176)
            end
        else
            drawing.drawText("AYUDA", x + 12, y + 52, 0.24, 173, 221, 208)
            local help = {
                "Elige la mision con la que entras al nivel. Automatico sigue tu estrella.",
                "Muestra u oculta el contador durante la practica.",
                "Repite tras 3 segundos al terminar o morir. Abre el menu para detenerlo.",
                "Borra el progreso de la partida del juego. Conserva tus PB. Requiere confirmacion.",
            }
            drawing.wrapped(help[state.menu.row], x + 12, y + 73, 0.28, 90, 10, 195, 207, 216)
            menuView.menuRows(
                { "ACTO DE ENTRADA", "CONTADOR", "REINTENTO AUTOMATICO", "GUARDADO DEL JUEGO" },
                {
                    state.settings.autoAct and "Automatico" or "Acto " .. state.editor.entryAct,
                    state.settings.visible and "Visible" or "Oculto",
                    state.settings.autoRetry and "Activado / 3 segundos" or "Desactivado",
                    "Eliminar partida...",
                },
                x + 112,
                y + 49,
                176
            )
        end
        local action = "A: abrir"
        local adjustable = (state.menu.screen == "practice" or state.menu.screen == "builder")
                and state.menu.row < 3
            or state.menu.screen == "practice" and state.menu.row == 3
            or state.menu.screen == "settings" and state.menu.row < 4
            or state.menu.screen == "route" and state.menu.row < 3
            or state.menu.screen == "runs" and state.menu.row == 1
            or state.menu.screen == "runReview" and state.menu.row == 1
            or state.menu.screen == "timingHelp"
        if state.menu.screen == "rename" then
            action = state.editor.nameKey == 40 and "A: guardar"
                or state.editor.nameKey == 39 and "A: borrar"
                or state.editor.nameKey == 37 and "A: espacio"
                or "A: escribir"
        elseif state.menu.screen == "runs" and state.menu.row == 1 then
            action = "A: opciones"
        elseif
            (state.menu.screen == "practice" and state.menu.row == 3)
            or (state.menu.screen == "runReview" and state.menu.row == 2)
            or (state.menu.screen == "recordHelp" and state.menu.row == 1)
        then
            action = "A: empezar"
        elseif state.menu.screen == "builder" then
            action = state.menu.row < 3 and "A: siguiente"
                or state.menu.row == 3 and "A: agregar"
                or "A: siguiente"
        elseif state.menu.screen == "practice" and state.menu.row < 3 then
            action = "A: siguiente"
        elseif state.menu.screen == "session" then
            action = state.menu.row == 1 and (state.session.done and "A: empezar" or "A: continuar")
                or state.menu.row == 2 and "A: empezar"
                or "A: volver"
        elseif state.menu.screen == "practice" and state.menu.row == 5 then
            action = "A: abrir"
        elseif state.menu.screen == "recordHelp" and state.menu.row == 3 then
            action = "A: abrir"
        elseif state.menu.row == 5 or state.menu.screen == "recordHelp" and state.menu.row > 1 then
            action = "A: volver"
        elseif state.menu.screen == "settings" and (state.menu.row == 2 or state.menu.row == 3) then
            action = "A: confirmar"
        elseif adjustable then
            action = "Izq. / der.: cambiar"
        end
        if state.menu.screen == "runPlan" then
            action = state.menu.row == 2 and "A: siguiente" or "A: abrir"
        elseif state.menu.screen == "runReview" then
            action = state.menu.row == 1 and "Izq. / der.: cambiar"
                or state.menu.row == 2 and "A: empezar"
                or "A: abrir"
        elseif state.menu.screen == "timingHelp" then
            action = "A: volver"
        end
        djui_hud_set_color(106, 144, 196, 180)
        djui_hud_render_rect(x + 12, y + 201, 276, 0.5)
        drawing.buttonIcon("stick", x + 12, y + 205, 12)
        drawing.fitted("Stick: elegir", x + 28, y + 207, 0.23, 80, 220, 231, 250)
        drawing.buttonIcon(action == "Izq. / der.: cambiar" and "dpad" or "A", x + 117, y + 205, 12)
        drawing.fitted(action, x + 133, y + 207, 0.23, 91, 255, 235, 158)
        drawing.buttonIcon("B", x + 232, y + 205, 12)
        drawing.fitted(state.menu.screen == "home" and "B: cerrar" or "B: volver", x + 248, y + 207, 0.23, 42)
        if state.menu.resetConfirm then
            djui_hud_set_color(15, 19, 27, 255)
            djui_hud_render_rect(x + 6, y + 43, 288, 182)
            drawing.drawText("ELIMINAR PARTIDA " .. state.menu.resetSlot, x + 15, y + 52, 0.39, 255, 153, 132)
            drawing.fitted("Borra estrellas, llaves, gorras y progreso", x + 15, y + 79, 0.28, 268)
            drawing.fitted("del slot actual, incluida su copia interna.", x + 15, y + 94, 0.28, 268)
            drawing.drawText("No se puede deshacer desde este menu.", x + 15, y + 114, 0.27)
            drawing.drawText("Tus PB de StarLab se conservan.", x + 15, y + 132, 0.28, 173, 221, 208)
            drawing.buttonIcon("A", x + 15, y + 153, 13)
            drawing.fitted("Suelta A; manten A 2 s para borrar.", x + 34, y + 156, 0.27, 244)
            djui_hud_set_color(70, 42, 42, 255)
            djui_hud_render_rect(x + 15, y + 179, 260, 5)
            djui_hud_set_color(255, 153, 132, 255)
            djui_hud_render_rect(x + 15, y + 179, 260 * state.menu.resetHold / 60, 5)
            drawing.buttonIcon("B", x + 15, y + 195, 13)
            drawing.drawText("B: cancelar", x + 34, y + 198, 0.3)
        end
    end
end
