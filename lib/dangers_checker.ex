defmodule ExcellentMigrations.DangersChecker do
  alias ExcellentMigrations.{DangersFilter, Parser}

  def check_dangers(ast) do
    ast
    |> Parser.parse()
    |> DangersFilter.reject_dangers(skipped_types())
  end

  defp skipped_types do
    Application.get_env(:excellent_migrations, :skip_checks, [])
  end
end
