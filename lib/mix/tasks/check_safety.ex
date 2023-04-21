defmodule Mix.Tasks.ExcellentMigrations.CheckSafety do
  @moduledoc "Runs analysis on database migration files and detects potentially dangerous operations."
  use Mix.Task
  require Logger

  @shortdoc "Detects potentially dangerous operations in DB migrations"
  def run(args) do
    {parsed, _args, _invalid} = OptionParser.parse(args, strict: [paths: :string])

    params =
      case Keyword.get(parsed, :paths) do
        nil -> []
        paths -> [migrations_paths: String.split(paths, ",")]
      end

    case ExcellentMigrations.Runner.check_migrations(params) do
      :safe ->
        Logger.info("No dangerous operations detected in migrations.")

      {:dangerous, dangers} ->
        Enum.each(dangers, fn danger ->
          danger
          |> ExcellentMigrations.MessageGenerator.build_message()
          |> Logger.warn()
        end)

        exit({:shutdown, 1})
    end
  end
end
