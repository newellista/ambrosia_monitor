defmodule AmbrosiaMonitor.Reporter do
  use GenServer
  require Logger

  def start_link(database, url, _frequency) do
    GenServer.start_link(__MODULE__, {database, url}, name: __MODULE__)
  end

  def init(database, url) do
    :timer.send_interval(5_000, :report_measurements)
    {:ok, %{database: database, url: url}}
  end

  def handle_info(:report_measurements, %{database: _, url: []}=state) do
    {:noreply, state}
  end

  def handle_info(:report_measurements, %{database: database, url: url}=state) do
    case get_new_measurements(database) do
      {:ok, []} -> location("asdf")
      {:ok, records} -> 
        Logger.info "#{inspect records}"
        send_records(database, url, records)
      _ -> Logger.info "Default"
    end

    {:noreply, state}
  end

  defp send_records(database, url, records) do
    body = records |> IO.inspect
      |> Enum.map(&measurement_to_line/1)
      |> Enum.join("\n")

    IO.inspect body
    IO.inspect url
    case :hackney.request(:post, url, [], body, []) do
      {:ok, _status_code, _headers, client_ref} ->
        case :hackney.body(client_ref) do
          {:ok, body} -> 
            IO.inspect "############## Body: #{body}"
            records 
              |> Enum.map(&update_forward_time(&1, database))
          {:error, _status} ->
            Logger.info "Unable to send body"
          _ ->
            Logger.info "Unknown Error"
        end
      {:error, status_code} ->
        Logger.info "Error sending to #{url}: (#{status_code})"
    end
  end

  defp get_new_measurements(database) do
    Sqlitex.with_db(database, fn(db) ->
      Sqlitex.query(db, "SELECT id, serial_number, temperature, timestamp FROM temperature_readings WHERE forwarded_at IS NULL", into: %{})
    end)
  end

  defp measurement_to_line(%{id: _, serial_number: _, temperature: _, timestamp: _}=line) do
    case location(line.serial_number) do
      nil ->
        "temperature,location=Unknown,sensor=#{line.serial_number} value=#{line.temperature} #{line.timestamp}000000"
      {location, sensor_name} ->
        "temperature,location=#{location},sensor=#{sensor_name} value=#{line.temperature} #{line.timestamp}000000"
    end
  end

  defp update_forward_time(%{id: _, serial_number: _, temperature: _, timestamp: _}=line, database) do
    Sqlitex.Server.query(Sqlitex.Server, "UPDATE temperature_readings set forwarded_at=#{:os.system_time(:milli_seconds)} where id=#{line.id}") |> IO.inspect
  end

  defp location(serial) do
    # map serial number of probe to location and sensor name
    nil
  end
end
