defmodule ExcellentMigrations.CredoCheck.CheckSafety do
  alias ExcellentMigrations.{
    MessageGenerator,
    DangersChecker
  }

  use Credo.Check,
    base_priority: :high,
    category: :warning,
    explanations: [
      check: """
      Checks if database migrations contain potentially dangerous operations.
      """
    ]

  def run(source_file, params \\ []) do
    if relevant_file?(source_file.filename) do
      detect_dangers(source_file, params)
    else
      []
    end
  end

  defp relevant_file?(path) do
    start_after = Application.get_env(:excellent_migrations, :start_after)
    String.contains?(path, "migrations/") && migration_timestamp(path) > start_after
  end

  defp migration_timestamp(path) do
    path
    |> Path.basename()
    |> String.split("_")
    |> hd()
  end

  defp detect_dangers(source_file, params) do
    issue_meta = IssueMeta.for(source_file, params)

    dangers =
      source_file
      |> SourceFile.ast()
      |> DangersChecker.check_dangers()

    Enum.map(dangers, fn {type, line} -> build_issue(type, line, issue_meta) end)
  end

  defp build_issue(danger_type, line, issue_meta) do
    format_issue(
      issue_meta,
      message: MessageGenerator.build_message(danger_type),
      line_no: line
    )
  end
end
