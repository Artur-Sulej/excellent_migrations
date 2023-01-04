defmodule Mix.Tasks.ExcellentMigrations.Migrate do
  @moduledoc "Runs `ecto.migrate` task only if no dangerous operations were detected in migrations."
  use Mix.Task
  require Logger

  @shortdoc "Runs `ecto.migrate` if migrations are safe"
  def run(args) do
    case ExcellentMigrations.Runner.check_migrations() do
      :safe ->
        Mix.Task.run("ecto.migrate", args)

      {:dangerous, dangers} ->
        Enum.each(dangers, fn danger ->
          danger
          |> ExcellentMigrations.MessageGenerator.build_message()
          |> Logger.error()
        end)

        Mix.raise("Dangerous operations detected in migrations!")
    end
  end
end
