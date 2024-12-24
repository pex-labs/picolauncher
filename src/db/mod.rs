mod schema;

use std::path::Path;

use anyhow;
use diesel::prelude::*;
use schema::*;

// TODO create initial db migration

pub static DB_PATH: &'static str = "./db.sqlite";

pub struct DB {
    conn: SqliteConnection,
}

impl DB {
    pub fn connect(db_path: &str) -> anyhow::Result<DB> {
        let conn = SqliteConnection::establish(db_path)?;
        Ok(DB { conn })
    }

    pub fn add_favorite(&mut self, filename: &str) -> anyhow::Result<()> {
        diesel::insert_into(schema::favorites::table)
            .values(&NewFavorite { filename })
            .returning(Favorite::as_returning())
            .execute(&mut self.conn)?;

        Ok(())
    }

    pub fn get_favorites(&mut self) -> anyhow::Result<()> {
        let favorites = favorites::dsl::favorites
            .select(Favorite::as_select())
            .load(&mut self.conn)?;

        println!("results {favorites:?}");

        Ok(())
    }
}
