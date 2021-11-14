defmodule Mix.Tasks.ExcellentMigrations.CheckSafety do
  @moduledoc "Runs analysis on DB migration files and detects potentially dangerous operations."
  use Mix.Task
  require Logger

  @shortdoc "Detects potentially dangerous operations in DB migrations"
  def run(_args) do
    case ExcellentMigrations.Checker.check_migrations() do
      :ok -> Logger.info("No dangerous operations detected in migrations.")
      {:error, dangers} -> Enum.each(dangers, fn %{message: message} -> Logger.warn(message) end)
    end
  end
end
