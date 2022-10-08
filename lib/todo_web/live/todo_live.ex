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
    IO.inspect(base64)
    "data:image/jpeg;base64," <> raw = base64
    gray =
      raw
      |> Base.decode64!()
      |> Evision.imdecode!(Evision.cv_IMREAD_GRAYSCALE)

    gray =
      Evision.imencode!(".jpg", gray)
    {:noreply, assign(socket, gray_image: gray)}
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
