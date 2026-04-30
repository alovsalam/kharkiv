module events;

module vaudio;
module vmath;

fn :: events trigger_crash() {
    CrashState.active = true;
    CrashState.timer = CrashState.duration;

    vaudio.play_sound(Audio.explosion_drone);
    vaudio.play_sound(Audio.explosion);
    vaudio.play_sound(Audio.signal_lost);
}

fn :: events update(cam_pos) {
    if (CrashState.active == false && RuntimeState.signal_lost == false) {
        if (cam_pos[1] <= 0.0) {
            events.trigger_crash();
        }
    }

    missions.update(cam_pos);

    if (CrashState.active == false && RuntimeState.signal_lost == false) {
        if (missions.enemy_hits_player(cam_pos)) {
            events.trigger_crash();
        }
    }

    if (CrashState.active == true) {
        CrashState.timer = CrashState.timer - 0.016;
        RuntimeState.ui_glitch_factor = 15.0;
        StrikeState.screen_shake = vmath.random(-20, 20);

        if (CrashState.timer <= 0.0) {
            CrashState.active = false;
            RuntimeState.signal_lost = true;
        }
    }

    if (Params.score > RuntimeState.old_score) {
        RuntimeState.ui_glitch_factor = 3.0;
        RuntimeState.old_score = Params.score;
    }

    if (RuntimeState.siren_active == false) {
        if (RuntimeState.run_time > 17.0) {
            RuntimeState.siren_active = true;
            vaudio.play_sound(Audio.siren);
        }
    }

    if (StrikeState.active == false) {
        if (vmath.random(0, 1000) > 998) {
            if (RuntimeState.siren_active == false) {
                if (RuntimeState.run_time > 17.0) {
                    RuntimeState.siren_active = true;
                }
            }

            StrikeState.active = true;
            StrikeState.timer = StrikeState.duration;
            vaudio.play_sound(Audio.explosion);
        }
    }

    if (StrikeState.active == true) {
        StrikeState.timer = StrikeState.timer - 0.016;
        StrikeState.intensity = StrikeState.timer / StrikeState.duration;
        StrikeState.screen_shake = vmath.sin(RuntimeState.run_time * 100.0) * (StrikeState.intensity * 10.0);

        if (StrikeState.timer <= 0.0) {
            StrikeState.active = false;
            StrikeState.intensity = 0.0;
            StrikeState.screen_shake = 0.0;
        }
    }
}

fn :: events reset_after_signal_loss() {
    state.reset_signal_loss();
    player.reset_camera();
    missions.init_next();
}
