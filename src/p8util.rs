// misc pico8 utilities

use image::{ImageReader, GenericImageView, Pixel, Pixels};
use ndarray::{arr1, Array1, arr2, Array2};
use std::cmp::Ordering;
use std::io::{self, Write};
use std::path::Path;

use lazy_static::lazy_static;
use anyhow::{anyhow, Result};

lazy_static! {
    static ref PALETTE: Array2<u8> = arr2(&[
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
}

// TODO super stupid impl currently, each section is just represented by the entire string
pub struct Cart {
    pub sprite: Vec<String>
}

impl Cart {
    pub fn new() -> Self {
        Self {
            sprite: vec![]
        }
    }

    pub fn write<W: Write>(&self, writer: &mut W) -> anyhow::Result<()> {
        write!(writer, "pico-8 cartridge // http://www.pico-8.com\nversion 42\n__gfx__\n")?;
        for spriteline in self.sprite.iter() {
            writeln!(writer, "{}", spriteline)?;
        }

        Ok(())
    }
}

// convert a screenshot png of size 128x128 to a cartridge
pub fn screenshot2cart(png_path: &Path) -> anyhow::Result<Cart> {
    let img = ImageReader::open(png_path)?.decode()?;

    if img.width() != 128 || img.height() != 128 {
        return Err(anyhow!("Only images of size 128x128 are supported"));
    }

    let mut cart = Cart::new();

    for y in 0..img.height() {
        let mut spriteline = String::new();
        for x in 0..img.width() {
            let rgba: Array1<u8> = arr1(&img.get_pixel(x, y).0);

            let dist = PALETTE
                .rows()
                .into_iter()
                .map(|row| {
                    row.iter()
                        .zip(rgba.iter())
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

            let col = format!("{:x}", min_index);
            spriteline += &col;
        }
        cart.sprite.push(spriteline);
    }

    Ok(cart) 
}

// takes cart with 128x128 sprite in sprite section and downscales it
pub fn downscale_cart(cart: &Cart, size: u8) -> anyhow::Result<Cart> {
    let mut new_cart = Cart::new();

    let step = (128/size) as usize;
    for y in (0..128).step_by(step) {
        let mut spriteline = String::new();
        for x in (0..128).step_by(step) {
            // TODO this is cumbersome and not bounds checked
            let pixel = cart.sprite.get(y).unwrap().chars().nth(x).unwrap(); 
            spriteline += &pixel.to_string();
        }
        new_cart.sprite.push(spriteline);
    }

    Ok(new_cart)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_screenshot2cart() -> anyhow::Result<()> {
        // let cart = screenshot2cart("drive/screenshots/birdswithguns-5_0.png")?;
        Ok(())
    }
}
