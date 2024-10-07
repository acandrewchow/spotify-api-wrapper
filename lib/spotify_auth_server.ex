defmodule SpotifyAuthServer do
  use Plug.Router

  plug(:match)
  plug(:dispatch)

  get "/favicon.ico" do
    send_resp(conn, 204, "")
  end

  get "/callback" do
    conn
    |> put_resp_content_type("text/html")
    |> send_file(200, "lib/callback.html")
  end

  post "/store-token" do
    case Plug.Conn.read_body(conn) do
      {:ok, body, conn} ->
        token = Jason.decode!(body)["token"]
        IO.puts("Received token: #{token}")

        # Updates Spotify Auth token for user
        case save_token_to_env(token) do
          :ok -> send_resp(conn, 200, "Token stored.")
          {:error, reason} -> send_resp(conn, 500, "Failed to store token: #{reason}")
        end

      {:more, _body, _conn} ->
        send_resp(conn, 413, "Payload too large")

      {:error, reason} ->
        send_resp(conn, 500, "Error reading body: #{reason}")
    end
  end

  defp save_token_to_env(token) do
    env_path = ".env"

    case File.read(env_path) do
      {:ok, env_content} ->
        new_env_content =
          if String.contains?(env_content, "SPOTIFY_AUTH_TOKEN") do
            Regex.replace(~r/SPOTIFY_AUTH_TOKEN=.*/, env_content, "SPOTIFY_AUTH_TOKEN=#{token}")
          else
            env_content <> "SPOTIFY_AUTH_TOKEN=#{token}\n"
          end

        case File.write(env_path, new_env_content) do
          :ok -> :ok
          {:error, reason} -> {:error, reason}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Starts server
  def start_link(_opts) do
    Plug.Cowboy.http(__MODULE__, [], port: 3000)
  end
end
