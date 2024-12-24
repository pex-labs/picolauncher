use diesel::prelude::*;
use serde::{Deserialize, Serialize};
use serde_json::{Map, Value};

use crate::p8util::serialize_table;

diesel::table! {
    carts(id) {
        id -> Text,
        title -> Text,
        author -> Text,
        likes -> Integer,
        tags -> Text,
        lid -> Text,
        download_url -> Text,
        description -> Text,
        thumb_url -> Text,
        filename -> Text,
        favorite -> Bool,
    }
}

#[derive(Debug, Serialize, Deserialize, Clone, Queryable, Selectable)]
#[diesel(table_name = carts)]
#[diesel(check_for_backend(diesel::sqlite::Sqlite))]
pub struct Cart {
    pub title: String,
    pub author: String,
    pub likes: i32,
    pub tags: String,
    pub lid: String,
    pub download_url: String,
    pub description: String,
    pub thumb_url: String,
    pub filename: String,

    pub favorite: bool,
}

impl Cart {
    pub fn to_lua_table(&self) -> String {
        let mut prop_map = Map::<String, Value>::new();
        prop_map.insert("title".into(), Value::String(self.title.clone()));
        prop_map.insert("author".into(), Value::String(self.author.clone()));
        prop_map.insert(
            "cart_download_url".into(),
            Value::String(self.download_url.clone()),
        );
        prop_map.insert("tags".into(), Value::String(self.tags.clone()));
        prop_map.insert("filename".into(), Value::String(self.filename.clone()));

        serialize_table(&prop_map)
    }
}
