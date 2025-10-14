defmodule GCM.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Starts a worker by calling: GCM.Worker.start_link(arg)
      # {GCM.Worker, arg}
      {Bandit, scheme: :http, plug: Router, port: 8080},
      {FM, %{}},
      {Timeout, 200}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: GCM.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
