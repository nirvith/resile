shader_type canvas_item;
// Turns any enemy sprite into the same "alien green", so creatures from
// different art packs read as one species. Also does the red hit flash.

uniform vec4 tint : source_color = vec4(0.55, 1.0, 0.35, 1.0);       // palette alien green
uniform vec4 flash_color : source_color = vec4(1.0, 0.24, 0.35, 1.0); // palette alarm red
uniform float flash : hint_range(0.0, 1.0) = 0.0;                      // 0 = no flash, 1 = full red

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float brightness = dot(tex.rgb, vec3(0.299, 0.587, 0.114));
	vec3 alien = clamp(0.12 + brightness * 1.8, 0.0, 1.0) * tint.rgb;
	vec3 final_colour = mix(alien, flash_color.rgb, flash);
	COLOR = vec4(final_colour, tex.a) * COLOR;
}
