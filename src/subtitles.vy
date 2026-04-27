ruleset { dynamic_casting };

module subtitles;

module vglib;

group Data :: subtitles {
    lines = [
        [1.0, 4.0,  "POLINA-42: ZHENYA 1-1, proceed to target area."],
        [4.5, 7.0,  "PILOT: Copy that. Looking for targets of opportunity."],
        [8.0, 11.0, "POLINA-42: Scans indicate high value targets in the forest."],
        [12.0, 15.0, "PILOT: I have a visual on the tank column. Engaging."],
        [17.0, 20.0, "PILOT: Target destroyed. Moving to next waypoint."],
        [22.0, 25.0, "POLINA-42: Watch out for anti-air fire in sector 7."]
    ];
};

fn :: subtitles draw(run_time, u_col) {
    through line :: Data.lines -> loop {
        start_t = line[0];
        end_t   = line[1];
        text    = line[2];

        if (run_time >= start_t) {
            if (run_time <= end_t) {
                subtitle_size = vglib.measure_text(Shaders.vcr_font, text, 20);
                x_pos = 960 - (subtitle_size[0] / 4); # Ortala
                
                vglib.text_ex(Shaders.vcr_font, text, x_pos + 2, 902, 20, vglib.BLACK);
                
                vglib.text_ex(Shaders.vcr_font, text, x_pos, 900, 20, u_col);
            }
        }
    };
}