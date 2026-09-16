-- Ownership checks and lifecycle of the secondary training save. Never erase an unowned slot.
return function(app)
    local state = app.state
    local i18n = app.i18n
    local saveSlots = app.saveSlots

    function saveSlots.trainingSignature()
        local values = { save_file_get_flags() }
        local file = get_current_save_file_num() - 1
        for course = 0, 24 do
            values[#values + 1] = save_file_get_star_flags(file, course)
            values[#values + 1] = save_file_get_course_coin_score(file, course)
        end
        local empty = true
        for _, value in ipairs(values) do
            if value ~= 0 then
                empty = false
                break
            end
        end
        return table.concat(values, ":"), empty
    end

    function saveSlots.releaseTraining(exitIntro)
        if not state.training.active then
            return
        end
        local remembered = false
        if state.training.slot == get_current_save_file_num() and save_file_get_using_backup_slot() then
            local m = gMarioStates[0]
            if m.action == ACT_EXIT_LAND_SAVE_DIALOG then
                set_menu_mode(-1)
                reset_dialog_render_state()
                disable_time_stop_including_mario()
                set_mario_action(m, ACT_IDLE, 0)
            elseif m.action == ACT_INTRO_CUTSCENE then
                set_mario_action(m, ACT_IDLE, 0)
                if exitIntro then
                    warp_to_level(LEVEL_CASTLE_GROUNDS, 1, 0)
                end
            end
            local signature = saveSlots.trainingSignature()
            remembered = mod_storage_save("training_signature_" .. state.training.slot, signature)
            save_file_set_using_backup_slot(false)
            save_file_reload(0)
        end
        if remembered then
            mod_storage_save("training_active_" .. state.training.slot, "0")
        end
        state.training = { active = false }
    end

    function saveSlots.beginTraining()
        local function fail(text)
            state.practice.message = text
            i18n.say(text)
            return false
        end
        if not network_is_server() then
            return fail("La run desde cero requiere anfitrion sin otros jugadores.")
        end
        for i = 1, MAX_PLAYERS - 1 do
            if gNetworkPlayers[i] and gNetworkPlayers[i].connected then
                return fail("La run desde cero requiere anfitrion sin otros jugadores.")
            end
        end
        if gLevelValues.entryLevel ~= LEVEL_CASTLE_GROUNDS then
            return fail("La intro requiere el inicio original del juego base.")
        end
        local slot = get_current_save_file_num()
        if slot < 1 or slot > 4 then
            return fail("No se pudo preparar el espacio de entrenamiento.")
        end
        if save_file_get_using_backup_slot() then
            return fail("El guardado secundario esta ocupado. Vuelve a tu partida principal.")
        end
        save_file_set_using_backup_slot(true)
        local signature, empty = saveSlots.trainingSignature()
        -- The engine resets backup selection on restart, but an interrupted StarLab
        -- session retains its ownership marker. Its signature may predate pickups.
        local interrupted = mod_storage_load("training_active_" .. slot, "") == "1"
        if interrupted and not mod_storage_save("training_recovered_" .. slot, signature) then
            save_file_set_using_backup_slot(false)
            save_file_reload(0)
            return fail("No se pudo preparar el espacio de entrenamiento.")
        end
        if
            not empty
            and not interrupted
            and signature ~= mod_storage_load("training_signature_" .. slot, "")
        then
            save_file_set_using_backup_slot(false)
            save_file_reload(0)
            return fail("El espacio de entrenamiento contiene otro progreso. No se borro.")
        end
        if not mod_storage_save("training_active_" .. slot, "1") then
            save_file_set_using_backup_slot(false)
            save_file_reload(0)
            return fail("No se pudo preparar el espacio de entrenamiento.")
        end
        -- This API clears only the secondary slot; never erase the main save for a run.
        state.training = { active = true, slot = slot }
        save_file_erase_current_backup_save()
        save_file_reload(0)
        return true
    end

    function saveSlots.canReset()
        if not network_is_server() then
            return false
        end
        for i = 1, MAX_PLAYERS - 1 do
            if gNetworkPlayers[i] and gNetworkPlayers[i].connected then
                return false
            end
        end
        return get_current_save_file_num() >= 1 and get_current_save_file_num() <= 4
    end
end
