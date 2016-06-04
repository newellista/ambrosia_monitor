defmodule AmbrosiaMonitor.Archiver do
  use GenServer
  require Logger

  def start_link(url) do
    GenServer.start_link(__MODULE__, url, name: __MODULE__)
  end

  def init(url) do
    initialize_channel
    :timer.send_interval(30_000, :record_temperature)
    {:ok, %{url: url, measurements: []}}
  end

  def handle_info({_, _, _}=measurement, %{url: _, measurements: measurements}=state) do
    {:noreply, %{state | measurements: [measurement | measurements]}}
  end

  def handle_info(:record_temperature, %{url: url, measurements: measurements}=state) do
    measurements
      |> Enum.map(&store_temperature(&1, url))
    {:noreply, %{state | measurements: []}}
  end

  defp celsius_to_fahrenheit(celsius) do
    32.0 + (1.8 * celsius)
  end

  defp initialize_channel do
    :pg2.create(:thermex_measurements)
    :pg2.join(:thermex_measurements, self())
  end

  defp store_temperature({serial, temperature, timestamp}, url) do
    fahrenheit = celsius_to_fahrenheit(temperature)
    
    body = measurement_to_line(%{serial_number: serial, temperature: fahrenheit, timestamp: timestamp})
    send_to_collector(url, body)
  end

  defp send_to_collector(url, body) do
    case :hackney.request(:post, url, [], body, []) do
      {:ok, _status_code, _headers, client_ref} ->
        case :hackney.body(client_ref) do
          {:ok, body} -> 
            Logger.info "Update sent"
          {:error, _status} ->
            Logger.info "Unable to send body"
          _ ->
            Logger.info "Unknown Error"
        end
      {:error, status_code} ->
        Logger.info "Error sending to #{url}: (#{status_code})"
    end
  end

  defp measurement_to_line(%{serial_number: _, temperature: _, timestamp: _}=line) do
    case location(line.serial_number) do
      nil ->
        "temperature,location=Unknown,sensor=#{line.serial_number} value=#{line.temperature} #{line.timestamp}000000"
      {location, sensor_name} ->
        "temperature,location=#{location},sensor=#{sensor_name} value=#{line.temperature} #{line.timestamp}000000"
    end
  end

  defp location(_serial) do
    # map serial number of probe to location and sensor name
    nil
  end
end
