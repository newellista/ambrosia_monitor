defmodule AmbrosiaMonitor.Mixfile do
  use Mix.Project

  def project do
    [app: :ambrosia_monitor,
     version: "0.0.1",
     elixir: "~> 1.2",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger, :hackney, :nerves_ssdp_server, :nerves_ssdp_client, :thermex],
     mod: {AmbrosiaMonitor, []}]
  end

  defp deps do
    [
      {:hackney, "~> 1.6"},
      {:thermex, "~> 0.0.1"},
      {:nerves_ssdp_server, git: "https://github.com/nerves-project/nerves_ssdp_server", tag: "v0.2.0"},
      {:nerves_ssdp_client, git: "https://github.com/nerves-project/nerves_ssdp_client", tag: "v0.1.2"},
    ]
  end
end
