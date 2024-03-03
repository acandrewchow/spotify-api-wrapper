defmodule SpotifyPlaylistGenerator do
  @moduledoc """
    Documentation for `SpotifyPlaylistGenerator`.

    iex > SpotifyPlaylistGenerator.create_playlist("track_id")
  """
  # https://accounts.spotify.com/authorize?client_id=YOUR_CLIENT_ID&response_type=token&redirect_uri=YOUR_CALLBACK_URI&scope=user-read-private%20playlist-read-private%20playlist-modify-public%20playlist-modify-private&state=YOUR_STATE
  @token_url "https://accounts.spotify.com/api/token"
  @auth_token ""

  @doc """
    Retrieves information for a track
  """
  def get_track_info(track_id) do
    {:ok, access_token} = get_spotify_access_token()
    url = "https://api.spotify.com/v1/tracks/#{track_id}"

    headers = authorization_headers(access_token)

    response = HTTPoison.get(url, headers)

    case response do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, Jason.decode!(body)}

      {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
        {:error, "Unexpected status code: #{status_code}, body: #{body}"}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
    Retrieves information for an album
  """
  def get_album_info(album_id) do
    url = "https://api.spotify.com/v1/albums/#{album_id}"

    {:ok, access_token} = get_spotify_access_token()

    headers = authorization_headers(access_token)

    response = HTTPoison.get(url, headers)

    case response do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, Jason.decode!(body)}

      {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
        {:error, "Unexpected status code: #{status_code}, body: #{body}"}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
    Generates a playlist of X songs related to X track
  """
  def generate_playlist(playlist_name \\ "Recommended Playlist", opts \\ %{}) do
    {:ok, access_token} = get_spotify_access_token()

    url = "https://api.spotify.com/v1/recommendations"

    headers = authorization_headers(access_token)

    # Construct the query string based on a track for a recommendation
    query_params = [
      {"limit", Integer.to_string(Map.get(opts, :limit, 100))},
      {"seed_tracks", Enum.join(Map.get(opts, :seed_tracks, ["4kjI1gwQZRKNDkw1nI475M"]), ",")}
    ]

    url_with_query = "#{url}?#{URI.encode_query(query_params)}"

    response = HTTPoison.get(url_with_query, headers)

    case response do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        recommended_tracks = Jason.decode!(body)["tracks"]

        {:ok, playlist_data} = create_playlist(playlist_name)

        playlist_map = Jason.decode!(playlist_data)

        IO.inspect(playlist_map)

        {:ok, _added_tracks} =
          add_tracks_to_playlist(
            Map.get(playlist_map, "id"),
            recommended_tracks,
            @auth_token
          )

      {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
        {:error, "Unexpected status code: #{status_code}, body: #{body}"}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp create_playlist(playlist_name) do
    url = "https://api.spotify.com/v1/me/playlists"

    headers = authorization_headers(@auth_token)

    body_params = %{
      name: playlist_name,
      description: "This is a new description",
      public: true
    }

    response = HTTPoison.post(url, Jason.encode!(body_params), headers)

    IO.inspect(response)

    case response do
      {:ok, %HTTPoison.Response{status_code: 201, body: body}} ->
        {:ok, body}

      {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
        {:error, "Unexpected status code: #{status_code}, body: #{body}"}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp authorization_headers(access_token) do
    [
      {"Authorization", "Bearer #{access_token}"},
      {"Content-Type", "application/json"}
    ]
  end

  defp get_spotify_access_token do
    body_params = [
      grant_type: "client_credentials",
      client_id: Application.get_env(:spotify_playlist_generator, :client_id),
      client_secret: Application.get_env(:spotify_playlist_generator, :client_secret)
    ]

    headers = ["Content-Type": "application/x-www-form-urlencoded"]

    response = HTTPoison.post(@token_url, URI.encode_query(body_params), headers)

    case response do
      {:ok, %HTTPoison.Response{body: body}} ->
        {:ok, Jason.decode!(body)["access_token"]}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp add_tracks_to_playlist(playlist_id, tracks, access_token) do
    url = "https://api.spotify.com/v1/playlists/#{playlist_id}/tracks"
    headers = authorization_headers(access_token)

    IO.inspect(playlist_id)

    track_uris = Enum.map(tracks, &("spotify:track:" <> &1["id"]))

    body_params = %{
      uris: track_uris
    }

    response = HTTPoison.post(url, Jason.encode!(body_params), headers)

    case response do
      {:ok, %HTTPoison.Response{status_code: 201, body: _body}} ->
        {:ok, "Tracks added to playlist successfully"}

      {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
        {:error, "Unexpected status code: #{status_code}, body: #{body}"}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
