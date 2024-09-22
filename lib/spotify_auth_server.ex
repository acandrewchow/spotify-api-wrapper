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
    {:ok, body, conn} = Plug.Conn.read_body(conn)
    token = Jason.decode!(body)["token"]
    IO.puts("Received token: #{token}")
    send_resp(conn, 200, "Token stored.")
  end

  # Start the server
  def start_link(_opts) do
    Plug.Cowboy.http(__MODULE__, [], port: 3000)
  end
end
