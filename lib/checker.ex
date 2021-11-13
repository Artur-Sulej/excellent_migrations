defmodule ExcellentMigrations.Checker do
  alias ExcellentMigrations.{
    FilesReader,
    MessageGenerator,
    Parser
  }

  def check_migrations(opts \\ []) do
    migrations_paths =
      Keyword.get_lazy(opts, :migrations_paths, &FilesReader.get_migrations_paths/0)

    migrations_paths
    |> Task.async_stream(fn path ->
      path
      |> get_ast()
      |> Parser.parse()
      |> reject_safety_assured()
      |> build_result(path)
    end)
    |> Stream.flat_map(fn {:ok, items} -> items end)
    |> Enum.to_list()
    |> close()
  end

  defp close(_dangers = []), do: :ok
  defp close(dangers), do: {:error, dangers}

  defp get_ast(path) do
    {:ok, ast} = Code.string_to_quoted(File.read!(path))
    ast
  end

  defp reject_safety_assured(dangers) do
    if Keyword.get(dangers, :safety_assured) do
      []
    else
      Keyword.delete(dangers, :safety_assured)
    end
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
end
