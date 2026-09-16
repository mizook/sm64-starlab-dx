-- Automatic split progression, latest references, recording and overlay paging.
return function(app)
    local state = app.state
    local catalog = app.catalog
    local i18n = app.i18n
    local format = app.format
    local records = app.records
    local saveSlots = app.saveSlots
    local practice = app.practice
    local routes = app.routes
    local runs = app.runs

    function runs.splitRows()
        local rows = {}
        local activeRow = 1
        for i, cp in ipairs(state.run.route) do
            rows[#rows + 1] = { index = i }
            if i == state.run.index then
                activeRow = #rows + 1
            end
            if cp[4] == "count" then
                for j = 1, cp[2] do
                    rows[#rows + 1] = { index = i, sub = j }
                    if i == state.run.index and j == (state.run.progress or 0) + 1 then
                        activeRow = #rows
                    end
                end
            elseif i == state.run.index then
                activeRow = #rows
            end
        end
        if state.run.finished then
            activeRow = #rows
        end
        return rows, math.max(1, math.min(activeRow, #rows))
    end

    function runs.runDisplayInput(m)
        local c = m.controller
        local held = c.buttonDown
        if (held & L_TRIG) == 0 then
            state.input.overlayHeld = 0
            return false
        end
        local pressed = (c.buttonPressed | (held & ~state.input.overlayHeld)) & ~state.input.overlayHeld
        state.input.overlayHeld = held
        if
            not (state.run.active or state.run.finished)
            or djui_is_chatbox_open()
            or djui_console_is_open()
        then
            return false
        end
        if (pressed & L_JPAD) ~= 0 then
            state.settings.overlayMinimal = not state.settings.overlayMinimal
            state.settings.runOverlay = true
            mod_storage_save("run_minimal", state.settings.overlayMinimal and "on" or "off")
            mod_storage_save("run_overlay", "on")
        elseif not state.settings.overlayMinimal and (pressed & R_JPAD) ~= 0 then
            local layout = app.overlay.layout()
            state.overlayPage = layout.page + 1 < layout.pages and layout.page + 1 or nil
        else
            return false
        end
        c.buttonPressed = c.buttonPressed & ~(L_JPAD | R_JPAD)
        return true
    end

    runs.startRun = function()
        if not state.editor.storageOK then
            i18n.say("No se pudo guardar")
            return
        end
        if #state.editor.route == 0 then
            i18n.say("Agrega una estrella antes de empezar.")
            return
        end
        state.checkpoints.saved = nil
        local cp = state.editor.route[1]
        practice.selectChallenge(
            cp[1],
            catalog.courses[cp[1]][4] and (cp[4] == "count" and 3 or cp[4] == "pipe" and 1 or 2) or 1,
            cp[3]
        )
        if state.settings.runFromIntro and not saveSlots.beginTraining() then
            state.practice.phase = "stopped"
            records.publish()
            return
        end
        state.run = {
            active = true,
            finished = false,
            index = 1,
            total = 0,
            splits = {},
            best = {},
            route = {},
            key = routes.routeKey(),
            lastTick = -1,
            seen = {},
            progress = 0,
            stars = 0,
            keys = 0,
            subTimes = {},
            saved = {},
            savedSubs = {},
        }
        state.overlayPage = nil
        for i, item in ipairs(state.editor.route) do
            state.run.route[i] = { item[1], item[2], item[3], item[4] }
            state.run.best[i] = tonumber(mod_storage_load(state.run.key .. "_s" .. i))
            state.run.saved[i] = tonumber(mod_storage_load(state.run.key .. "_last_s" .. i))
                or state.run.best[i]
            state.run.subTimes[i] = {}
            state.run.savedSubs[i] = {}
            if item[4] == "count" then
                for j = 1, item[2] do
                    state.run.savedSubs[i][j] =
                        tonumber(mod_storage_load(state.run.key .. "_last_s" .. i .. "_star" .. j))
                end
            end
        end
        state.run.pb = tonumber(mod_storage_load(state.run.key .. "_pb"))
        if state.settings.runFromIntro then
            state.run.intro = true
            state.run.lakituPending = true
            state.run.castleWelcomePending = true
            state.menu.open = false
            state.practice.phase, state.practice.frames, state.practice.pendingFrames, state.practice.arrival =
                "pending", 0, 0, false
            local m = gMarioStates[0]
            practice.closeSaveDialog(m)
            practice.refillHealth(m)
            set_menu_mode(-1)
            reset_dialog_render_state()
            disable_time_stop_including_mario()
            m.freeze = 0
            m.capTimer, m.hurtCounter, m.healCounter = 0, 0, 0
            m.numLives = 4
            m.numCoins = 0
            m.numStars = 0
            m.numKeys = 0
            m.prevNumStarsForDialog = 0
            state.practice.message = "Preparando partida nueva e intro..."
            if not warp_to_start_level() then
                practice.stop("Warp rechazado. Cierra menus y reintenta.")
            end
            records.publish()
        else
            practice.start(true)
        end
    end

    function runs.finishCheckpoint(m, o, accepted, pipeLevel)
        if
            not accepted
            or m.playerIndex ~= 0
            or state.practice.phase ~= "running"
            or state.run.lastTick == state.run.total
        then
            return
        end
        local cp = state.run.route[state.run.index]
        if not cp then
            return
        end
        if pipeLevel then
            if cp[4] ~= "pipe" or pipeLevel ~= catalog.courses[cp[1]][4] then
                return
            end
        else
            local level = gNetworkPlayers[0].currLevelNum
            local isKey = obj_has_behavior_id(o, id_bhvBowserKey) ~= 0
            local isGrand = ((o.oInteractionSubtype or 0) & INT_SUBTYPE_GRAND_STAR) ~= 0
            local token = level
                .. ":"
                .. (isKey and "key" or isGrand and "grand" or ((o.oBehParams >> 24) & 0x1F))
            if state.run.seen[token] then
                return
            end
            state.run.seen[token] = true
            local matches = cp[4] == "count"
                    and not isKey
                    and not isGrand
                    and level == catalog.courses[cp[1]][3]
                or cp[4] == "key" and isKey and level == catalog.courses[cp[1]][4]
                or cp[4] == "grand" and isGrand and level == LEVEL_BOWSER_3
            if not matches then
                i18n.say("Split fuera de orden")
                return
            end
            if cp[4] == "count" then
                state.run.progress = state.run.progress + 1
                state.run.stars = state.run.stars + 1
                state.run.subTimes[state.run.index][state.run.progress] = state.run.total
                if
                    not mod_storage_save(
                        state.run.key .. "_last_s" .. state.run.index .. "_star" .. state.run.progress,
                        tostring(state.run.total)
                    )
                then
                    i18n.say("No se pudo guardar el registro en disco.")
                end
                if state.run.progress < cp[2] then
                    return
                end
            elseif cp[4] == "key" then
                state.run.keys = state.run.keys + 1
            end
        end
        state.run.progress = 0
        state.run.lastTick = state.run.total
        state.run.flash = 30
        state.run.splits[state.run.index] = state.run.total
        if not mod_storage_save(state.run.key .. "_last_s" .. state.run.index, tostring(state.run.total)) then
            i18n.say("No se pudo guardar el registro en disco.")
        end
        if state.run.best[state.run.index] then
            local previous = state.run.index > 1 and state.run.splits[state.run.index - 1] or 0
            local bestPrevious = state.run.index > 1 and state.run.best[state.run.index - 1] or 0
            if bestPrevious then
                local loss = (state.run.total - previous) - (state.run.best[state.run.index] - bestPrevious)
                if loss > 0 and (not state.run.loss or loss > state.run.loss) then
                    state.run.loss, state.run.lossCheckpoint = loss, cp
                end
            end
        end
        i18n.say(
            "Split " .. state.run.index .. "/" .. #state.run.route .. "  " .. format.fmt(state.run.total)
        )
        state.run.index = state.run.index + 1
        if state.run.index > #state.run.route then
            state.run.active, state.run.finished, state.practice.phase = false, true, "finished"
            local newPB = not state.run.pb or state.run.total < state.run.pb
            if newPB then
                local ok = mod_storage_save(state.run.key .. "_pb", tostring(state.run.total))
                for i, value in ipairs(state.run.splits) do
                    ok = mod_storage_save(state.run.key .. "_s" .. i, tostring(value)) and ok
                end
                if not ok then
                    i18n.say("No se pudo guardar el registro en disco.")
                end
            end
            state.practice.message = newPB and "NUEVO PB!" or "Run completada"
            state.review.loss, state.review.checkpoint = state.run.loss, state.run.lossCheckpoint
            i18n.say(state.practice.message .. "  " .. format.fmt(state.run.total))
            records.publish()
        end
    end

    function runs.recordPickup(m, o, accepted)
        if not accepted or m.playerIndex ~= 0 or state.recording.lastTick == state.clock.tick then
            return
        end
        local level = gNetworkPlayers[0].currLevelNum
        local isKey = obj_has_behavior_id(o, id_bhvBowserKey) ~= 0
        local isGrand = ((o.oInteractionSubtype or 0) & INT_SUBTYPE_GRAND_STAR) ~= 0
        local token = level
            .. ":"
            .. (isKey and "key" or isGrand and "grand" or ((o.oBehParams >> 24) & 0x1F))
        if state.recording.seen[token] then
            return
        end
        for i, c in ipairs(catalog.courses) do
            if c[3] == level or c[4] == level then
                local kind = isKey and "key" or isGrand and "grand" or "count"
                if (isKey or isGrand) and level ~= c[4] then
                    return
                end
                if isKey and i ~= 16 and i ~= 17 or isGrand and i ~= 18 then
                    return
                end
                local planned = 0
                for _, cp in ipairs(state.editor.route) do
                    if cp[1] == i and cp[4] == kind then
                        planned = planned + cp[2]
                    end
                end
                if kind == "count" and planned >= catalog.starCapacity(i) then
                    i18n.say("El nivel ya tiene todas sus estrellas en la ruta.")
                    return
                end
                if kind ~= "count" and planned > 0 then
                    i18n.say("Ese checkpoint ya esta en la ruta.")
                    return
                end
                local previous = state.editor.route[#state.editor.route]
                local before = routes.encodeRoute()
                if
                    kind == "count"
                    and previous
                    and previous[1] == i
                    and previous[4] == "count"
                    and previous[2] < catalog.starCapacity(i)
                then
                    previous[2] = previous[2] + 1
                    if not routes.saveRoute() then
                        previous[2] = previous[2] - 1
                        return
                    end
                    state.editor.undoAdditions[state.editor.slot] =
                        { before = before, after = routes.encodeRoute() }
                else
                    if #state.editor.route >= routes.MAX_ROUTE then
                        state.recording.active = false
                        i18n.say("Ruta llena: 64 bloques")
                        return
                    end
                    if not routes.appendCheckpoint({ i, 1, 1, kind }) then
                        return
                    end
                end
                state.recording.seen[token] = true
                state.recording.lastTick = state.clock.tick
                i18n.say(
                    routes.checkpointLabel(state.editor.route[#state.editor.route])
                        .. " / "
                        .. routes.routeSummary(state.editor.route)
                )
                return
            end
        end
    end
end
