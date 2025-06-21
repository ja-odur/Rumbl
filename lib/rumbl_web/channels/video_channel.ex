defmodule RumblWeb.VideoChannel do
  use RumblWeb, :channel

  def join("videos:" <> video_id, _params, socket) do
    :timer.send_interval(5_000, :ping)
    {:ok, socket}
  end

  def handle_in("new_annotation", params, socket) do
    broadcast!(
      socket,
      "new_annotation",
      %{
        user: %{username: "annon"},
        body: params["body"],
        at: params["at"]
      }
    )
    
    {:reply, :ok, socket}
  end
end
