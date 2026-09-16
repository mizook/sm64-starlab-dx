-- Course and target metadata; engine pickup matching.
return function(app)
    local state = app.state
    local catalog = app.catalog

    catalog.courses = {
        { "bob", "Bob-omb Battlefield", LEVEL_BOB },
        { "wf", "Whomp's Fortress", LEVEL_WF },
        { "jrb", "Jolly Roger Bay", LEVEL_JRB },
        { "ccm", "Cool, Cool Mountain", LEVEL_CCM },
        { "bbh", "Big Boo's Haunt", LEVEL_BBH },
        { "hmc", "Hazy Maze Cave", LEVEL_HMC },
        { "lll", "Lethal Lava Land", LEVEL_LLL },
        { "ssl", "Shifting Sand Land", LEVEL_SSL },
        { "ddd", "Dire, Dire Docks", LEVEL_DDD },
        { "sl", "Snowman's Land", LEVEL_SL },
        { "wdw", "Wet-Dry World", LEVEL_WDW },
        { "ttm", "Tall, Tall Mountain", LEVEL_TTM },
        { "thi", "Tiny-Huge Island", LEVEL_THI },
        { "ttc", "Tick Tock Clock", LEVEL_TTC },
        { "rr", "Rainbow Ride", LEVEL_RR },
        { "bitdw", "Bowser in the Dark World", LEVEL_BITDW, LEVEL_BOWSER_1 },
        { "bitfs", "Bowser in the Fire Sea", LEVEL_BITFS, LEVEL_BOWSER_2 },
        { "bits", "Bowser in the Sky", LEVEL_BITS, LEVEL_BOWSER_3 },
        { "castle", "Castillo / Toad y MIPS", LEVEL_CASTLE, nil, 5 },
        { "pss", "The Princess's Secret Slide", LEVEL_PSS, nil, 2 },
        { "sa", "The Secret Aquarium", LEVEL_SA, nil, 1 },
        { "totwc", "Tower of the Wing Cap", LEVEL_TOTWC, nil, 1 },
        { "cotmc", "Cavern of the Metal Cap", LEVEL_COTMC, nil, 1 },
        { "vcutm", "Vanish Cap Under the Moat", LEVEL_VCUTM, nil, 1 },
        { "wmotr", "Wing Mario Over the Rainbow", LEVEL_WMOTR, nil, 1 },
    }

    local titles = {
        wf = {
            "Chip Off Whomp's Block",
            "To the Top of the Fortress",
            "Shoot into the Wild Blue",
            "Red Coins on the Floating Isle",
            "Fall onto the Caged Island",
            "Blast Away the Wall",
            "100 monedas",
        },
        bob = {
            "Big Bob-omb on the Summit",
            "Footrace with Koopa the Quick",
            "Shoot to the Island in the Sky",
            "Find the 8 Red Coins",
            "Mario Wings to the Sky",
            "Behind Chain Chomp's Gate",
            "100 monedas",
        },
    }

    function catalog.targetCount(index)
        return catalog.courses[index][5] or (catalog.courses[index][4] and 3 or 7)
    end

    function catalog.starCapacity(index)
        return catalog.courses[index][5] or (catalog.courses[index][4] and 1 or 7)
    end

    function catalog.effectiveAct()
        return (catalog.courses[state.editor.courseIndex][4] or catalog.courses[state.editor.courseIndex][5])
                and 1
            or (state.settings.autoAct and math.min(state.editor.target, 6) or state.editor.entryAct)
    end

    function catalog.targetLabel(index, target)
        if not catalog.courses[index][4] then
            return "S" .. target
        end
        return target == 1 and "TUBO" or target == 2 and (index == 18 and "FINAL" or "LLAVE") or "ROJAS"
    end

    function catalog.targetLevel(index, target, level)
        local c = catalog.courses[index]
        return level == c[3] or (c[4] and target == 2 and level == c[4])
    end

    function catalog.pickupMatches(index, target, o, level)
        local c = catalog.courses[index]
        local isKey = obj_has_behavior_id(o, id_bhvBowserKey) ~= 0
        local isGrand = ((o.oInteractionSubtype or 0) & INT_SUBTYPE_GRAND_STAR) ~= 0
        if c[4] then
            if target == 1 then
                return false
            end
            if target == 2 then
                return level == c[4] and (index == 18 and isGrand or index ~= 18 and isKey)
            end
            return level == c[3] and not isKey and not isGrand and ((o.oBehParams >> 24) & 0x1F) == 0
        end
        return level == c[3] and not isKey and not isGrand and (((o.oBehParams >> 24) & 0x1F) + 1) == target
    end

    function catalog.starName(levelIndex, target)
        if levelIndex > 18 then
            return catalog.courses[levelIndex][2]
        end
        if catalog.courses[levelIndex][4] then
            return target == 1 and "Recorrido hasta el tubo"
                or target == 2 and (levelIndex == 18 and "Recorrido + estrella final" or "Recorrido + llave")
                or "8 monedas rojas"
        end
        local name = smlua_text_utils_act_name_get(levelIndex, target)
        if name and name ~= "" then
            return name
        end
        local c = catalog.courses[levelIndex]
        return titles[c[1]] and titles[c[1]][target]
            or (target == 7 and "100 monedas" or "Estrella " .. target)
    end

    function catalog.title()
        return catalog.starName(state.practice.courseIndex, state.practice.target)
    end
end
