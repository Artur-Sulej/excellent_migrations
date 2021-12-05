defmodule ExcellentMigrations.ConfigCommentsParser do
  @moduledoc false

  def parse(source_code) do
    {:ok, stream} = StringIO.open(source_code)

    stream
    |> IO.binstream(:line)
    |> Stream.with_index(1)
    |> Stream.filter(fn {line, _line_number} ->
      Regex.match?(~r/\s*#\s*excellent_migrations.*/, line)
    end)
    |> Stream.map(fn {line, line_number} ->
      line = String.replace(line, ~r/\s*#\s*excellent_migrations\s*:\s*/, "")
      {line, line_number}
    end)
    |> Stream.flat_map(&get_config/1)
    |> Enum.to_list()
  end

  defp get_config({"safety-assured-for-this-file" <> types, _line_number}) do
    map_types(types, :all)
  end

  defp get_config({"safety-assured-for-next-line" <> types, line_number}) do
    map_types(types, line_number)
  end

  defp map_types(types, line_number) do
    types
    |> String.trim()
    |> String.split(" ")
    |> Enum.map(&{build_type(&1), line_number})
  end

  defp build_type(string) do
    string
    |> String.trim()
    |> String.to_atom()
  end
end
