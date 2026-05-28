module renderer;

module vglib;
module vmath;

renderer_screen_target = 0;
renderer_title_size_intro = [0, 0];
renderer_sub_size_intro = [0, 0];
renderer_rotation_speed = 0.0;
renderer_fade_speed = 0.0;
renderer_intro_dur = 0.0;
renderer_fog_shader = 0;
renderer_vhs_shader = 0;
renderer_font = 0;

fn :: renderer init(screen_w, screen_h, rotation_speed, fade_speed, intro_dur, fog_shader, vhs_shader, vcr_font) {
    renderer_screen_target = vglib.load_render_texture(screen_w, screen_h);
    renderer_rotation_speed = rotation_speed;
    renderer_fade_speed = fade_speed;
    renderer_intro_dur = intro_dur;
    renderer_fog_shader = fog_shader;
    renderer_vhs_shader = vhs_shader;
    renderer_font = vcr_font;

    renderer_title_size_intro = vglib.measure_text(renderer_font, "KHARKIV, UKRAINE", 80);
    renderer_sub_size_intro = vglib.measure_text(renderer_font, "APRIL 25, 2026", 30);
}

fn :: renderer render_world(camera, cam_pos) {
    vglib.begin_texture_mode(renderer_screen_target);
        bg_r = 55 + (StrikeState.intensity * 150);
        bg_g = 65 + (StrikeState.intensity * 30);
        bg_b = 65 + (StrikeState.intensity * 20);

        vglib.clear(vglib.rgba(bg_r, bg_g, bg_b, 255));
        vglib.begin3d(camera);
            vglib.rotate_view(camera, renderer_rotation_speed);

            vglib.set_shader_camera(renderer_fog_shader, camera);
            vglib.begin_shader(renderer_fog_shader);
                vglib.set_shader_value(renderer_fog_shader, "fogDensity", 0.004);
                vglib.set_shader_value(renderer_fog_shader, "fogColor", [0.25, 0.27, 0.3, 1.0]);

                world.draw(cam_pos);
                player.draw_projectiles();
            vglib.end_shader();
        vglib.end3d();
    vglib.end_texture_mode();
}

fn :: renderer draw_frame(camera, cam_pos) {
    vglib.begin();
        vglib.clear(vglib.BLACK);

        if (RuntimeState.intro_finished == false) {
            renderer.draw_intro();
        } else {
            if (RuntimeState.signal_lost == true) {
                renderer.draw_signal_lost();
            } else {
                renderer.draw_live_feed(camera, cam_pos);
            }
        }

        if (vglib.key_down(vglib.ESCAPE)) {
            vglib.enable_cursor();
        }
    vglib.end();
}

fn :: renderer draw_intro() {
    RuntimeState.intro_time = RuntimeState.intro_time + 0.016;

    if (RuntimeState.intro_time < renderer_fade_speed) {
        intro_alpha = int64((RuntimeState.intro_time / renderer_fade_speed) * 255.0);
    } else {
        intro_alpha = 255;
    }

    if (RuntimeState.intro_time > renderer_intro_dur) {
        RuntimeState.intro_finished = true;
    }

    t_color = vglib.rgba(255, 255, 255, intro_alpha);
    vglib.text_ex(renderer_font, "KHARKIV, UKRAINE", (960 - (renderer_title_size_intro[0] / 4)), 500, 40, t_color);
    vglib.text_ex(renderer_font, "APRIL 25, 2026", 850, 560, 20, t_color);
}

fn :: renderer draw_signal_lost() {
    static_val = vmath.random(30, 55);
    vglib.clear(vglib.rgba(static_val, static_val, static_val, 255));

    vglib.rect(vmath.sin(RuntimeState.run_time * 17.3) * 960.0 + 960.0, vmath.sin(RuntimeState.run_time * 9.1) * 540.0 + 270.0, 800.0, 2.0, vglib.rgba(255, 255, 255, 40));
    vglib.rect(vmath.sin(RuntimeState.run_time * 41.1) * 960.0 + 960.0, vmath.sin(RuntimeState.run_time * 7.3) * 540.0 + 810.0, 400.0, 1.0, vglib.rgba(200, 200, 200, 60));

    if (RuntimeState.lost_alpha < 1.0) {
        RuntimeState.lost_alpha = RuntimeState.lost_alpha + 0.02;
    }

    box_a = int64(RuntimeState.lost_alpha * 220.0);
    text_a = int64(RuntimeState.lost_alpha * 255.0);
    sub_a = int64(RuntimeState.lost_alpha * 180.0);

    jitter_x = vmath.random(-1, 1);
    jitter_y = vmath.random(-1, 1);

    main_text = "SIGNAL LOST";
    main_size = vglib.measure_text(renderer_font, main_text, 60);

    sub_text = "CONNECTION TERMINATED // NO FEED";
    sub_size = vglib.measure_text(renderer_font, sub_text, 18);

    rect_w = main_size[0] + 100;
    rect_h = 160;
    vglib.rect(960 - (rect_w / 2), 460, rect_w, rect_h, vglib.rgba(15, 15, 15, box_a));

    vglib.text_ex(renderer_font, main_text,
                960 - (main_size[0] / 2) + jitter_x,
                500 + jitter_y, 60, vglib.rgba(255, 255, 255, text_a));

    vglib.text_ex(renderer_font, sub_text,
                960 - (sub_size[0] / 2) + jitter_x,
                590 + jitter_y, 18, vglib.rgba(140, 140, 140, sub_a));

    if (vglib.key_down(vglib.ENTER)) {
        events.reset_after_signal_loss();
    }
}

fn :: renderer draw_live_feed(camera, cam_pos) {
    if (CrashState.active == true) {
        p = (CrashState.timer / CrashState.duration);
        flash_alpha = int64((1.0 - p) * 180.0);
        vglib.rect(0, 0, 1920, 1080, vglib.rgba(255, 255, 255, flash_alpha));

        if (vmath.random(0, 10) > 7) {
            vglib.rect(0, 0, 1920, 1080, vglib.rgba(255, 0, 0, 40));
        }
    }

    if (RuntimeState.ui_glitch_factor > 0.0) {
        RuntimeState.ui_glitch_factor = RuntimeState.ui_glitch_factor - 0.005;
    }

    vglib.set_shader_value(renderer_vhs_shader, "time", RuntimeState.run_time);
    if (CrashState.active) {
        noise_val = 2.5 + (vmath.random(0, 100) / 20.0);
    } else {
        noise_val = 0.1 + (StrikeState.intensity * 1.1);
    }
    vglib.set_shader_value(renderer_vhs_shader, "noiseAmount", noise_val);
    vglib.set_shader_value(renderer_vhs_shader, "zoomAmount", PlayerFlight.zoom_amount);
    vglib.set_shader_value(renderer_vhs_shader, "renderSize", [1920.0, 1080.0]);

    ui_offset_x = 0.0;
    ui_offset_y = 0.0;

    if (StrikeState.active) {
        ui_offset_x = StrikeState.screen_shake * 3.5;
        ui_offset_y = (vmath.cos(RuntimeState.run_time * 80.0) * StrikeState.intensity) * 10.0;
    }

    vglib.begin_shader(renderer_vhs_shader);
        vglib.draw_render_texture(renderer_screen_target);
    vglib.end_shader();

    u_col = vglib.rgba(180, 255, 180, 180);
    
    missions.draw_ui(u_col, cam_pos, camera);

    renderer.draw_crosshair(u_col, ui_offset_x, ui_offset_y);
    renderer.draw_altimeter(u_col, cam_pos[1], ui_offset_x, ui_offset_y);
    renderer.draw_compass(u_col, ui_offset_x, ui_offset_y);
    renderer.draw_telemetry(u_col, cam_pos, ui_offset_x, ui_offset_y);
}

fn :: renderer draw_crosshair(u_col, ui_offset_x, ui_offset_y) {
    glitch = vmath.sin(RuntimeState.run_time * 60.0) * (RuntimeState.ui_glitch_factor * 5.0);
    cx = 960 + glitch + ui_offset_x;
    cy = 540 + ui_offset_y;
    size = 150;

    vglib.line(cx - size, cy - size, cx - size + 40, cy - size, u_col);
    vglib.line(cx - size, cy - size, cx - size, cy - size + 40, u_col);
    vglib.line(cx + size, cy - size, cx + size - 40, cy - size, u_col);
    vglib.line(cx + size, cy - size, cx + size, cy - size + 40, u_col);
    vglib.line(cx - size, cy + size, cx - size + 40, cy + size, u_col);
    vglib.line(cx - size, cy + size, cx - size, cy + size - 40, u_col);
    vglib.line(cx + size, cy + size, cx + size - 40, cy + size, u_col);
    vglib.line(cx + size, cy + size, cx + size, cy + size - 40, u_col);
    vglib.line(cx - 20, cy, cx + 20, cy, u_col);
    vglib.line(cx, cy - 20, cx, cy + 20, u_col);

    vglib.text_ex(renderer_font, "ARM", cx - 30, cy - size - 30, 15, vglib.rgba(255, 50, 50, 200));
    vglib.text_ex(renderer_font, "LOCKED", cx + size - 80 + ui_offset_x, cy + size + 10 + ui_offset_y, 15, u_col);
}

fn :: renderer draw_altimeter(u_col, cam_y, ui_offset_x, ui_offset_y) {
    alt_base_x = 80 + ui_offset_x;
    alt_base_y = 540 + ui_offset_y;
    scaling_factor = 3.0;

    vglib.line(alt_base_x + 25, alt_base_y - 150, alt_base_x + 25, alt_base_y + 150, u_col);

    offset_y = int64(cam_y * scaling_factor) % 30;
    
    through i :: -6..6 -> loop {
        curr_y = alt_base_y - (i * 30) + offset_y;

        if (curr_y > (alt_base_y - 150)) {
            if (curr_y < (alt_base_y + 150)) {
                h_val = int64(cam_y / 10) * 10 + (i * 10);

                if (h_val % 20 == 0) {
                    vglib.line(alt_base_x + 5, curr_y, alt_base_x + 25, curr_y, u_col);
                    vglib.text_ex(renderer_font, string(h_val), alt_base_x - 40, curr_y - 8, 14, u_col);
                } else {
                    vglib.line(alt_base_x + 15, curr_y, alt_base_x + 25, curr_y, u_col);
                }
            }
        }
    };
}

fn :: renderer draw_compass(u_col, ui_offset_x, ui_offset_y) {
    compass_x = 800 + ui_offset_x;
    compass_y = 80 + ui_offset_y;

    through i :: 0..8 -> loop {
        curr_x = compass_x + (i * 40);
        vglib.line(curr_x, compass_y, curr_x, compass_y + 20, u_col);
    };

    vglib.text_ex(renderer_font, "219", 945, 110, 15, u_col);
    vglib.line(960, 70, 960, 100, vglib.WHITE);
}

fn :: renderer draw_telemetry(u_col, cam_pos, ui_offset_x, ui_offset_y) {
    cached_zoom = PlayerFlight.zoom_amount;
    
    vglib.text_ex(renderer_font, "3 C", 60, 40, 18, u_col);
    vglib.text_ex(renderer_font, "AREA: 34M2", 60, 70, 18, u_col);

    cur_x = cam_pos[0];
    cur_z = cam_pos[2];

    grid_str_x = "LAT: " + string(int64(cur_x / 10.0)) + " 24' 11''";
    grid_str_z = "LNG: " + string(int64(cur_z / 10.0)) + " 13' 54''";

    vglib.text_ex(renderer_font, grid_str_x, 1650 + ui_offset_x, 40 + ui_offset_y, 18, u_col);
    vglib.text_ex(renderer_font, grid_str_z, 1650 + ui_offset_x, 70 + ui_offset_y, 18, u_col);
    vglib.text_ex(renderer_font, "ELV: " + string(int64(cam_pos[1])) + "m MSL", 1650 + ui_offset_x, 100 + ui_offset_y, 18, u_col);

    zoom_label = "ZOOM: " + string(int64(cached_zoom * 10.0) / 10.0) + "x";
    vglib.text_ex(renderer_font, zoom_label, 1650 + ui_offset_x, 130 + ui_offset_y, 18, u_col);
}
