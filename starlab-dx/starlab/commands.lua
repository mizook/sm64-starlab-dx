-- Chat command dispatch.
return function(app)
    local state = app.state
    local catalog = app.catalog
    local i18n = app.i18n
    local format = app.format
    local audio = app.audio
    local records = app.records
    local practice = app.practice
    local checkpoints = app.checkpoints
    local routes = app.routes
    local runs = app.runs
    local menu = app.menu
    local commands = app.commands

    function commands.command(text)
        local args = {}
        for word in text:lower():gmatch("%S+") do
            args[#args + 1] = word
        end
        local cmd = args[1] or "help"
        if cmd == "help" then
            i18n.say("/sl wf 3 = practicar estrella 3 de WF. /sl bob 7 1 = 100 monedas en acto 1.")
            i18n.say(
                "/sl menu | runs | settings | sounds | run | retry | review | stop | stats | profile NOMBRE"
            )
            i18n.say("L + abajo: repetir. L + arriba: selector (cancela el intento activo).")
            i18n.say("Practica: L+izq guarda, L+der carga. Borrar en Practica o /sl clearpoint")
        elseif cmd == "name" or cmd == "copy" or cmd == "undo" then
            if not state.menu.open then
                menu.openMenu()
            end
            local ok
            if cmd == "name" then
                ok = routes.saveRunName(text:match("^%s*%S+%s*(.-)%s*$") or "")
            elseif cmd == "copy" then
                ok = routes.duplicateRoute()
            else
                ok = routes.undoAddition()
            end
            state.menu.screen, state.menu.row = "manage", 1
            i18n.say(state.editor.manageNotice)
            audio.menuSound(ok and "confirm" or "blocked")
        elseif cmd == "timing" then
            if not state.menu.open then
                menu.openMenu()
            end
            app.help.open(1)
        elseif cmd == "clearpoint" then
            checkpoints.clearPracticePoint()
        elseif cmd == "sounds" then
            audio.toggleMenuSounds()
        elseif cmd == "runfrom" then
            practice.stop()
            state.settings.runFromIntro = args[2] ~= "checkpoint"
            mod_storage_save("run_start", state.settings.runFromIntro and "intro" or "checkpoint")
            i18n.say(
                state.settings.runFromIntro and "Inicio de run: intro" or "Inicio de run: primer checkpoint"
            )
        elseif cmd == "practice" then
            menu.openMenu()
            if state.editor.courseIndex > 18 then
                state.editor.courseIndex, state.editor.target, state.editor.entryAct = 1, 1, 1
            end
            state.menu.screen, state.menu.row = "practice", 1
        elseif cmd == "overlay" then
            state.settings.runOverlay = not state.settings.runOverlay
            mod_storage_save("run_overlay", state.settings.runOverlay and "on" or "off")
            i18n.say(state.settings.runOverlay and "Overlay de run: visible" or "Overlay de run: oculto")
        elseif cmd == "menu" then
            menu.openMenu()
        elseif cmd == "session" then
            practice.beginSession()
        elseif cmd == "list" then
            for _, c in ipairs(catalog.courses) do
                i18n.say(c[1] .. " - " .. c[2])
            end
            i18n.say("Estrellas 1-6 segun el selector del juego; 7 = 100 monedas. Acto opcional 1-6.")
            i18n.say("Bowser: 1 = tubo, 2 = llave/final, 3 = rojas. Acto fijo 1.")
        elseif cmd == "runs" then
            if not state.menu.open then
                menu.openMenu()
            end
            state.menu.screen, state.menu.row = "runs", 1
            routes.loadRoute()
        elseif cmd == "settings" then
            if not state.menu.open then
                menu.openMenu()
            end
            state.menu.screen, state.menu.row = "settings", 1
        elseif cmd == "block" then
            local found
            for i, c in ipairs(catalog.courses) do
                if c[1] == args[2] then
                    found = i
                end
            end
            local count = tonumber(args[3])
            if
                found
                and count
                and count % 1 == 0
                and count >= 1
                and count <= (catalog.courses[found][4] and 3 or catalog.starCapacity(found))
            then
                state.editor.courseIndex, state.editor.count = found, count
                routes.addCheckpoint()
            else
                i18n.say("/sl block bob 3 | /sl block castle 1 | /sl block bitdw 2")
            end
        elseif cmd == "minimal" then
            state.settings.overlayMinimal = not state.settings.overlayMinimal
            state.settings.runOverlay = true
            mod_storage_save("run_minimal", state.settings.overlayMinimal and "on" or "off")
            mod_storage_save("run_overlay", "on")
        elseif cmd == "add" then
            routes.addCheckpoint()
        elseif cmd == "review" then
            practice.practiceLoss()
        elseif cmd == "run" then
            runs.startRun()
        elseif cmd == "retry" then
            if state.run.active or state.run.finished then
                runs.startRun()
            else
                practice.start()
            end
        elseif cmd == "stop" then
            practice.stop()
        elseif cmd == "hud" then
            state.settings.visible = not state.settings.visible
        elseif cmd == "stats" then
            i18n.say(
                catalog.courses[state.practice.courseIndex][1]:upper()
                    .. " "
                    .. catalog.targetLabel(state.practice.courseIndex, state.practice.target)
                    .. " A"
                    .. state.practice.entryAct
                    .. " | "
                    .. state.settings.profile
            )
            i18n.say(
                "PB "
                    .. format.fmt(state.practice.pb)
                    .. " | Completados "
                    .. state.practice.finishes
                    .. "/"
                    .. state.practice.attempts
                    .. " | Ultimo "
                    .. format.fmt(state.practice.last)
            )
        elseif cmd == "room" then
            i18n.say("PB locales compartidos para este mismo desafio y perfil (sin verificacion):")
            for i = 0, MAX_PLAYERS - 1 do
                local p, s = gNetworkPlayers[i], gPlayerSyncTable[i]
                if p and p.connected and s and s.slChallenge == state.practice.challengeKey then
                    i18n.say(p.name .. " | " .. format.fmt(s.slPB and s.slPB > 0 and s.slPB or nil))
                end
            end
        elseif cmd == "profile" then
            if not args[2] or #args[2] > 24 or not args[2]:match("^[a-z0-9_-]+$") then
                i18n.say("Usa /sl profile nombre (1-24 letras, numeros, _ o -).")
            else
                practice.stop("Perfil cambiado. Inicia otro intento.")
                state.session = { active = false, done = false, values = {} }
                state.checkpoints.saved, state.checkpoints.active, state.checkpoints.pending = nil, nil, nil
                state.settings.profile = args[2]
                mod_storage_save("profile", state.settings.profile)
                records.loadStats()
                records.publish()
                i18n.say(
                    "Perfil: " .. state.settings.profile .. ". Usa otro perfil al cambiar condiciones o mods."
                )
            end
        else
            local found
            for i, c in ipairs(catalog.courses) do
                if c[1] == cmd then
                    found = i
                end
            end
            local target = tonumber(args[2])
            local chosenAct = args[3] and tonumber(args[3]) or (target and math.min(target, 6))
            if
                not found
                or found > 18
                or not target
                or target % 1 ~= 0
                or target < 1
                or target > (found and catalog.targetCount(found) or 7)
                or not chosenAct
                or chosenAct % 1 ~= 0
                or chosenAct < 1
                or chosenAct > 6
            then
                i18n.say("Objetivo invalido. Ejemplo: /sl wf 3. /sl help para ayuda.")
            else
                practice.selectChallenge(found, target, chosenAct)
                practice.start()
            end
        end
        return true
    end
    local dispatch = commands.command
    function commands.command(text)
        local screen, row, epoch = state.menu.screen, state.menu.row, state.menu.navigationEpoch
        local wasOpen = state.menu.open
        local result = dispatch(text)
        if
            state.menu.open
            and state.menu.screen ~= "home"
            and state.menu.screen ~= "timingHelp"
            and screen ~= "timingHelp"
            and screen ~= state.menu.screen
        then
            if not wasOpen or epoch ~= state.menu.navigationEpoch then
                menu.remember(
                    "home",
                    state.menu.screen == "runs" and 2 or state.menu.screen == "settings" and 3 or 1
                )
            else
                menu.remember(screen, row)
            end
        end
        return result
    end
end
