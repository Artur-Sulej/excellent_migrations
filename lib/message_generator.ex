defmodule ExcellentMigrations.MessageGenerator do
  @moduledoc false

  def build_message(%{type: type, path: path, line: line}) do
    """
    #{build_message(type)} in #{path}:#{line}

        For more info:
          * https://github.com/Artur-Sulej/excellent_migrations#checks
          * https://github.com/Artur-Sulej/excellent_migrations#assuring-safety
    """
  end

  def build_message(type) do
    type
    |> Atom.to_string()
    |> String.replace("_", " ")
    |> String.capitalize()
  end
end
