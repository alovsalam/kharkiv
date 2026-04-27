module config;

ruleset { dynamic_casting, warnings };

group Engine {
    screen_w = 1920;
    screen_h = 1080;
    target_fps = 75;
    app_title = "Drone FPV - Kharkiv Operation v0.1";
    is_fullscreen = true;

    fly_speed = 0.45;
    rotation_speed = 0.12;
    sprint_boost = 2.0;

    spawn_x = 0.0;
    spawn_y = 90.0;
    spawn_z = -2500.0;

    intro_dur = 7.0;
    fade_speed = 3.0;
    ui_glitch_duration = 2.5;
};

out("CONFIG: System parameters initialized successfully.");

deploy config;