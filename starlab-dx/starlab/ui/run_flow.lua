-- Guided route creation and pre-run review. Existing route persistence is reused.
return function(app)
    local state, routes, drawing = app.state, app.routes, app.drawing
    local flow = app.runFlow

    function flow.begin()
        state.menu.screen, state.menu.row = #state.editor.route == 0 and "runPlan" or "builder", 1
    end

    function flow.review()
        if #state.editor.route == 0 or not state.editor.storageOK then
            state.editor.builderNotice = #state.editor.route == 0 and "Agrega un bloque para continuar."
                or "No se pudo guardar"
            app.audio.menuSound("blocked")
            state.menu.screen, state.menu.row = "builder", 1
            return false
        end
        state.editor.cursor = math.max(1, math.min(state.editor.cursor, #state.editor.route))
        state.menu.screen, state.menu.row = "runReview", 2
        return true
    end

    function flow.input(delta, confirm)
        if state.menu.screen == "runPlan" then
            if confirm then
                if state.menu.row == 1 then
                    state.editor.renameReturn = "runPlan"
                    state.editor.nameDraft = routes.runName()
                    state.editor.nameKey = 1
                    state.menu.screen, state.menu.row = "rename", 1
                elseif state.menu.row == 2 then
                    state.menu.screen, state.menu.row = "builder", 1
                end
            end
            return true
        elseif state.menu.screen == "runReview" then
            if state.menu.row == 1 and (delta ~= 0 or confirm) then
                local intro = not state.settings.runFromIntro
                if mod_storage_save("run_start", intro and "intro" or "checkpoint") then
                    state.settings.runFromIntro = intro
                else
                    app.i18n.say("No se pudo guardar")
                    app.audio.menuSound("blocked")
                end
            elseif confirm and state.menu.row == 2 then
                app.runs.startRun()
            end
            return true
        end
        return false
    end

    function flow.draw(x, y)
        if state.menu.screen == "runPlan" then
            drawing.wrapped(
                "Una run es una lista de niveles y cantidades, en orden.",
                x + 12,
                y + 50,
                0.27,
                94,
                6
            )
            drawing.wrapped(
                "Ejemplo: BOB x3, WF x2 y una llave.",
                x + 12,
                y + 126,
                0.26,
                94,
                5,
                255,
                226,
                148
            )
            app.menuView.menuRows(
                { "NOMBRE OPCIONAL", "SIGUIENTE: ESTRELLAS" },
                { routes.runName(), "Elegir niveles y cantidades" },
                x + 112,
                y + 49,
                176
            )
            drawing.wrapped(
                "Se guarda cada bloque al agregarlo. No necesitas un boton Guardar.",
                x + 118,
                y + 148,
                0.25,
                164,
                4,
                181,
                244,
                190
            )
            return true
        elseif state.menu.screen == "runReview" then
            local stars, keys = routes.routeTotals(state.editor.route)
            drawing.fittedName(routes.runName(), x + 12, y + 49, 0.32, 94)
            drawing.drawText(
                stars == 1 and "1 estrella" or stars .. " estrellas",
                x + 12,
                y + 69,
                0.26,
                255,
                221,
                114
            )
            drawing.drawText(
                keys == 1 and "1 llave" or keys .. " llaves",
                x + 12,
                y + 83,
                0.26,
                255,
                221,
                114
            )
            drawing.drawText(
                #state.editor.route == 1 and "1 split" or #state.editor.route .. " splits",
                x + 12,
                y + 97,
                0.24,
                181,
                244,
                190
            )
            drawing.wrapped(
                state.settings.runFromIntro and "Reinicia el entrenamiento; conserva tu partida principal."
                    or "Empieza en el primer nivel. Usa el progreso actual de la partida.",
                x + 12,
                y + 121,
                0.24,
                94,
                7,
                221,
                231,
                241
            )
            app.menuView.menuRows({ "INICIO DE RUN", "COMENZAR RUN" }, {
                state.settings.runFromIntro and "Intro / entrenamiento nuevo"
                    or "Primer nivel / progreso actual",
                "Todo listo. Iniciar cronometro",
            }, x + 112, y + 49, 176)
            return true
        end
        return false
    end
end
