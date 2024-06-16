shader_type spatial;
render_mode blend_mix,depth_draw_opaque,cull_back,diffuse_burley,specular_schlick_ggx;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform sampler2D DEPTH_TEXTURE : hint_depth_texture, filter_linear_mipmap;

uniform float speed : hint_range(-1,1) = 0.01;

//colors
uniform sampler2D noise1: source_color,filter_linear_mipmap,repeat_enable; //add Godot noise here
uniform sampler2D noise2: source_color,filter_linear_mipmap,repeat_enable; //add Godot noise here
uniform vec4 color: source_color;
uniform vec4 edge_color: source_color;

//foam
uniform float edge_scale = 0.05;

//waves
uniform vec2 wave_strengh = vec2(0.079, 0.07);
uniform vec2 wave_frequency = vec2(29.0, 37.0);
uniform vec2 time_factor = vec2(1.3, 1.1);

varying vec2 uvWorld;


float waves(vec2 pos, float time){
	return (
		wave_strengh.y * sin(pos.y * wave_frequency.y + time * time_factor.y) +
		wave_strengh.x * sin(pos.x * wave_frequency.x + time * time_factor.x)
	);
}


void vertex() {
	uvWorld = (MODEL_MATRIX * vec4(VERTEX, 1.0f)).xz;
	VERTEX.y += waves(uvWorld, TIME * 0.79);
}


void fragment() {
	float time = TIME * speed;
	float n1 = texture(noise1, uvWorld * 0.137 + time).r;
	float n2 = texture(noise2, uvWorld * 0.11 - time * 0.2).r;
	
	vec2 uv_movement = uvWorld * 0.1;
	uv_movement += TIME * speed;
	
	float sum = (n1 + n2) - 1.0;
//	float sum = n1 * n2;
//	sum = pow(sum, 0.5);
	
	float depthRaw = texture(DEPTH_TEXTURE, SCREEN_UV).x;
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depthRaw);
	vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	view.xyz /= view.w;
	
	float waterDepth = -view.z + VERTEX.z;
	waterDepth = waterDepth * 0.1 + sum * 0.1;
	
	vec4 col = mix(edge_color, color, step(edge_scale, waterDepth));
	
	float fin = 0.0;
	if (sum > 0.0 && sum < 0.1) {
		fin = 0.03;
	}
	if (sum > 0.55) {
		fin = 0.5;
	}
	
	ALBEDO = mix(col.rgb, vec3(1.0), fin);
	
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}
