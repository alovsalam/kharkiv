module state;

group RuntimeState :: state {
    run_time = 0.0;
    intro_time = 0.0;
    intro_finished = false;
    ui_glitch_factor = 1.0;
    signal_lost = false;
    lost_alpha = 0.0;
    old_score = 0;
    siren_active = false;
};

group StrikeState :: state {
    active = false;
    timer = 0.0;
    duration = 0.4;
    intensity = 0.0;
    screen_shake = 0.0;
};

group CrashState :: state {
    active = false;
    timer = 0.0;
    duration = 1.2;
};

fn :: state tick() {
    RuntimeState.run_time = RuntimeState.run_time + 0.016;
}

fn :: state reset_signal_loss() {
    RuntimeState.signal_lost = false;
    RuntimeState.lost_alpha = 0.0;
    RuntimeState.ui_glitch_factor = 0.0;
    RuntimeState.run_time = 0.0;
    RuntimeState.siren_active = false;

    CrashState.active = false;
    CrashState.timer = 0.0;

    StrikeState.active = false;
    StrikeState.timer = 0.0;
    StrikeState.intensity = 0.0;
    StrikeState.screen_shake = 0.0;
}
