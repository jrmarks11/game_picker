defmodule GamePickerWeb.RocketLive.Index do
  use GamePickerWeb, :live_view

  @tick_rate 50  # milliseconds
  @max_height 450  # pixels (adjusted for new layout)
  @rise_speed 5  # pixels per tick
  @fall_speed 3  # pixels per tick
  @fuel_consumption 1.1  # fuel units per tick while flying (need ~99 fuel to reach space)
  @max_fuel 100

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:rocket_height, 0)
     |> assign(:fuel, 50)
     |> assign(:is_flying, false)
     |> assign(:launch_count, 0)
     |> assign(:message, "")
     |> assign(:stars_collected, 0)
     |> assign(:show_celebration, false)
     |> assign(:currently_at_space, false)}
  end

  @impl true
  def handle_event("launch", _params, socket) do
    if socket.assigns.fuel > 0 and not socket.assigns.is_flying do
      Process.send_after(self(), :tick, @tick_rate)

      {:noreply,
       socket
       |> assign(:is_flying, true)
       |> assign(:launch_count, socket.assigns.launch_count + 1)
       |> assign(:message, "🚀 WHOOOOSH! 🚀")
       |> assign(:show_celebration, false)
       |> assign(:currently_at_space, false)}
    else
      message = if socket.assigns.fuel == 0 do
        "Need more fuel! Click 'Add Fuel' ⛽"
      else
        "Rocket is already flying!"
      end

      {:noreply, assign(socket, :message, message)}
    end
  end

  @impl true
  def handle_event("add_fuel", _params, socket) do
    new_fuel = min(socket.assigns.fuel + 20, @max_fuel)

    {:noreply,
     socket
     |> assign(:fuel, new_fuel)
     |> assign(:message, "⛽ Fuel added! Ready to launch!")}
  end

  @impl true
  def handle_event("set_custom_fuel", %{"fuel" => fuel_str}, socket) do
    case Integer.parse(fuel_str) do
      {fuel_amount, _} when fuel_amount >= 0 and fuel_amount <= @max_fuel ->
        {:noreply,
         socket
         |> assign(:fuel, fuel_amount)
         |> assign(:message, "⚡ Custom fuel set to #{fuel_amount}!")}

      _ ->
        {:noreply,
         socket
         |> assign(:message, "❌ Please enter a number between 0 and 100!")}
    end
  end

  @impl true
  def handle_event("reset", _params, socket) do
    {:noreply,
     socket
     |> assign(:rocket_height, 0)
     |> assign(:is_flying, false)
     |> assign(:message, "Rocket ready for launch!")
     |> assign(:show_celebration, false)
     |> assign(:currently_at_space, false)}
  end

  @impl true
  def handle_info(:tick, socket) do
    cond do
      # Going up with fuel
      socket.assigns.is_flying and socket.assigns.fuel > 0 and socket.assigns.rocket_height < @max_height ->
        new_height = min(socket.assigns.rocket_height + @rise_speed, @max_height)
        new_fuel = max(socket.assigns.fuel - @fuel_consumption, 0)

        # Check if we JUST reached the very top and weren't already there
        just_reached_space = new_height == @max_height and socket.assigns.rocket_height < @max_height and not socket.assigns.currently_at_space

        Process.send_after(self(), :tick, @tick_rate)

        {:noreply,
         socket
         |> assign(:rocket_height, new_height)
         |> assign(:fuel, new_fuel)
         |> maybe_celebrate(just_reached_space)}

      # At max height with fuel - consuming fuel but not moving
      socket.assigns.is_flying and socket.assigns.fuel > 0 and socket.assigns.rocket_height >= @max_height ->
        new_fuel = max(socket.assigns.fuel - @fuel_consumption, 0)

        Process.send_after(self(), :tick, @tick_rate)

        {:noreply,
         socket
         |> assign(:fuel, new_fuel)}

      # At the top or out of fuel - start falling
      socket.assigns.is_flying and socket.assigns.rocket_height > 0 ->
        new_height = max(socket.assigns.rocket_height - @fall_speed, 0)

        # Reset space flag if we've dropped below max height
        left_space = socket.assigns.rocket_height == @max_height and new_height < @max_height

        if new_height > 0 do
          Process.send_after(self(), :tick, @tick_rate)
        end

        {:noreply,
         socket
         |> assign(:rocket_height, new_height)
         |> assign(:is_flying, new_height > 0)
         |> maybe_left_space(left_space)
         |> maybe_land(new_height)}

      true ->
        {:noreply, assign(socket, :is_flying, false)}
    end
  end

  defp maybe_celebrate(socket, true) do
    socket
    |> assign(:message, "🌟 Amazing! You reached space! 🌟")
    |> assign(:stars_collected, socket.assigns.stars_collected + 1)
    |> assign(:show_celebration, true)
    |> assign(:currently_at_space, true)
  end
  defp maybe_celebrate(socket, false), do: socket

  defp maybe_left_space(socket, true) do
    socket
    |> assign(:currently_at_space, false)
  end
  defp maybe_left_space(socket, false), do: socket

  defp maybe_land(socket, 0) do
    socket
    |> assign(:message, "Rocket landed safely! 🎉")
    |> assign(:show_celebration, false)
    |> assign(:currently_at_space, false)
  end
  defp maybe_land(socket, _), do: socket
end