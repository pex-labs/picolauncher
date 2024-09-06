// misc pico8 utilities

use image::{ImageReader, GenericImageView, Pixel, Pixels};
use ndarray::{arr1, Array1, arr2, Array2};
use std::cmp::Ordering;
use std::collections::HashMap;
use std::io::{self, Write, BufRead};
use std::path::Path;
use std::fs::File;

use lazy_static::lazy_static;
use anyhow::{anyhow, Result};
use strum::IntoEnumIterator;
use pino_deref::{Deref, DerefMut};

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

#[derive(strum_macros::Display, strum_macros::EnumIter, Debug, Eq, PartialEq, Hash, Clone, Copy)]
pub enum SectionName {
    Lua,
    Gfx,
    Gff,
    Label,
    Map,
    Sfx,
    Music,
}

impl SectionName {
    pub fn header(&self) -> String {
        format!("__{}__", self.to_string().to_lowercase())
    }
}

#[derive(Deref, DerefMut)]
pub struct Section(Vec<String>);

impl Section {
    pub fn new() -> Self {
        Section(Vec::new())
    }
}

/*
impl ToString for SectionName {
    fn to_string(&self) -> String {
        match self {
            SectionName::Lua => "__lua__",
            SectionName::Gfx => "__gfx__",
            SectionName::Gff => "__gff__",
            SectionName::Label => "__label__",
            SectionName::Map => "__map__",
            SectionName::Sfx => "__sfx__",
            SectionName::Music => "__music__",
        }.into()
    }
}
*/

// TODO super stupid impl currently, each section is just represented by the entire string
pub struct Cart {
    pub sections: HashMap<SectionName, Section>,
}

impl Cart {
    pub fn new() -> Self {
        Self {
            sections: HashMap::new(),
        }
    }

    pub fn get_section(&mut self, section: SectionName) -> &Section {
        let section = self.sections.entry(section).or_insert(Section::new());
        section
    }

    pub fn get_section_mut(&mut self, section: SectionName) -> &mut Section {
        let section = self.sections.entry(section).or_insert(Section::new());
        section
    }

    // Parse a cart file into memory
    pub fn from_file(cart_path: &Path) -> anyhow::Result<Cart> {
        let mut new_cart = Cart::new();
        
        let file = File::open(cart_path)?;

        let reader = io::BufReader::new(file);

        let mut cur_section: Option<SectionName> = None;
        'line: for line in reader.lines() {
            let line = line?;

            for section_name in SectionName::iter() {
                if line == section_name.header() {
                    cur_section = Some(section_name); 
                    continue 'line;
                }
            }

            if let Some(cur_section) = cur_section {
                let sec = new_cart.get_section_mut(cur_section);
                sec.push(line);
            }
        }

        Ok(new_cart)
    }

    pub fn write<W: Write>(&self, writer: &mut W) -> anyhow::Result<()> {
        write!(writer, "pico-8 cartridge // http://www.pico-8.com\nversion 42\n")?;

        for (name, section) in self.sections.iter() {
            write!(writer, "{}\n", name.header())?;

            for line in section.iter() {
                writeln!(writer, "{}", line)?;
            }
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
        let gfx = cart.get_section_mut(SectionName::Gfx);
        gfx.push(spriteline);
    }

    Ok(cart) 
}

fn is_power_of_two(x: u8) -> bool {
    x > 0 && (x & (x - 1)) == 0
}

// takes cart with 128x128 sprite in sprite section and downscales it as well as arranges in sfx
// section
pub fn format_label(cart: &mut Cart, size: u8) -> anyhow::Result<Cart> {
    // check that size is passed as power of 2
    if !is_power_of_two(size) && size <= 128 {
        return Err(anyhow!("size can only be a power of 2"))
    }

    let mut new_cart = Cart::new();
    let gfx = cart.get_section(SectionName::Gfx);
    let new_gfx = new_cart.get_section_mut(SectionName::Gfx);

    let step = (128/size) as usize;
    let mut spriteline = String::new();
    for y in (0..128).step_by(step) {
        for x in (0..128).step_by(step) {
            // TODO this is cumbersome and not bounds checked
            let pixel = gfx.get(y).unwrap().chars().nth(x).unwrap(); 
            spriteline += &pixel.to_string();

            if spriteline.len() >= 128 {
                new_gfx.push(spriteline.clone());
                spriteline.clear();
            }
        }
    }

    Ok(new_cart)
}

// Convert a standard cartridge into a music cart (a cartridge that only contains music data)
pub fn cart2music(cart_path: &Path) -> anyhow::Result<Cart> {
    let mut cart = Cart::from_file(cart_path)?;
    let mut new_cart = Cart::new();

    // copy over sfx and music sections
    if let Some(sec_sfx) = cart.sections.remove(&SectionName::Sfx) {
        new_cart.sections.insert(SectionName::Sfx, sec_sfx);
    }
    if let Some(sec_music) = cart.sections.remove(&SectionName::Music) {
        new_cart.sections.insert(SectionName::Music, sec_music);
    }

    // move label to gfx
    if let Some(sec_label) = cart.sections.remove(&SectionName::Label) {
        new_cart.sections.insert(SectionName::Gfx, sec_label);
    }

    Ok(new_cart)
}

pub fn cart2label(cart_path: &Path) -> anyhow::Result<Cart> {
    let mut cart = Cart::from_file(cart_path)?;
    let mut new_cart = Cart::new();

    // move label to gfx
    if let Some(sec_label) = cart.sections.remove(&SectionName::Label) {
        new_cart.sections.insert(SectionName::Gfx, sec_label);
    }

    let scaled_cart = format_label(&mut new_cart, 64)?;

    Ok(scaled_cart)
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
