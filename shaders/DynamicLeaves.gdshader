shader_type particles;

uniform uint TREE_SEED = 0;
uniform sampler2D NOISE2D;
uniform sampler2D EMISSION_MASK;

uniform float sway_speed = 1.0;
uniform float sway_strength = 0.05;
uniform float sway_phase_len = 8.0;

uniform vec2 origin = vec2(0., 0.);
uniform float leaf_scale = 0.1;
uniform vec2 tree_size;

float rand_from_seed(in uint seed) {
  int k;
  int s = int(seed);
  if (s == 0)
    s = 305420679;
  k = s / 127773;
  s = 16807 * (s - k * 127773) - 2836 * k;
  if (s < 0)
    s += 2147483647;
  seed = uint(s);
  return float(seed % uint(65536)) / 65535.0;
}

uint hash(uint x) {
  x = ((x >> uint(16)) ^ x) * uint(73244475);
  x = ((x >> uint(16)) ^ x) * uint(73244475);
  x = (x >> uint(16)) ^ x;
  return x;
}

void start() {
	vec2 position;
	bool valid = false;
	uint i = uint(0);
	while(!valid && i < uint(10000)){
		uint dist_seed = hash(NUMBER + uint(1)  + i  + RANDOM_SEED + TREE_SEED);
		uint angl_seed = hash(NUMBER + uint(27) + i + RANDOM_SEED + TREE_SEED);
		float dist = rand_from_seed(dist_seed);
		float angl = rand_from_seed(angl_seed);
//		position = dist * vec2(sin(angl), cos(angl));
		position = vec2(dist, angl);
		valid = rand_from_seed(dist_seed + angl_seed + i*uint(4325246425)) < texture(EMISSION_MASK, position).r && texture(EMISSION_MASK, position).a > 0.;
		i++;
	}
	
	CUSTOM.x = texture(NOISE2D, position).r;
	
	TRANSFORM[3].xy = origin + position * tree_size;
	TRANSFORM[0] = vec4(leaf_scale, 0., 0., 0.);
	TRANSFORM[1] = vec4(0., leaf_scale, 0., 0.);
	TRANSFORM[2] = vec4(0., 0., leaf_scale, 0.);
}

void process() {
	// Place process code here.
	
	vec2 position;
	bool valid = false;
	uint i = uint(0);
	while(!valid  && i < uint(10000)){
		uint dist_seed = hash(NUMBER + uint(1)  + i  + RANDOM_SEED + TREE_SEED);
		uint angl_seed = hash(NUMBER + uint(27) + i + RANDOM_SEED + TREE_SEED);
		float dist = rand_from_seed(dist_seed);
		float angl = rand_from_seed(angl_seed);
//		position = dist * vec2(sin(angl), cos(angl));
		position = vec2(dist, angl);
		valid = rand_from_seed(dist_seed + angl_seed + i*uint(4325246425)) <= texture(EMISSION_MASK, position).r && texture(EMISSION_MASK, position).a > 0. ;
		i++;
	}
	
	CUSTOM.x = texture(NOISE2D, position).r;
	
	TRANSFORM[3].xy = origin + position * tree_size;
//	TRANSFORM[0] *= leaf_scale;
//	TRANSFORM[1] *= leaf_scale;
//	TRANSFORM[2] *= leaf_scale;
	
	float strength = 100. * sway_strength;
	
    TRANSFORM[3].x += sin(TIME * sway_speed + CUSTOM.x * TAU) * strength * 1.52435;
    TRANSFORM[3].y += cos(TIME * sway_speed * 1.12412 + CUSTOM.x * TAU) * strength;
	
}
