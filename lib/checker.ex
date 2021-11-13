defmodule ExcellentMigrations.Checker do
  alias ExcellentMigrations.{
    MessageGenerator,
    Parser
  }

  def check_migrations(file_paths) do
    file_paths
    |> Task.async_stream(fn path ->
      path
      |> get_ast()
      |> Parser.parse()
      |> generate_message(path)
    end)
    |> Stream.flat_map(fn {:ok, messages} -> messages end)
    |> Stream.reject(&is_nil/1)
    |> Enum.to_list()
    |> close()
  end

  defp close(_messages = []) do
    :ok
  end

  defp close(messages) do
    {:error, messages}
  end

  defp generate_message(warnings, path) do
    cond do
      Keyword.get(warnings, :safety_assured) ->
        []

      warnings == [] ->
        []

      true ->
        warnings
        |> Keyword.delete(:safety_assured)
        |> Enum.map(fn {key, line} -> MessageGenerator.get_message(key, path, line) end)
    end
  end

  defp get_ast(file_path) do
    {:ok, ast} = Code.string_to_quoted(File.read!(file_path))
    ast
  end
end
