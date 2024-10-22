defmodule SpotifyPlaylistGenerator do
  @moduledoc """
  Documentation for `SpotifyPlaylistGenerator`.
  """

  alias Helpers.SpotifyHelpers

  @base_url "https://api.spotify.com/v1"

  @doc """
  Generates a playlist of songs related to specific artists.
  Accepts artist names

  ## Parameters

  - `playlist_name`: The name of the playlist to be created. Defaults to "Recommended Playlist".
  - `artist_names`: A list of artist names for which the playlist will be generated.
  - `limit`: The maximum number of tracks to include in the playlist.

  ## Examples

      iex> SpotifyPlaylistGenerator.generate_playlist("My Favorite Playlist", ["Drake", "Adele"], 20)
      {:ok, "Playlist created and tracks added successfully"}

      iex> SpotifyPlaylistGenerator.generate_playlist("Chill Vibes", ["Billie Eilish"], 50)
      {:ok, "Playlist created and tracks added successfully"}

      iex> SpotifyPlaylistGenerator.generate_playlist("Unknown Artists", ["NonExistentArtist"], 10)
      {:error, "Failed to create playlist: No valid artist IDs found"}

  """
  @spec generate_playlist(String.t(), [String.t()], integer()) ::
          {:ok, String.t()} | {:error, String.t()}
  def generate_playlist(playlist_name \\ "Recommended Playlist", artist_names, limit) do
    with {:ok, artist_ids} <- fetch_artist_ids(artist_names),
         query_params = build_query_params(artist_ids, limit),
         {:ok, recommended_tracks} <- fetch_recommendations(query_params),
         {:ok, playlist_data} <- create_playlist(playlist_name),
         {:ok, _added_tracks} <- add_tracks_to_playlist(playlist_data["id"], recommended_tracks) do
      {:ok, "Playlist created and tracks added successfully"}
    else
      {:error, reason} ->
        {:error, "Failed to create playlist: #{reason}"}
    end
  end

  @doc """
  Generates a playlist of songs based on a specific genre.
  Accepts genre name instead of genre ID.

  Note: There's a limit of 1000 songs when generating a playlist

  ## Parameters

  - `playlist_name`: The name of the playlist to be created. Defaults to "Genre Playlist".
  - `genre`: The genre for which the playlist will be generated.
  - `limit`: The maximum number of tracks to include in the playlist.

  ## Examples

      iex> SpotifyPlaylistGenerator.generate_playlist_by_genre("My Rock Playlist", "rock", 20)
      {:ok, "Playlist created and tracks added successfully"}

       iex> SpotifyPlaylistGenerator.generate_playlist_by_genre("Workout Playlist", "work-out", 20)
      {:ok, "Playlist created and tracks added successfully"}

      iex> SpotifyPlaylistGenerator.generate_playlist_by_genre("Chill Vibes", "chill", 50)
      {:ok, "Playlist created and tracks added successfully"}

      iex> SpotifyPlaylistGenerator.generate_playlist_by_genre("Unknown Genre", "unknown_genre", 10)
      {:error, "Failed to create playlist: No tracks found for this genre"}

  """
  @spec generate_playlist_by_genre(String.t(), String.t(), integer()) ::
          {:ok, String.t()} | {:error, String.t()}
  def generate_playlist_by_genre(playlist_name \\ "Genre Playlist", genre, limit) do
    query_params = build_genre_query_params(genre, limit)

    with {:ok, recommended_tracks} <- fetch_recommendations(query_params),
         {:ok, playlist_data} <- create_playlist(playlist_name),
         {:ok, _added_tracks} <- add_tracks_to_playlist(playlist_data["id"], recommended_tracks) do
      {:ok, "Playlist created and tracks added successfully"}
    else
      {:error, reason} ->
        {:error, "Failed to create playlist: #{reason}"}
    end
  end

  defp fetch_artist_ids(artist_names) do
    artist_names
    |> Enum.map(&fetch_artist_id/1)
    |> Enum.reduce([], fn
      {:ok, id}, acc -> [id | acc]
      {:error, _} = error, acc -> acc ++ [error]
    end)
    |> case do
      [] -> {:error, "No valid artist IDs found"}
      artist_ids -> {:ok, artist_ids}
    end
  end

  defp fetch_artist_id(artist_name) do
    url = "#{@base_url}/search?q=#{URI.encode(artist_name)}&type=artist&limit=1"

    case HTTPoison.get(url, SpotifyHelpers.authorization_headers()) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        artist = Jason.decode!(body)["artists"]["items"] |> List.first()
        if artist, do: {:ok, artist["id"]}, else: {:error, "Artist not found"}

      {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
        {:error, "Unexpected status code: #{status_code}, body: #{body}"}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp fetch_recommendations(query_params) do
    url = "#{@base_url}/recommendations?#{query_params}"

    case HTTPoison.get(url, SpotifyHelpers.authorization_headers()) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, Jason.decode!(body)["tracks"]}

      {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
        {:error, "Unexpected status code: #{status_code}, body: #{body}"}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp create_playlist(playlist_name) do
    url = "#{@base_url}/me/playlists"

    body_params = %{
      name: playlist_name,
      description: "Playlist generated by SpotifyPlaylistGenerator",
      public: true
    }

    case HTTPoison.post(url, Jason.encode!(body_params), SpotifyHelpers.authorization_headers()) do
      {:ok, %HTTPoison.Response{status_code: 201, body: body}} ->
        {:ok, Jason.decode!(body)}

      {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
        {:error, "Unexpected status code: #{status_code}, body: #{body}"}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp add_tracks_to_playlist(playlist_id, tracks) do
    url = "#{@base_url}/playlists/#{playlist_id}/tracks"
    track_uris = Enum.map(tracks, &("spotify:track:" <> &1["id"]))
    body_params = %{uris: track_uris}

    case HTTPoison.post(url, Jason.encode!(body_params), SpotifyHelpers.authorization_headers()) do
      {:ok, %HTTPoison.Response{status_code: 201}} ->
        {:ok, "Tracks added to playlist successfully"}

      {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
        {:error, "Unexpected status code: #{status_code}, body: #{body}"}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp build_genre_query_params(genre, limit) do
    [
      {"limit", Integer.to_string(limit)},
      {"seed_genres", genre}
    ]
    |> URI.encode_query()
  end

  defp build_query_params(artist_ids, limit) do
    [
      {"limit", Integer.to_string(limit)},
      {"seed_artists", Enum.join(artist_ids, ",")}
    ]
    |> URI.encode_query()
  end
end
