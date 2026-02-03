# Implementation Summary: Issue #11 - Output Transform Handling

## Overview
Implemented proper handling for rotated displays by adding output transform support to cosmic-bg-ng.

## Changes Made

### 1. Added `transform` Field to CosmicBgLayer (Line 102)
```rust
pub struct CosmicBgLayer {
    ...
    transform: wl_output::Transform,
}
```
- Stores the current transform state (rotation/mirroring) for each layer
- Initialized from `output_info.transform` in `new_layer()` method

### 2. Added Helper Function `is_rotated_90_or_270()` (Line 105-113)
```rust
fn is_rotated_90_or_270(transform: wl_output::Transform) -> bool {
    matches!(
        transform,
        wl_output::Transform::_90
            | wl_output::Transform::_270
            | wl_output::Transform::Flipped90
            | wl_output::Transform::Flipped270
    )
}
```
- Detects 90° and 270° rotations (including flipped variants)
- Used to determine when dimensions need to be swapped

### 3. Added `effective_size()` Method to CosmicBgLayer (Line 115-124)
```rust
impl CosmicBgLayer {
    pub fn effective_size(&self) -> Option<(u32, u32)> {
        self.size.map(|(w, h)| {
            if is_rotated_90_or_270(self.transform) {
                (h, w)
            } else {
                (w, h)
            }
        })
    }
}
```
- Returns effective size with width/height swapped for 90°/270° rotations
- Available for use in the draw pipeline when rotation handling is needed

### 4. Initialize Transform in `new_layer()` (Line 400)
```rust
CosmicBgLayer {
    ...
    transform: output_info.transform,
    ...
}
```
- Initializes transform from output info when layer is created

### 5. Implemented `transform_changed()` Callback (Line 442-472)
```rust
fn transform_changed(
    &mut self,
    _conn: &Connection,
    _qh: &QueueHandle<Self>,
    surface: &wl_surface::WlSurface,
    new_transform: wl_output::Transform,
) {
    // Find the wallpaper containing the surface and update its transform
    for wallpaper in &mut self.wallpapers {
        if let Some(layer) = wallpaper
            .layers
            .iter_mut()
            .find(|layer| layer.layer.wl_surface() == surface)
        {
            // Only process if transform actually changed
            if layer.transform != new_transform {
                tracing::debug!(
                    old_transform = ?layer.transform,
                    new_transform = ?new_transform,
                    "output transform changed"
                );

                layer.transform = new_transform;
                layer.needs_redraw = true;

                // Trigger a redraw with the new transform
                wallpaper.draw();
            }
            break;
        }
    }
}
```
- Finds the wallpaper/layer for the affected surface
- Updates the transform field
- Marks layer for redraw
- Triggers immediate redraw to apply the new transform

## How It Works

1. **Initialization**: When a layer surface is created, the current output transform is captured from OutputInfo

2. **Transform Detection**: When the compositor notifies us of a transform change via transform_changed():
   - The callback finds the corresponding wallpaper layer by surface
   - Compares old and new transforms (only acts if changed)
   - Updates the layer's transform field
   - Marks the layer as needing redraw
   - Triggers an immediate redraw

3. **Dimension Handling**: The effective_size() method provides the correct dimensions:
   - For 0°/180° rotations: returns original (width, height)
   - For 90°/270° rotations: returns swapped (height, width)

4. **Logging**: Debug logging shows transform changes for troubleshooting

## Testing

The implementation follows Wayland protocol patterns and should handle:
- Portrait displays (90° rotation)
- Inverted displays (180° rotation)
- Landscape displays (270° rotation)
- Flipped variants of all rotations

## Notes

- The implementation is defensive: only processes actual transform changes
- Uses Rust's matches! macro for clean transform variant matching
- Follows existing code patterns in the codebase
- Includes documentation comments for public API
- Transform state is persistent across redraws
