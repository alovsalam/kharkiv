module audio_system;

module vaudio;

fn :: audio_system start() {
    vaudio.play_sound(Audio.startup);
    vaudio.play_sound(Audio.battle);
    vaudio.play_sound(Audio.chatter);

    vaudio.sound_volume(Audio.startup, 3.15);
    vaudio.sound_volume(Audio.battle, 1.9);
    vaudio.sound_volume(Audio.chatter, 3.0);
    vaudio.sound_volume(Audio.drone_flying, 0.8);
    vaudio.sound_volume(Audio.explosion, 2.9);
    vaudio.sound_volume(Audio.explosion_drone, 1.3);
    vaudio.sound_volume(Audio.tank_shot, 1.5);
    vaudio.sound_volume(Audio.siren, 1.0);
    vaudio.sound_volume(Audio.signal_lost, 1.0);
}

fn :: audio_system update() {
    if (vaudio.is_playing(Audio.battle) == false) {
        vaudio.play_sound(Audio.battle);
    }

    if (vaudio.is_playing(Audio.chatter) == false) {
        vaudio.play_sound(Audio.chatter);
    }

    if (RuntimeState.intro_finished == true) {
        if (vaudio.is_playing(Audio.drone_flying) == false) {
            vaudio.play_sound(Audio.drone_flying);
        }
    }

    if (RuntimeState.siren_active == true) {
        if (vaudio.is_playing(Audio.siren) == false) {
            vaudio.play_sound(Audio.siren);
        }
    }

    if (RuntimeState.signal_lost == true) {
        if (vaudio.is_playing(Audio.signal_lost) == false) {
            vaudio.play_sound(Audio.signal_lost);
        }
    }
}
