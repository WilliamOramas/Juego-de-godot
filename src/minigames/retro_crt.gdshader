shader_type canvas_item;

uniform float vignette_intensity = 0.4;
uniform float vignette_opacity : hint_range(0.0, 1.0) = 0.8;
uniform vec4 vignette_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

void fragment() {
    vec2 uv = UV;
    float dist = distance(uv, vec2(0.5, 0.5));
    
    // Calculate basic radial vignette
    float vignette = smoothstep(vignette_intensity, 1.0, dist);
    
    // Simple retro dither pattern (2x2 Bayer-like matrix approximation)
    vec2 coord = FRAGCOORD.xy;
    float dither = mod(coord.x + mod(coord.y, 2.0), 2.0);
    
    // Apply dither to make the edge fade pixelated
    float final_vignette = vignette * mix(0.5, 1.0, dither);
    
    // CRT Scanlines (horizontal bands)
    // We use a high frequency sine wave based on UV.y
    float scanline = sin(uv.y * 600.0 * 3.14159) * 0.05;
    
    // Add everything to get final alpha
    float alpha = (final_vignette * vignette_opacity) + scanline;
    
    COLOR = vec4(vignette_color.rgb, clamp(alpha, 0.0, 1.0));
}
