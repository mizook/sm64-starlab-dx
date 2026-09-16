-- Engine integration. Install once, after every module is connected.
return function(app)
    local state = app.state
    local i18n = app.i18n
    local audio = app.audio
    local records = app.records
    local saveSlots = app.saveSlots
    local practice = app.practice
    local checkpoints = app.checkpoints
    local routes = app.routes
    local runs = app.runs
    local menu = app.menu
    local input = app.input
    local events = app.events
    local commands = app.commands
    local hud = app.hud

    records.loadStats()

    routes.loadRoute()

    hook_chat_command("sl", "StarLab DX: /sl help", commands.command)

    hook_event(HOOK_ON_WARP, events.onWarp)

    hook_behavior(id_bhvCameraLakitu, OBJ_LIST_DEFAULT, false, runs.initIntroLakitu, nil)

    hook_event(HOOK_ON_LEVEL_INIT, function()
        -- Starting the game uses gChangeLevel, not a regular warp. Warp destination
        -- arguments may be stale here; the local player's level is already refreshed.
        if state.practice.phase == "pending" and state.run.active and state.run.intro then
            state.practice.arrival = gNetworkPlayers[0].currLevelNum == LEVEL_CASTLE_GROUNDS
        end
    end)

    hook_event(HOOK_BEFORE_MARIO_UPDATE, events.beforeMario)

    -- Mario updates stop in single-player pause, but global updates still receive input.
    hook_event(HOOK_UPDATE, function()
        if not is_game_paused() or djui_is_chatbox_open() or djui_console_is_open() then
            return
        end
        local m = gMarioStates[0]
        if not m or not m.controller then
            return
        end
        local c = m.controller
        if runs.runDisplayInput(m) then
            return
        end
        if checkpoints.practicePointInput(m) then
            return
        end
        if (c.buttonDown & L_TRIG) == 0 then
            return
        end
        if (c.buttonPressed & U_JPAD) ~= 0 then
            practice.closeSaveDialog(m)
            menu.openMenu()
            input.consumeInput(c)
        elseif
            state.settings.retryEnabled
            and state.practice.phase ~= "pending"
            and (c.buttonPressed & D_JPAD) ~= 0
        then
            practice.closeSaveDialog(m)
            input.consumeInput(c)
            if state.run.active or state.run.finished then
                runs.startRun()
            else
                practice.start()
            end
        end
    end)

    hook_event(HOOK_ON_INTERACT, events.onInteract)

    hook_event(HOOK_ON_DEATH, function(m)
        if
            m.playerIndex == 0
            and not state.run.active
            and (state.practice.phase == "running" or state.practice.phase == "pending")
        then
            practice.stop("Intento terminado por muerte.")
            if state.settings.autoRetry and not state.session.done then
                state.practice.retryCountdown = 90
            end
        end
    end)

    hook_event(HOOK_ON_HUD_RENDER, hud.hud)

    hook_event(HOOK_ON_EXIT, function()
        -- Close a normal session cleanly; the active marker handles crashes/reloads.
        saveSlots.releaseTraining()
    end)

    hook_event(HOOK_ON_MODS_LOADED, function()
        local slot = get_current_save_file_num()
        if mod_storage_load("training_active_" .. slot, "") == "1" and save_file_get_using_backup_slot() then
            state.training = { active = true, slot = slot }
            saveSlots.releaseTraining()
        end
        records.publish()
        i18n.say("L + arriba: selector de estrellas. /sl menu tambien lo abre.")
    end)

    hook_mod_menu_button(i18n.tr("Abrir selector grafico (cerrar pausa despues)"), menu.openMenu)

    hook_mod_menu_button("Runs / Auto splits", function()
        menu.openMenu()
        state.menu.screen = "runs"
        routes.loadRoute()
    end)

    hook_mod_menu_button(i18n.tr("Ajustes y guardado"), function()
        menu.openMenu()
        state.menu.screen = "settings"
    end)

    hook_mod_menu_button(i18n.tr("Iniciar / repetir estrella"), function()
        if state.run.active or state.run.finished then
            runs.startRun()
        else
            practice.start()
        end
    end)

    hook_mod_menu_button(i18n.tr("Tiempos y checkpoints"), function()
        menu.openMenu()
        app.help.open(1)
    end)
    hook_mod_menu_button(i18n.tr("Detener practica"), function()
        practice.stop()
    end)

    hook_mod_menu_button(i18n.tr("Borrar checkpoint de practica"), checkpoints.clearPracticePoint)

    hook_mod_menu_button(i18n.tr("Activar/desactivar sonidos del menu"), audio.toggleMenuSounds)

    hook_mod_menu_button(i18n.tr("Mostrar/ocultar overlay de runs"), function()
        commands.command("overlay")
    end)

    hook_mod_menu_button(i18n.tr("Panel completo / solo tiempo"), function()
        commands.command("minimal")
    end)

    hook_mod_menu_button(i18n.tr("Cambiar inicio de runs: intro / checkpoint"), function()
        commands.command(state.settings.runFromIntro and "runfrom checkpoint" or "runfrom intro")
    end)
end
