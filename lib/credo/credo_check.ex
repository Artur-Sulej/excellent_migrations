defmodule ExcellentMigrations.CredoCheck.CheckSafety do
  use Credo.Check

  def run(source_file, params \\ []) do
    if String.contains?(source_file.filename, "migrations/") do
      dangers =
        source_file
        |> SourceFile.ast()
        |> ExcellentMigrations.Parser.parse()

      IO.puts("--- #{inspect(dangers)} ---")
    end

    []
  end
end
