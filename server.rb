require "sinatra"
require "pg"
require "pry"

configure :development do
  set :db_config, { dbname: "movies" }
end

configure :test do
  set :db_config, { dbname: "movies_test" }
end

def db_connection
  begin
    connection = PG.connect(Sinatra::Application.db_config)
    yield(connection)
  ensure
    connection.close
  end
end

get "/" do
  erb :index
end

get "/actors" do

  @actors = []

  db_connection do |conn|
    @actors = conn.exec("SELECT * FROM actors;")
  end

  erb :'actors/index'
end

get "/actors/:id" do
  @actor_data = []

  db_connection do |conn|
    @actor_data = conn.exec("SELECT * FROM actors WHERE actors.id = ($1)", [params["id"]]).first
  end

  @actor_movies = []

  db_connection do |conn|
      @actor_movies = conn.exec("SELECT movies.id, movies.title, movies.year, cast_members.character
      FROM movies JOIN cast_members ON movies.id = cast_members.movie_id
      JOIN actors ON cast_members.actor_id = actors.id
      WHERE actors.id = ($1)
      ORDER BY movies.title", [params["id"]])
    end

  erb :'actors/show'
end

get "/movies" do
  @movies = []

  db_connection do |conn|
    @movies = conn.exec("SELECT movies.id, movies.title, movies.year, movies.rating, genres.name AS genre, studios.name AS studio
    FROM movies
    LEFT JOIN genres ON movies.genre_id = genres.id
    LEFT JOIN studios ON movies.studio_id = studios.id;")
  end

  erb :'movies/index'
end

get "/movies/:movie_id" do
  @movie_data = []

  db_connection do |conn|
    @movie_data = conn.exec("SELECT movies.title, movies.year, movies.rating, genres.name AS genre, studios.name AS studio, cast_members.character, actors.name AS actor, actors.id AS actor_id
    FROM movies
    JOIN cast_members ON movies.id = cast_members.movie_id
    JOIN actors ON cast_members.actor_id = actors.id
    LEFT JOIN genres ON movies.genre_id = genres.id
    LEFT JOIN studios ON movies.studio_id = studios.id
    WHERE movies.id = ($1)", [params["movie_id"]]).first
  end


  erb :'movies/show'
end
