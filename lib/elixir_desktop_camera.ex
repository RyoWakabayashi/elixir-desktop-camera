defmodule ElixirDesktopCamera do
  use Application

  def config_dir() do
    Path.join([Desktop.OS.home(), ".config", "elixir_desktop_camera"])
  end

  @app Mix.Project.config()[:app]
  def start(:normal, []) do
    File.mkdir_p!(config_dir())

    :session = :ets.new(:session, [:named_table, :public, read_concurrency: true])

    children = [
      {Phoenix.PubSub, name: ElixirDesktopCamera.PubSub},
      {Finch, name: ElixirDesktopCamera.Finch},
      ElixirDesktopCameraWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: ElixirDesktopCamera.Supervisor]
    {:ok, sup} = Supervisor.start_link(children, opts)

    {:ok, {_ip, port}} = Bandit.PhoenixAdapter.server_info(ElixirDesktopCameraWeb.Endpoint, :http)

    {:ok, _} =
      Supervisor.start_child(sup, {
        Desktop.Window,
        [
          app: @app,
          id: ElixirDesktopCameraWindow,
          title: "elixir_desktop_camera",
          size: {400, 800},
          url: "http://localhost:#{port}"
        ]
      })
  end

  def config_change(changed, _new, removed) do
    ElixirDesktopCameraWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
