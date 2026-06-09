shader_type canvas_item;

uniform float vignette_intensity = 0.4;
uniform float vignette_opacity : hint_range(0.0, 1.0) = 0.8;
uniform vec4 vignette_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

uniform float scanline_intensity : hint_range(0.0, 1.0) = 0.15;
uniform float scanline_frequency : hint_range(100.0, 1000.0) = 400.0;

void fragment() {
	vec2 uv = UV;

	vec4 color = texture(TEXTURE, uv);

	float dist = length(uv - 0.5);

	// Scanlines
	float scanline = sin(uv.y * scanline_frequency * 3.14159);
	scanline = clamp(scanline, 0.0, 1.0);
	scanline = mix(1.0, scanline, scanline_intensity);
	color.rgb *= scanline;

	// Vignette
	float vig = 1.0 - smoothstep(vignette_intensity, 1.0, dist) * vignette_opacity;
	color.rgb = mix(vignette_color.rgb, color.rgb, vig);

	// Alpha: transparent at center (action_sprite visible), opaque at corners
	float vig_alpha = smoothstep(vignette_intensity, 1.0, dist) * vignette_opacity;
	color.a = clamp(vig_alpha + 0.05, 0.0, 1.0);

	COLOR = color;
}
