defmodule TodoWeb.TodoLive do
  @moduledoc """
    Main live view of our TodoApp. Just allows adding, removing and checking off
    todo items
  """
  use TodoWeb, :live_view
  require Logger

  @impl true

  def mount(_args, _session, socket) do
    todos = TodoApp.Todo.all_todos()
    TodoApp.Todo.subscribe()
    socket =
      socket
      |> assign(:gray_image, nil)
      |> assign(:todos, todos)
    {:ok, socket}
  end

  @impl true
  def handle_info(:changed, socket) do
    todos = TodoApp.Todo.all_todos()
    {:noreply, assign(socket, todos: todos)}
  end

  def handle_event("take", %{"image" => base64}, socket) do
    "data:image/bmp;base64," <> raw = base64
    all =
      raw
      |> Base.decode64!()
      |> Nx.from_binary({:u, 8})

    meta =
      all
      |> Nx.slice([0], [54])
      |> IO.inspect()

    width =
      meta
      |> Nx.slice([18], [4])
      |> IO.inspect()
      |> Nx.to_flat_list()
      |> Enum.with_index
      |> Enum.reduce(0, fn({number, index}, acc) ->
        acc + number * 256 ** index
      end)
      |> IO.inspect()

    height =
      meta
      |> Nx.slice([22], [4])
      |> IO.inspect()
      |> Nx.to_flat_list()
      |> Enum.with_index
      |> Enum.reduce(1, fn({number, index}, acc) ->
        acc + (255 - number) * 256 ** index
      end)
      |> IO.inspect()

    rgba =
      all
      |> Nx.slice([54], [width * height * 4])
      |> Nx.reshape({width, height, 4})

    rgb =
      rgba
      |> Nx.slice([0, 0, 0], [width, height, 3])

    a =
      rgba
      |> Nx.slice([0, 0, 3], [width, height, 1])

    gray =
      rgb
      |> Nx.mean(axes: [-1])
      |> Nx.round()
      |> Nx.tile([3, 1, 1])
      |> Nx.transpose(axes: [1, 2, 0])
      |> Nx.as_type({:u, 8})

    gray =
      [gray, a]
      |> Nx.concatenate(axis: -1)
      |> Nx.flatten()

    gray_all =
      [meta, gray]
      |> Nx.concatenate()
      |> Nx.to_binary()

    {:noreply, assign(socket, gray_image: gray_all)}
  end

  @impl true
  def handle_event("add", %{"text" => ""}, socket) do
    {:noreply, socket}
  end

  def handle_event("add", %{"text" => text}, socket) do
    TodoApp.Todo.add_todo(text, "todo")

    Desktop.Window.show_notification(TodoWindow, "Added todo: #{text}",
      callback: &notification_event/1
    )

    {:noreply, socket}
  end

  def handle_event("toggle", %{"id" => id}, socket) do
    id = String.to_integer(id)
    TodoApp.Todo.toggle_todo(id)
    {:noreply, socket}
  end

  def handle_event("drop", %{"id" => id}, socket) do
    id = String.to_integer(id)
    TodoApp.Todo.drop_todo(id)
    {:noreply, socket}
  end

  def notification_event(action) do
    Desktop.Window.show_notification(TodoWindow, "You did '#{inspect(action)}' me!",
      id: :click,
      type: :warning
    )
  end
end
