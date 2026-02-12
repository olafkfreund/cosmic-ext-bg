// SPDX-License-Identifier: MPL-2.0

use colorgrad::{Color, Gradient as ColorGradient};
use cosmic_ext_bg_config::Gradient;
use image::Rgb32FImage;

/// Generate a background image from a color.
pub fn single(color: [f32; 3], width: u32, height: u32) -> Rgb32FImage {
    Rgb32FImage::from_pixel(width, height, image::Rgb(color))
}

/// Generate a background image from a gradient.
pub fn gradient(
    gradient: &Gradient,
    width: u32,
    height: u32,
) -> Result<Rgb32FImage, colorgrad::GradientBuilderError> {
    let mut colors = Vec::with_capacity(gradient.colors.len());

    for &[r, g, b] in &*gradient.colors {
        colors.push(colorgrad::Color::from_linear_rgba(
            f32::from(r),
            f32::from(g),
            f32::from(b),
            1.0,
        ));
    }

    let grad = colorgrad::GradientBuilder::new()
        .colors(&colors)
        .mode(colorgrad::BlendMode::LinearRgb)
        .build::<colorgrad::LinearGradient>()?;

    let mut imgbuf = image::ImageBuffer::new(width, height);

    let width = f64::from(width);
    let height = f64::from(height);

    // Map t which is in range [a, b] to range [c, d]
    #[allow(clippy::items_after_statements)]
    fn remap(t: f64, a: f64, b: f64, c: f64, d: f64) -> f64 {
        (t - a) * ((d - c) / (b - a)) + c
    }

    #[allow(clippy::items_after_statements)]
    const SCALE: f64 = 0.015;

    let positioner: Box<dyn Fn(u32, u32) -> f64> = match gradient.radius as u16 {
        0 => Box::new(|_x, y| 1.0 - (y as f64 / height)),
        90 => Box::new(|x, _y| x as f64 / width),
        180 => Box::new(|_x, y| y as f64 / height),
        270 => Box::new(|x, _y| 1.0 - (x as f64 / width)),
        _ => {
            let (dmin, dmax) = grad.domain();
            let angle = f64::from(gradient.radius.to_radians());
            let cos_a = f64::cos(angle);
            let sin_a = f64::sin(angle);
            Box::new(move |x, y| {
                let (x, y) = (f64::from(x) - width / SCALE, f64::from(y) - height / SCALE);

                remap(
                    x * cos_a - y * sin_a,
                    -width / SCALE,
                    width / SCALE,
                    f64::from(dmin),
                    f64::from(dmax),
                )
            })
        }
    };

    #[allow(clippy::cast_possible_truncation)]
    for (x, y, pixel) in imgbuf.enumerate_pixels_mut() {
        let Color { r, g, b, .. } = grad.at(positioner(x, y) as f32);

        *pixel = image::Rgb([r as f32, g as f32, b as f32]);
    }

    Ok(imgbuf)
}
