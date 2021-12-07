defmodule ExcellentMigrations.ConfigCommentsParser do
  @moduledoc false

  def parse(source_code) do
    {:ok, stream} = StringIO.open(source_code)

    stream
    |> IO.binstream(:line)
    |> Stream.with_index(1)
    |> Stream.filter(fn {content, _line} ->
      Regex.match?(~r/\s*#\s*excellent_migrations.*/, content)
    end)
    |> Stream.map(fn {content, line} ->
      content = String.replace(content, ~r/\s*#\s*excellent_migrations\s*:\s*/, "")
      {content, line}
    end)
    |> Stream.flat_map(&get_safety_assured/1)
    |> Enum.to_list()
  end

  defp get_safety_assured({"safety-assured-for-this-file" <> types, _line}) do
    build_safe_types(types, :all)
  end

  defp get_safety_assured({"safety-assured-for-next-line" <> types, line}) do
    build_safe_types(types, line)
  end

  defp build_safe_types(types, line) do
    types
    |> String.trim()
    |> String.split(" ")
    |> Enum.map(&{prepare_type(&1), line})
  end

  defp prepare_type(string) do
    string
    |> String.trim()
    |> String.replace("-", "_")
    |> String.to_atom()
  end
end
