// SPDX-License-Identifier: MPL-2.0
// Plasma shader preset for cosmic-bg

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

@fragment
fn fs_main(@builtin(position) frag_coord: vec4<f32>) -> @location(0) vec4<f32> {
    let uv = frag_coord.xy / uniforms.resolution;
    let time = uniforms.time;

    // Multiple plasma focal points
    var value = 0.0;

    // First wave
    value += sin(uv.x * 10.0 + time);

    // Second wave
    value += sin(uv.y * 10.0 + time * 0.8);

    // Diagonal wave
    value += sin((uv.x + uv.y) * 10.0 + time * 0.6);

    // Radial wave from center
    let cx = uv.x - 0.5;
    let cy = uv.y - 0.5;
    let dist = sqrt(cx * cx + cy * cy);
    value += sin(dist * 20.0 - time * 2.0);

    // Normalize to 0-1 range
    value = value / 4.0 + 0.5;

    // Create vibrant plasma colors
    let r = sin(value * 3.14159 * 2.0) * 0.5 + 0.5;
    let g = sin(value * 3.14159 * 2.0 + 2.094) * 0.5 + 0.5;
    let b = sin(value * 3.14159 * 2.0 + 4.188) * 0.5 + 0.5;

    return vec4<f32>(r, g, b, 1.0);
}
