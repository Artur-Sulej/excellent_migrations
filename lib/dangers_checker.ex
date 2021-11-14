defmodule ExcellentMigrations.DangersChecker do
  alias ExcellentMigrations.Parser

  def check_dangers(ast) do
    ast
    |> Parser.parse()
    |> reject_safety_assured()
    |> skip_ignored_checks()
  end

  defp reject_safety_assured(dangers) do
    if Keyword.get(dangers, :safety_assured) do
      []
    else
      Keyword.delete(dangers, :safety_assured)
    end
  end

  defp skip_ignored_checks(dangers) do
    skipped_types = Application.get_env(:excellent_migrations, :skip_checks, [])

    Enum.reduce(skipped_types, dangers, fn skipped_type, dangers_acc ->
      Keyword.delete(dangers_acc, skipped_type)
    end)
  end
end
