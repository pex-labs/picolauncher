// This function is able to parse a variety of files and returns a byte array that represents a pico-8 readable format.
// Supported formats are:
// - .p8
// - .p8.png
// - .png: assumes dimensions divisible by 128 (screenshot)

// load_image:w,h,frames,mode
// w = number between 1 and 128
// w = number between 1 and 128
// mode: # In the future there will be different drawing modes that allow you to display the image with scanlines.
//         Because it is technically possible to screenshot up to 32 colors on the screen at one time.
// - default: default palette mode. all colors will be converted/mapped to the default palette.
// - custom:  custom palette mode, only 1 palette allowed.
// - cust32:  outputs screen orientation (horizontal/vertical). then palette mappings for all rows. then each row.
//

// a 64x64 image can load at 60 fps if on max cpu. 30 fps if on lower cpu.

// 1 second gif at 60 fps can be loaded in 4 seconds without any compression. though scan lines could be cycled and cached to guarantee max load speed.

// - for 32 color gifs, up to 12 frames can be loaded a second (on high cpu),   6 frames a second to be safe.
// - frames can in 4 frames on near max cpu (15 fps). 8 frames with half cpu (7.5 fps).
// - palette can change each frame, so each frame is loading a separate image. if loading scanlines, there could be 2 bits before each scanline. 1 bit: palette, 2 bit: same line
// - if switching rotation, not same as previous frame.

// - gif playback could be sped up by checking scan lines that changed from the previous frame. but do i really want to do that?
// gifs files only support 100fps, 50fps, 33.3fps, 25fps, and slower.

// frames can be loaded 10 frames can be loaded in 1 se

use image::{DynamicImage, GenericImageView, ImageReader};
use lazy_static::lazy_static;
use log::debug;
use ndarray::{arr1, arr2, Array1, Array2};
use std::cmp::Ordering;
use std::env;
use std::path::Path;

lazy_static! {
    static ref DEFAULT_PALETTE: Array2<u8> = arr2(&[
        [0, 0, 0],
        [29, 43, 83],
        [126, 37, 83],
        [0, 135, 81],
        [171, 82, 54],
        [95, 87, 79],
        [194, 195, 199],
        [255, 241, 232],
        [255, 0, 77],
        [255, 163, 0],
        [255, 236, 39],
        [0, 228, 54],
        [41, 173, 255],
        [131, 118, 156],
        [255, 119, 168],
        [255, 204, 170]
    ]);
    static ref EXTENDED_PALETTE: Array2<u8> = arr2(&[
        [41, 24, 20],
        [17, 29, 53],
        [66, 33, 54],
        [18, 83, 89],
        [116, 47, 41],
        [73, 51, 59],
        [162, 136, 121],
        [243, 239, 125],
        [190, 18, 80],
        [255, 108, 36],
        [168, 231, 46],
        [0, 181, 67],
        [6, 90, 181],
        [117, 70, 101],
        [255, 110, 89],
        [255, 157, 129]
    ]);
}

fn rgba_to_pico8(palette: &Array2<u8>, img: &DynamicImage, x: u32, y: u32) -> usize {
    let pixel: Array1<u8> = arr1(&img.get_pixel(x, y).0);

    let dist = palette
        .rows()
        .into_iter()
        .map(|row| {
            row.iter()
                .zip(pixel.iter())
                .map(|(&c, &p)| (c as f64 - p as f64).powi(2))
                .sum::<f64>()
        })
        .collect::<Vec<f64>>();

    // Find the index of the minimum distance
    let min_index = dist
        .iter()
        .enumerate()
        .min_by(|(_, a), (_, b)| a.partial_cmp(b).unwrap_or(Ordering::Equal))
        .map(|(idx, _)| idx)
        .unwrap();

    // Return the min index.
    // This is a number between 0-15 if using a single palette.
    // could be between 0-31 if combining both palettes.
    min_index
}

// coords for where the label image starts. (16, 24)
// dimensions to verify p8.png file: 160 x 205
pub fn process(filepath: &Path, width: u32, height: u32) -> Vec<u8> {
    let width = width + width%2; // Width is changed because each row must be even since there are 2 pixels per row.
    match process_(filepath, width, height) {
        Err(_) => vec![0; ((width/2)*height) as usize],
        Ok(value) => value,
    }
}

// intermediate function. width must be even
fn process_(filepath: &Path, width: u32, height: u32) -> anyhow::Result<Vec<u8>> {
    let img_path = ImageReader::open(filepath)?;
    let _img_format = img_path.format();
    let img = img_path.decode()?;
    let mut imgdata = vec![0; ((width/2)*height) as usize]; // this is the default value

    // assume these exact dimensions mean the image is a pico8 cartridge.
    if img.width() == 160 && img.height() == 205 {
        let halfwidth = width/2;
        for y in 0..height {
            let img_y = (128.0/(height as f64)*(y as f64)) as u32;
            for x in 0..halfwidth {
                let img_x1 = (128.0/(width as f64)*((x*2+0) as f64)) as u32;
                let img_x2 = (128.0/(width as f64)*((x*2+1) as f64)) as u32;
                // println!("imgy is {} | x is {} | img_x1 is {} | img_x2 is {}", img_y, x, img_x1, img_x2);

                let p1 = rgba_to_pico8(&DEFAULT_PALETTE, &img, 16+img_x1, img_y+24);
                let p2 = rgba_to_pico8(&DEFAULT_PALETTE, &img, 16+img_x2, img_y+24);
                imgdata[(y * halfwidth + x) as usize] = (p2 << 4 | p1) as u8;
            }
        }
    }

    Ok(imgdata)
}

#[cfg(test)]
mod tests {
    use std::path::PathBuf;

    use super::*;

    #[test]
    fn test_printdata() -> anyhow::Result<()> {
        let _cart = process(PathBuf::from("./testcarts/test1.p8.png").as_path(), 128, 128);
        assert_eq!(_cart, [17; 8192]); // 17 means 0b00010001 or 0x11, so dark blue (1) in every pixel, which is what this test cart is
        Ok(())
    }

    #[test]
    fn test_printdata_64() -> anyhow::Result<()> {
        let _cart = process(PathBuf::from("./testcarts/test1.p8.png").as_path(), 64, 64);
        assert_eq!(_cart, [17; 32*64]); // 17 means 0b00010001 or 0x11, so dark blue (1) in every pixel, which is what this test cart is
        Ok(())
    }
}
