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
  def handle_event("take", %{"pixel" => pixel}, socket) do
    width = 400

    # ピクセルデータをテンソルに変換
    pixel_tensor =
      "<<#{pixel}>>"
      |> Code.eval_string()
      |> elem(0)
      |> Nx.from_binary({:u, 8})

    {length} = Nx.shape(pixel_tensor)
    height = div(length, width * 4)

    pixel_tensor = Nx.reshape(pixel_tensor, {width, height, 4})
    alpha_tensor = Nx.slice_along_axis(pixel_tensor, 3, 1, axis: -1)

    # グレースケールに変換
    gray_tensor =
      pixel_tensor
      |> Nx.slice_along_axis(0, 3, axis: -1)
      |> Nx.mean(axes: [-1], keep_axes: true)
      |> Nx.as_type({:u, 8})

    # ピクセルデータに変換
    gray_pixel =
      [gray_tensor, gray_tensor, gray_tensor, alpha_tensor]
      |> Nx.concatenate(axis: -1)
      |> Nx.to_flat_list()

    {:reply, %{image: gray_pixel}, socket}
  end
end
