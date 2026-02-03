// SPDX-License-Identifier: MPL-2.0
// Waves shader preset for cosmic-bg

struct Uniforms {
    resolution: vec2<f32>,
    time: f32,
    _padding: f32,
}

@group(0) @binding(0)
var<uniform> uniforms: Uniforms;

@vertex
fn vs_main(@builtin(vertex_index) vertex_index: u32) -> @builtin(position) vec4<f32> {
    // Fullscreen triangle
    let x = f32(i32(vertex_index) - 1);
    let y = f32(i32(vertex_index & 1u) * 2 - 1);
    return vec4<f32>(x, y, 0.0, 1.0);
}

// Convert HSV to RGB
fn hsv_to_rgb(h: f32, s: f32, v: f32) -> vec3<f32> {
    let c = v * s;
    let x = c * (1.0 - abs(((h / 60.0) % 2.0) - 1.0));
    let m = v - c;

    var rgb: vec3<f32>;
    let h_i = i32(h / 60.0) % 6;

    if h_i == 0 {
        rgb = vec3<f32>(c, x, 0.0);
    } else if h_i == 1 {
        rgb = vec3<f32>(x, c, 0.0);
    } else if h_i == 2 {
        rgb = vec3<f32>(0.0, c, x);
    } else if h_i == 3 {
        rgb = vec3<f32>(0.0, x, c);
    } else if h_i == 4 {
        rgb = vec3<f32>(x, 0.0, c);
    } else {
        rgb = vec3<f32>(c, 0.0, x);
    }

    return rgb + vec3<f32>(m, m, m);
}

@fragment
fn fs_main(@builtin(position) frag_coord: vec4<f32>) -> @location(0) vec4<f32> {
    let uv = frag_coord.xy / uniforms.resolution;
    let time = uniforms.time;

    // Multi-layer wave pattern
    var wave = 0.0;

    // Horizontal waves
    wave += sin(uv.y * 20.0 + time * 1.5) * 0.3;
    wave += sin(uv.y * 15.0 - time * 1.2 + uv.x * 5.0) * 0.2;
    wave += sin(uv.y * 8.0 + time * 0.8 + uv.x * 3.0) * 0.15;

    // Vertical influence
    wave += sin(uv.x * 12.0 + time * 0.5) * 0.1;

    // Normalize
    wave = wave * 0.5 + 0.5;

    // Create ocean-like colors using HSV
    let hue = 200.0 + wave * 60.0 + sin(time * 0.3) * 20.0;
    let saturation = 0.6 + wave * 0.3;
    let value = 0.3 + wave * 0.5;

    let color = hsv_to_rgb(hue, saturation, value);

    return vec4<f32>(color, 1.0);
}
