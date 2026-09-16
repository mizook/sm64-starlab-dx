-- One state instance per app. Domain tables remain stable; run/session snapshots
-- may be replaced, so consumers read state.run/state.session at the time of use.
-- nil fields (PB, pending warps, checkpoints) are intentionally absent until set.
return function()
    return {
        practice = {
            courseIndex = 2,
            target = 3,
            entryAct = 3,
            phase = "idle",
            frames = 0,
            message = "Elige una estrella en /sl help",
            pendingFrames = 0,
            arrival = false,
            attempts = 0,
            finishes = 0,
            recent = {},
        },
        settings = {
            profile = mod_storage_load("profile", "vanilla"),
            visible = true,
            retryEnabled = true,
            autoAct = true,
            sessionMode = false,
            autoRetry = mod_storage_load("auto_retry", "off") == "on",
            runFromIntro = mod_storage_load("run_start", "intro") ~= "checkpoint",
            runOverlay = mod_storage_load("run_overlay", "on") ~= "off",
            overlayMinimal = mod_storage_load("run_minimal", "off") == "on",
            menuSounds = mod_storage_load("menu_sounds", "on") ~= "off",
        },
        menu = {
            open = false,
            row = 1,
            screen = "practice",
            resetConfirm = false,
            resetHold = 0,
            resetReleased = false,
        },
        editor = {
            courseIndex = 2,
            target = 3,
            entryAct = 3,
            count = 1,
            slot = 1,
            route = {},
            storageOK = true,
            cursor = 1,
            builderNotice = "",
            undoAdditions = {},
            manageNotice = "",
            nameDraft = "",
            nameKey = 1,
        },
        input = {
            navDirection = 0,
            navWait = 0,
            menuActionHeld = 0,
            overlayHeld = 0,
            practiceHeld = 0,
        },
        -- saved: reusable point; active: source of the current partial;
        -- pending: point awaiting warp arrival. Clearing saved never promotes
        -- an active partial into a full-star attempt.
        checkpoints = {},
        recording = { active = false, lastTick = -1, seen = {} },
        review = {},
        clock = { tick = 0 },
        session = { active = false, done = false, values = {} },
        run = { active = false, index = 1, total = 0, splits = {}, best = {}, finished = false },
        training = { active = false },
    }
end
