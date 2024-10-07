# SpotifyAPIWrapper

SpotifyAPIWrapper is an Elixir application that interacts with the Spotify Web API, allowing users to manage and generate personalized playlists, fetch user-specific data and many more. This application simplifies authentication, playlist creation, and track management using Spotify’s API by providing a convenient wrapper for developers to easily integrate Spotify’s functionality into their own projects.

## Requirements
1. Have Elixir Installed
  - Instructions to install Elixir can be found here: https://elixir-lang.org/install.html
2. Have Git Installed
  - Installations to install Git can be found here: https://git-scm.com/book/en/v2/Getting-Started-Installing-Git

## Prerequisites
1. Create a Spotify Account
2. Access the Spotify Developer Dashboard to create a new project
3. Ensure that you have a `CLIENT_ID` and `CLIENT_SECRET` for your spotify application
4. Set your Redirect URI to `http://localhost:3000/callback`

## Setup
1. Clone the repository `git clone https://github.com/acandrewchow/spotify_api_wrapper`
2. Create a .env file in the main directory with the following contents:
  ``` bash
  CLIENT_ID=YOUR_CLIENT_ID
  CLIENT_SECRET=YOUR_CLIENT_SECRET
  SPOTIFY_AUTH_TOKEN=AUTO_POPULATED
  ```

## To Create a Playlist

1. Open the interactive elixir `iex` terminal with `iex -S mix`
2. Generate an authentication token that we'll need in order to perform requests within the API
    - `Helpers.SpotifyHelpers.generate_authorization_url`
  Next, generate a playlist!
3. `SpotifyPlaylistGenerator.generate_playlist("Playlist name")`

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `spotify_api_wrapper` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:spotify_api_wrapper, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/spotify_api_wrapper>.

