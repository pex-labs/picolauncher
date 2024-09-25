use std::{
    path::{Path, PathBuf},
    sync::Arc,
    time::Instant,
};

use anyhow::Result;
use futures::future::join_all;
use headless_chrome::{Browser, LaunchOptions, Tab};
use lazy_static::lazy_static;
use log::{debug, warn};
use regex::Regex;
use reqwest::{Client, Url};
use scraper::{Html, Selector};
use serde::Serialize;
use serde_json::{Map, Value};
use tokio::{fs::OpenOptions, io::AsyncWriteExt};

use crate::p8util::serialize_table;

lazy_static! {
    static ref GALLERY_RE: Regex = Regex::new(r#"<div id="pdat_(\d+)""#).unwrap();
}

#[derive(Debug, Serialize, Clone)]
pub struct CartData {
    pub title: String,
    pub author: String,
    pub likes: u32,
    pub tags: Vec<String>,
    pub lid: String,
    pub download_url: String,
    pub description: String,
    pub thumb_url: String,
    pub filename: String,
}

impl CartData {
    pub fn to_lua_table(&self) -> String {
        let mut prop_map = Map::<String, Value>::new();
        prop_map.insert("title".into(), Value::String(self.title.clone()));
        prop_map.insert("author".into(), Value::String(self.author.clone()));
        prop_map.insert(
            "cart_download_url".into(),
            Value::String(self.download_url.clone()),
        );
        prop_map.insert("tags".into(), Value::String(self.tags.join(",")));
        prop_map.insert("filename".into(), Value::String(self.filename.clone()));

        serialize_table(&prop_map)
    }
}

/// The schema for the metadata json files present in drive/carts/metadata
// TODO should combine this with CartData struct
#[derive(Serialize)]
pub struct Metadata {
    pub name: String,
    pub filename: String,
    pub author: String,
    pub tags: String,
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

    // can extract filename from the download url
    let filename = filename_from_url(&cart_download_url).unwrap();
    let mut split = filename.splitn(2, ".");
    let filestem = split.next().unwrap();

    Ok(CartData {
        title,
        author,
        likes,
        tags,
        lid,
        download_url: cart_download_url,
        description,
        thumb_url,
        filename: filestem.to_string(),
    })
}

pub fn build_bbs_url(
    sub: Sub,
    page: u32,
    search: Option<String>,
    tag: Option<String>,
    orderby: Option<OrderBy>,
) -> String {
    // cat=7 : refers to pico8 carts (6 is voxatron, 7 is picotron)
    // carts_tab=1 : pagination
    // sub=2 : carts (1 chat, 2 releases, 3 work in progress, 4 collaboration, 5 workshop, 6 bugs, 7 blog,
    // 8 jam, 9 code snippets, 10 :: (?), 11 :: (?), 12 tutorials, 13 (?), 14 gfx snippets, 15 sfx
    //   snippets, 16 gif stream, 17 VOB, 18 :: (?), onwards not used)
    // mode=carts : show cartridges
    // orderby=featured, orderby=ts, orderby=favourites
    // cc4=1 : filter by CC4 license
    // search= : filter by some term
    // tag= : include tag
    let mut url = format!(
        "https://www.lexaloffle.com/bbs/?cat=7#page={}&mode=carts&sub={}",
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

pub async fn crawl_bbs(tab: Arc<Tab>, url: &str) -> Result<Vec<CartData>> {
    let browser_context_id = tab.get_browser_context_id().unwrap();
    debug!("browser context id for tab: {:?}", browser_context_id);

    let start = Instant::now();
    tab.navigate_to(url)?;
    debug!("navigate took: {:?}", start.elapsed());

    //let start = Instant::now();
    //tab.wait_until_navigated()?;
    //debug!("wait until navigated took: {:?}", start.elapsed());

    let start = Instant::now();
    // TODO maybe employ a timeout/retry mechanic here?
    tab.wait_for_element(r#"div[id^="pdat_"]"#)?;
    debug!("wait for element took: {:?}", start.elapsed());

    // TODO maybe use regex to find pdat to improve speed
    let content = tab.get_content()?;

    // TODO this loop is the bottleneck - it needs to visit every page and grab the cartdata
    // either grab all the carts in parallel or make wrapper microservice that scrapes bbs every so often
    let mut tasks = vec![];
    for cap in GALLERY_RE.captures_iter(&content) {
        // TODO not great that we are making a new client for each request
        let client = reqwest::Client::new();

        let pid = cap.get(1).unwrap().as_str();
        // println!("Found href: {:?}", pid);
        let cart_url = format!("https://www.lexaloffle.com/bbs/?pid={pid}");
        let task = tokio::spawn(async move {
            let start = Instant::now();
            let cartdata = scrape_cart(&client, &cart_url).await;
            debug!("scrape cart {:?} took: {:?}", &cart_url, start.elapsed());
            cartdata
        });
        tasks.push(task);
    }

    let start = Instant::now();
    let results = join_all(tasks).await;
    debug!("scrape each cart page took: {:?}", start.elapsed());

    // TODO could add some log if any cards were dropped due to errors?
    let cartdatas = results
        .into_iter()
        .filter_map(|x| x.ok())
        .filter_map(|x| x.ok())
        .collect();

    Ok(cartdatas)
}

/// Downloads file from url to given directory
pub async fn download_cart(client: Client, url: String, dest: &Path) -> anyhow::Result<()> {
    let res = client.get(url).send().await?;
    let bytes = res.bytes().await?;
    let mut file = OpenOptions::new()
        .create(true)
        .write(true)
        .open(dest)
        .await?;
    file.write_all(&bytes).await?;

    Ok(())
}

/// Extract the filename of the file to be downloaded from a given url
pub fn filename_from_url(url: &str) -> Option<String> {
    let parsed = Url::parse(url).ok()?;
    let segments = parsed.path_segments()?;
    segments.last().map(|name| name.to_string())
}
