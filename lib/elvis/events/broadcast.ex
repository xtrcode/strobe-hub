defmodule Elvis.Events.Broadcast do
  @moduledoc """
  This event handler is responsible for broadcasting the required events to the
  controllers in the necessary format.
  """

  use     GenEvent
  require Logger

  # Send progress updates every @progress_interval times
  @progress_interval 3 # * 100 ms intervals

  def register do
    Otis.State.Events.add_mon_handler(__MODULE__, %{ progress_count: %{} })
  end


  def handle_event({:library_response, id, response, socket}, state) do
    Phoenix.Channel.push(socket, "library", %{ libraryId: id, folder: response })
    {:ok, state}
  end

  def handle_event({:new_source_created, rendition}, state) do
    source = Otis.State.source(rendition)
    broadcast!("new_source_created", source)
    {:ok, state}
  end

  def handle_event({:zone_finished, zone_id}, state) do
    broadcast!("zone_play_pause", %{zoneId: zone_id, status: :stop})
    {:ok, state}
  end

  def handle_event({:sources_skipped, zone_id, source_ids}, state) do
    broadcast!("source_changed", %{zoneId: zone_id, removeSourceIds: source_ids})
    {:ok, state}
  end

  def handle_event({:source_changed, _zone_id, nil, _new_source_id}, state) do
    {:ok, state}
  end
  def handle_event({:source_changed, zone_id, old_source_id, _new_source_id}, state) do
    broadcast!("source_changed", %{zoneId: zone_id, removeSourceIds: [old_source_id]})
    {:ok, state}
  end

  def handle_event({:source_progress, zone_id, source_id, progress_ms, duration_ms}, state) do
    count = case Map.get(state.progress_count, zone_id, 0) do
      0 ->
        broadcast!("source_progress", %{
          zoneId: zone_id, sourceId: source_id,
          progress: progress_ms, duration: duration_ms
        })
        @progress_interval
      n ->
        n - 1
    end
    {:ok, %{state | progress_count: Map.put(state.progress_count, zone_id, count)}}
  end

  def handle_event({:zone_play_pause, zone_id, status}, state) do
    broadcast!("zone_play_pause", %{zoneId: zone_id, status: status})
    {:ok, state}
  end

  def handle_event({event, zone_id, receiver_id}, state)
  when event in [:receiver_added, :receiver_removed] do
    broadcast!(to_string(event), %{zoneId: zone_id, receiverId: receiver_id})
    {:ok, state}
  end

  def handle_event({:receiver_volume_change, id, volume}, state) do
    broadcast!("volume_change", %{ id: id, target: "receiver", volume: volume })
    {:ok, state}
  end

  def handle_event({:zone_volume_change, id, volume}, state) do
    broadcast!("volume_change", %{ id: id, target: "zone", volume: volume })
    {:ok, state}
  end

  def handle_event(event, state) do
    IO.inspect [:broadcast?, event]
    {:ok, state}
  end

  defp broadcast!(event, msg) do
    # msg = Map.put(args, :event, event)
    Elvis.Endpoint.broadcast!("controllers:browser", event, msg)
  end
end
