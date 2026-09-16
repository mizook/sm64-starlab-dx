-- CoopDX 1.5.1 warp_to_start_level does not reset gNeverEnteredCastle.
-- Replay its two entry interactions only in an owned, fresh training run.
return function(app)
    local state, runs = app.state, app.runs
    local function freshRun()
        return state.run.active
            and state.run.intro
            and state.training.active
            and state.training.slot == get_current_save_file_num()
            and save_file_get_using_backup_slot()
    end

    function runs.initIntroLakitu(o)
        if
            not freshRun()
            or not state.run.lakituPending
            or gNetworkPlayers[0].currLevelNum ~= LEVEL_CASTLE_GROUNDS
            or o.oBehParams2ndByte ~= CAMERA_LAKITU_BP_INTRO
        then
            return
        end
        -- Additive init hooks run AFTER the native behavior. Native init marks
        -- the intro Lakitu for deletion when the persistent castle flag is set.
        -- Keep this freshly created actor alive; its original movement/dialog
        -- behavior (including the bridge bounds used for Lakitu skip) is intact.
        o.activeFlags = o.activeFlags | ACTIVE_FLAG_ACTIVE
        state.run.lakituPending = false
    end

    function runs.updateIntroInteractions(m)
        if
            not freshRun()
            or state.practice.phase ~= "running"
            or not state.run.castleWelcomePending
            or gNetworkPlayers[0].currLevelNum ~= LEVEL_CASTLE
        then
            return
        end
        local dialog = gBehaviorValues.dialogs.CastleEnterDialog
        if m.action == ACT_READING_AUTOMATIC_DIALOG and m.actionArg == dialog then
            state.run.castleWelcomePending = false -- Native first visit already handled it.
        elseif m.action == ACT_IDLE and not is_game_paused() then
            -- Wait for the door/warp animation rather than interrupting entry.
            state.run.castleWelcomePending = false
            set_mario_action(m, ACT_READING_AUTOMATIC_DIALOG, dialog)
        end
    end
end
