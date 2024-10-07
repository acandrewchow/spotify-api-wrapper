defmodule SpotifyPlaylistGenerator do
  @moduledoc """
  Documentation for `SpotifyPlaylistGenerator`.

  iex > SpotifyPlaylistGenerator.create_playlist("track_id")
  """

  alias Helpers.SpotifyHelpers

  @base_url "https://api.spotify.com/v1"
  @default_limit 100
  @default_seed_track "4kjI1gwQZRKNDkw1nI475M"

  @doc """
  Generates a playlist of X songs related to X track
  """
  @spec generate_playlist(String.t(), keyword()) :: {:ok, String.t()} | {:error, String.t()}
  def generate_playlist(playlist_name \\ "Recommended Playlist", opts \\ []) do
    opts = Keyword.merge([limit: @default_limit, seed_tracks: [@default_seed_track]], opts)
    query_params = build_query_params(opts)

    with {:ok, recommended_tracks} <- fetch_recommendations(query_params),
         {:ok, playlist_data} <- create_playlist(playlist_name),
         {:ok, _added_tracks} <- add_tracks_to_playlist(playlist_data["id"], recommended_tracks) do
      {:ok, "Playlist created and tracks added successfully"}
    else
      {:error, reason} ->
        {:error, "Failed to create playlist: #{reason}"}
    end
  end

  defp build_query_params(opts) do
    [
      {"limit", Integer.to_string(opts[:limit])},
      {"seed_tracks", Enum.join(opts[:seed_tracks], ",")}
    ]
    |> URI.encode_query()
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
      description: "This is a new description",
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
end
