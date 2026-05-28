module world;

module vglib;
module vmath;

world_map_data = vglib.load_map("maps/kharkiv_map.dat");
world_forest_density = 2200;
world_forest_trees = [];

fn :: world init() {
    world.generate_forest();
}

fn :: world generate_forest() {
    world_forest_trees = [];

    through i :: 0..world_forest_density -> loop {
        tx = vmath.random(-2500, 2500);
        tz = vmath.random(-2000, 2500);
        t_scale = 4.0 + (vmath.random(0, 100) / 100.0);

        world_forest_trees = world_forest_trees + [[tx, 0.0, tz, t_scale]];
    };
    
    vglib.upload_persistent_group("forest_trees", world_forest_trees);
}

fn :: world draw(cam_pos) {
    vglib.plane_texture(Textures.slots[7], 0.0, 0.0, 0.0, 10000.0, 10000.0);

    render_dist_sq = Engine.render_distance_map * Engine.render_distance_map;

    through w :: world_map_data -> loop {
        dx = cam_pos[0] - w[0];
        if (dx > -Engine.render_distance_map && dx < Engine.render_distance_map) {
            dz = cam_pos[2] - w[2];
            if (dz > -Engine.render_distance_map && dz < Engine.render_distance_map) {
                dist_sq = dx*dx + dz*dz;
                if (dist_sq < render_dist_sq) {
                    t_idx = int64(w[4]) % Textures.slots.size();
                    vglib.cube_texture(Textures.slots[t_idx], w[0], w[1], w[2], w[3], vglib.WHITE);
                }
            }
        }
    };

    vglib.draw_persistent_group("forest_trees", Models.tree_model, cam_pos, Engine.render_distance_trees);
    missions.draw_3d_marker();
}
