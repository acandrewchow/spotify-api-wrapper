import Config

if File.exists?(".env") do
  File.stream!(".env")
  |> Enum.each(fn line ->
    [key, value] = String.split(line, "=", parts: 2)
    System.put_env(String.trim(key), String.trim(value))
  end)
end

config :spotify_playlist_generator,
  client_id: System.fetch_env!("CLIENT_ID"),
  client_secret: System.fetch_env!("CLIENT_SECRET")
