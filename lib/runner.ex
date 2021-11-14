defmodule ExcellentMigrations.Runner do
  alias ExcellentMigrations.{
    FilesReader,
    MessageGenerator,
    Parser
  }

  def check_migrations(opts \\ []) do
    opts
    |> Keyword.get_lazy(:migrations_paths, &FilesReader.get_migrations_paths/0)
    |> Task.async_stream(fn path ->
      path
      |> get_ast()
      |> Parser.parse()
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
