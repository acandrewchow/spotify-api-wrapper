defmodule SpotifyPlaylistGenerator do
  @moduledoc """
  Documentation for `SpotifyPlaylistGenerator`.

  iex > SpotifyPlaylistGenerator.create_playlist("track_id")
  """

  @base_url "https://api.spotify.com/v1"
  @auth_token "BQAR_S9PeSA_KtbDXYBqCmEnCkoNiEE4e210T3fTqN9kPuTD4T-hdv_nXU9NvtYxeO4qbjtn--hC8qLoJh_riubEYIPmRWT3HjKWkqmugOvcjL366K05KVJLXcvSMKUigMpbwKlnVgpsSMyAVXbc33ooPYH7ZMvpqFm4QMwRHZ-YewomNrS8MhZoIA038JPl5RmCk2GhpDItg-y0QPciEPG0PTSHK1dvujrICVIV4ctYV7TGCecLKSjXFN6LsSI18VM"
  @default_limit 10
  @default_seed_track "4kjI1gwQZRKNDkw1nI475M"

  @spec get_env_configs() :: map()
  def get_env_configs do
    %{
      client_id: System.fetch_env!("CLIENT_ID"),
      client_secret: System.fetch_env!("CLIENT_SECRET")
    }
  end

  @spec extract_auth_token(String.t()) :: String.t() | nil
  def extract_auth_token(url) do
    url
    |> String.split("#")
    |> List.last()
    |> case do
      nil ->
        nil

      fragment ->
        fragment
        |> String.split("&")
        |> Enum.find_value(fn param ->
          [key, value] = String.split(param, "=", parts: 2)
          if key == "access_token", do: value
        end)
    end
  end

  @spec get_track_info(String.t()) :: {:ok, map()} | {:error, String.t()}
  def get_track_info(track_id) do
    make_request("tracks/#{track_id}")
  end

  @doc """
  Retrieves information for an album
  """
  @spec get_album_info(String.t()) :: {:ok, map()} | {:error, String.t()}
  def get_album_info(album_id) do
    make_request("albums/#{album_id}")
  end

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

    case HTTPoison.get(url, authorization_headers()) do
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

    case HTTPoison.post(url, Jason.encode!(body_params), authorization_headers()) do
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

    case HTTPoison.post(url, Jason.encode!(body_params), authorization_headers()) do
      {:ok, %HTTPoison.Response{status_code: 201}} ->
        {:ok, "Tracks added to playlist successfully"}

      {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
        {:error, "Unexpected status code: #{status_code}, body: #{body}"}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp authorization_headers do
    [
      {"Authorization", "Bearer #{@auth_token}"},
      {"Content-Type", "application/json"}
    ]
  end

  defp make_request(endpoint) do
    url = "#{@base_url}/#{endpoint}"

    case HTTPoison.get(url, authorization_headers()) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, Jason.decode!(body)}

      {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
        {:error, "Unexpected status code: #{status_code}, body: #{body}"}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
