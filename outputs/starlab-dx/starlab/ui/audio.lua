-- Menu sounds and their preference.
return function(app)
    local state = app.state
    local i18n = app.i18n
    local audio = app.audio

    function audio.menuSound(kind)
        if not state.settings.menuSounds then
            return
        end
        local sounds = {
            move = SOUND_MENU_CHANGE_SELECT,
            confirm = SOUND_MENU_CLICK_FILE_SELECT,
            back = SOUND_MENU_MESSAGE_DISAPPEAR,
            open = SOUND_MENU_MESSAGE_APPEAR,
            added = SOUND_MENU_STAR_SOUND,
            blocked = SOUND_MENU_CAMERA_BUZZ,
        }
        if sounds[kind] then
            play_sound(sounds[kind], gGlobalSoundSource)
        end
    end

    function audio.toggleMenuSounds()
        state.settings.menuSounds = not state.settings.menuSounds
        mod_storage_save("menu_sounds", state.settings.menuSounds and "on" or "off")
        i18n.say(
            state.settings.menuSounds and "Sonidos del menu: activados" or "Sonidos del menu: desactivados"
        )
        audio.menuSound("confirm")
    end
end
