defmodule AmbrosiaMonitor.Archiver do
  use GenServer
  require Logger

  def start_link(database) do
    GenServer.start_link(__MODULE__, database, name: __MODULE__)
  end

  def init(database) do
    initialize_database(database)
    initialize_channel
    :timer.send_interval(5_000, :record_temperature)
    {:ok, %{database: database, measurements: []}}
  end

  def handle_info({_, _, _}=measurement, %{database: _, measurements: measurements}=state) do
    {:noreply, %{state | measurements: [measurement | measurements]}}
  end

  def handle_info(:record_temperature, %{database: _, measurements: []}=state) do
    {:noreply, state}
  end
  
  def handle_info(:record_temperature, %{database: database, measurements: measurements}=state) do
    measurements
      |> Enum.map(&store_temperature(&1, database))
    {:noreply, %{state | measurements: []}}
  end

  defp celsius_to_fahrenheit(celsius) do
    32.0 + (1.8 * celsius)
  end

  defp initialize_channel do
    :pg2.create(:thermex_measurements)
    :pg2.join(:thermex_measurements, self())
  end

  defp initialize_database(database) do
    Logger.info "initialize_database"
    Sqlitex.with_db(database, fn(db) ->
      Sqlitex.query(db, "CREATE TABLE IF NOT EXISTS temperature_readings(id INTEGER PRIMARY KEY AUTOINCREMENT, location text, serial_number text, temperature INTEGER, timestamp INTEGER, forwarded_at INTEGER)") |> IO.inspect
    end)
  end

  defp store_temperature({serial, temperature, timestamp}, database) do
    fahrenheit = celsius_to_fahrenheit(temperature)
    Sqlitex.with_db(database, fn(db) ->
      Sqlitex.query(db, "INSERT INTO temperature_readings(serial_number, temperature, timestamp) VALUES('#{serial}', #{fahrenheit}, #{timestamp})") |> IO.inspect
    end)
  end
end
