# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

# This configuration is loaded before any dependency and is restricted
# to this project. If another project depends on this project, this
# file won't be loaded nor affect the parent project. For this reason,
# if you want to provide default values for your application for
# 3rd-party users, it should be done in your "mix.exs" file.

# You can configure for your application as:
#
#     config :ambrosia_monitor, key: :value
#
# And access this configuration in your application as:
#
#     Application.get_env(:ambrosia_monitor, :key)
#
# Or configure a 3rd-party app:
#
#     config :logger, level: :info
#

# It is also possible to import configuration files, relative to this
# directory. For example, you can emulate configuration per environment
# by uncommenting the line below and defining dev.exs, test.exs and such.
# Configuration from the imported file will override the ones defined
# here (which is why it is important to import them last).
#
#     import_config "#{Mix.env}.exs"

if System.get_env("ambrosia_reporting_url") do
  config :ambrosia_monitor, :config, url: System.get_env("ambrosia_reporting_url")
else
  config :ambrosia_monitor, :config, url: "http://104.131.15.48:8086/write?db=ambrosia_temperatures"
end

if System.get_env("ambrosia_reporting_frequency") do
  config :ambrosia_monitor, :config, frequency: System.get_env("ambrosia_reporting_frequency")
else
  config :ambrosia_monitor, :config, frequency: 30_000
end

if System.get_env("ambrosia_database") do
  config :ambrosia_monitor, :config, database: System.get_env("ambrosia_database")
else
  config :ambrosia_monitor, :config, database: "ambrosia_temps.sqlite3"
end
