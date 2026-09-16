-- Compact split panel and nested star/key rows.
return function(app)
    local state = app.state
    local catalog = app.catalog
    local format = app.format
    local routes = app.routes
    local runs = app.runs
    local drawing = app.drawing
    local art = app.art
    local overlay = app.overlay

    -- Shared with input so page navigation always matches the rendered layout.
    -- Keep the panel narrow. Scale rows and their icons together, then paginate extreme routes.
    function overlay.layout()
        djui_hud_set_resolution(RESOLUTION_N64)
        local allRows, activeRow = runs.splitRows()
        local bodyHeight = math.max(4.5, djui_hud_get_screen_height() - 16 - 64)
        local maxRows = math.max(1, math.floor(bodyHeight / 4.5))
        local columns = 1
        local rowsPerColumn = math.max(1, math.min(maxRows, math.ceil(#allRows / columns)))
        local capacity = rowsPerColumn * columns
        local pages = math.max(1, math.ceil(#allRows / capacity))
        local page = math.min(state.overlayPage or math.floor((activeRow - 1) / capacity), pages - 1)
        local rowHeight = math.min(7, bodyHeight / rowsPerColumn)
        return {
            allRows = allRows,
            activeRow = activeRow,
            columns = columns,
            rowsPerColumn = rowsPerColumn,
            capacity = capacity,
            pages = pages,
            page = page,
            first = page * capacity + 1,
            last = math.min(#allRows, (page + 1) * capacity),
            rowHeight = rowHeight,
            width = columns * 144 + (columns - 1) * 6,
        }
    end

    function overlay.splitIcon(kind, x, y, size, completed)
        if kind == "count" or kind == "grand" then
            local tex = art.paintingTexture("texture_hud_char_star", true)
            if tex and tex.width and tex.width > 0 then
                local tint = completed and 255 or 170
                djui_hud_set_color(tint, tint, tint, 255)
                djui_hud_render_texture(tex, x, y, size / tex.width, size / tex.height)
            else
                drawing.titleStar(x, y, size)
            end
        elseif kind == "key" then
            local pixels = {
                "01110000",
                "11011000",
                "11011000",
                "01110000",
                "00100000",
                "00111110",
                "00101000",
                "00000000",
            }
            djui_hud_set_color(
                completed and 255 or 197,
                completed and 211 or 169,
                completed and 78 or 96,
                255
            )
            for row, line in ipairs(pixels) do
                for col = 1, #line do
                    if line:sub(col, col) == "1" then
                        djui_hud_render_rect(
                            x + (col - 1) * size / 8,
                            y + (row - 1) * size / 8,
                            size / 8,
                            size / 8
                        )
                    end
                end
            end
        else
            djui_hud_set_color(91, 185, 104, 255)
            djui_hud_render_rect(x, y, size, size * 0.3)
            djui_hud_render_rect(x + size * 0.15, y + size * 0.3, size * 0.7, size * 0.7)
        end
    end

    function overlay.drawRun()
        if not state.settings.runOverlay then
            return
        end
        local x, y = 8, 8
        if state.settings.overlayMinimal then
            djui_hud_set_color(5, 9, 15, 185)
            djui_hud_render_rect(x, y, 89, 22)
            drawing.drawText(format.fmt(state.run.total), x + 4, y + 2, 0.52)
            return
        end
        local layout = overlay.layout()
        local allRows, activeRow = layout.allRows, layout.activeRow
        local pages, page = layout.pages, layout.page
        local first, lastIndex = layout.first, layout.last
        local footerY = y + 40 + layout.rowsPerColumn * layout.rowHeight
        local rowScale = layout.rowHeight / 9
        local showRetry = state.settings.retryEnabled and state.practice.phase ~= "pending"
        djui_hud_set_color(5, 9, 15, 205)
        djui_hud_render_rect(x, y, layout.width, footerY - y + 24)
        drawing.fittedName(routes.runName(), x + 5, y + 3, 0.20, layout.width - 38, 206, 214, 222)
        drawing.drawText(
            math.min(state.run.index, #state.run.route) .. "/" .. #state.run.route,
            x + layout.width - 28,
            y + 3,
            0.20,
            206,
            214,
            222
        )
        drawing.drawText(format.fmt(state.run.total), x + 5, y + 10, 0.42)
        drawing.fitted("PB " .. format.fmt(state.run.pb), x + 90, y + 16, 0.15, 49, 151, 166, 188)
        local plannedStars, plannedKeys = routes.routeTotals(state.run.route)
        drawing.fitted(
            (state.run.stars or 0)
                .. "/"
                .. plannedStars
                .. " estrellas / "
                .. (state.run.keys or 0)
                .. "/"
                .. plannedKeys
                .. " llaves",
            x + 5,
            y + 25,
            0.18,
            132,
            163,
            178,
            192
        )
        for column = 0, layout.columns - 1 do
            local cx = x + column * 150
            drawing.fitted("ACTUAL", cx + 77, y + 33, 0.13, 29, 150, 164, 182)
            drawing.fitted("GUARDADO", cx + 110, y + 33, 0.13, 30, 150, 164, 182)
            if column > 0 then
                djui_hud_set_color(67, 83, 103, 180)
                djui_hud_render_rect(cx - 3, y + 39, 0.5, footerY - y - 40)
            end
        end
        for rowIndex = first, lastIndex do
            local slot = rowIndex - first
            local column = math.floor(slot / layout.rowsPerColumn)
            local columnRow = slot % layout.rowsPerColumn
            local x = x + column * 150
            local row = allRows[rowIndex]
            local i = row.index
            local cp = state.run.route[i]
            local ry = y + 40 + columnRow * layout.rowHeight
            local value, reference
            if row.sub then
                value, reference = state.run.subTimes[i][row.sub], state.run.savedSubs[i][row.sub]
            else
                value, reference = state.run.splits[i], state.run.saved[i]
            end
            local active = rowIndex == activeRow and not state.run.finished
            if active then
                djui_hud_set_color(51, 66, 86, 220)
                djui_hud_render_rect(x + 2, ry - 1, 140, layout.rowHeight)
            end
            if row.sub then
                djui_hud_set_color(67, 83, 103, 255)
                djui_hud_render_rect(x + 8, ry - 1, 0.5, layout.rowHeight)
                djui_hud_render_rect(x + 8, ry + 3 * rowScale, 4, 0.5)
                overlay.splitIcon("count", x + 14, ry, 7 * rowScale, value ~= nil)
                local label = "Recogida " .. row.sub
                if columnRow == 0 then
                    label = catalog.courses[cp[1]][1]:upper() .. " / " .. row.sub
                end
                drawing.fitted(
                    label,
                    x + 23,
                    ry + rowScale,
                    0.19 * rowScale,
                    50,
                    active and 240 or 181,
                    active and 243 or 196,
                    active and 246 or 214
                )
            else
                overlay.splitIcon(cp[4], x + 5, ry, 7 * rowScale, value ~= nil)
                local label = catalog.courses[cp[1]][1]:upper()
                if cp[4] == "count" then
                    label = label .. " x" .. cp[2]
                end
                drawing.fitted(label, x + 15, ry, 0.21 * rowScale, 58, 255, 211, 78)
            end
            local ahead = value and reference and value <= reference
            drawing.fitted(
                value and format.fmt(value) or "--",
                x + 77,
                ry + rowScale,
                0.19 * rowScale,
                29,
                not row.sub and 255 or value and (ahead and 153 or reference and 255 or 223) or 126,
                not row.sub and 211 or value and (ahead and 225 or reference and 157 or 230) or 144,
                not row.sub and 78 or value and (ahead and 191 or reference and 145 or 240) or 165
            )
            drawing.fitted(
                reference and format.fmt(reference) or "--",
                x + 110,
                ry + rowScale,
                0.19 * rowScale,
                30,
                not row.sub and 224 or 151,
                not row.sub and 193 or 166,
                not row.sub and 114 or 188
            )
        end
        if showRetry then
            drawing.buttonIcon("L", x + 5, footerY, 8)
            drawing.buttonIcon("down", x + 15, footerY, 8)
            drawing.fitted("Reiniciar run", x + 27, footerY + 1, 0.19, 110, 193, 204, 218)
        end
        drawing.fitted("L+izq: solo tiempo", x + 5, footerY + 9, 0.17, 134, 163, 178, 192)
        if pages > 1 then
            drawing.fitted(
                "L+der: pagina " .. (page + 1) .. "/" .. pages,
                x + 5,
                footerY + 17,
                0.16,
                134,
                163,
                178,
                192
            )
        end
    end
end
