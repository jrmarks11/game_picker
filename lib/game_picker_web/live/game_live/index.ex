defmodule GamePickerWeb.GameLive.Index do
  use GamePickerWeb, :live_view

  alias GamePicker.Games
  alias GamePicker.Games.Game

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:games, list_games())
     |> assign(:game, %Game{})
     |> assign(:changeset, Games.change_game(%Game{}))
     |> assign(:selected_game, nil)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Game Picker")
    |> assign(:game, %Game{})
  end

  @impl true
  def handle_event("save", %{"game" => game_params}, socket) do
    case Games.create_game(game_params) do
      {:ok, _game} ->
        {:noreply,
         socket
         |> put_flash(:info, "Game added successfully!")
         |> assign(:games, list_games())
         |> assign(:game, %Game{})
         |> assign(:changeset, Games.change_game(%Game{}))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    game = Games.get_game!(id)
    {:ok, _} = Games.delete_game(game)

    {:noreply,
     socket
     |> put_flash(:info, "Game deleted successfully")
     |> assign(:games, list_games())}
  end

  @impl true
  def handle_event("pick_random", _params, socket) do
    selected_game = Games.get_random_game()

    {:noreply,
     socket
     |> assign(:selected_game, selected_game)}
  end

  @impl true
  def handle_event("clear_selection", _params, socket) do
    {:noreply, assign(socket, :selected_game, nil)}
  end

  defp list_games do
    Games.list_games()
  end
end