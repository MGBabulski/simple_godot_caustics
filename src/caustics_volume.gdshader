shader_type spatial;
render_mode cull_front, depth_test_disabled, ambient_light_disabled, unshaded;

uniform sampler2D depth_texture : hint_depth_texture;
uniform sampler2D screen_texture : hint_screen_texture;

// size of the box mesh - must be forwarded for bounding box calculation
uniform vec3 bounding_box_size = vec3(1.0);

// scale for uv
uniform float uv_scale = 0.1;

// speed of caustics texture scroll
uniform float caustics_speed = 1.0;

// strength of caustics
uniform float caustics_strength = 0.2;

// chromatic aberration parameter
uniform float caustics_aberration = 0.1;

// cutoff parameter for channels
uniform float chromatic_cutoff : hint_range(0.0, 1.0, 0.001) = 0.0;

// blending factor (between two caustic axis)
uniform float blending_factor : hint_range(0.0, 1.0, 0.001) = 0.5;

// fade point (controlls when caustics start to fade)
uniform float fading_point = 0.0;

// noise textures for generating caustics (full black have no effect, for 1 texture per axis second one must be white)
uniform sampler2D noise_XZ_1 : hint_normal, repeat_enable;
uniform sampler2D noise_XZ_2 : hint_normal, repeat_enable;
uniform sampler2D noise_XY_1 : hint_normal, repeat_enable;
uniform sampler2D noise_XY_2 : hint_normal, repeat_enable;

// skew for xy caustics
uniform mat3 XY_transform = mat3(1.0);

void vertex () {}

// function to check if a point exists in bounding box and calculate fade factor
vec2 check_bounding_box (vec3 world_coordinates, mat4 model_matrix)
{
	// simple calculation of bounding coordinates (TL;DR we transform local coordinates of AABB points to world space and compare values)
	vec3 bounding = bounding_box_size / 2.0;
	vec3 far = (model_matrix * vec4(-bounding,1.0)).rgb;
	vec3 near = (model_matrix * vec4(bounding,1.0)).rgb;
	// checking fade factor
	float fade = 1.0;
	if (fading_point > 0.001)
	{
		// calculating distance from nearest edge
		vec3 fdist = abs(world_coordinates - far);
		vec3 ndist = abs(world_coordinates - near);
		fdist = min(fdist,ndist);
		float mindist = min(fdist.x,min(fdist.y,fdist.z));
		// calculating fade
		fade = mindist > fading_point ? 1.0 : mix(0.0,1.0,mindist/fading_point);
	}
	// checking if input vector is inside bounding box
	world_coordinates = step(far,world_coordinates) * step(world_coordinates,near);
	float bmask = world_coordinates.x * world_coordinates.y * world_coordinates.z;		// 0 if outside 1 if inside
	// returns a tuple
	return vec2(bmask,fade);
}

// simple panner
vec2 animate_uv (vec2 uv, vec2 dir)
{
	return dir * TIME * caustics_speed + (uv * uv_scale);
}

// simple aberration engine for caustics generation from noise (3x)
vec3 get_noise_XZ (vec2 uv)
{
	// splitting uvs for separate processing
	vec2 uvr = uv + vec2(caustics_aberration);
	vec2 uvg = uv + vec2(caustics_aberration,-caustics_aberration);
	vec2 uvb = uv + vec2(-caustics_aberration);
	// getting textures
	const vec2 anim1 = vec2(0.9,0.2);
	const vec2 anim2 = vec2(-0.5,-0.7);
	vec3 c1 = vec3
	(
		texture(noise_XZ_1,animate_uv(uvr,anim1)).r,
		texture(noise_XZ_1,animate_uv(uvg,anim1)).g,
		texture(noise_XZ_1,animate_uv(uvb,anim1)).b
	);
	vec3 c2 = vec3
	(
		texture(noise_XZ_2,animate_uv(uvr,anim2)).r,
		texture(noise_XZ_2,animate_uv(uvg,anim2)).g,
		texture(noise_XZ_2,animate_uv(uvb,anim2)).b
	);
	// mixing colors
	return min(c1,c2);
}

vec3 get_noise_XY  (vec2 uv)
{
	// splitting uvs for separate processing
	vec2 uvr = uv + vec2(caustics_aberration);
	vec2 uvg = uv + vec2(caustics_aberration,-caustics_aberration);
	vec2 uvb = uv + vec2(-caustics_aberration);
	// getting textures
	const vec2 anim1 = vec2(-0.5,0.6);
	const vec2 anim2 = vec2(0.3,-0.8);
	vec3 c1 = vec3
	(
		texture(noise_XY_1,animate_uv(uvr,anim1)).r,
		texture(noise_XY_1,animate_uv(uvg,anim1)).g,
		texture(noise_XY_1,animate_uv(uvb,anim1)).b
	);
	vec3 c2 = vec3
	(
		texture(noise_XY_2,animate_uv(uvr,anim2)).r,
		texture(noise_XY_2,animate_uv(uvg,anim2)).g,
		texture(noise_XY_2,animate_uv(uvb,anim2)).b
	);
	// mixing colors
	return min(c1,c2);
}

vec3 get_color_vec (vec3 global_coords)
{
	// generating uvs
	vec2 uvXZ = global_coords.xz;
	vec2 uvXY = (XY_transform * global_coords).xy;
	// getting colors
	vec3 cXZ = get_noise_XZ(uvXZ);
	vec3 cXY = get_noise_XY(uvXY);
	return mix(cXZ,cXY,blending_factor);
}

void fragment ()
{
	// calculating world coordinates (see offcial docs)
	float depth = texture(depth_texture, SCREEN_UV).x;
  	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth);		// modern architecture only (see official docs if you've got problems)
  	vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
  	view.xyz /= view.w;
	vec4 world = INV_VIEW_MATRIX * INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	vec3 world_position = world.xyz / world.w;
	// calculating bounding box mask
	vec2 bmask_fade = check_bounding_box(world_position,MODEL_MATRIX);
	float bounding_box_mask = bmask_fade.x;
	float fade_factor = bmask_fade.y;
	vec4 screen = texture(screen_texture,SCREEN_UV);
	if (bounding_box_mask < 0.5)
	{
		ALBEDO = screen.rgb;
		ALPHA = screen.a;
	}
	else
	{
		vec3 caustics = get_color_vec(world_position);
		caustics.x = caustics.x < chromatic_cutoff ? 0.0 : caustics.x;
		caustics.y = caustics.y < chromatic_cutoff ? 0.0 : caustics.y;
		caustics.z = caustics.z < chromatic_cutoff ? 0.0 : caustics.z;
		caustics *= caustics_strength * fade_factor;
		float coeff = (caustics.x + caustics.y + caustics.z) / 3.0;
		coeff = clamp(coeff,0.0,1.0);
		ALBEDO = mix(screen.rgb,caustics,coeff);
		ALPHA = coeff;
	}
}
