require IEx

defmodule AmbrosiaMonitor do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false
    
    children = case Application.get_env(:ambrosia_monitor, :config) do
      [url: url] -> [
        worker(AmbrosiaMonitor.Archiver, [url]), 
      ]
      nil -> Process.exit(self, "Invalid Environment")
    end

    opts = [strategy: :one_for_one, name: AmbrosiaMonitor.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
