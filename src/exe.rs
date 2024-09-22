//! Utilities related to external executables

use anyhow::anyhow;
use serde::{Deserialize, Serialize};
use serde_json::{Map, Value};

use crate::serialize_table;

#[derive(Serialize, Deserialize, Debug)]
pub struct ExeMeta {
    name: String,
    author: String,
    path: String,
}

impl ExeMeta {
    /// Serializes to a lua table
    pub fn to_lua_table(&self) -> anyhow::Result<String> {
        // TODO maybe there's a better way to convert to map?
        let value = serde_json::to_value(self)?;
        if let Value::Object(map) = value {
            Ok(serialize_table(&map))
        } else {
            Err(anyhow!("Failed to convert struct to map"))
        }
    }
}
