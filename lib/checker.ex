defmodule ExcellentMigrations.Checker do
  defmacro __using__(_opts) do
    check_migrations()
  end

  defmacro enable_safety_check do
    check_migrations()
  end

  def check_migrations do
    # Make it run concurrently
    Enum.each(
      file_paths(),
      fn path ->
        path
        |> get_ast()
        |> check_safety()
      end
    )
  end

  defp file_paths do
    [
      "/20170414131851_add_sth.exs",
      "/20180830090807_add_sth.exs"
    ]
  end

  defp get_ast(file_path) do
    {:ok, ast} = Code.string_to_quoted(File.read!(file_path))
    ast
  end

  defp check_safety(ast) do
    ExcellentMigrations.Parser.parse(ast)
  end
end
