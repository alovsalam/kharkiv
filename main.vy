ruleset { dynamic_casting, warnings };

module vglib;
module vaudio;
module vmath;

use "src/config.vy";

vglib.init(Engine.screen_w, Engine.screen_h, Engine.target_fps, Engine.app_title, vglib.FULLSCREEN + vglib.VSYNC);


camera = vglib.camera(100.0);
vglib.set_pos(camera, Engine.spawn_x, Engine.spawn_y, Engine.spawn_z);
vglib.disable_cursor();


vglib.begin();
vglib.clear(vglib.BLACK);
vglib.end();

use "src/loader.vy";
use "src/missions.vy";
use "src/subtitles.vy";

# --- RENDER TARGETS ---
screen_target  = vglib.load_render_texture(Engine.screen_w, Engine.screen_h);

map_data = vglib.load_map("maps/kharkiv_map.dat");


# --- STATE ---
run_time = 0.0;
intro_time = 0.0;
intro_finished = false;
ui_glitch_factor = 1.0;
signal_lost = false;
current_roll = 0.0;
target_roll = 0.0;
roll_speed = 0.1;
turn_speed = 1.5;
lost_alpha = 0.0;
old_score = 0;
zoom_amount = 1.0;
zoom_target = 1.0;

# --- ARTILLERY EVENT STATE ---
strike_active = false;
strike_timer = 0.0;
strike_duration = 0.4;
strike_intensity = 0.0;
screen_shake = 0.0;

# --- CRASH SEQUENCE STATE ---
crash_active = false;
crash_timer = 0.0;
crash_duration = 1.2;

# -- NUKE SIREN --
siren_active = false;



# -- FOREST MAP --
forest_density = 2200;
forest_trees = [];

through i :: 0..forest_density -> loop {
    tx = vmath.random(-2500, 2500);
    tz = vmath.random(-2000, 2500); 
    
    t_scale = 4.0 + (vmath.random(0, 100) / 100.0);
    forest_trees = forest_trees + [[tx, 0.0, tz, t_scale]];
};

vaudio.play_sound(Audio.startup);
vaudio.play_sound(Audio.battle);
vaudio.play_sound(Audio.chatter);

vaudio.sound_volume(Audio.startup, 3.15);
vaudio.sound_volume(Audio.battle, 1.9);
vaudio.sound_volume(Audio.chatter, 3.0);
vaudio.sound_volume(Audio.drone_flying, 0.8);
vaudio.sound_volume(Audio.explosion, 2.9);
vaudio.sound_volume(Audio.explosion_drone, 1.3);
vaudio.sound_volume(Audio.siren, 1.0);
vaudio.sound_volume(Audio.signal_lost, 1.0);

title_size_intro = vglib.measure_text(Shaders.vcr_font, "KHARKIV, UKRAINE", 80);
sub_size_intro   = vglib.measure_text(Shaders.vcr_font, "APRIL 25, 2026", 30);

# Pre-renders
vglib.upload_persistent_group("forest_trees", forest_trees);

# Mission starts
missions.init_next();

while (vglib.running()) {
    run_time = run_time + 0.016;
    temp_pos = vglib.get_pos(camera);
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

    vglib.move_forward(camera, f_speed);
    if (vglib.key_down(vglib.S)) {
        if (shift_pressed) {
            zoom_target = zoom_target - 0.04;
        } else {
            cam_y = cam_y + v_speed;
        }
    }
    if (vglib.key_down(vglib.W)) {
        if (shift_pressed) {
            zoom_target = zoom_target + 0.04;
        } else {
            cam_y = cam_y - v_speed;
        }
    }

    if (vglib.key_down(vglib.Q)) {
        target_roll = -30.0; 
        vglib.move_right(camera, -f_speed); 
    } else if (vglib.key_down(vglib.E)) {
        target_roll = 30.0;
        vglib.move_right(camera, f_speed);
    } else {
        target_roll = 0.0;
    }

    vglib.set_camera_height(camera, cam_y);
    current_roll = current_roll + (target_roll - current_roll) * roll_speed;
    vglib.set_roll(camera, current_roll);

    cam_pos = vglib.get_pos(camera);
    cam_y = cam_pos[1];

    # Safe zoom controls (keyboard only): Shift+W zooms in, Shift+S zooms out.
    if (zoom_target < 1.0) { zoom_target = 1.0; }
    if (zoom_target > 3.0) { zoom_target = 3.0; }
    zoom_amount = zoom_amount + (zoom_target - zoom_amount) * 0.18;

    if (crash_active == false && signal_lost == false) {
        
        if (cam_y <= 0.0) {
            crash_active = true;
            crash_timer = crash_duration;
            vaudio.play_sound(Audio.explosion_drone);
            vaudio.play_sound(Audio.explosion);
            vaudio.play_sound(Audio.signal_lost);
        }
        
        # Tree collisions are intentionally ignored to allow pass-through flight.
    }

    missions.update(cam_pos);
    if (crash_active == false && signal_lost == false) {
        if (missions.enemy_hits_player(cam_pos)) {
            crash_active = true;
            crash_timer = crash_duration;
            vaudio.play_sound(Audio.explosion_drone);
            vaudio.play_sound(Audio.explosion);
            vaudio.play_sound(Audio.signal_lost);
        }
    }

    if (crash_active == true) {
        crash_timer = crash_timer - 0.016;
        ui_glitch_factor = 15.0;
        screen_shake = vmath.random(-20, 20); 
        if (crash_timer <= 0.0) {
            crash_active = false;
            signal_lost = true;
        }
    }

    if (Params.score > old_score) {
        ui_glitch_factor = 3.0;
        old_score = Params.score;
    }

    if (siren_active == false) {
        if (run_time > 17.0) {
            siren_active = true;
            vaudio.play_sound(Audio.siren);
        }
    }

    if (strike_active == false) {
        if (vmath.random(0, 1000) > 998) {
            if (siren_active == false) {
                if (run_time > 17.0) {
                    siren_active = true;
                }
            }
            strike_active = true;
            strike_timer = strike_duration;

            vaudio.play_sound(Audio.explosion);
        }
    }

    if (strike_active == true) {
        strike_timer = strike_timer - 0.016;
        strike_intensity = strike_timer / strike_duration;
        screen_shake = vmath.sin(run_time * 100.0) * (strike_intensity * 10.0);

        if (strike_timer <= 0.0) {
            strike_active = false;
            strike_intensity = 0.0;
            screen_shake = 0.0;
        }
    }

    if (vaudio.is_playing(Audio.battle) == false) {
        vaudio.play_sound(Audio.battle);
    }

    if (vaudio.is_playing(Audio.chatter) == false) {
        vaudio.play_sound(Audio.chatter);
    }

    if(intro_finished == true){
        if (vaudio.is_playing(Audio.drone_flying) == false) {
            vaudio.play_sound(Audio.drone_flying);
        }
    }

    if (siren_active == true) {
        if (vaudio.is_playing(Audio.siren) == false) {
            vaudio.play_sound(Audio.siren);
        }
    }

    if (signal_lost == true) {
        if (vaudio.is_playing(Audio.signal_lost) == false) {
            vaudio.play_sound(Audio.signal_lost);
        }
    }



    vglib.begin_texture_mode(screen_target);
        bg_r = 55 + (strike_intensity * 150);
        bg_g = 65 + (strike_intensity * 30);
        bg_b = 65 + (strike_intensity * 20);
        vglib.clear(vglib.rgba(bg_r, bg_g, bg_b, 255));
        vglib.begin3d(camera);         
            vglib.rotate_view(camera, Engine.rotation_speed);

            vglib.set_shader_camera(Shaders.fog, camera);
            vglib.begin_shader(Shaders.fog);
                vglib.set_shader_value(Shaders.fog, "fogDensity", 0.004);
                vglib.set_shader_value(Shaders.fog, "fogColor", [0.25, 0.27, 0.3, 1.0]);

                vglib.plane_texture(Textures.slots[7], 0.0, 0.0, 0.0, 10000.0, 10000.0);
                
                through w :: map_data -> loop {
                    dx = cam_pos[0] - w[0];
                    if (dx > -130.0 && dx < 130.0) {
                        dz = cam_pos[2] - w[2];
                        if (dz > -130.0 && dz < 130.0) {
                            if ((dx*dx + dz*dz) < 15000.0) {
                                t_idx = int64(w[4]) % Textures.slots.size();
                                vglib.cube_texture(Textures.slots[t_idx], w[0], w[1], w[2], w[3], vglib.WHITE);
                            }
                        }
                    }
                };

                vglib.draw_persistent_group("forest_trees", Models.tree_model, cam_pos, 2000.0);
                missions.draw_3d_marker();
            vglib.end_shader();
        vglib.end3d();
    vglib.end_texture_mode();

    # 2. FINAL UI & COLOR SHADER
    vglib.begin();
        vglib.clear(vglib.BLACK);

        if (intro_finished == false) {
            intro_time = intro_time + 0.016;
            if (intro_time < Engine.fade_speed) {
                intro_alpha = int64((intro_time / Engine.fade_speed) * 255.0);
            } else {
                intro_alpha = 255;
            }
            if (intro_time > Engine.intro_dur) { intro_finished = true; }

            t_color = vglib.rgba(255, 255, 255, intro_alpha);
            vglib.text_ex(Shaders.vcr_font, "KHARKIV, UKRAINE", ( 960 - ( title_size_intro[0] / 4 ) ), 500, 40, t_color);
            vglib.text_ex(Shaders.vcr_font, "APRIL 25, 2026", 850, 560, 20, t_color);
        } 
        else {
            if (signal_lost == true) {
                static_val = vmath.random(30, 55);
                vglib.clear(vglib.rgba(static_val, static_val, static_val, 255));
                
                vglib.rect(vmath.sin(run_time * 17.3) * 960.0 + 960.0, vmath.sin(run_time * 9.1)  * 540.0 + 270.0, 800.0, 2.0,  vglib.rgba(255, 255, 255, 40));
                vglib.rect(vmath.sin(run_time * 41.1) * 960.0 + 960.0, vmath.sin(run_time * 7.3)  * 540.0 + 810.0, 400.0, 1.0,  vglib.rgba(200, 200, 200, 60));

                if (lost_alpha < 1.0) { lost_alpha = lost_alpha + 0.02; }
                
                box_a = int64(lost_alpha * 220.0);
                text_a = int64(lost_alpha * 255.0);
                sub_a = int64(lost_alpha * 180.0);

                jitter_x = vmath.random(-1, 1);
                jitter_y = vmath.random(-1, 1); 

                main_text = "SIGNAL LOST";
                main_size = vglib.measure_text(Shaders.vcr_font, main_text, 60);
                
                sub_text = "CONNECTION TERMINATED // NO FEED";
                sub_size = vglib.measure_text(Shaders.vcr_font, sub_text, 18);

                rect_w = main_size[0] + 100;
                rect_h = 160;
                vglib.rect(960 - (rect_w / 2), 460, rect_w, rect_h, vglib.rgba(15, 15, 15, box_a));

                vglib.text_ex(Shaders.vcr_font, main_text, 
                            960 - (main_size[0] / 2) + jitter_x, 
                            500 + jitter_y, 60, vglib.rgba(255, 255, 255, text_a));

                vglib.text_ex(Shaders.vcr_font, sub_text, 
                            960 - (sub_size[0] / 2) + jitter_x, 
                            590 + jitter_y, 18, vglib.rgba(140, 140, 140, sub_a));

                if (vglib.key_down(vglib.ENTER)) {
                    signal_lost = false;
                    crash_active = false;
                    lost_alpha = 0.0;
                    ui_glitch_factor = 0.0; 
                    screen_shake = 0.0;
                    vglib.set_pos(camera, Engine.spawn_x, Engine.spawn_y, Engine.spawn_z);
                    vglib.set_roll(camera, 0.0);
                    current_roll = 0.0;
                    target_roll = 0.0;
                    run_time = 0.0;
                    siren_active = false;
                    strike_active = false;
                    missions.init_next();
                }
            }
            else {
                if (crash_active == true) {
                    p = (crash_timer / crash_duration);
                    
                    flash_alpha = int64((1.0 - p) * 180.0);
                    vglib.rect(0, 0, 1920, 1080, vglib.rgba(255, 255, 255, flash_alpha));

                    if (vmath.random(0, 10) > 7) {
                        vglib.rect(0, 0, 1920, 1080, vglib.rgba(255, 0, 0, 40));
                    }
                }

                if (ui_glitch_factor > 0.0) { ui_glitch_factor = ui_glitch_factor - 0.005; }
                vglib.set_shader_value(Shaders.vhs_color, "time", run_time);
                if (crash_active) {
                    noise_val = 2.5 + (vmath.random(0, 100) / 20.0);
                } else {
                    noise_val = 0.1 + (strike_intensity * 1.1);
                }
                vglib.set_shader_value(Shaders.vhs_color, "noiseAmount", noise_val);
                vglib.set_shader_value(Shaders.vhs_color, "zoomAmount", zoom_amount);
                vglib.set_shader_value(Shaders.vhs_color, "renderSize", [1920.0, 1080.0]);

                ui_offset_x = 0.0;
                ui_offset_y = 0.0;

                if (strike_active) {
                    ui_offset_x = screen_shake * 3.5;
                    ui_offset_y = (vmath.cos(run_time * 80.0) * strike_intensity) * 10.0;
                }

                vglib.begin_shader(Shaders.vhs_color);
                    vglib.draw_render_texture(screen_target); 
                vglib.end_shader();

                u_col = vglib.rgba(180, 255, 180, 180);

                missions.draw_ui(u_col, cam_pos, camera);

                glitch = vmath.sin(run_time * 60.0) * (ui_glitch_factor * 5.0);
                cx = 960 + glitch + ui_offset_x; 
                cy = 540 + ui_offset_y;
                size = 150;

                # --- ORIGINAL CROSSHAIR ---
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



                alt_base_x = 80 + ui_offset_x;
                alt_base_y = 540 + ui_offset_y;
                scaling_factor = 3.0;

                vglib.line(alt_base_x + 25, alt_base_y - 150, alt_base_x + 25, alt_base_y + 150, u_col);

                through i :: -6..6 -> loop {
                    offset_y = int64(cam_y * scaling_factor) % 30; 
                    curr_y = alt_base_y - (i * 30) + offset_y;
                    
                    if (curr_y > (alt_base_y - 150)) {
                        if (curr_y < (alt_base_y + 150)) {
                            
                            h_val = int64(cam_y / 10) * 10 + (i * 10);
                            
                            if (h_val % 20 == 0) {
                                vglib.line(alt_base_x + 5, curr_y, alt_base_x + 25, curr_y, u_col);
                                vglib.text_ex(Shaders.vcr_font, string(h_val), alt_base_x - 40, curr_y - 8, 14, u_col);
                            } else {
                                vglib.line(alt_base_x + 15, curr_y, alt_base_x + 25, curr_y, u_col);
                            }
                        }
                    }
                };

                compass_x = 800 + ui_offset_x;
                compass_y = 80 + ui_offset_y;
                through i :: 0..8 -> loop {
                    curr_x = compass_x + (i * 40);
                    vglib.line(curr_x, compass_y, curr_x, compass_y + 20, u_col);
                };
                vglib.text_ex(Shaders.vcr_font, "219", 945, 110, 15, u_col);
                vglib.line(960, 70, 960, 100, vglib.WHITE);

                vglib.text_ex(Shaders.vcr_font, "3 C", 60, 40, 18, u_col);
                vglib.text_ex(Shaders.vcr_font, "AREA: 34M2", 60, 70, 18, u_col);
                vglib.text_ex(Shaders.vcr_font, "ARM", cx - 30, cy - size - 30, 15, vglib.rgba(255, 50, 50, 200));

                cur_x = cam_pos[0];
                cur_z = cam_pos[2];

                grid_str_x = "LAT: " + string(int64(cur_x / 10.0)) + " 24' 11''";
                grid_str_z = "LNG: " + string(int64(cur_z / 10.0)) + " 13' 54''";

                vglib.text_ex(Shaders.vcr_font, grid_str_x, 1650 + ui_offset_x, 40 + ui_offset_y, 18, u_col);
                vglib.text_ex(Shaders.vcr_font, grid_str_z, 1650 + ui_offset_x, 70 + ui_offset_y, 18, u_col);

                vglib.text_ex(Shaders.vcr_font, "ELV: " + string(int64(cam_y)) + "m MSL", 1650 + ui_offset_x, 100 + ui_offset_y, 18, u_col);
                zoom_label = "ZOOM: " + string(int64(zoom_amount * 10.0) / 10.0) + "x";
                vglib.text_ex(Shaders.vcr_font, zoom_label, 1650 + ui_offset_x, 130 + ui_offset_y, 18, u_col);
                
                vglib.text_ex(Shaders.vcr_font, "LOCKED", cx + size - 80 + ui_offset_x, cy + size + 10 + ui_offset_y, 15, u_col);
            }
        }

        if (vglib.key_down(vglib.ESCAPE)) { vglib.enable_cursor(); }
    vglib.end();
}
vglib.close();