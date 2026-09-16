-- Route editing, serialization, migration and persistence.
return function(app)
    local state = app.state
    local catalog = app.catalog
    local i18n = app.i18n
    local routes = app.routes

    routes.MAX_ROUTE = 64

    function routes.runName(slot)
        local name = mod_storage_load("route_name_" .. (slot or state.editor.slot), "")
        return name ~= "" and name or "Run " .. (slot or state.editor.slot)
    end

    function routes.checkpointLabel(cp)
        if cp[4] == "count" then
            return catalog.courses[cp[1]][1]:upper() .. " x" .. cp[2]
        end
        return catalog.courses[cp[1]][1]:upper()
            .. " "
            .. (cp[4] == "key" and "LLAVE" or cp[4] == "grand" and "FINAL" or "TUBO")
    end

    function routes.routeTotals(list)
        local stars, keys = 0, 0
        for _, cp in ipairs(list) do
            if cp[4] == "count" then
                stars = stars + cp[2]
            elseif cp[4] == "key" then
                keys = keys + 1
            end
        end
        return stars, keys
    end

    function routes.routeSummary(list)
        local stars, keys = routes.routeTotals(list)
        return stars .. " estrellas / " .. keys .. " llaves / " .. #list .. " splits"
    end

    function routes.encodeRoute(list)
        local values = {}
        for _, cp in ipairs(list or state.editor.route) do
            values[#values + 1] = table.concat(cp, ":")
        end
        return table.concat(values, ",")
    end

    function routes.loadRoute()
        state.editor.route = {}
        state.editor.storageOK = true
        local data = mod_storage_load("route_v2_" .. state.editor.slot, "__missing__")
        if data == "__missing__" then
            -- Preserve the original exact-star route. Merge adjacent stars into a count.
            for ls, ss, acts in
                mod_storage_load("route_" .. state.editor.slot, ""):gmatch("(%d+):(%d+):(%d+)")
            do
                local l, t, a = tonumber(ls), tonumber(ss), tonumber(acts)
                if l >= 1 and l <= 18 and t >= 1 and t <= catalog.targetCount(l) and a >= 1 and a <= 6 then
                    local kind = not catalog.courses[l][4] and "count"
                        or t == 1 and "pipe"
                        or t == 2 and (l == 18 and "grand" or "key")
                        or "count"
                    local previous = state.editor.route[#state.editor.route]
                    if
                        kind == "count"
                        and previous
                        and previous[1] == l
                        and previous[4] == kind
                        and previous[2] < catalog.starCapacity(l)
                    then
                        previous[2] = previous[2] + 1
                    elseif #state.editor.route < routes.MAX_ROUTE then
                        state.editor.route[#state.editor.route + 1] = { l, 1, 1, kind }
                    end
                end
            end
            if #state.editor.route > 0 then
                state.editor.storageOK =
                    mod_storage_save("route_v2_" .. state.editor.slot, routes.encodeRoute())
                if state.editor.storageOK then
                    i18n.say("Ruta convertida a cantidades; PB anteriores conservados.")
                else
                    i18n.say("No se pudo guardar")
                end
            end
        else
            for ls, ns, acts, kind in data:gmatch("(%d+):(%d+):(%d+):(%a+)") do
                local l, n, a = tonumber(ls), tonumber(ns), tonumber(acts)
                if
                    l >= 1
                    and l <= #catalog.courses
                    and a >= 1
                    and a <= 6
                    and #state.editor.route < routes.MAX_ROUTE
                then
                    local valid = kind == "count" and n >= 1 and n <= catalog.starCapacity(l)
                        or kind == "key" and (l == 16 or l == 17) and n == 1
                        or kind == "grand" and l == 18 and n == 1
                        or kind == "pipe" and l >= 16 and l <= 18 and n == 1
                    if valid then
                        state.editor.route[#state.editor.route + 1] = { l, n, a, kind }
                    end
                end
            end
        end
    end

    function routes.routeKey()
        return (state.settings.runFromIntro and "run_counts_intro_v1_" or "run_counts_v1_")
            .. state.settings.profile
            .. "_"
            .. routes.encodeRoute()
    end

    function routes.saveRoute()
        local saved = mod_storage_save("route_v2_" .. state.editor.slot, routes.encodeRoute())
        if not saved then
            i18n.say("No se pudo guardar el registro en disco.")
        end
        return saved
    end

    function routes.appendCheckpoint(cp)
        local before = routes.encodeRoute()
        state.editor.route[#state.editor.route + 1] = cp
        if not routes.saveRoute() then
            table.remove(state.editor.route)
            return false
        end
        state.editor.undoAdditions[state.editor.slot] = { before = before, after = routes.encodeRoute() }
        return true
    end

    function routes.canUndoAddition()
        local saved = state.editor.undoAdditions[state.editor.slot]
        return saved and saved.after == routes.encodeRoute()
    end

    function routes.undoAddition()
        if not routes.canUndoAddition() then
            state.editor.manageNotice = "No hay nada que deshacer"
            return false
        end
        if
            not mod_storage_save(
                "route_v2_" .. state.editor.slot,
                state.editor.undoAdditions[state.editor.slot].before
            )
        then
            state.editor.manageNotice = "No se pudo guardar"
            return false
        end
        state.editor.undoAdditions[state.editor.slot] = nil
        routes.loadRoute()
        state.editor.cursor = math.max(1, math.min(state.editor.cursor, #state.editor.route))
        state.editor.manageNotice = "Ultima estrella deshecha"
        state.editor.builderNotice = state.editor.manageNotice
        return true
    end

    function routes.saveRunName(value)
        value = value:match("^%s*(.-)%s*$")
        if #value > 20 or value:find("[^A-Za-z0-9 %-]") then
            state.editor.manageNotice = "Nombre: letras, numeros, espacios y guion."
            return false
        end
        if not mod_storage_save("route_name_" .. state.editor.slot, value) then
            state.editor.manageNotice = "No se pudo guardar"
            return false
        end
        state.editor.manageNotice = "Nombre guardado"
        return true
    end

    function routes.duplicateRoute()
        if #state.editor.route == 0 then
            state.editor.manageNotice = "Ruta vacia"
            return false
        end
        local destination = nil
        for i = 1, 5 do
            if
                i ~= state.editor.slot
                and mod_storage_load("route_v2_" .. i, mod_storage_load("route_" .. i, "")) == ""
                and mod_storage_load("route_name_" .. i, "") == ""
            then
                destination = i
                break
            end
        end
        if not destination then
            state.editor.manageNotice = "Sin espacios libres"
            return false
        end
        local data, name = routes.encodeRoute(), routes.runName():sub(1, 15) .. " COPY"
        if not mod_storage_save("route_v2_" .. destination, data) then
            state.editor.manageNotice = "No se pudo guardar"
            return false
        end
        local named = mod_storage_save("route_name_" .. destination, name)
        state.editor.slot = destination
        routes.loadRoute()
        state.editor.cursor = 1
        state.editor.undoAdditions[state.editor.slot] = nil
        state.editor.manageNotice = named and "Ruta duplicada" or "Copia guardada sin nombre"
        return true
    end

    function routes.addCheckpoint()
        if not state.editor.storageOK then
            state.editor.builderNotice = "No se pudo guardar"
            return
        end
        if #state.editor.route >= routes.MAX_ROUTE then
            state.editor.builderNotice = "Ruta llena: 64 bloques"
            i18n.say(state.editor.builderNotice)
            return
        end
        local kind = "count"
        if catalog.courses[state.editor.courseIndex][4] then
            kind = state.editor.count == 1 and "count"
                or state.editor.count == 2 and (state.editor.courseIndex == 18 and "grand" or "key")
                or "pipe"
        end
        local quantity = kind == "count"
                and (catalog.courses[state.editor.courseIndex][4] and 1 or state.editor.count)
            or 1
        local total = 0
        for _, cp in ipairs(state.editor.route) do
            if cp[1] == state.editor.courseIndex and cp[4] == kind then
                if kind ~= "count" then
                    state.editor.builderNotice = "Ese checkpoint ya esta en la ruta."
                    i18n.say(state.editor.builderNotice)
                    return
                end
                total = total + cp[2]
            end
        end
        if total + quantity > catalog.starCapacity(state.editor.courseIndex) then
            state.editor.builderNotice = "El nivel ya tiene todas sus estrellas en la ruta."
            i18n.say(state.editor.builderNotice)
            return
        end
        state.editor.builderNotice = routes.appendCheckpoint({ state.editor.courseIndex, quantity, 1, kind })
                and "Bloque agregado"
            or "No se pudo guardar"
        if state.editor.builderNotice == "Bloque agregado" then
            i18n.say(
                routes.checkpointLabel(state.editor.route[#state.editor.route])
                    .. " / "
                    .. routes.routeSummary(state.editor.route)
            )
        end
    end
end
