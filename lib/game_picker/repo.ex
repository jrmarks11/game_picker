defmodule GamePicker.Repo do
  use Ecto.Repo,
    otp_app: :game_picker,
    adapter: Ecto.Adapters.Postgres
end
