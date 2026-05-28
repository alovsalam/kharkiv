module missions;

module vglib;
module vaudio;
module vmath;

target_pos = [0.0, 0.0, 0.0];
target_radius = 80.0;
army_green = vglib.rgba(45, 65, 45, 255);
tank_move_speed = 0.9;
tank_stop_dist = 220.0;
aim_dir = [0.0, 0.0, 1.0];
fire_cooldown = 2.1;
fire_timer = 0.7;
enemy_projectiles = [];
projectile_speed = 12.0;
projectile_life = 3.2;
tank_count = 12;
enemy_tanks = [];

group Params :: missions {
    score = 0;
    impacts = [[0.0, 0.0]];
};

fn :: missions generate_target() {
    tx = vmath.random(-2000, 2000);
    tz = vmath.random(500, 3000); 
    ty = 0.0;
    
    target_pos = [tx + 0.0, ty, tz + 0.0];

    # Spawn a formation of many tanks around the main objective tank.
    enemy_tanks = [];
    through i :: 0..tank_count -> loop {
        spread_x = vmath.random(-900, 900);
        spread_z = vmath.random(-900, 900);
        spawn_x = (tx + spread_x) + 0.0;
        spawn_z = (tz + spread_z) + 0.0;

        if (i == 0) {
            spawn_x = tx;
            spawn_z = tz;
        }

        dir_x = 0.0;
        dir_z = 1.0;
        cooldown = 0.2 + ((vmath.random(0, 100) + 0.0) / 100.0) * fire_cooldown;
        enemy_tanks = enemy_tanks + [[spawn_x, spawn_z, dir_x, dir_z, cooldown]];
    };
}

fn :: missions init_next() {
    missions.generate_target();
}

fn :: missions update(cam_pos) {    
    # Update all tanks: move, aim and shoot.
    updated_tanks = [];
    visible_count = 0;
    max_update_per_frame = 4;
    
    through tank :: enemy_tanks -> loop {
        if (visible_count >= max_update_per_frame) {
            updated_tanks = updated_tanks + [tank];
            visible_count = visible_count + 1;
            continue;
        }
        
        tank_x = tank[0];
        tank_z = tank[1];
        tank_dir_x = tank[2];
        tank_dir_z = tank[3];
        tank_fire_t = tank[4];

        to_x = cam_pos[0] - tank_x;
        to_z = cam_pos[2] - tank_z;
        dist_2d = vmath.hypot(to_x, to_z);

        if (dist_2d > 0.001) {
            tank_dir_x = to_x / dist_2d;
            tank_dir_z = to_z / dist_2d;
        }

        if (dist_2d > tank_stop_dist) {
            step = tank_move_speed;
            if (step > (dist_2d - tank_stop_dist)) {
                step = dist_2d - tank_stop_dist;
            }
            tank_x = tank_x + (tank_dir_x * step);
            tank_z = tank_z + (tank_dir_z * step);
        }

        tank_fire_t = tank_fire_t - 0.016;
        if (tank_fire_t <= 0.0) {
            tank_fire_t = fire_cooldown + (((vmath.random(0, 100) + 0.0) / 100.0) * 0.7);
            vaudio.play_sound(Audio.tank_shot);

            shot_dx = cam_pos[0] - tank_x;
            shot_dy = cam_pos[1] - 12.0;
            shot_dz = cam_pos[2] - tank_z;
            shot_len = vmath.sqrt((shot_dx * shot_dx) + (shot_dy * shot_dy) + (shot_dz * shot_dz));

            if (shot_len > 0.001) {
                enemy_projectiles = enemy_projectiles + [[
                    tank_x + (tank_dir_x * 18.0), 12.0, tank_z + (tank_dir_z * 18.0),
                    (shot_dx / shot_len) * projectile_speed,
                    (shot_dy / shot_len) * projectile_speed,
                    (shot_dz / shot_len) * projectile_speed,
                    projectile_life
                ]];
            }
        }

        updated_tanks = updated_tanks + [[tank_x, tank_z, tank_dir_x, tank_dir_z, tank_fire_t]];
        visible_count = visible_count + 1;
    };
    enemy_tanks = updated_tanks;

    # Primary objective tank is the first tank in the formation.
    if (enemy_tanks.size() > 0) {
        target_pos = [enemy_tanks[0][0], 0.0, enemy_tanks[0][1]];
        aim_dir = [enemy_tanks[0][2], 0.0, enemy_tanks[0][3]];
    }

    # Simulate projectiles - limit updates per frame for performance.
    next_projectiles = [];
    proj_count = 0;
    max_proj_update = 20;
    through shot :: enemy_projectiles -> loop {
        if (proj_count >= max_proj_update) {
            next_projectiles = next_projectiles + [shot];
            proj_count = proj_count + 1;
            continue;
        }
        
        new_x = shot[0] + shot[3];
        new_y = shot[1] + shot[4];
        new_z = shot[2] + shot[5];
        new_life = shot[6] - 0.016;

        if (new_life > 0.0) {
            next_projectiles = next_projectiles + [[new_x, new_y, new_z, shot[3], shot[4], shot[5], new_life]];
        }
        proj_count = proj_count + 1;
    };
    enemy_projectiles = next_projectiles;

    if (cam_pos[1] <= 1.0) {
        dx = cam_pos[0] - target_pos[0];
        dz = cam_pos[2] - target_pos[2];
        
        dist_sq_2d = (dx*dx) + (dz*dz);

        if (dist_sq_2d < (target_radius * target_radius)) {
            Params.impacts = Params.impacts + [[target_pos[0], target_pos[2]]];

            Params.score = Params.score + 1;
            missions.generate_target();
        }
    }
}

fn :: missions fire(cam_pos) {
    dx = cam_pos[0] - target_pos[0];
    dz = cam_pos[2] - target_pos[2];
    
    dist_sq_2d = (dx*dx) + (dz*dz);

    if (dist_sq_2d < (target_radius * target_radius * 200.0)) {
        Params.impacts = Params.impacts + [[target_pos[0], target_pos[2]]];

        Params.score = Params.score + 1;
        missions.generate_target();
        return true;
    }
    return false;
}

fn :: missions enemy_hits_player(cam_pos) {
    hit_radius = 10.0;
    through shot :: enemy_projectiles -> loop {
        dx = cam_pos[0] - shot[0];
        dy = cam_pos[1] - shot[1];
        dz = cam_pos[2] - shot[2];
        if ((dx*dx + dy*dy + dz*dz) < (hit_radius * hit_radius)) {
            return true;
        }
    };
    return false;
}

fn :: missions player_hits_tank(shot_pos) {
    hit_r = 25.0;
    kept = [];
    hit_any = false;

    through tank :: enemy_tanks -> loop {
        tank_x = tank[0];
        tank_z = tank[1];
        dx = shot_pos[0] - tank_x;
        dz = shot_pos[2] - tank_z;

        if (hit_any == false && (dx*dx + dz*dz) < (hit_r * hit_r)) {
            hit_any = true;
            Params.score = Params.score + 1;
        } else {
            kept = kept + [tank];
        }
    };

    if (hit_any) {
        enemy_tanks = kept;
    }

    return hit_any;
}

# Checks whether the shot segment (A->B in XZ) intersects a tank hit circle.
# This fixes "skipping" when projectiles move far per frame.
fn :: missions player_hits_tank_segment(a_pos, b_pos) {
    hit_r = 25.0;
    hit_r2 = hit_r * hit_r;
    kept = [];
    hit_any = false;

    ax = a_pos[0]; az = a_pos[2];
    bx = b_pos[0]; bz = b_pos[2];
    vx = bx - ax;
    vz = bz - az;
    vv = (vx * vx) + (vz * vz);

    through tank :: enemy_tanks -> loop {
        tank_x = tank[0];
        tank_z = tank[1];

        if (hit_any == false) {
            wx = tank_x - ax;
            wz = tank_z - az;

            t = 0.0;
            if (vv > 0.000001) {
                t = ((wx * vx) + (wz * vz)) / vv;
            }

            if (t < 0.0) { t = 0.0; }
            if (t > 1.0) { t = 1.0; }

            px = ax + (vx * t);
            pz = az + (vz * t);

            dx = tank_x - px;
            dz = tank_z - pz;
            if ((dx * dx) + (dz * dz) < hit_r2) {
                hit_any = true;
                Params.score = Params.score + 1;
            } else {
                kept = kept + [tank];
            }
        } else {
            kept = kept + [tank];
        }
    };

    if (hit_any) {
        enemy_tanks = kept;
    }

    return hit_any;
}

fn :: missions draw_ui(u_col, cam_pos, camera) {
    cx = 960; cy = 540;

    # 1. RANGE yazısı
    dx = cam_pos[0] - target_pos[0];
    dz = cam_pos[2] - target_pos[2];
    dist = int64(vmath.hypot(dx, dz));
    
    vglib.text_ex(Shaders.vcr_font, "TARGET DIST: " + string(dist) + " M", 60, 220, 20, u_col);
    vglib.text_ex(Shaders.vcr_font, "TARGET COORDS : " + 
        string(target_pos[0]) + " " + 
        string(target_pos[1]) + " " + 
        string(target_pos[2]), 
        60, 250, 20, u_col);
    vglib.text_ex(Shaders.vcr_font, "STRIKES: " + string(Params.score), 60, 280, 20, vglib.rgba(255, 50, 50, 200));

    # 2. İstiqamət Oxu (Pointer)
    target_angle = vmath.degrees(vmath.atan2(target_pos[2] - cam_pos[2], target_pos[0] - cam_pos[0]));
    drone_yaw = vglib.get_yaw(camera); 
    total_angle = vmath.radians(target_angle + drone_yaw + 90.0);
    
    ptr_x = cx + vmath.cos(total_angle) * 160.0;
    ptr_y = cy + vmath.sin(total_angle) * 160.0;
    
    vglib.circle(ptr_x, ptr_y, 4.0, u_col);
    vglib.line(cx + vmath.cos(total_angle) * 140.0, cy + vmath.sin(total_angle) * 140.0, ptr_x, ptr_y, u_col);


}

fn :: missions draw_3d_marker() {
    visible_count = 0;
    
    through tank :: enemy_tanks -> loop {
        if (visible_count >= Engine.max_visible_tanks) { break; }
        
        tank_x = tank[0];
        tank_z = tank[1];
        tank_dir_x = tank[2];
        tank_dir_z = tank[3];

        vglib.draw_model(Models.target_model, tank_x, 0.0, tank_z, 4.0, army_green);

        vglib.line_3d(
            tank_x, 14.0, tank_z,
            tank_x + (tank_dir_x * 70.0), 20.0, tank_z + (tank_dir_z * 70.0),
            vglib.rgba(255, 140, 80, 150)
        );
        
        visible_count = visible_count + 1;
    };
    
    vglib.line_3d(target_pos[0], 0.0, target_pos[2], target_pos[0], 500.0, target_pos[2], vglib.rgba(255, 0, 0, 100));

    through shot :: enemy_projectiles -> loop {
        tail_x = shot[0] - (shot[3] * 0.7);
        tail_y = shot[1] - (shot[4] * 0.7);
        tail_z = shot[2] - (shot[5] * 0.7);
        vglib.line_3d(tail_x, tail_y, tail_z, shot[0], shot[1], shot[2], vglib.rgba(255, 220, 120, 220));
    };

    through i :: 0..12 -> loop {
        ang = vmath.radians(i * 30.0);
        x1 = target_pos[0] + vmath.cos(ang) * target_radius;
        z1 = target_pos[2] + vmath.sin(ang) * target_radius;
        
        ang2 = vmath.radians((i+1) * 30.0);
        x2 = target_pos[0] + vmath.cos(ang2) * target_radius;
        z2 = target_pos[2] + vmath.sin(ang2) * target_radius;
        
        vglib.line_3d(x1, 1.0, z1, x2, 1.0, z2, vglib.RED);
    };
}