use diesel::prelude::*;

diesel::table! {
    favorites(id) {
        id -> Integer,
        filename -> Text,
    }
}

#[derive(Queryable, Selectable, Debug)]
#[diesel(table_name = favorites)]
#[diesel(check_for_backend(diesel::sqlite::Sqlite))]
pub struct Favorite {
    pub id: i32,
    pub filename: String,
}

#[derive(Insertable)]
#[diesel(table_name = favorites)]
pub struct NewFavorite<'a> {
    pub filename: &'a str,
}
