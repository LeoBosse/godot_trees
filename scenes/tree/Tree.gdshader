shader_type canvas_item;

uniform sampler2D NOISE_PATTERN;
uniform float NOISE_OFFSET;
uniform vec3 BASE_COLOR;
uniform float hori_freq = 0.1;
uniform float vert_freq = .5;

void fragment() {
	/////////////////////////////////////
	// Use noise texture
	//H_freq = .1, vert_freq = .5
//	vec2 noise_pos =  (vec2(NOISE_OFFSET) + vec2(UV.x * hori_freq, UV.y * vert_freq)) / vec2(2.);
//	float noiseValue = texture(NOISE_PATTERN, noise_pos).x;
//	COLOR.rgb = BASE_COLOR.rgb * vec3(noiseValue * UV.x);
	
	/////////////////////////////////////
	//Patterns
	//H_freq = 2, vert_freq = 15
	COLOR.rgb = BASE_COLOR.rgb * vec3(.5 * abs(cos(UV.x * hori_freq*6.28) + sin(UV.y * vert_freq*6.28)));
}
