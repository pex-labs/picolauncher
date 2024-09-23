use std::sync::Arc;

use anyhow::Result;
use headless_chrome::{Browser, LaunchOptions, Tab};
use lazy_static::lazy_static;
use log::warn;
use regex::Regex;
use reqwest::{Client, Url};
use scraper::{Html, Selector};

lazy_static! {
    static ref GALLERY_RE: Regex = Regex::new(r#"<div id="pdat_(\d+)""#).unwrap();
}

#[derive(Debug)]
pub struct CartData {
    pub title: String,
    pub author: String,
    pub likes: u32,
    pub tags: Vec<String>,
    pub lid: String,
    pub cart_download_url: String,
    pub description: String,
    pub thumb_url: String,
}

/// Subsection of BBS
pub enum Sub {
    Chat = 1,
    Releases = 2,
    WIP = 3,
    Collaboration = 4,
    Workshop = 5,
    Bugs = 6,
    Blog = 7,
    Jam = 8,
    CodeSnippets = 9,
    Tutorials = 12,
    GFXSnippets = 14,
    SFXSnippets = 15,
    GIFStream = 16,
    VOB = 17,
}

pub enum OrderBy {
    Featured,
    New,
}

impl ToString for OrderBy {
    fn to_string(&self) -> String {
        match self {
            OrderBy::Featured => String::from("featured"),
            OrderBy::New => String::from("ts"),
        }
    }
}

/// Scrape a given cartridge page
pub async fn scrape_cart(client: &Client, cart_url: &str) -> Result<CartData> {
    // Fetch the cartridge page
    let cart_page = client.get(cart_url).send().await?.text().await?;

    // Parse the HTML content
    let document = Html::parse_document(&cart_page);

    //  title
    let title_selector = Selector::parse("title").unwrap();
    let title = document
        .select(&title_selector)
        .next()
        .map(|e| e.inner_html())
        .unwrap_or_else(|| "No Title".to_string());

    //  author
    let author_selector = Selector::parse("a[href^=\"/bbs/?uid=\"] b").unwrap();
    let author = document
        .select(&author_selector)
        .next()
        .map(|e| e.inner_html())
        .unwrap_or_else(|| "Unknown Author".to_string());

    // Extract number of likes
    let likes_selector = Selector::parse("a[href^=\"#favs\"]").unwrap();
    let likes_text = document
        .select(&likes_selector)
        .next()
        .map(|e| e.inner_html())
        .unwrap_or_else(|| "0".to_string());
    let likes = likes_text.trim().parse::<u32>().unwrap_or(0);

    //  tags
    let tags_selector = Selector::parse("a[href^=\"?mode=carts&tag=\"]").unwrap();
    let tags = document
        .select(&tags_selector)
        .map(|e| e.inner_html())
        .collect::<Vec<_>>();

    //  LID (label id)
    let lid_selector = Selector::parse("img.cart").unwrap();
    let lid = document
        .select(&lid_selector)
        .next()
        .and_then(|e| e.value().attr("src"))
        .and_then(|src| {
            let re = Regex::new(r"bbs/cposts/(\d+)\.p8\.png").unwrap();
            re.captures(src)
                .and_then(|caps| caps.get(1).map(|m| m.as_str().to_string()))
        })
        .unwrap_or_else(|| "No LID".to_string());

    //  cart download link
    let a_selector = Selector::parse("a[href$='.p8.png']").unwrap();
    let cart_download_url = document
        .select(&a_selector)
        .next()
        .and_then(|a| a.value().attr("href"))
        .map(|href| format!("https://www.lexaloffle.com{}", href))
        .unwrap_or_else(|| "No Download URL".to_string());

    //  description
    let desc_selector = Selector::parse("div[style='min-height:44px;']").unwrap();
    let description = if let Some(desc_div) = document.select(&desc_selector).next() {
        let description_text = desc_div
            .text()
            .collect::<Vec<_>>()
            .join("\n")
            .trim()
            .to_string();
        description_text
    } else {
        "No description available.".to_string()
    };

    // extract thumbnail URL
    let img_selector = Selector::parse("img").unwrap();
    let thumb_url = {
        let mut thumb_url = None;
        for img in document.select(&img_selector) {
            if let Some(src) = img.value().attr("src") {
                if src.contains("thumbs") {
                    let base_url = Url::parse("https://www.lexaloffle.com/").unwrap();
                    thumb_url = Some(base_url.join(src).unwrap().to_string());
                    break;
                }
            }
        }
        thumb_url.unwrap_or_else(|| "No Thumbnail URL".to_string())
    };

    Ok(CartData {
        title,
        author,
        likes,
        tags,
        lid,
        cart_download_url,
        description,
        thumb_url,
    })
}

pub fn build_bbs_url(
    sub: Sub,
    page: u32,
    search: Option<String>,
    tag: Option<String>,
    orderby: Option<OrderBy>,
) -> String {
    let mut url = format!(
        "https://www.lexaloffle.com/bbs/?cat=7&carts_tab={}#mode=carts&sub={}",
        page, sub as i32
    );
    if let Some(search) = search {
        if !search.trim().is_empty() {
            url.push_str(&format!("&search={}", urlencoding::encode(&search)));
        }
    }
    if let Some(tag) = tag {
        url.push_str(&format!("&tag={}", urlencoding::encode(&tag)));
    }
    if let Some(orderby) = orderby {
        url.push_str(&format!("&orderby={}", orderby.to_string()));
    }
    url
}

pub async fn crawl_bbs(client: &Client, url: &str) -> Result<Vec<CartData>> {
    let options = LaunchOptions::default_builder()
        .build()
        .expect("Could not find chrome-executable");

    let browser = Browser::new(options)?;

    let tab = browser.new_tab()?;
    tab.navigate_to(url)?;
    tab.wait_for_element(r#"div[id^="pdat_"]"#)?;

    // TODO maybe use regex to find pdat to improve speed
    let content = tab.get_content()?;

    let mut cartdatas = vec![];
    for cap in GALLERY_RE.captures_iter(&content) {
        let pid = cap.get(1).unwrap().as_str();
        println!("Found href: {:?}", pid);
        let cart_url = format!("https://www.lexaloffle.com/bbs/?pid={pid}");
        let Ok(cartdata) = scrape_cart(&client, &cart_url).await else {
            warn!("failed to scrape cart {cart_url}");
            continue;
        };
        cartdatas.push(cartdata);
    }
    /*
    // Old browser agent method
    let mut cart_urls: Vec<String> = vec![];
    for elem in tab.find_elements(r#"div[id^="pdat_"]"#)? {
        let link_elem = elem.find_element(r#"a[href^="/bbs/?pid="]"#)?;
        let cart_path = link_elem.get_attribute_value("href")?.unwrap();
        let cart_url = format!("https://www.lexaloffle.com{}", cart_path);
        cart_urls.push(cart_url);
    }

    for cart_url in cart_urls {
        println!("scraping {cart_url}");
        let Ok(cartdata) = scrape_cart(&client, &cart_url).await else {
            warn!("failed to scrape cart {cart_url}");
            continue;
        };
        cartdatas.push(cartdata);
    }
    */

    Ok(cartdatas)
}
