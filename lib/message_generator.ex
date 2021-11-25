defmodule ExcellentMigrations.MessageGenerator do
  @moduledoc false

  def build_message(%{type: type, path: path, line: line}) do
    "#{build_message(type)} in #{path}:#{line}"
  end

  def build_message(type) do
    type
    |> Atom.to_string()
    |> String.replace("_", " ")
    |> String.capitalize()
  end
end
