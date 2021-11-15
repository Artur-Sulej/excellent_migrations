defmodule ExcellentMigrations.Runner do
  alias ExcellentMigrations.{
    DangersChecker,
    FilesFinder,
    MessageGenerator
  }

  def check_migrations(opts \\ []) do
    opts
    |> get_migrations_paths()
    |> Task.async_stream(fn path ->
      path
      |> get_ast()
      |> DangersChecker.check_dangers()
      |> build_result(path)
    end)
    |> Stream.flat_map(fn {:ok, items} -> items end)
    |> Enum.to_list()
    |> close()
  end

  defp get_migrations_paths(opts) do
    opts
    |> Keyword.get_lazy(:migrations_paths, &FilesFinder.get_migrations_paths/0)
    |> Enum.sort()
  end

  defp get_ast(path) do
    {:ok, ast} = Code.string_to_quoted(File.read!(path))
    ast
  end

  defp build_result(dangers, path) do
    Enum.map(dangers, fn {type, line} ->
      %{
        type: type,
        path: path,
        line: line,
        message: MessageGenerator.build_message(type, path, line)
      }
    end)
  end

  defp close(_dangers = []), do: :safe
  defp close(dangers), do: {:dangerous, dangers}
end
