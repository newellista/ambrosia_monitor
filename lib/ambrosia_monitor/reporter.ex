defmodule AmbrosiaMonitor.Reporter do
  use GenServer
  require Logger

  def start_link(url, _frequency) do
    GenServer.start_link(__MODULE__, url, name: __MODULE__)
  end

  def init(url) do
    :timer.send_interval(5_000, :report_measurements)
    {:ok, %{url: url}}
  end

  def handle_info(:report_measurements, %{url: []}=state) do
    {:noreply, state}
  end

  def handle_info(:report_measurements, %{url: url}=state) do
    case get_new_measurements do
      {:ok, []} -> Logger.info "Nothing to report"
      {:ok, records} -> 
        Logger.info "#{inspect records}"
        send_records(url, records)
      _ -> Logger.info "Default"
    end

    {:noreply, state}
  end

  defp send_records(url, records) do
    body = Enum.map(records)
      |> Enum.map(&measurement_to_line/1)
      |> Enum.join("\n")

    IO.inspect body
    # {:ok, _status_code, _headers, client_ref} = :hackney.request(:post, url, [], body, []) |> IO.inspect
    # {:ok, _body} = :hackney.body(client_ref)
    # {:noreply, %{state | measurements: []}}
  end

  defp get_new_measurements do
    Sqlitex.Server.query(Sqlitex.Server, "SELECT id, serial_number, temperature, timestamp, forwarded_at FROM temperature_readings WHERE forwarded_at IS NULL", into: %{})
  end

  defp measurement_to_line({serial, fahrenheit, timestamp}) do
    case location(serial) do
      nil ->
        "temperature,location=Unknown sensor=#{serial} value=#{fahrenheit} #{timestamp}000000"
      {location, sensor_name} ->
        "temperature,location=#{location} sensor=#{sensor_name} value=#{fahrenheit} #{timestamp}000000"
    end
  end

  defp location(serial) do
    # map serial number of probe to location and sensor name
    nil
  end
end
