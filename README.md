# SpotifyPlaylistGenerator

SpotifyPlaylistGenerator is a simple elixir application that allows users to generate playlists based on a given track. 


## Requirements
1. Have Elixir Installed
  - Instructions to install Elixir can be found here: https://elixir-lang.org/install.html


## Prerequisites
1. Create a Spotify Account
2. Access the Spotify Developer Dashboard to create a new project
3. Ensure that you have a `CLIENT_ID` and `CLIENT_SECRET` for the corresponding spotify application
4. Set your Redirect URI to `http://localhost:3000/callback`

## Setup
1. Clone the repository `git clone https://github.com/acandrewchow/spotify_playlist_generator`
2. Create a .env file in the main directory with the following contents:
  ``` bash
  CLIENT_ID=YOUR_CLIENT_ID
  CLIENT_SECRET=YOUR_CLIENT_SECRET
  ```

 
## To Run

1. Run the elixir iex terminal with `iex -S mix`
2. Create an URL for authorization - each auth token lasts 6 hours once generated
    - Example link: https://accounts.spotify.com/authorize?client_id=YOUR_CLIENT_ID&response_type=token&redirect_uri=YOUR_CALLBACK_URI&scope=user-read-private%20playlist-read-private%20playlist-modify-public%20playlist-modify-private&state=YOUR_STATE
    - You will need to replace replace `YOUR_CLIENT_ID` and `YOUR_CALLBACK_URI` with your values 
3. Generate an authentication token that we'll need in order to perform actions within the API
4. Extract the auth token: `auth_token = SpotifyPlaylistGenerator.extract_auth_token(url)`
6. Copy the auth token and update the @auth_token module attribute on line 9
7. Recompile the file using `recompile`
8. `SpotifyPlaylistGenerator.generate_playlist("Playlist name")`

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `spotify_playlist_generator` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:spotify_playlist_generator, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/spotify_playlist_generator>.

