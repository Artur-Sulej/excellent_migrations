if Code.ensure_loaded?(Credo.Check) do
  defmodule ExcellentMigrations.CredoCheck.MigrationsSafety do
    @moduledoc """
    Custom Credo check to be used in `.credo.exs` file.
    """

    alias ExcellentMigrations.{
      DangersDetector,
      FilesFinder,
      MessageGenerator
    }

    use Credo.Check,
      base_priority: :high,
      category: :warning,
      explanations: [
        check: """
        Checks if database migrations contain potentially dangerous operations.
        """
      ]

    @doc false
    def run(source_file, params \\ []) do
      start_after = Application.get_env(:excellent_migrations, :start_after)

      if FilesFinder.relevant_file?(source_file.filename, start_after) do
        detect_dangers(source_file, params)
      else
        []
      end
    end

    defp detect_dangers(source_file, params) do
      issue_meta = IssueMeta.for(source_file, params)
      ast = SourceFile.ast(source_file)
      source_code = SourceFile.source(source_file)
      dangers = DangersDetector.detect_dangers(ast, source_code)
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
end
