-- HUD composition for full attempts, partial practice and runs.
return function(app)
    local state = app.state
    local catalog = app.catalog
    local i18n = app.i18n
    local format = app.format
    local records = app.records
    local drawing = app.drawing
    local menuView = app.menuView
    local overlay = app.overlay
    local hud = app.hud

    -- Reuse the same N64 button primitives as menus and the run overlay.
    local function checkpointControls(x, y, compact)
        local function hint(button, label, column, row, enabled)
            local hx, hy = x + column * (compact and 86 or 64), y + row * 9
            drawing.buttonIcon("L", hx, hy, compact and 6 or 7, enabled)
            drawing.buttonIcon(button, hx + 9, hy, compact and 6 or 7, enabled)
            local shade = enabled and 222 or 139
            drawing.fitted(
                label,
                hx + 19,
                hy + 1,
                compact and 0.16 or 0.18,
                compact and 64 or 42,
                shade,
                shade,
                shade
            )
        end
        hint("left", "Guardar punto", 0, 0, state.practice.phase == "running")
        hint("right", "Cargar punto", 1, 0, app.checkpoints.canLoad())
        hint("down", "Inicio estrella", 0, 1, true)
        hint("up", "Menu / borrar", 1, 1, true)
    end

    function hud.hud()
        if not state.settings.visible and not state.menu.open then
            return
        end
        djui_hud_set_resolution(RESOLUTION_N64)
        djui_hud_set_font(FONT_NORMAL)
        if state.menu.open then
            menuView.drawMenu()
            djui_hud_set_color(255, 255, 255, 255)
            return
        end
        if state.recording.active then
            local y = djui_hud_get_screen_height() - 47
            djui_hud_set_color(10, 17, 25, 210)
            djui_hud_render_rect(8, y, 215, 40)
            drawing.drawText(
                "GRABANDO RUTA " .. state.editor.slot .. " / " .. #state.editor.route .. " SPLITS",
                14,
                y + 4,
                0.3,
                255,
                210,
                83
            )
            drawing.buttonIcon("L", 14, y + 22, 12)
            drawing.buttonIcon("up", 30, y + 22, 12)
            drawing.fitted("L + arriba: guardar y terminar", 47, y + 24, 0.25, 166)
            return
        end
        if state.run.active or state.run.finished then
            overlay.drawRun()
            return
        end
        if
            state.checkpoints.active
            or state.practice.phase == "running"
            or state.practice.phase == "pending"
        then
            local y = djui_hud_get_screen_height() - 39
            djui_hud_set_color(8, 14, 22, 150)
            djui_hud_render_rect(8, y, 220, 32)
            drawing.drawText(
                state.practice.phase == "pending" and "LISTO..." or format.fmt(state.practice.frames),
                12,
                y + 1,
                0.58
            )
            local partial = state.checkpoints.active
            drawing.fitted(
                partial and ("Mejor parcial " .. format.fmt(partial.best))
                    or ("PB " .. format.fmt(state.practice.pb)),
                12,
                y + 22,
                0.18,
                78,
                173,
                195,
                203
            )
            if state.checkpoints.saved then
                djui_hud_set_color(255, 211, 78, 255)
                djui_hud_render_rect(92, y + 25, 2, 2)
            end
            -- Keep shortcuts visible beside the timer without changing HUD height.
            checkpointControls(98, y + 10)
            djui_hud_set_color(255, 255, 255, 255)
            return
        end
        local y = djui_hud_get_screen_height() - 91
        djui_hud_set_color(12, 20, 30, 215)
        djui_hud_render_rect(6, y, 228, 85)
        djui_hud_set_color(255, 210, 83, 255)
        i18n.printText(
            "STARLAB DX  /  "
                .. catalog.courses[state.practice.courseIndex][1]:upper()
                .. "  "
                .. catalog.targetLabel(state.practice.courseIndex, state.practice.target)
                .. "  A"
                .. state.practice.entryAct,
            12,
            y + 3,
            0.22
        )
        djui_hud_set_color(255, 255, 255, 255)
        i18n.printText(format.fmt(state.practice.frames), 12, y + 12, 0.7)
        drawing.fitted("PB completo " .. format.fmt(state.practice.pb), 126, y + 20, 0.18, 103)
        djui_hud_set_color(173, 221, 208, 255)
        drawing.fitted(state.practice.message, 12, y + 36, 0.18, 216)
        djui_hud_set_color(193, 199, 210, 255)
        drawing.buttonIcon("L", 12, y + 45, 6)
        drawing.buttonIcon("down", 21, y + 45, 6)
        drawing.drawText("Repetir", 30, y + 46, 0.18)
        drawing.buttonIcon("L", 110, y + 45, 6)
        drawing.buttonIcon("up", 119, y + 45, 6)
        drawing.drawText("Selector", 128, y + 46, 0.18)
        drawing.fitted(state.practice.finishes .. "/" .. state.practice.attempts, 200, y + 46, 0.18, 29)
        local summary, average = records.recentSummary(state.practice.recent)
        drawing.fitted(
            state.practice.retryCountdown
                    and ("Reintento en " .. math.ceil(state.practice.retryCountdown / 30) .. " s | L+arriba: selector")
                or (summary .. "  /  " .. average),
            12,
            y + 55,
            0.18,
            216
        )
        checkpointControls(12, y + 65, true)
        djui_hud_set_color(255, 255, 255, 255)
    end
end
