// SPDX-License-Identifier: MPL-2.0
// Animated gradient shader preset for cosmic-bg

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

// Smooth interpolation between colors
fn mix_color(a: vec3<f32>, b: vec3<f32>, t: f32) -> vec3<f32> {
    return a * (1.0 - t) + b * t;
}

@fragment
fn fs_main(@builtin(position) frag_coord: vec4<f32>) -> @location(0) vec4<f32> {
    let uv = frag_coord.xy / uniforms.resolution;
    let time = uniforms.time;

    // Rotate gradient direction over time
    let angle = time * 0.2;
    let cos_a = cos(angle);
    let sin_a = sin(angle);

    // Center-relative coordinates
    let centered = uv - vec2<f32>(0.5, 0.5);
    let rotated = vec2<f32>(
        centered.x * cos_a - centered.y * sin_a,
        centered.x * sin_a + centered.y * cos_a
    );

    // Gradient position (0 to 1)
    let pos = rotated.x + rotated.y + 0.5;

    // Animate color palette
    let phase = time * 0.3;

    // Define gradient colors (COSMIC-inspired purple/blue palette)
    let color1 = vec3<f32>(0.15, 0.1, 0.25);   // Deep purple
    let color2 = vec3<f32>(0.25, 0.15, 0.4);   // Purple
    let color3 = vec3<f32>(0.2, 0.3, 0.5);     // Blue-purple
    let color4 = vec3<f32>(0.1, 0.2, 0.35);    // Dark blue

    // Smooth color interpolation with animation
    let t = (sin(pos * 3.14159 + phase) + 1.0) * 0.5;
    let t2 = (sin(pos * 3.14159 * 2.0 + phase * 1.5) + 1.0) * 0.5;

    var color: vec3<f32>;
    if t < 0.33 {
        color = mix_color(color1, color2, t * 3.0);
    } else if t < 0.66 {
        color = mix_color(color2, color3, (t - 0.33) * 3.0);
    } else {
        color = mix_color(color3, color4, (t - 0.66) * 3.0);
    }

    // Add subtle shimmer
    let shimmer = sin(pos * 50.0 + time * 2.0) * 0.02 + 1.0;
    color = color * shimmer;

    return vec4<f32>(color, 1.0);
}
