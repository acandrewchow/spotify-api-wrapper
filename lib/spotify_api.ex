defmodule SpotifyAPI do
  @moduledoc """
  The `SpotifyAPI` module provides functions to interact with the Spotify Web API.
  Supports retrieving information about artists, albums, tracks, user playlists, top artists, and more.

  Spotify Official Documentation: https://developer.spotify.com/documentation/web-api
  """

  @base_url "https://api.spotify.com/v1"

  alias Helpers.SpotifyHelpers
  alias HTTPoison

  @doc """
  Retrieves information for a given artist using the provided artist ID.

  ## Parameters

  - `artist_id`: The ID of the artist

  ## Examples

      iex> SpotifyAPI.get_artist_info("artist_id")
      {:ok, artist_data}
  """
  @spec get_artist_info(String.t()) :: {:ok, map()} | {:error, String.t()}
  def get_artist_info(artist_id) do
    make_request("artists/#{artist_id}")
  end

  @doc """
  Retrieves a list of new album releases.

  ## Examples

      iex> SpotifyAPI.get_new_releases()
      {:ok, new_releases}
  """
  @spec get_new_releases() :: {:ok, map()} | {:error, String.t()}
  def get_new_releases do
    make_request("browse/new-releases")
  end

  @doc """
  Retrieves information for a track using the provided track ID.

  ## Parameters

  - `track_id`: The ID of the track you want to retrieve information for.

  ## Examples

      iex> SpotifyAPI.get_track_info("track_id")
      {:ok, track_data}
  """
  @spec get_track_info(String.t()) :: {:ok, map()} | {:error, String.t()}
  def get_track_info(track_id) do
    make_request("tracks/#{track_id}")
  end

  @doc """
  Retrieves information for an album using the provided album ID.

  ## Parameters

  - `album_id`: The ID of the album you want to retrieve information for.

  ## Examples

      iex> SpotifyAPI.get_album_info("album_id")
      {:ok, album_data}
  """
  @spec get_album_info(String.t()) :: {:ok, map()} | {:error, String.t()}
  def get_album_info(album_id) do
    make_request("albums/#{album_id}")
  end

  @doc """
  Retrieves the current user's playlists.

  ## Examples

      iex> SpotifyAPI.get_user_playlists()
      {:ok, playlists_data}
  """
  @spec get_user_playlists() :: {:ok, map()} | {:error, String.t()}
  def get_user_playlists do
    make_request("me/playlists")
  end

  @doc """
  Retrieves the current user's top artists.

  ## Examples

      iex> SpotifyAPI.get_user_top_artists()
      {:ok, top_artists}
  """
  @spec get_user_top_artists() :: {:ok, map()} | {:error, String.t()}
  def get_user_top_artists do
    make_request("me/top/artists")
  end

  @doc """
  Retrieves the current user's top tracks.

  ## Examples

      iex> SpotifyAPI.get_user_top_tracks()
      {:ok, top_tracks}
  """
  @spec get_user_top_tracks() :: {:ok, map()} | {:error, String.t()}
  def get_user_top_tracks do
    make_request("me/top/tracks")
  end

  @doc """
  Searches for songs, albums, artists, and more based on a query string.

  ## Parameters

  - `query`: The search query string (e.g., artist name, song title).
  - `type`: A comma-separated list of types to search for (e.g., "track", "album", "artist", "playlist").

  ## Examples

      iex> SpotifyAPI.search("Daft Punk", "track,artist")
      {:ok, search_results}
  """
  @spec search(String.t(), String.t()) :: {:ok, map()} | {:error, String.t()}
  def search(query, type \\ "track") do
    query_params =
      URI.encode_query(%{
        "q" => query,
        "type" => type
      })

    make_request("search?#{query_params}")
  end

  @doc """
  Deletes all playlists of the authenticated user.

  This function retrieves all playlists and sends a delete request for each.

  ## Examples

      iex> SpotifyAPI.delete_all_playlists()
      {:ok, "All playlists deleted successfully"}

      iex> SpotifyAPI.delete_all_playlists()
      {:error, "Failed to delete playlists: <error message>"}
  """
  @spec delete_all_playlists() :: {:ok, String.t()} | {:error, String.t()}
  def delete_all_playlists do
    with {:ok, playlists} <- fetch_playlists(),
         _ <- Enum.each(playlists, &delete_playlist(&1["id"])) do
      {:ok, "All playlists deleted successfully"}
    else
      {:error, reason} -> {:error, "Failed to delete playlists: #{reason}"}
    end
  end

  @spec fetch_playlists() :: {:ok, list(map())} | {:error, String.t()}
  defp fetch_playlists do
    url = "#{@base_url}/me/playlists?limit=50"

    case http_request(:get, url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        playlists = Jason.decode!(body)["items"]
        {:ok, playlists}

      {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
        {:error, "Unexpected status code: #{status_code}, body: #{body}"}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end

  @spec delete_playlist(String.t()) :: :ok | {:error, String.t()}
  defp delete_playlist(playlist_id) do
    url = "#{@base_url}/playlists/#{playlist_id}/followers"

    case http_request(:delete, url) do
      {:ok, %HTTPoison.Response{status_code: 204}} ->
        :ok

      {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
        {:error,
         "Failed to delete playlist #{playlist_id}: Unexpected status code: #{status_code}, body: #{body}"}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end

  @spec make_request(String.t()) :: {:ok, map()} | {:error, String.t()}
  defp make_request(endpoint) do
    url = "#{@base_url}/#{endpoint}"

    case http_request(:get, url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, Jason.decode!(body)}

      {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
        {:error, "Unexpected status code: #{status_code}, body: #{body}"}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end

  @spec http_request(atom(), String.t()) ::
          {:ok, HTTPoison.Response.t()} | {:error, %HTTPoison.Error{}}
  defp http_request(method, url) do
    headers = SpotifyHelpers.authorization_headers()

    case method do
      :get -> HTTPoison.get(url, headers)
      :delete -> HTTPoison.delete(url, headers)
    end
  end
end
