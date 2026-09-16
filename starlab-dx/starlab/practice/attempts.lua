-- Full-star attempt lifecycle, health and session management.
return function(app)
    local state = app.state
    local catalog = app.catalog
    local i18n = app.i18n
    local format = app.format
    local records = app.records
    local saveSlots = app.saveSlots
    local practice = app.practice

    function practice.stop(reason)
        saveSlots.releaseTraining(true)
        state.practice.retryCountdown = nil
        state.recording.active = false
        if state.practice.phase == "running" and not state.run.active and not state.checkpoints.active then
            records.recordAttempt(0)
        end
        state.run.active, state.run.finished = false, false
        state.practice.phase = "stopped"
        state.practice.message = reason or "Practica detenida"
        records.publish()
    end

    function practice.refillHealth(m)
        if not m then
            return
        end
        m.health = 0x880
        m.hurtCounter = 0
        m.healCounter = 0
    end

    function practice.closeSaveDialog(m)
        if is_game_paused() then
            game_unpause()
        end
        if m and m.action == ACT_EXIT_LAND_SAVE_DIALOG then
            set_menu_mode(-1)
            reset_dialog_render_state()
            disable_time_stop_including_mario()
            set_mario_action(m, ACT_IDLE, 0)
        end
    end

    function practice.start(keepRun)
        local m = gMarioStates and gMarioStates[0]
        practice.closeSaveDialog(m)
        practice.refillHealth(m)
        state.practice.retryCountdown = nil
        state.recording.active = false
        if state.practice.phase == "running" and not state.run.active and not state.checkpoints.active then
            records.recordAttempt(0)
        end
        state.checkpoints.active, state.checkpoints.pending = nil, nil
        if state.session.done and keepRun ~= true then
            state.session.showSummary = true
            state.practice.phase = "stopped"
            return
        end
        if keepRun ~= true then
            state.run.active, state.run.finished = false, false
            -- Every full-star attempt starts with fresh training progress before
            -- level objects/dialogs initialize. A run's intermediate warps keep it.
            saveSlots.releaseTraining()
            if not saveSlots.beginTraining(true) then
                state.practice.phase = "stopped"
                records.publish()
                return
            end
            if m then
                m.numStars, m.numKeys = 0, 0
            end
        end
        state.menu.open = false
        -- Mark pending BEFORE requesting the warp; never time the old level.
        state.practice.phase, state.practice.frames, state.practice.pendingFrames, state.practice.arrival =
            "pending", 0, 0, false
        state.practice.message = "Entrando al nivel..."
        local p = gNetworkPlayers[0]
        local ok
        if
            p.currLevelNum == catalog.courses[state.practice.courseIndex][3]
            and p.currActNum == state.practice.entryAct
        then
            ok = warp_restart_level()
        else
            ok = warp_to_level(catalog.courses[state.practice.courseIndex][3], 1, state.practice.entryAct)
        end
        if not ok then
            practice.stop("Warp rechazado. Cierra menus y reintenta.")
        end
        records.publish()
    end

    function practice.selectChallenge(index, target, chosenAct)
        saveSlots.releaseTraining()
        if state.practice.phase == "running" and not state.run.active and not state.checkpoints.active then
            records.recordAttempt(0)
        end
        state.session = { active = false, done = false, values = {} }
        state.practice.retryCountdown = nil
        local nextAct = catalog.courses[index][4] and 1 or chosenAct
        if
            state.practice.courseIndex ~= index
            or state.practice.target ~= target
            or state.practice.entryAct ~= nextAct
        then
            state.checkpoints.saved = nil
        end
        state.checkpoints.active, state.checkpoints.pending = nil, nil
        state.practice.courseIndex, state.practice.target, state.practice.entryAct = index, target, nextAct
        state.practice.phase, state.practice.frames = "idle", 0
        state.run.active, state.run.finished = false, false
        records.loadStats()
        state.practice.message = catalog.title() .. " | Acto " .. state.practice.entryAct
        records.publish()
    end

    function practice.beginSession()
        practice.selectChallenge(state.editor.courseIndex, state.editor.target, catalog.effectiveAct())
        state.session = { active = true, done = false, values = {}, key = state.practice.challengeKey }
        practice.start()
    end

    function practice.practiceLoss()
        if not state.review.checkpoint then
            i18n.say("Aun no hay una perdida comparada con PB.")
            return
        end
        local cp = state.review.checkpoint
        practice.selectChallenge(
            cp[1],
            catalog.courses[cp[1]][4] and (cp[4] == "count" and 3 or cp[4] == "pipe" and 1 or 2) or 1,
            cp[3]
        )
        practice.start()
    end

    function practice.completePractice()
        if state.practice.frames < 1 then
            return
        end
        if state.checkpoints.active then
            state.practice.phase = "finished"
            local elapsed = math.max(0, state.practice.frames - state.checkpoints.active.frames)
            state.checkpoints.active.best = math.min(state.checkpoints.active.best or elapsed, elapsed)
            state.practice.message = "Parcial terminado. El PB completo se conserva."
            records.publish()
            i18n.say(state.practice.message .. " " .. format.fmt(state.practice.frames))
            if state.settings.autoRetry and state.checkpoints.saved then
                state.practice.retryCountdown = 90
            end
            return
        end
        local previous = state.practice.pb
        state.practice.phase, state.practice.last = "finished", state.practice.frames
        records.recordAttempt(state.practice.frames)
        state.practice.finishes = state.practice.finishes + 1
        records.save("_wins", state.practice.finishes)
        if not state.practice.pb or state.practice.frames < state.practice.pb then
            state.practice.pb = state.practice.frames
            records.save("_pb", state.practice.pb)
            state.practice.message = previous
                    and ("NUEVO PB! -" .. format.fmt(previous - state.practice.frames))
                or "PRIMER PB!"
        else
            state.practice.message = state.practice.frames == state.practice.pb and "Igualaste tu PB!"
                or ("+" .. format.fmt(state.practice.frames - state.practice.pb) .. " respecto al PB")
        end
        records.publish()
        i18n.say(
            catalog.title() .. "  " .. format.fmt(state.practice.frames) .. " | " .. state.practice.message
        )
        if state.settings.autoRetry and not state.session.done then
            state.practice.retryCountdown = 90
        end
    end
end
