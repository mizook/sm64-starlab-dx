-- Gameplay event handlers and timing; registration is isolated in hooks.lua.
return function(app)
    local state = app.state
    local catalog = app.catalog
    local records = app.records
    local practice = app.practice
    local checkpoints = app.checkpoints
    local runs = app.runs
    local menu = app.menu
    local input = app.input
    local events = app.events

    function events.onWarp(_, level)
        if state.practice.phase == "running" then
            if state.run.active then
                runs.finishCheckpoint(gMarioStates[0], nil, true, level)
            elseif
                catalog.courses[state.practice.courseIndex][4]
                and state.practice.target == 1
                and level == catalog.courses[state.practice.courseIndex][4]
            then
                practice.completePractice()
            end
        end
        if state.practice.phase == "pending" then
            if
                level
                == (
                    state.run.active and state.run.intro and LEVEL_CASTLE_GROUNDS
                    or catalog.courses[state.practice.courseIndex][3]
                )
            then
                state.practice.arrival = true
            else
                practice.stop("Entrada cancelada: destino distinto.")
            end
        elseif
            state.practice.phase == "running"
            and not state.run.active
            and not catalog.targetLevel(state.practice.courseIndex, state.practice.target, level)
        then
            practice.stop(
                state.practice.message:find("Recogiste S", 1, true) and state.practice.message
                    or "Saliste del nivel. Reintenta."
            )
        end
    end

    function events.beforeMario(m)
        if m.playerIndex ~= 0 then
            return
        end
        state.clock.tick = state.clock.tick + 1
        if state.run.flash and state.run.flash > 0 then
            state.run.flash = state.run.flash - 1
        end
        local c = m.controller
        if
            state.training.active
            and state.run.active
            and (get_current_save_file_num() ~= state.training.slot or not save_file_get_using_backup_slot())
        then
            practice.stop("No se pudo preparar el espacio de entrenamiento.")
            return
        end
        if state.session.showSummary then
            state.session.showSummary = false
            state.practice.retryCountdown = nil
            state.menu.open, state.menu.screen, state.menu.row = true, "session", 1
            state.input.menuActionHeld = A_BUTTON | B_BUTTON | Z_TRIG
            input.consumeInput(c)
            return
        end
        if state.menu.open then
            if not is_game_paused() and not djui_is_chatbox_open() and not djui_console_is_open() then
                menu.menuInput(c)
            end
            return
        end
        runs.updateIntroInteractions(m)
        local uiBusy = djui_is_chatbox_open() or djui_console_is_open()
        if not uiBusy and (c.buttonDown & L_TRIG) ~= 0 and (c.buttonPressed & U_JPAD) ~= 0 then
            practice.closeSaveDialog(m)
            menu.openMenu()
            input.consumeInput(c)
            return
        end
        if not uiBusy then
            runs.runDisplayInput(m)
            if checkpoints.practicePointInput(m) and state.practice.phase == "pending" then
                return
            end
        end
        if
            state.settings.retryEnabled
            and state.practice.phase ~= "pending"
            and not uiBusy
            and (c.buttonDown & L_TRIG) ~= 0
            and (c.buttonPressed & D_JPAD) ~= 0
        then
            c.buttonPressed = c.buttonPressed & ~D_JPAD
            if state.run.active or state.run.finished then
                runs.startRun()
            else
                practice.start()
            end
            return
        end
        if state.practice.retryCountdown and not uiBusy and not is_game_paused() then
            state.practice.retryCountdown = state.practice.retryCountdown - 1
            if state.practice.retryCountdown <= 0 then
                if state.checkpoints.active then
                    checkpoints.loadPracticePoint()
                else
                    practice.start()
                end
                return
            end
        end
        if state.practice.phase == "pending" then
            state.practice.pendingFrames = state.practice.pendingFrames + 1
            if state.practice.pendingFrames > 900 then
                practice.stop("La entrada no termino. Usa /sl retry.")
                return
            end
            local p = gNetworkPlayers[0]
            if
                state.run.active
                and state.run.intro
                and state.practice.arrival
                and p.currLevelNum == LEVEL_CASTLE_GROUNDS
                and m.action ~= ACT_UNINITIALIZED
                and not is_game_paused()
            then
                practice.refillHealth(m)
                if m.action ~= ACT_INTRO_CUTSCENE then
                    set_mario_action(m, ACT_INTRO_CUTSCENE, 0)
                end
                state.practice.phase, state.practice.frames = "running", 0
                state.practice.message = "Run desde intro; guardado principal conservado."
                records.publish()
            elseif
                state.practice.arrival
                and p.currLevelNum == catalog.courses[state.practice.courseIndex][3]
                and (p.currActNum == state.practice.entryAct or catalog.courses[state.practice.courseIndex][4] or catalog.courses[state.practice.courseIndex][5])
                and m.action ~= ACT_UNINITIALIZED
                and (m.action & ACT_FLAG_INTANGIBLE) == 0
                and not is_game_paused()
            then
                practice.refillHealth(m)
                state.practice.phase, state.practice.frames = "running", 0
                if not state.run.active then
                    state.practice.attempts = state.practice.attempts + 1
                    records.save("_tries", state.practice.attempts)
                end
                state.practice.message = "Ve por " .. catalog.title()
                records.publish()
            end
        end
        if state.practice.phase == "running" then
            if
                not state.run.active
                and not catalog.targetLevel(
                    state.practice.courseIndex,
                    state.practice.target,
                    gNetworkPlayers[0].currLevelNum
                )
            then
                practice.stop(
                    state.practice.message:find("Recogiste S", 1, true) and state.practice.message
                        or "Nivel cambiado. Reintenta."
                )
            elseif not is_game_paused() then
                state.practice.frames = state.practice.frames + 1
                if state.run.active then
                    state.run.total = state.run.total + 1
                end
            end
        end
    end

    function events.onInteract(m, o, interaction, accepted)
        if state.recording.active then
            if interaction == INTERACT_STAR_OR_KEY then
                runs.recordPickup(m, o, accepted)
            end
            return
        end
        if state.run.active then
            if interaction == INTERACT_STAR_OR_KEY then
                runs.finishCheckpoint(m, o, accepted)
            end
            return
        end
        if state.run.finished then
            return
        end
        if
            state.practice.phase ~= "running"
            or m.playerIndex ~= 0
            or not accepted
            or interaction ~= INTERACT_STAR_OR_KEY
        then
            return
        end
        if catalog.courses[state.practice.courseIndex][4] then
            if
                catalog.pickupMatches(
                    state.practice.courseIndex,
                    state.practice.target,
                    o,
                    gNetworkPlayers[0].currLevelNum
                )
            then
                practice.completePractice()
            end
            return
        end
        if gNetworkPlayers[0].currLevelNum ~= catalog.courses[state.practice.courseIndex][3] then
            return
        end
        local collected = ((o.oBehParams >> 24) & 0x1F) + 1
        if
            not catalog.pickupMatches(
                state.practice.courseIndex,
                state.practice.target,
                o,
                gNetworkPlayers[0].currLevelNum
            )
        then
            -- 100-coin stars are an optional intermediate pickup, never the wrong finish.
            state.practice.message = "Recogiste S" .. collected .. "; objetivo S" .. state.practice.target
            return
        end
        practice.completePractice()
    end
end
