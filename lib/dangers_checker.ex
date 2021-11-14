defmodule ExcellentMigrations.DangersChecker do
  alias ExcellentMigrations.Parser

  def check_dangers(ast) do
    ast
    |> Parser.parse()
    |> reject_safety_assured()
  end

  defp reject_safety_assured(dangers) do
    if Keyword.get(dangers, :safety_assured) do
      []
    else
      Keyword.delete(dangers, :safety_assured)
    end
  end
end
