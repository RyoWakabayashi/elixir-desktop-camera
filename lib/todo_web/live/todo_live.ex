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

  def handle_event("take", %{"data" => raw}, socket) do
    pixel =
      raw
      |> Map.to_list()
      |> Enum.map(fn {k, v} -> {String.to_integer(k), v} end)
      |> Enum.sort()
      |> Enum.map(fn {_k, v} -> v end)
      |> Nx.tensor()

    {row} = Nx.shape(pixel)
    pixel =
      pixel
      |> Nx.reshape({div(row, 4), 4})

    gray =
      pixel
        |> Nx.mean(axes: [-1])
        |> Nx.round()
        |> Nx.as_type({:u, 8})
        |> Nx.to_flat_list()
        |> Enum.map(fn avg -> [avg, avg, avg] end)
        |> Nx.tensor()

      a = Nx.slice_along_axis(pixel, 4, 1, axis: -1)

      gray =
        Nx.concatenate([gray, a], axis: -1)
        |> Nx.to_flat_list()

    {:reply, %{image: gray}, socket}
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
