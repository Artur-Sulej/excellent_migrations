defmodule ExcellentMigrations.Checker do
  alias ExcellentMigrations.{
    FilesReader,
    MessageGenerator,
    Parser
  }

  def check_migrations(opts \\ []) do
    migrations_paths = Keyword.get_lazy(opts, :migrations_paths, &FilesReader.get_migrations_paths/0)

    migrations_paths
    |> Task.async_stream(fn path ->
      path
      |> get_ast()
      |> Parser.parse()
      |> reject_safety_assured()
      |> generate_message(path)
    end)
    |> Stream.flat_map(fn {:ok, messages} -> messages end)
    |> Stream.reject(&is_nil/1)
    |> Enum.to_list()
    |> close()
  end

  defp close(_messages = []), do: :ok
  defp close(messages), do: {:error, messages}

  defp reject_safety_assured(warnings) do
    if Keyword.get(warnings, :safety_assured) do
      []
    else
      Keyword.delete(warnings, :safety_assured)
    end
  end

  defp generate_message(warnings, path) do
    Enum.map(warnings, fn {key, line} -> MessageGenerator.get_message(key, path, line) end)
  end

  defp get_ast(file_path) do
    {:ok, ast} = Code.string_to_quoted(File.read!(file_path))
    ast
  end
end
