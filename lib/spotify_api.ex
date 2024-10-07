defmodule SpotifyAPI do
  @moduledoc """
  The `SpotifyAPI` module provides functions to interact with the Spotify Web API.
  Supports retrieving information about artists, albums, tracks, user playlists, top artists and many more.g
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

  defp make_request(endpoint) do
    url = "#{@base_url}/#{endpoint}"

    case HTTPoison.get(url, SpotifyHelpers.authorization_headers()) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, Jason.decode!(body)}

      {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
        {:error, "Unexpected status code: #{status_code}, body: #{body}"}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
