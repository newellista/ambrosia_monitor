defmodule AmbrosiaMonitor.Archiver do
  use GenServer
  require Logger

  def start_link() do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(_) do
    initialize_database
    initialize_channel
    :timer.send_interval(5_000, :record_temperature)
    {:ok, %{measurements: []}}
  end

  def handle_info(:record_temperature, %{measurements: []}=state) do
    Logger.info "Nothing to record"
    {:noreply, state}
  end
  
  def handle_info(:record_temperature, %{measurements: measurements}=state) do
    store_temperature(measurements)
    {:noreply, %{state | measurements: []}}
  end

  defp celsius_to_fahrenheit(celsius) do
    32.0 + (1.8 * celsius)
  end

  defp initialize_channel do
    :pg2.create(:thermex_measurements)
    :pg2.join(:thermex_measurements, self())
  end

  defp initialize_database do
    Logger.info "initialize_database"
    Sqlitex.Server.query(Sqlitex.Server, "CREATE TABLE IF NOT EXISTS temperature_readings(id INTEGER PRIMARY KEY AUTOINCREMENT, location text, serial_number text, temperature INTEGER, timestamp INTEGER, forwarded_at INTEGER)") |> IO.inspect
  end

  defp store_temperature({location, serial, temperature, timestamp}) do
    fahrenheit = celsius_to_fahrenheit(temperature)
    Sqlitex.Server.query(Sqlitex.Server, "INSERT INTO temperature_readings(location, serial_number, temperature, timestamp) VALUES(#{location}, #{serial}, #{fahrenheit}, #{timestamp})") |> IO.inspect
  end
end
