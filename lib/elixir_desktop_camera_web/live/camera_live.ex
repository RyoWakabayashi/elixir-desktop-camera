defmodule ElixirDesktopCameraWeb.CameraLive do
  use ElixirDesktopCameraWeb, :live_view

  @impl true
  def mount(_args, _session, socket) do
    socket
    |> assign(gray_image: nil)
    |> then(&{:ok, &1})
  end

  # 写真撮影時の処理
  # 画像をグレースケールに変換する
  @impl true
  def handle_event("take", %{"image" => base64}, socket) do
    IO.inspect(base64)
    "data:image/jpeg;base64," <> raw = base64
    gray =
      raw
      |> Base.decode64!()
      |> Evision.imdecode(Evision.Constant.cv_IMREAD_GRAYSCALE)

    gray =
      Evision.imencode(".jpg", gray)
    {:noreply, assign(socket, gray_image: gray)}
  end
end
