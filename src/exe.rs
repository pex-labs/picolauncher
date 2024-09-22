//! Utilities related to external executables

use serde::Deserialize;

#[derive(Deserialize, Debug)]
pub struct ExeMeta {
    name: String,
    author: String,
    path: String,
}
