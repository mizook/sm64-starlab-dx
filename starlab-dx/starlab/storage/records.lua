-- Full-attempt PBs, history, sessions and synchronized summary. Storage keys remain compatible.
return function(app)
    local state = app.state
    local catalog = app.catalog
    local i18n = app.i18n
    local format = app.format
    local records = app.records

    function records.key()
        return "tick_v1_"
            .. state.settings.profile
            .. "_"
            .. catalog.courses[state.practice.courseIndex][1]
            .. "_s"
            .. state.practice.target
            .. "_a"
            .. state.practice.entryAct
    end

    function records.loadStats()
        state.practice.challengeKey = records.key()
        state.practice.pb = tonumber(mod_storage_load(state.practice.challengeKey .. "_pb"))
        state.practice.attempts = tonumber(mod_storage_load(state.practice.challengeKey .. "_tries")) or 0
        state.practice.finishes = tonumber(mod_storage_load(state.practice.challengeKey .. "_wins")) or 0
        state.practice.last = nil
        state.practice.recent = {}
        for value in (mod_storage_load(state.practice.challengeKey .. "_recent", "")):gmatch("%d+") do
            if #state.practice.recent < 10 then
                state.practice.recent[#state.practice.recent + 1] = tonumber(value)
            end
        end
    end

    function records.recordAttempt(value)
        state.practice.recent[#state.practice.recent + 1] = value
        if #state.practice.recent > 10 then
            table.remove(state.practice.recent, 1)
        end
        local values = {}
        for i, v in ipairs(state.practice.recent) do
            values[i] = tostring(v)
        end
        if not mod_storage_save(state.practice.challengeKey .. "_recent", table.concat(values, ",")) then
            i18n.say("No se pudo guardar el registro en disco.")
        end
        if
            state.session.active
            and state.session.key == state.practice.challengeKey
            and #state.session.values < 10
        then
            state.session.values[#state.session.values + 1] = value
            if #state.session.values == 10 then
                state.session.active, state.session.done, state.session.showSummary = false, true, true
                state.practice.retryCountdown = nil
                local out = {}
                for i, v in ipairs(state.session.values) do
                    out[i] = tostring(v)
                end
                if
                    not mod_storage_save(state.practice.challengeKey .. "_session", table.concat(out, ","))
                then
                    i18n.say("No se pudo guardar el registro en disco.")
                end
            end
        end
    end

    function records.sessionStats()
        local sorted, sum, best = {}, 0, nil
        for _, v in ipairs(state.session.values) do
            if v > 0 then
                sorted[#sorted + 1] = v
                sum = sum + v
                best = best and math.min(best, v) or v
            end
        end
        table.sort(sorted)
        local n = #sorted
        local median = n > 0
                and (n % 2 == 1 and sorted[(n + 1) / 2] or (sorted[n / 2] + sorted[n / 2 + 1]) / 2)
            or nil
        return n, n > 0 and sum / n or nil, median, best
    end

    function records.recentSummary(values)
        local wins, sum = 0, 0
        for _, v in ipairs(values) do
            if v > 0 then
                wins = wins + 1
                sum = sum + v
            end
        end
        return "Recientes " .. wins .. "/" .. #values,
            wins > 0 and ("Media " .. format.fmt(sum / wins)) or "Sin tiempos aun"
    end

    function records.save(suffix, value)
        if not mod_storage_save(state.practice.challengeKey .. suffix, tostring(value)) then
            i18n.say("No se pudo guardar el registro en disco.")
        end
    end

    function records.publish()
        local s = gPlayerSyncTable[0]
        s.slChallenge = state.practice.challengeKey
        s.slLabel = catalog.courses[state.practice.courseIndex][1]:upper()
            .. " "
            .. catalog.targetLabel(state.practice.courseIndex, state.practice.target)
            .. " A"
            .. state.practice.entryAct
        s.slPB = state.practice.pb or 0
        s.slPhase = state.practice.phase
    end
end
