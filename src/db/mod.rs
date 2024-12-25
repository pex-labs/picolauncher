mod schema;

use std::path::Path;

use anyhow;
use diesel::prelude::*;
pub use schema::Cart;
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

    /*
    pub fn add_favorite(&mut self, filename: &str) -> anyhow::Result<()> {
        diesel::insert_into(schema::favorites::table)
            .values(&NewFavorite { filename })
            .returning(Favorite::as_returning())
            .execute(&mut self.conn)?;

        Ok(())
    }

    pub fn del_favorite(&mut self, filename: &str) -> anyhow::Result<()> {
        Ok(())
    }

    pub fn get_favorites(&mut self) -> anyhow::Result<()> {
        let favorites = favorites::dsl::favorites
            .select(Favorite::as_select())
            .load(&mut self.conn)?;

        println!("results {favorites:?}");

        Ok(())
    }
    */

    pub fn migrate(&mut self) -> anyhow::Result<()> {
        let sql = r#"
            CREATE TABLE IF NOT EXISTS carts (
                id TEXT PRIMARY KEY,
                title TEXT NOT NULL,
                author TEXT NOT NULL,
                likes INTEGER NOT NULL,
                tags TEXT NOT NULL,
                lid TEXT NOT NULL,
                download_url TEXT NOT NULL,
                description TEXT NOT NULL,
                thumb_url TEXT NOT NULL,
                filename TEXT NOT NULL,
                favorite BOOLEAN NOT NULL
            );
        "#;

        diesel::sql_query(sql).execute(&mut self.conn)?;

        Ok(())
    }

    pub fn insert_cart(&mut self, cart: &Cart) -> anyhow::Result<()> {
        diesel::insert_into(schema::carts::table)
            .values(cart)
            .on_conflict(crate::db::carts::id)
            .do_update()
            .set(cart)
            .execute(&mut self.conn)?;

        Ok(())
    }
    // TODO need to avoid sql injections LOL
    pub fn insert_carts(&mut self, carts: &Vec<Cart>) -> anyhow::Result<()> {
        diesel::insert_into(schema::carts::table)
            .values(carts)
            .execute(&mut self.conn)?;

        Ok(())
    }

    pub fn get_conn(&mut self) -> &mut SqliteConnection {
        &mut self.conn
    }
}
