shader_type canvas_item;

uniform float wipe_progress : hint_range(0.0, 2.0) = 0.0;
uniform float smooth_edge : hint_range(0.0, 1.0) = 0.05;
uniform vec4 fade_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

void fragment() {
    float mask = 0.0;
    
    if (wipe_progress <= 1.0) {
        // Phase 1: Cover screen from left to right (0.0 = clear, 1.0 = fully black)
        float threshold = wipe_progress * (1.0 + smooth_edge);
        mask = 1.0 - smoothstep(threshold - smooth_edge, threshold, UV.x);
    } else {
        // Phase 2: Uncover screen from left to right (1.0 = fully black, 2.0 = clear)
        float progress_back = wipe_progress - 1.0;
        float threshold = progress_back * (1.0 + smooth_edge);
        mask = smoothstep(threshold - smooth_edge, threshold, UV.x);
    }
    
    COLOR = vec4(fade_color.rgb, mask * fade_color.a);
}
