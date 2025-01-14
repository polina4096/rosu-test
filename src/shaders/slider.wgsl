// Vertex shader
struct CameraUniform {
	proj: mat4x4<f32>,
	view: mat4x4<f32>,
};

@group(0) @binding(0)
var<uniform> camera: CameraUniform;

struct VertexInput {
	@location(0) pos: vec3<f32>,
	@location(1) uv: vec2<f32>,
}

struct InstanceInput {
	@location(2) pos: vec2<f32>,
	@location(3) alpha: f32,
}

struct VertexOutput {
    @builtin(position) clip_position: vec4<f32>,
	@location(0) uv: vec2<f32>,
	@location(1) alpha: f32,
};

@vertex
fn vs_main(
	model: VertexInput,
	instance: InstanceInput
) -> VertexOutput {
    var out: VertexOutput;
	out.uv = model.uv;
	out.alpha = instance.alpha;

    out.clip_position = camera.proj
	 	* vec4<f32>(model.pos.x + instance.pos.x, model.pos.y + instance.pos.y, model.pos.z, 1.0);


    return out;
}


// Fragment shader

//@group(0) @binding(0)
//var texture: texture_2d<f32>;
//@group(0) @binding(1)
//var texture_sampler: sampler;

const DEFAULT_TRANSITION_SIZE: f32 = 0.011;
const DEFAULT_BORDER_SIZE: f32 = 0.11;
const OUTER_SHADOW_SIZE: f32 = 0.08;

fn get_inner_body_color(body_color: vec4<f32>) -> vec4<f32> {
// TODO redo
	let brightness_multiplier = 0.25;

	var b = vec4<f32>(body_color);
	b.r = min(1.0, body_color.r * (1.0 + 0.5 * brightness_multiplier) + brightness_multiplier);
	b.g = min(1.0, body_color.g * (1.0 + 0.5 * brightness_multiplier) + brightness_multiplier);
	b.b = min(1.0, body_color.b * (1.0 + 0.5 * brightness_multiplier) + brightness_multiplier);
	return b;
}


fn get_outer_body_color(body_color: vec4<f32>) -> vec4<f32> {
	let darkness_multiplier = 0.1;
	var b = vec4<f32>(body_color);

	b.r = min(1.0, body_color.r / (1.0 + darkness_multiplier));
	b.g = min(1.0, body_color.g / (1.0 + darkness_multiplier));
	b.b = min(1.0, body_color.b / (1.0 + darkness_multiplier));
	return b;
}

@fragment
fn fs_main(in: VertexOutput) -> @location(0) vec4<f32> {
	var out_color = vec4<f32>(0.0, 0.0, 0.0, 0.0);

	let border_size_multiplier = 1.0;

	let border_size = DEFAULT_BORDER_SIZE * border_size_multiplier;
	let transition_size = DEFAULT_TRANSITION_SIZE;

	var border_color = vec4<f32>(1.0, 1.0, 1.0, 0.7);
	let outer_shadow_color = vec4<f32>(0.0, 0.0, 0.0, 0.25);

	let bodyColor = vec4<f32>(0.0, 0.0, 0.0, 0.7);
	var inner_body_color = get_inner_body_color(bodyColor);
	var outer_body_color = get_outer_body_color(bodyColor);

	if (in.uv.x < OUTER_SHADOW_SIZE - transition_size) {
		let delta: f32 = in.uv.x / (OUTER_SHADOW_SIZE - transition_size);
		out_color = mix(vec4<f32>(0.0, 0.0, 0.0, 0.0), outer_shadow_color, delta);
	}

	if (in.uv.x > OUTER_SHADOW_SIZE - transition_size && in.uv.x < OUTER_SHADOW_SIZE + transition_size) {
		let delta: f32 = (in.uv.x - OUTER_SHADOW_SIZE + transition_size) / (2.0*transition_size);
		out_color = mix(outer_shadow_color, border_color, delta);
	}

	if (in.uv.x > OUTER_SHADOW_SIZE + transition_size && in.uv.x < OUTER_SHADOW_SIZE + border_size - transition_size) {
		out_color = border_color;
	}

	if (in.uv.x > OUTER_SHADOW_SIZE + border_size - transition_size && in.uv.x < OUTER_SHADOW_SIZE + border_size + transition_size)
	{
		let delta = (in.uv.x - OUTER_SHADOW_SIZE - border_size + transition_size) / (2.0*transition_size);
		out_color = mix(border_color, outer_body_color, delta);
	}

	if (in.uv.x > OUTER_SHADOW_SIZE + border_size + transition_size) // outer body + inner body
	{	
		let size = OUTER_SHADOW_SIZE + border_size + transition_size;
		let delta = ((in.uv.x - size) / (1.0-size));
		out_color = mix(outer_body_color, inner_body_color, delta);
	}

	//return vec4<f32>(1.0, 1.0, 1.0, 1.0);

	return out_color;
}

