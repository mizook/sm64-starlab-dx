-- Explanations live outside the active timer; opening the menu already cancels it.
return function(app)
    local state, drawing, help = app.state, app.drawing, app.help
    local pages = {
        {
            {
                "ESTRELLA COMPLETA / PB",
                "Desde la entrada hasta tu objetivo. PB es tu mejor intento completo.",
            },
            {
                "PARCIAL DESDE CHECKPOINT",
                "El reloj retoma el tiempo guardado. Mejor parcial mide desde el punto; no reemplaza el PB completo.",
            },
            {
                "RUN / TIEMPO DE PRACTICA",
                "Desde el inicio elegido; incluye la intro si la eliges. 30 Hz; la pausa no suma. No es RTA oficial.",
            },
        },
        {
            {
                "ACTUAL",
                "Tiempo acumulado de esta run al completar cada estrella o bloque; no duracion del segmento.",
            },
            {
                "GUARDADO",
                "Ultimo tiempo de ese punto en otro intento. Puede venir de una run incompleta o mas lenta.",
            },
            {
                "REFERENCIA Y PB",
                "Sin ultimo tiempo se usa el split del PB, si existe. -- indica sin registro. PB conserva la mejor run completa.",
            },
        },
        {
            {
                "AL CARGAR UN CHECKPOINT",
                "Restaura a Mario y la camara al instante, sin recargar la zona. Guarda sobre suelo firme.",
            },
            {
                "ESTADO LOCAL DE MARIO",
                "Monedas, enemigos e interruptores no se restauran al estado que tenian al guardar.",
            },
            {
                "VOLVER AL INTENTO COMPLETO",
                "L + abajo reinicia desde la entrada. Cargar punto se desactiva sin punto o fuera de su zona. Borralo en Practica.",
            },
        },
    }
    function help.open(page)
        if state.menu.screen ~= "timingHelp" then
            state.menu.helpReturn, state.menu.helpReturnRow = state.menu.screen, state.menu.row
        end
        state.menu.helpPage = page or 1
        state.menu.screen, state.menu.row = "timingHelp", 1
    end
    function help.back()
        state.menu.screen, state.menu.row = state.menu.helpReturn or "home", state.menu.helpReturnRow or 1
    end
    function help.input(delta, confirm)
        if state.menu.screen ~= "timingHelp" then
            return false
        end
        if delta ~= 0 then
            state.menu.helpPage = (state.menu.helpPage - 1 + delta) % #pages + 1
        end
        if confirm then
            help.back()
        end
        return true
    end
    function help.draw(x, y)
        if state.menu.screen ~= "timingHelp" then
            return false
        end
        local tabs = { "1. TIEMPOS", "2. SPLITS", "3. CHECKPOINT" }
        for i, label in ipairs(tabs) do
            djui_hud_set_color(i == state.menu.helpPage and 55 or 28, 78, 145, 255)
            djui_hud_render_rect(x + 12 + (i - 1) * 93, y + 49, 90, 17)
            drawing.fitted(label, x + 16 + (i - 1) * 93, y + 53, 0.22, 82)
        end
        for i, item in ipairs(pages[state.menu.helpPage]) do
            local py = y + 76 + (i - 1) * 40
            drawing.drawText(item[1], x + 12, py, 0.22, 255, 221, 114)
            drawing.wrapped(item[2], x + 12, py + 12, 0.235, 274, 3, 221, 231, 241)
        end
        return true
    end
end
