use anyhow::Result;
use flutter_rust_bridge::frb;
use image::{DynamicImage, ImageBuffer, Rgba};

/// Metadata about a frame
pub struct FrameInfo {
    pub width: u32,
    pub height: u32,
    pub size_bytes: u64,
}

/// Result of frame processing
pub struct ProcessedFrame {
    pub data: Vec<u8>, // RGBA bytes
    pub width: u32,
    pub height: u32,
}

/// Get basic frame info from raw RGBA bytes
#[frb(sync)]
pub fn get_frame_info(bytes: Vec<u8>, width: u32, height: u32) -> FrameInfo {
    FrameInfo {
        width,
        height,
        size_bytes: bytes.len() as u64,
    }
}

/// Process frame — applies pipeline: resize if 4K → normalize → return
#[frb(sync)]
pub fn process_frame(bytes: Vec<u8>, width: u32, height: u32) -> Result<ProcessedFrame> {
    let img = ImageBuffer::<Rgba<u8>, Vec<u8>>::from_raw(width, height, bytes)
        .ok_or_else(|| anyhow::anyhow!("Failed to create image buffer"))?;

    let dynamic = DynamicImage::ImageRgba8(img);

    // If 4K, downscale to 1080p for performance
    let processed = if width > 1920 {
        dynamic.resize(1920, 1080, image::imageops::FilterType::Lanczos3)
    } else {
        dynamic
    };

    let rgba = processed.to_rgba8();
    let (w, h) = (rgba.width(), rgba.height());

    Ok(ProcessedFrame {
        data: rgba.into_raw(),
        width: w,
        height: h,
    })
}

/// Convert frame to grayscale
#[frb(sync)]
pub fn apply_grayscale(bytes: Vec<u8>, width: u32, height: u32) -> Result<ProcessedFrame> {
    let img = ImageBuffer::<Rgba<u8>, Vec<u8>>::from_raw(width, height, bytes)
        .ok_or_else(|| anyhow::anyhow!("Invalid frame buffer"))?;

    let dynamic = DynamicImage::ImageRgba8(img);
    let gray = dynamic.grayscale().to_rgba8();
    let (w, h) = (gray.width(), gray.height());

    Ok(ProcessedFrame {
        data: gray.into_raw(),
        width: w,
        height: h,
    })
}

/// Adjust brightness (-255 to +255)
#[frb(sync)]
pub fn apply_brightness(
    bytes: Vec<u8>,
    width: u32,
    height: u32,
    value: i32,
) -> Result<ProcessedFrame> {
    let img = ImageBuffer::<Rgba<u8>, Vec<u8>>::from_raw(width, height, bytes)
        .ok_or_else(|| anyhow::anyhow!("Invalid frame buffer"))?;

    let dynamic = DynamicImage::ImageRgba8(img);
    let brightened = dynamic.brighten(value);
    let rgba = brightened.to_rgba8();
    let (w, h) = (rgba.width(), rgba.height());

    Ok(ProcessedFrame {
        data: rgba.into_raw(),
        width: w,
        height: h,
    })
}
