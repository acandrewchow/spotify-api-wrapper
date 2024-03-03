# SpotifyPlaylistGenerator

**TODO: Add description**

## Prerequisites

1. Ensure you have a developer account for Spotify in order to generate a `CLIENT_ID` and `CLIENT_SECRET`
2. Create an URL for authorization - each auth token lasts 6 hours once generated
    - Example link: https://accounts.spotify.com/authorize?client_id=YOUR_CLIENT_ID&response_type=token&redirect_uri=YOUR_CALLBACK_URI&scope=user-read-private%20playlist-read-private%20playlist-modify-public%20playlist-modify-private&state=YOUR_STATE
    - Copy the Auth Token in the URL into the module atribute `@auth_token`
3. Replace `CLIENT_ID` and `CLIENT_SECRET` in with your values in `config/runtime.exs`
4. 
 
## To Run

1. Run iex with `iex -S mix`
2. `SpotifyPlaylistGenerator.generate_playlist("Playlist name")`

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

