ruleset { dynamic_casting, warnings };

module vglib;

use "src/config.vy";

vglib.init(Engine.screen_w, Engine.screen_h, Engine.target_fps, Engine.app_title, vglib.FULLSCREEN + vglib.VSYNC);

vglib.begin();
vglib.clear(vglib.BLACK);
vglib.end();

use "src/loader.vy";
use "src/state.vy";
use "src/missions.vy";
use "src/subtitles.vy";
use "src/player.vy";
use "src/world.vy";
use "src/audio_system.vy";
use "src/events.vy";
use "src/renderer.vy";

player.init();
world.init();
renderer.init(
    Engine.screen_w, Engine.screen_h,
    Engine.rotation_speed, Engine.fade_speed, Engine.intro_dur,
    Shaders.fog, Shaders.vhs_color, Shaders.vcr_font
);
audio_system.start();
missions.init_next();

while (vglib.running()) {
    state.tick();

    cam_pos = player.update_controls();
    player.fire_if_requested();

    events.update(cam_pos);
    audio_system.update();

    camera = player.get_camera();
    renderer.render_world(camera, cam_pos);
    renderer.draw_frame(camera, cam_pos);
}

vglib.close();
