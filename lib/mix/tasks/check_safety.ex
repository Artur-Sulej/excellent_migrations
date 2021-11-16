defmodule Mix.Tasks.ExcellentMigrations.CheckSafety do
  @moduledoc "Runs analysis on database migration files and detects potentially dangerous operations."
  use Mix.Task
  require Logger

  @shortdoc "Detects potentially dangerous operations in DB migrations"
  def run(_args) do
    case ExcellentMigrations.Runner.check_migrations() do
      :safe ->
        Logger.info("No dangerous operations detected in migrations.")

      {:dangerous, dangers} ->
        Enum.each(dangers, fn danger ->
          danger
          |> ExcellentMigrations.MessageGenerator.build_message()
          |> Logger.warn()
        end)

        System.stop(1)
    end
  end
end
