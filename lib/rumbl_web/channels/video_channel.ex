defmodule RumblWeb.VideoChannel do
  
  use RumblWeb, :channel
  alias Rumbl.{Accounts, Multimedia}

  def join("videos:" <> video_id, params, socket) do
    send(self(), :after_join)
    last_seen_id = params["last_seen_id"] || 0
    video_id = String.to_integer(video_id)
    video = Multimedia.get_video!(video_id)
    
    annotations = 
      video 
      |> Multimedia.list_annotations(last_seen_id)
      |> RumblWeb.AnnotationJSON.annotations()
      
    {:ok, %{annotations: annotations}, assign(socket, :video_id, video_id)}
  end
  
  def handle_info(:after_join, socket) do
    push(socket, "presence_state", RumblWeb.Presence.list(socket))
    {:ok, _} = RumblWeb.Presence.track(
      socket,
      socket.assigns.user_id,
      %{device: "browser"}
    )
    {:noreply, socket}
  end
  
  def handle_in(event, params, socket) do
    user = Accounts.get_user!(socket.assigns.user_id)
    handle_in(event, params, user, socket)
  end

  def handle_in("new_annotation", params, user, socket) do
    case Multimedia.annotate_video(user, socket.assigns.video_id, params) do
      {:ok, annotation} ->
        broadcast!(
          socket, 
          "new_annotation",
          %{
            id: annotation.id,
            user: RumblWeb.UserJSON.show(user),
            body: annotation.body,
            at: annotation.at
          }
        )
        {:reply, :ok, socket}
        
      {:error, changeset} ->
        {:reply, {:error, %{errors: changeset}}, socket}
    end
  end
end
