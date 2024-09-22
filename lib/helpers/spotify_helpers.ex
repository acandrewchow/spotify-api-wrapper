defmodule Helpers.SpotifyHelpers do
  @moduledoc """
  A collection of functions to provide
  authentication for the Spotify API
  """

  @auth_base_url "https://accounts.spotify.com/authorize"
  @redirect_uri "http://localhost:3000/callback"
  @scopes "user-read-private playlist-read-private playlist-modify-public playlist-modify-private"

  def generate_authorization_url do
    SpotifyAuthServer.start_link([])

    client_id = System.fetch_env!("CLIENT_ID")

    query_params = %{
      client_id: client_id,
      response_type: "token",
      redirect_uri: @redirect_uri,
      scope: @scopes
    }

    query_string = URI.encode_query(query_params)
    auth_url = "#{@auth_base_url}?#{query_string}"

    System.cmd("open", [auth_url])
  end

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

  @spec open_url(String.t()) :: {:ok, String.t()} | {:error, String.t()}
  def open_url(url) do
    case :os.type() do
      # macOS
      {:unix, :darwin} ->
        System.cmd("open", [url])

      # Linux
      {:unix, _} ->
        System.cmd("xdg-open", [url])

      # Windows
      {:win32, _} ->
        System.cmd("cmd", ["/c", "start", url])

      _ ->
        {:error, "Unsupported OS"}
    end
  end
end
