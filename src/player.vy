module player;

module vglib;
module vaudio;
module vmath;

group PlayerFlight :: player {
    current_roll = 0.0;
    target_roll = 0.0;
    roll_speed = 0.1;
    zoom_amount = 1.0;
    zoom_target = 1.0;
};

group PlayerShots :: player {
    items = [];
    speed = 18.0;
    life = 3.2;
};

player_camera = vglib.camera(100.0);

fn :: player init() {
    player.reset_camera();
    vglib.disable_cursor();
}

fn :: player get_camera() {
    return player_camera;
}

fn :: player reset_camera() {
    vglib.set_pos(player_camera, Engine.spawn_x, Engine.spawn_y, Engine.spawn_z);
    vglib.set_roll(player_camera, 0.0);

    PlayerFlight.current_roll = 0.0;
    PlayerFlight.target_roll = 0.0;
    PlayerFlight.zoom_amount = 1.0;
    PlayerFlight.zoom_target = 1.0;
    PlayerShots.items = [];
}

fn :: player update_controls() {
    temp_pos = vglib.get_pos(player_camera);
    cam_y = temp_pos[1];

    f_speed = Engine.fly_speed;
    v_speed = 0.5;
    mult = 1.0;
    shift_pressed = vglib.key_down(vglib.LEFT_SHIFT);

    if (shift_pressed) {
        mult = 2.4;
    }

    if (vglib.key_down(vglib.SPACE)) {
        mult = 6.0;
    }

    f_speed = f_speed * mult;
    v_speed = v_speed * mult;

    vglib.move_forward(player_camera, f_speed);

    if (vglib.key_down(vglib.S)) {
        if (shift_pressed) {
            PlayerFlight.zoom_target = PlayerFlight.zoom_target - 0.04;
        } else {
            cam_y = cam_y + v_speed;
        }
    }

    if (vglib.key_down(vglib.W)) {
        if (shift_pressed) {
            PlayerFlight.zoom_target = PlayerFlight.zoom_target + 0.04;
        } else {
            cam_y = cam_y - v_speed;
        }
    }

    if (vglib.key_down(vglib.Q)) {
        PlayerFlight.target_roll = -30.0;
        vglib.move_right(player_camera, -f_speed);
    } else if (vglib.key_down(vglib.E)) {
        PlayerFlight.target_roll = 30.0;
        vglib.move_right(player_camera, f_speed);
    } else {
        PlayerFlight.target_roll = 0.0;
    }

    vglib.set_camera_height(player_camera, cam_y);
    PlayerFlight.current_roll = PlayerFlight.current_roll + (PlayerFlight.target_roll - PlayerFlight.current_roll) * PlayerFlight.roll_speed;
    vglib.set_roll(player_camera, PlayerFlight.current_roll);

    if (PlayerFlight.zoom_target < 1.0) { PlayerFlight.zoom_target = 1.0; }
    if (PlayerFlight.zoom_target > 3.0) { PlayerFlight.zoom_target = 3.0; }
    PlayerFlight.zoom_amount = PlayerFlight.zoom_amount + (PlayerFlight.zoom_target - PlayerFlight.zoom_amount) * 0.18;

    return vglib.get_pos(player_camera);
}

fn :: player fire_if_requested() {
    if (vglib.key_pressed(85) && CrashState.active == false && RuntimeState.signal_lost == false) {
        cam_pos = vglib.get_pos(player_camera);
        yaw = vglib.get_yaw(player_camera);
        ang = vmath.radians(yaw + 90.0);
        dir_x = vmath.cos(ang);
        dir_z = vmath.sin(ang);

        vaudio.play_sound(Audio.tank_shot);
        PlayerShots.items = PlayerShots.items + [[
            cam_pos[0] + (dir_x * 8.0), cam_pos[1] - 3.0, cam_pos[2] + (dir_z * 8.0),
            dir_x * PlayerShots.speed, 0.0, dir_z * PlayerShots.speed,
            PlayerShots.life
        ]];
    }
}

fn :: player draw_projectiles() {
    next_shots = [];

    through s :: PlayerShots.items -> loop {
        nx = s[0] + s[3];
        ny = s[1] + s[4];
        nz = s[2] + s[5];
        life = s[6] - 0.016;

        tail_x = s[0] - (s[3] * 0.7);
        tail_y = s[1] - (s[4] * 0.7);
        tail_z = s[2] - (s[5] * 0.7);

        vglib.line_3d(tail_x, tail_y, tail_z, s[0], s[1], s[2], vglib.rgba(255, 90, 90, 255));
        vglib.line_3d(s[0], s[1], s[2], nx, ny, nz, vglib.rgba(255, 210, 120, 240));

        if (life > 0.0) {
            if (missions.player_hits_tank_segment([s[0], 0.0, s[2]], [nx, 0.0, nz]) == false) {
                next_shots = next_shots + [[nx, ny, nz, s[3], s[4], s[5], life]];
            }
        }
    };

    PlayerShots.items = next_shots;
}
