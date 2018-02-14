defmodule Enchufe.Timer do
  use GenServer
  require Logger

  def start_link() do
    GenServer.start_link __MODULE__, %{}
  end

  def init(_state) do
    Logger.warn "Enchufe timer server started"
    EnchufeWeb.Endpoint.subscribe "timer:start", []
    state = %{timer_ref: nil, timer: nil}
    {:ok, state}
  end

  def handle_info(:update, %{timer: 0}) do
    broadcast 0, "TIMEEEE"
    {:noreply, %{timer_ref: nil, timer: 0}}
  end
  def handle_info(:update, %{timer: time}) do
    leftover = time - 1
    timer_ref = schedule_timer 1_000
    broadcast leftover, "tick tock... tick tock"
    {:noreply, %{timer_ref: timer_ref, timer: leftover}}
  end

  def handle_info(%{event: "start_timer"}, %{timer_ref: old_timer_ref}) do
    cancel_timer(old_timer_ref)
    duration = 30
    timer_ref = schedule_timer 1_000
    broadcast duration, "Started timer!"
    {:noreply, %{timer_ref: timer_ref, timer: duration}}
  end

  defp schedule_timer(interval), do: Process.send_after self(), :update, interval

  defp cancel_timer(nil), do: :ok
  defp cancel_timer(ref), do: Process.cancel_timer(ref)

  defp broadcast(time, response) do
    EnchufeWeb.Endpoint.broadcast! "timer:update", "new_time", %{
      response: response,
      time: time,
    }
  end
end
