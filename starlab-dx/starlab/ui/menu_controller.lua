-- Controller navigation and menu actions; view rendering lives in menu_view.lua.
return function(app)
    local state = app.state
    local catalog = app.catalog
    local i18n = app.i18n
    local audio = app.audio
    local saveSlots = app.saveSlots
    local practice = app.practice
    local routes = app.routes
    local runs = app.runs
    local menu = app.menu
    local input = app.input
    local flow, help = app.runFlow, app.help

    menu.nameKeys = {}

    for c in ("ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"):gmatch(".") do
        menu.nameKeys[#menu.nameKeys + 1] = c
    end

    menu.nameKeys[37], menu.nameKeys[38], menu.nameKeys[39], menu.nameKeys[40] = "SPACE", "-", "DEL", "OK"

    -- Store actual navigation origins, not a fixed screen hierarchy.
    function menu.remember(screen, row)
        state.menu.history = state.menu.history or {}
        state.menu.history[#state.menu.history + 1] = { screen = screen, row = row }
    end

    function menu.back()
        state.menu.returning = true
        if state.menu.screen == "timingHelp" then
            help.back()
            return
        end
        local previous = table.remove(state.menu.history or {})
        if previous then
            state.menu.screen, state.menu.row = previous.screen, previous.row
        elseif state.menu.screen == "home" then
            state.menu.open = false
        else
            local parents = {
                practice = { "home", 1 },
                runs = { "home", 2 },
                settings = { "home", 3 },
                session = { "practice", 3 },
                manage = { "runs", 1 },
                runPlan = { "runs", 2 },
                builder = { "runs", 2 },
                route = { "runs", 3 },
                runReview = { "runs", 4 },
                recordHelp = { "route", 4 },
                rename = { state.editor.renameReturn or "manage", 1 },
            }
            local parent = parents[state.menu.screen] or { "home", 1 }
            state.menu.screen, state.menu.row = parent[1], parent[2]
        end
        state.editor.renameReturn = nil
        state.menu.focusScreen = nil
    end

    function menu.openMenu()
        state.menu.history = {}
        state.menu.navigationEpoch = (state.menu.navigationEpoch or 0) + 1
        audio.menuSound("open")
        state.practice.retryCountdown = nil
        if state.training.active and state.practice.phase == "finished" then
            saveSlots.releaseTraining(true)
        end
        state.editor.renameReturn = nil
        local wasRecording = state.recording.active
        if state.recording.active then
            state.recording.active = false
            i18n.say("Ruta guardada. Ya puedes correrla.")
        end
        -- Browsing must never freeze a live attempt into an artificially faster PB.
        if state.practice.phase == "running" or state.practice.phase == "pending" then
            practice.stop("Intento cancelado al abrir el selector.")
        end
        state.editor.courseIndex, state.editor.target, state.editor.entryAct =
            state.practice.courseIndex, state.practice.target, state.practice.entryAct
        state.menu.open, state.menu.row, state.menu.screen = true, 1, "home"
        state.input.navDirection, state.input.navWait = 0, 0
        state.input.menuActionHeld = A_BUTTON | B_BUTTON | Z_TRIG
        state.menu.resetConfirm, state.menu.resetHold, state.menu.resetReleased = false, 0, false

        if wasRecording then
            state.menu.screen, state.menu.row = "runs", 4
        end
    end

    function menu.menuInput(c)
        local pressed, down = c.buttonPressed, c.buttonDown
        -- Consuming buttonDown can make the engine report buttonPressed again on
        -- every held frame. Keep our own A/B edges before clearing game input.
        -- Preserve the latch across submenus so one press cannot confirm twice.
        local actions = A_BUTTON | B_BUTTON | Z_TRIG
        local held = (down | pressed) & actions
        pressed = (pressed & ~actions) | (held & ~state.input.menuActionHeld)
        state.input.menuActionHeld = held
        local sx, sy = c.rawStickX or c.stickX or 0, c.rawStickY or c.stickY or 0
        input.consumeInput(c)
        if (down & L_TRIG) ~= 0 then
            return
        end -- release the menu shortcut before navigating
        if state.menu.resetConfirm then
            if (pressed & B_BUTTON) ~= 0 then
                audio.menuSound("back")
                state.menu.resetConfirm = false
                state.menu.resetHold = 0
                return
            end
            if (down & A_BUTTON) == 0 then
                state.menu.resetReleased = true
                state.menu.resetHold = 0
            end
            if state.menu.resetReleased and (down & A_BUTTON) ~= 0 then
                state.menu.resetHold = state.menu.resetHold + 1
            end
            if state.menu.resetHold >= 60 then
                state.menu.resetConfirm, state.menu.resetHold = false, 0
                if not saveSlots.canReset() or get_current_save_file_num() ~= state.menu.resetSlot then
                    audio.menuSound("blocked")
                    i18n.say("Borrado cancelado: cambio la partida o hay otros jugadores.")
                    return
                end
                audio.menuSound("confirm")
                practice.stop("Guardado reiniciado. Tus PB se conservan.")
                save_file_erase(state.menu.resetSlot - 1)
                save_file_reload(0)
                state.menu.open = false
                if not warp_to_start_level() then
                    i18n.say("Guardado borrado. Sal al castillo para recargar el nivel.")
                end
                i18n.say("Partida " .. state.menu.resetSlot .. " borrada. Los PB de StarLab se conservan.")
            end
            return
        end
        if
            (pressed & Z_TRIG) ~= 0
            and (
                state.menu.screen == "home"
                or state.menu.screen == "practice"
                or state.menu.screen == "runs"
                or state.menu.screen == "settings"
                or state.menu.screen == "runReview"
            )
        then
            help.open(state.menu.screen == "practice" and 3 or 1)
            audio.menuSound("open")
            return
        end
        if (pressed & B_BUTTON) ~= 0 then
            audio.menuSound("back")
            menu.back()
            return
        end
        if (state.menu.screen == "builder" or state.menu.screen == "manage") and (pressed & Z_TRIG) ~= 0 then
            audio.menuSound(routes.undoAddition() and "back" or "blocked")
            return
        end
        local direction = 0
        local buttons = down | pressed
        if (buttons & U_JPAD) ~= 0 then
            direction = 1
        elseif (buttons & D_JPAD) ~= 0 then
            direction = 2
        elseif (buttons & L_JPAD) ~= 0 then
            direction = 3
        elseif (buttons & R_JPAD) ~= 0 then
            direction = 4
        elseif math.max(math.abs(sx), math.abs(sy)) >= 40 then
            if math.abs(sy) >= math.abs(sx) then
                direction = sy > 0 and 1 or 2
            else
                direction = sx < 0 and 3 or 4
            end
        end
        -- One immediate step, then 0.4 s initial delay and 0.2 s repeat at 30 Hz.
        local step = false
        if direction == 0 then
            state.input.navDirection, state.input.navWait = 0, 0
        elseif direction ~= state.input.navDirection then
            state.input.navDirection, state.input.navWait, step = direction, 12, true
        else
            state.input.navWait = state.input.navWait - 1
            if state.input.navWait <= 0 then
                state.input.navWait, step = 6, true
            end
        end
        if state.menu.screen == "rename" then
            if step then
                local row, col = math.floor((state.editor.nameKey - 1) / 10), (state.editor.nameKey - 1) % 10
                if direction == 1 then
                    row = (row + 3) % 4
                elseif direction == 2 then
                    row = (row + 1) % 4
                elseif direction == 3 then
                    col = (col + 9) % 10
                elseif direction == 4 then
                    col = (col + 1) % 10
                end
                state.editor.nameKey = row * 10 + col + 1
                audio.menuSound("move")
            end
            if (pressed & A_BUTTON) ~= 0 then
                local key = menu.nameKeys[state.editor.nameKey]
                if key == "OK" then
                    if routes.saveRunName(state.editor.nameDraft) then
                        menu.back()
                        state.editor.renameReturn = nil
                        audio.menuSound("confirm")
                    else
                        audio.menuSound("blocked")
                    end
                elseif key == "DEL" then
                    state.editor.nameDraft = state.editor.nameDraft:sub(1, -2)
                    audio.menuSound("back")
                elseif #state.editor.nameDraft < 20 then
                    state.editor.nameDraft = state.editor.nameDraft .. (key == "SPACE" and " " or key)
                    audio.menuSound("confirm")
                else
                    audio.menuSound("blocked")
                end
            end
            return
        end
        local function selectionState()
            return table.concat({
                state.menu.row,
                state.editor.courseIndex,
                state.editor.target,
                state.editor.entryAct,
                state.editor.count,
                tostring(state.settings.autoAct),
                tostring(state.settings.visible),
                tostring(state.settings.autoRetry),
                tostring(state.settings.sessionMode),
                state.editor.slot,
                state.editor.cursor,
            }, ":")
        end
        local beforeSelection = step and selectionState() or nil
        local cue = nil
        local rows = (
            state.menu.screen == "home"
            or state.menu.screen == "session"
            or state.menu.screen == "recordHelp"
            or state.menu.screen == "runPlan"
        )
                and 3
            or 5
        if
            state.menu.screen == "runs"
            or state.menu.screen == "manage"
            or state.menu.screen == "route"
            or state.menu.screen == "settings"
        then
            rows = 4
        elseif state.menu.screen == "builder" then
            rows = 3
        elseif state.menu.screen == "runReview" then
            rows = 2
        elseif state.menu.screen == "timingHelp" then
            rows = 1
        end
        local utilityGrid = state.menu.screen == "practice" and state.menu.row >= 4
        if step and utilityGrid then
            if direction == 1 then
                state.menu.row = 3
            elseif direction == 2 then
                state.menu.row = 1
            elseif direction == 3 or direction == 4 then
                state.menu.row = state.menu.row == 4 and 5 or 4
            end
        elseif step and direction == 1 then
            state.menu.row = (state.menu.row - 2) % rows + 1
        elseif step and direction == 2 then
            state.menu.row = state.menu.row % rows + 1
        end
        local delta = step and not utilityGrid and (direction == 3 and -1 or direction == 4 and 1 or 0) or 0
        if flow.input(delta, (pressed & A_BUTTON) ~= 0) or help.input(delta, (pressed & A_BUTTON) ~= 0) then
            if step or (pressed & A_BUTTON) ~= 0 then
                audio.menuSound("move")
            end
            return
        end
        if state.menu.screen == "practice" and delta ~= 0 and state.menu.row <= 2 then
            state.checkpoints.saved = nil
        end
        if state.menu.screen == "practice" or state.menu.screen == "builder" then
            if delta ~= 0 then
                state.editor.builderNotice = ""
            end
            if state.menu.row == 1 and delta ~= 0 then
                state.editor.courseIndex = (state.editor.courseIndex - 1 + delta)
                        % (state.menu.screen == "builder" and #catalog.courses or 18)
                    + 1
                if state.menu.screen == "builder" then
                    state.editor.count = 1
                end
                if
                    state.menu.screen == "builder"
                    or state.editor.target > catalog.targetCount(state.editor.courseIndex)
                then
                    state.editor.target = 1
                    if state.settings.autoAct then
                        state.editor.entryAct = 1
                    end
                end
            elseif state.menu.row == 2 and delta ~= 0 then
                if state.menu.screen == "builder" then
                    state.editor.count = (state.editor.count - 1 + delta)
                            % (catalog.courses[state.editor.courseIndex][4] and 3 or catalog.starCapacity(
                                state.editor.courseIndex
                            ))
                        + 1
                else
                    state.editor.target = (state.editor.target - 1 + delta)
                            % catalog.targetCount(state.editor.courseIndex)
                        + 1
                end
                if state.settings.autoAct then
                    state.editor.entryAct = math.min(state.editor.target, 6)
                end
            elseif state.menu.screen == "practice" and state.menu.row == 3 and delta ~= 0 then
                state.settings.sessionMode = not state.settings.sessionMode
            end
        elseif state.menu.screen == "settings" then
            if state.menu.row == 1 and delta ~= 0 then
                local value = state.settings.autoAct and 0 or state.editor.entryAct
                value = (value + delta) % 7
                state.settings.autoAct, state.editor.entryAct =
                    value == 0, value == 0 and math.min(state.editor.target, 6) or value
            elseif state.menu.row == 2 and delta ~= 0 then
                state.settings.visible = not state.settings.visible
            elseif state.menu.row == 3 and delta ~= 0 then
                state.settings.autoRetry = not state.settings.autoRetry
                mod_storage_save("auto_retry", state.settings.autoRetry and "on" or "off")
            end
        elseif state.menu.screen == "runs" and state.menu.row == 1 and delta ~= 0 then
            state.editor.slot = (state.editor.slot - 1 + delta) % 5 + 1
            routes.loadRoute()
        elseif state.menu.screen == "route" and delta ~= 0 and #state.editor.route > 0 then
            if state.menu.row == 1 then
                state.editor.cursor = (state.editor.cursor - 1 + delta) % #state.editor.route + 1
            elseif state.menu.row == 2 then
                local dest = math.max(1, math.min(#state.editor.route, state.editor.cursor + delta))
                state.editor.route[dest], state.editor.route[state.editor.cursor] =
                    state.editor.route[state.editor.cursor], state.editor.route[dest]
                state.editor.cursor = dest
                routes.saveRoute()
            end
        end
        if step and beforeSelection ~= selectionState() then
            cue = "move"
        end
        if (pressed & A_BUTTON) ~= 0 then
            local inactive = state.menu.screen == "route" and state.menu.row < 3
                or state.menu.screen == "settings" and state.menu.row == 1
            cue = not inactive and "confirm" or cue
            if state.menu.screen == "home" then
                if state.menu.row == 1 then
                    if state.editor.courseIndex > 18 then
                        state.editor.courseIndex, state.editor.target, state.editor.entryAct = 1, 1, 1
                    end
                    state.menu.screen = (state.session.active or state.session.done) and "session"
                        or "practice"
                elseif state.menu.row == 2 then
                    state.menu.screen = "runs"
                    routes.loadRoute()
                else
                    state.menu.screen = "settings"
                end
                state.menu.row = 1
            elseif state.menu.screen == "practice" then
                if state.menu.row == 3 then
                    if state.settings.sessionMode then
                        practice.beginSession()
                    else
                        practice.selectChallenge(
                            state.editor.courseIndex,
                            state.editor.target,
                            catalog.effectiveAct()
                        )
                        practice.start()
                    end
                elseif state.menu.row == 4 then
                    if state.checkpoints.saved then
                        app.checkpoints.clearPracticePoint()
                    else
                        audio.menuSound("blocked")
                    end
                elseif state.menu.row == 5 then
                    state.menu.screen, state.menu.row = "settings", 1
                else
                    state.menu.row = state.menu.row + 1
                end
            elseif state.menu.screen == "runs" then
                if state.menu.row == 1 then
                    state.menu.screen, state.menu.row, state.editor.manageNotice = "manage", 1, ""
                elseif state.menu.row == 2 then
                    state.editor.builderNotice = ""
                    if #state.editor.route > 0 then
                        flow.begin()
                    else
                        cue = "blocked"
                    end
                elseif state.menu.row == 3 then
                    state.menu.screen, state.menu.row, state.editor.cursor = "route", 1, 1
                elseif state.menu.row == 4 then
                    if #state.editor.route == 0 then
                        flow.begin()
                    else
                        flow.review()
                    end
                elseif state.menu.row == 5 then
                    menu.back()
                end
            elseif state.menu.screen == "manage" then
                if state.menu.row == 1 then
                    state.editor.renameReturn = nil
                    state.editor.nameDraft = mod_storage_load("route_name_" .. state.editor.slot, "")
                    state.editor.nameKey = 1
                    state.editor.manageNotice = ""
                    state.menu.screen = "rename"
                elseif state.menu.row == 2 then
                    cue = routes.duplicateRoute() and "confirm" or "blocked"
                elseif state.menu.row == 3 then
                    cue = routes.undoAddition() and "back" or "blocked"
                elseif state.menu.row == 4 then
                    state.settings.runOverlay = not state.settings.runOverlay
                    mod_storage_save("run_overlay", state.settings.runOverlay and "on" or "off")
                end
            elseif state.menu.screen == "builder" then
                if state.menu.row < 3 then
                    state.menu.row = state.menu.row + 1
                elseif state.menu.row == 3 then
                    routes.addCheckpoint()
                    cue = state.editor.builderNotice == "Bloque agregado" and "added" or "blocked"
                end
            elseif state.menu.screen == "recordHelp" then
                if state.menu.row == 1 then
                    if #state.editor.route >= routes.MAX_ROUTE then
                        cue = "blocked"
                        state.editor.builderNotice = "Ruta llena: 64 bloques"
                        state.menu.screen, state.menu.row = "builder", 3
                    else
                        state.recording.seen = {}
                        state.recording.active, state.menu.open, state.recording.lastTick = true, false, -1
                        i18n.say("Grabando estrellas. L + arriba para terminar.")
                    end
                elseif state.menu.row == 2 then
                    menu.back()
                else
                    state.menu.screen, state.menu.row = "runs", #state.editor.route > 0 and 4 or 2
                end
            elseif state.menu.screen == "route" then
                if state.menu.row == 3 and #state.editor.route > 0 then
                    table.remove(state.editor.route, state.editor.cursor)
                    state.editor.cursor = math.max(1, math.min(state.editor.cursor, #state.editor.route))
                    routes.saveRoute()
                elseif state.menu.row == 4 then
                    state.menu.screen, state.menu.row = "recordHelp", 1
                end
            elseif state.menu.screen == "session" then
                if state.menu.row == 1 then
                    if state.session.done then
                        state.session = { active = false, done = false, values = {} }
                        practice.start()
                    else
                        practice.start()
                    end
                elseif state.menu.row == 2 then
                    practice.beginSession()
                elseif state.menu.row == 3 then
                    state.session.active = false
                    state.session.done = false
                    menu.back()
                end
            elseif state.menu.screen == "settings" then
                if state.menu.row == 4 then
                    if state.training.active then
                        cue = "blocked"
                        i18n.say("Vuelve al inicio para salir del entrenamiento.")
                    elseif saveSlots.canReset() then
                        state.menu.resetSlot = get_current_save_file_num()
                        state.menu.resetConfirm, state.menu.resetHold, state.menu.resetReleased =
                            true, 0, false
                    else
                        cue = "blocked"
                        i18n.say("Para borrar, crea una partida solo y sin otros jugadores.")
                    end
                elseif state.menu.row == 3 then
                    state.settings.autoRetry = not state.settings.autoRetry
                    mod_storage_save("auto_retry", state.settings.autoRetry and "on" or "off")
                elseif state.menu.row == 2 then
                    state.settings.visible = not state.settings.visible
                end
            end
        end
        if cue then
            audio.menuSound(cue)
        end
    end
    local dispatch = menu.menuInput
    function menu.menuInput(c)
        local screen, row = state.menu.screen, state.menu.row
        state.menu.returning = false
        dispatch(c)
        if
            state.menu.open
            and screen ~= state.menu.screen
            and not state.menu.returning
            and screen ~= "timingHelp"
            and state.menu.screen ~= "timingHelp"
        then
            menu.remember(screen, row)
        end
    end
end
