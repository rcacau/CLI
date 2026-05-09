defmodule AgendaCli.Application do
  use Application

  def start(_type, _args) do
    autostart? = Mix.env() != :test and System.get_env("AGENDA_CLI_AUTOSTART", "true") == "true"
    children = if autostart?, do: [{Task, fn -> AgendaCli.main([]) end}], else: []
    Supervisor.start_link(children, strategy: :one_for_one, name: AgendaCli.Supervisor)
  end
end
