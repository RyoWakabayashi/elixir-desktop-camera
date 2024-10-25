defmodule ElixirDesktopCameraWeb.Layouts do
  @moduledoc """
  This module holds different layouts used by your application.

  See the `layouts` directory for all templates available.
  The "root" layout is a skeleton rendered as part of the
  application router. The "app" layout is set as the default
  layout on both `use ElixirDesktopCameraWeb, :controller` and
  `use ElixirDesktopCameraWeb, :live_view`.
  """
  use ElixirDesktopCameraWeb, :html

  embed_templates "layouts/*"
end
