module world;

module vglib;
module vmath;

world_map_data = vglib.load_map("maps/kharkiv_map.dat");
world_forest_density = 2200;
world_forest_trees = [];

fn :: world init() {
    world.generate_forest();
    vglib.upload_persistent_group("forest_trees", world_forest_trees);
}

fn :: world generate_forest() {
    world_forest_trees = [];

    through i :: 0..world_forest_density -> loop {
        tx = vmath.random(-2500, 2500);
        tz = vmath.random(-2000, 2500);
        t_scale = 4.0 + (vmath.random(0, 100) / 100.0);

        world_forest_trees = world_forest_trees + [[tx, 0.0, tz, t_scale]];
    };
}

fn :: world draw(cam_pos) {
    vglib.plane_texture(Textures.slots[7], 0.0, 0.0, 0.0, 10000.0, 10000.0);

    through w :: world_map_data -> loop {
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
}
