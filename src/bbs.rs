use std::{collections::HashMap, fs::File, path::Path, sync::Arc, time::Instant};

use anyhow::{anyhow, Result};
use futures::future::join_all;
use headless_chrome::Tab;
use lazy_static::lazy_static;
use log::debug;
use regex::Regex;
use reqwest::{Client, Url};
use scraper::{Html, Selector};
use tokio::{fs::OpenOptions, io::AsyncWriteExt};

use crate::{
    consts::{GAMES_DIR, LABEL_DIR},
    db::{schema::Cart, DB},
    hal::pico8_export,
    p8util::{cart2label, filename_from_url},
};

lazy_static! {
    static ref GALLERY_RE: Regex = Regex::new(r#"<div id="pdat_(\d+)""#).unwrap();
    static ref PID_RE: Regex = Regex::new(r#"pid=(\d+)"#).unwrap();
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

impl fmt::Display for OrderBy {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            OrderBy::Featured => write!(f, "featured"),
            OrderBy::New => write!(f, "ts"),
        }
    }
}

/// Scrape a given cartridge page
pub async fn scrape_cart(client: &Client, cart_url: &str) -> Result<Cart> {
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
    let likes = likes_text.trim().parse::<i32>().unwrap_or(0);

    //  tags
    let tags_selector = Selector::parse("a[href^=\"?mode=carts&tag=\"]").unwrap();
    let tags = document
        .select(&tags_selector)
        .map(|e| e.inner_html())
        .collect::<Vec<_>>()
        .join(",");

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

    // extract id from url
    println!("{cart_url:?}");
    let captures = PID_RE.captures(cart_url).unwrap();
    let id = captures
        .get(1)
        .ok_or(anyhow::anyhow!("could not find id in cart url"))?
        .as_str();
    let id = id.parse::<i32>()?;

    Ok(Cart {
        id,
        title,
        author,
        likes,
        tags,
        lid,
        download_url: cart_download_url,
        description,
        thumb_url,
        filename: filestem.to_string(),
        favorite: false,
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
        url.push_str(&format!("&orderby={}", orderby));
    }
    url
}

pub async fn crawl_bbs(tab: Arc<Tab>, url: &str) -> Result<Vec<Cart>> {
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
        .truncate(true)
        .write(true)
        .open(dest)
        .await?;
    file.write_all(&bytes).await?;

    Ok(())
}

// TODO this function is pretty similar to the functionality in cli.rs - should aggerate this
pub async fn postprocess_cart(
    db: &mut DB,
    pico8_bins: &Vec<String>,
    cart: &Cart,
    path: &Path,
) -> anyhow::Result<()> {
    // TODO: since path.file_prefix is still unstable, we need to split on the first period
    let filename = path.file_name().unwrap().to_str().unwrap();
    let mut split = filename.splitn(2, ".");
    let filestem = split.next().unwrap();

    // generate p8 file from p8.png file
    let mut dest_path = GAMES_DIR.join(filestem);
    dest_path.set_extension("p8");
    if !dest_path.exists() {
        pico8_export(pico8_bins, path, &dest_path)
            .await
            .map_err(|e| anyhow!("failed to convert cart to p8 from file {path:?}: {e:?}"))?;
    }

    // generate label file
    let mut label_path = LABEL_DIR.join(filestem);
    label_path.set_extension("64.p8");
    if !label_path.exists() {
        let label_cart = cart2label(&dest_path)
            .map_err(|_| anyhow!("failed to generate label cart from {dest_path:?}"))?;

        let mut label_file = File::create(label_path.clone())
            .map_err(|e| anyhow!("failed to create label file {label_path:?}: {e:?}"))?;

        label_cart
            .write(&mut label_file)
            .map_err(|e| anyhow!("failed to write label file {label_path:?}: {e:?}"))?;
    }

    // generate metadata file
    /*
    let mut metadata_path = METADATA_DIR.clone().join(filestem);
    metadata_path.set_extension("json");
    if !metadata_path.exists() {
        let metadata_serialized = serde_json::to_string_pretty(cart).unwrap();

        let mut metadata_file = File::create(metadata_path.clone()).unwrap();
        metadata_file
            .write_all(metadata_serialized.as_bytes())
            .unwrap();
    }
    */

    // save metadata to db
    // TODO might be nicer to do batch insert instead of single query per cart?
    db.insert_cart(cart)?;

    Ok(())
}

// TODO can maybe use the memoize crate, but it's a bit weird with futures
// TODO can also maybe persist to disk and have a TTL option

type BBSCacheEntry = Vec<Cart>;

/// BBS caching
///
/// Store the existing requests in RAM to limit the amount of scraping that needs to be done
/// In particular, this is used to memoize the response of crawl_bbs
pub struct BBSCache {
    /// Key is given by the query string
    cache: HashMap<String, BBSCacheEntry>,
    // TODO can add more functionality like time to live or cache capacity in the future
}

// just a hashmap wrapper for now lol
impl BBSCache {
    pub fn new() -> Self {
        Self {
            cache: HashMap::new(),
        }
    }

    pub fn insert(&mut self, query: &str, data: BBSCacheEntry) {
        self.cache.insert(query.to_owned(), data);
    }

    pub fn query(&self, query: &str) -> Option<&BBSCacheEntry> {
        self.cache.get(query)
    }

    pub fn flush(&mut self) {
        self.cache.clear()
    }
}

impl Default for BBSCache {
    fn default() -> Self {
        Self::new()
    }
}
