-- Local Mario snapshots, never level warps or full-world save states.
return function(app)
    local state = app.state
    local catalog = app.catalog
    local i18n = app.i18n
    local audio = app.audio
    local records = app.records
    local practice = app.practice
    local checkpoints = app.checkpoints

    -- Copy values only: engine userdata must never be retained across level loads.
    local marioFields = {
        "action",
        "prevAction",
        "actionArg",
        "actionTimer",
        "actionState",
        "health",
        "hurtCounter",
        "healCounter",
        "cap",
        "capTimer",
        "flags",
        "invincTimer",
        "squishTimer",
        "doubleJumpTimer",
        "wallKickTimer",
        "forwardVel",
        "slideVelX",
        "slideVelZ",
        "slideYaw",
        "twirlYaw",
        "peakHeight",
        "quicksandDepth",
    }
    local cameraFields = { "mode", "defMode", "yaw", "nextYaw" }
    local lakituFields = {
        "mode",
        "defMode",
        "yaw",
        "nextYaw",
        "oldYaw",
        "oldPitch",
        "oldRoll",
        "roll",
        "focusDistance",
        "focHSpeed",
        "focVSpeed",
        "posHSpeed",
        "posVSpeed",
    }
    local function capture(object, fields, vectors)
        local result = {}
        if not object then
            return result
        end
        for _, field in ipairs(fields) do
            result[field] = object[field]
        end
        for _, field in ipairs(vectors) do
            local v = object[field]
            if v then
                result[field] = { x = v.x, y = v.y, z = v.z }
            end
        end
        return result
    end
    local function restore(object, snapshot)
        if not object then
            return
        end
        for field, value in pairs(snapshot) do
            if type(value) == "table" then
                if object[field] then
                    object[field].x, object[field].y, object[field].z = value.x, value.y, value.z
                end
            else
                object[field] = value
            end
        end
    end

    function checkpoints.canLoad()
        local point, p = state.checkpoints.saved, gNetworkPlayers[0]
        return point ~= nil
            and point.key == state.practice.challengeKey
            and point.slot == get_current_save_file_num()
            and point.level == p.currLevelNum
            and point.area == p.currAreaIndex
            and point.act == p.currActNum
    end

    function checkpoints.clearPracticePoint()
        state.checkpoints.saved = nil
        -- A loaded partial remains a partial even when its source point is deleted.
        i18n.say("Checkpoint borrado. Cargar punto desactivado.")
        audio.menuSound("back")
    end

    function checkpoints.savePracticePoint(m)
        local p = gNetworkPlayers[0]
        if
            state.practice.phase ~= "running"
            or not catalog.targetLevel(state.practice.courseIndex, state.practice.target, p.currLevelNum)
            or not m.floor
            or m.floor.object
            or not m.pos
            or not m.faceAngle
            or m.heldObj
            or m.riddenObj
            or (m.area and m.area.camera and (m.area.camera.cutscene or 0) ~= 0)
            or m.health <= 0x100
            or m.action == ACT_UNINITIALIZED
            or (m.action & (ACT_FLAG_AIR | ACT_FLAG_SWIMMING | ACT_FLAG_INTANGIBLE)) ~= 0
            or math.abs(m.pos.y - m.floorHeight) > 10
            or m.floor.normal.y < 0.7
        then
            i18n.say("Guarda el checkpoint sobre suelo firme durante el intento.")
            audio.menuSound("blocked")
            return
        end
        state.checkpoints.saved = {
            key = state.practice.challengeKey,
            slot = get_current_save_file_num(),
            level = p.currLevelNum,
            area = p.currAreaIndex,
            act = p.currActNum,
            x = m.pos.x,
            y = m.pos.y,
            z = m.pos.z,
            yaw = m.faceAngle.y,
            frames = state.practice.frames,
            cameraAngle = set_cam_angle(0),
            cameraStatus = capture(m.statusForCamera, { "action" }, { "pos", "faceAngle", "headRotation" }),
            mario = capture(m, marioFields, { "pos", "vel", "faceAngle", "angleVel" }),
            camera = capture(m.area and m.area.camera, cameraFields, { "pos", "focus" }),
            lakitu = capture(
                gLakituState,
                lakituFields,
                { "pos", "focus", "curPos", "curFocus", "goalPos", "goalFocus" }
            ),
        }
        i18n.say("Checkpoint guardado. L+der: cargar. Borralo en Practica.")
        audio.menuSound("added")
    end

    function checkpoints.loadPracticePoint()
        if not checkpoints.canLoad() then
            state.practice.retryCountdown = nil
            audio.menuSound("blocked")
            return
        end
        local m = gMarioStates[0]
        if m.action == ACT_UNINITIALIZED then
            return
        end
        if state.practice.phase == "running" and not state.checkpoints.active then
            records.recordAttempt(0)
        end
        state.session = { active = false, done = false, values = {} }
        state.practice.retryCountdown = nil
        state.menu.open = false
        practice.closeSaveDialog(m)
        set_menu_mode(-1)
        reset_dialog_render_state()
        disable_time_stop_including_mario()
        mario_stop_riding_and_holding(m)
        local point = state.checkpoints.saved
        set_mario_action(m, point.mario.action, point.mario.actionArg or 0)
        restore(m, point.mario)
        m.freeze = 0
        restore(m.statusForCamera, point.cameraStatus)
        if m.statusForCamera then
            m.statusForCamera.cameraEvent = 0
            m.statusForCamera.usedObj = nil
        end
        set_cam_angle(point.cameraAngle)
        if m.area and m.area.camera then
            -- soft_reset_camera queues init_camera for the next frame, which
            -- recomputes focus/yaw and destroys the orientation just restored.
            m.area.camera.cutscene = 0
            restore(m.area.camera, point.camera)
        end
        restore(gLakituState, point.lakitu)
        if m.area and m.area.camera then
            -- Re-seed native Lakitu rotation/transition state from the saved pose.
            -- Copying Camera alone leaves the last C-button/stick rotation active.
            -- Unlike soft_reset_camera, this does not queue a level camera init.
            set_camera_mode(m.area.camera, point.camera.mode, 1)
            restore(m.area.camera, point.camera)
            restore(gLakituState, point.lakitu)
            skip_camera_interpolation()
        end
        state.checkpoints.active = point
        state.checkpoints.pending = nil
        state.practice.phase, state.practice.frames, state.practice.pendingFrames, state.practice.arrival =
            "running", point.frames, 0, true
        state.practice.message = "Practica desde checkpoint / tiempo parcial"
        records.publish()
    end

    function checkpoints.practicePointInput(m)
        local c = m.controller
        if (c.buttonDown & L_TRIG) == 0 then
            state.input.practiceHeld = 0
            return false
        end
        local held = c.buttonDown | c.buttonPressed
        local pressed = held & ~state.input.practiceHeld
        state.input.practiceHeld = held
        if
            state.run.active
            or state.run.finished
            or state.recording.active
            or state.menu.open
            or state.practice.phase == "idle"
            or state.practice.phase == "pending"
            or djui_is_chatbox_open()
            or djui_console_is_open()
        then
            return false
        end
        -- Clearing belongs in the menu: L/Z + B is also a Mario movement.
        if (pressed & L_JPAD) ~= 0 then
            checkpoints.savePracticePoint(m)
        elseif (pressed & R_JPAD) ~= 0 then
            checkpoints.loadPracticePoint()
        else
            return false
        end
        c.buttonDown = c.buttonDown & ~(L_JPAD | R_JPAD)
        c.buttonPressed = c.buttonPressed & ~(L_JPAD | R_JPAD)
        return true
    end
end
