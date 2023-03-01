defmodule ExcellentMigrations.AstParser.IndexNotConcurrently do
  @moduledoc false

  @index_functions [:create, :create_if_not_exists, :drop, :drop_if_exists]
  @index_types [:index, :unique_index]

  @doc ~S"""
  Detects index added not concurrently

  ## Examples

      iex> "create index(:recipes, :cuisine)"
      ...> |> Code.string_to_quoted!()
      ...> |> ExcellentMigrations.AstParser.IndexNotConcurrently.detect()
      [index_not_concurrently: 1]
  """
  def detect({fun_name, location, [{operation, _, [_, _]}]})
       when fun_name in @index_functions and operation in @index_types do
    [{:index_not_concurrently, Keyword.get(location, :line)}]
  end

  def detect({fun_name, location, [{operation, _, [_, _, options]}]})
       when fun_name in @index_functions and operation in @index_types do
    case Keyword.get(options, :concurrently) do
      true -> []
      _ -> [{:index_not_concurrently, Keyword.get(location, :line)}]
    end
  end

  def detect(_), do: []
end
