defmodule ExcellentMigrations.CredoCheck.CheckSafety do
  use Credo.Check,
    base_priority: :high,
    category: :warning,
    explanations: [
      check: """
      Checks if database migrations contain potentially dangerous operations.
      """
    ]

  def run(source_file, params \\ []) do
    if String.contains?(source_file.filename, "migrations/") do
      issue_meta = IssueMeta.for(source_file, params)

      dangers =
        source_file
        |> SourceFile.ast()
        |> ExcellentMigrations.Parser.parse()

      Enum.map(dangers, fn {type, line} -> build_issue(type, line, issue_meta) end)
    else
      []
    end
  end

  defp build_issue(danger_type, line, issue_meta) do
    format_issue(
      issue_meta,
      message: ExcellentMigrations.MessageGenerator.build_message(danger_type),
      trigger: "@#{danger_type}",
      line_no: line
    )
  end
end
