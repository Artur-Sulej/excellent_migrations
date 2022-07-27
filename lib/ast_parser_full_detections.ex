defmodule ExcellentMigrations.AstParserFullDetections do
  @moduledoc false

  @index_functions [:create, :create_if_not_exists, :drop, :drop_if_exists]
  @index_types [:index, :unique_index]

  def parse(ast) do
    full_ast_detections(ast)
  end

  defp full_ast_detections(ast) do
    [
      &detect_invalid_index_concurrently/1
    ]
    |> Enum.map(&apply(&1, [ast]))
    |> Enum.concat()
  end

  defp detect_invalid_index_concurrently(ast) do
    default = %{
      line: nil,
      is_index_concurrently?: false,
      has_transaction?: false,
      has_lock?: false
    }

    ast
    |> Macro.postwalk(default, &detect_invalid_index_concurrently_inner/2)
    |> case do
      {_, %{is_index_concurrently?: false}} ->
        []

      {_, %{has_lock?: true, has_transaction?: true}} ->
        []

      {_, %{has_lock?: true, has_transaction?: false, line: line}} ->
        [{:index_concurrently_without_disable_migration_lock, line}]

      {_, %{has_lock?: false, has_transaction?: true, line: line}} ->
        [{:index_concurrently_without_disable_ddl_transaction, line}]

      {_, %{line: line}} ->
        [
          {:index_concurrently_without_disable_migration_lock, line},
          {:index_concurrently_without_disable_ddl_transaction, line}
        ]
    end
  end

  defp detect_invalid_index_concurrently_inner(
         {fun_name, location, [{operation, _, [_, _, options]}]} = ast_part,
         acc
       )
       when fun_name in @index_functions and operation in @index_types do
    is_concurrently? = Keyword.get(options, :concurrently, false) || acc.is_index_concurrently?
    line = if is_concurrently?, do: Keyword.get(location, :line), else: acc.line

    {ast_part, %{acc | is_index_concurrently?: is_concurrently?, line: line}}
  end

  defp detect_invalid_index_concurrently_inner(
         {:disable_ddl_transaction, _, [true]} = ast_part,
         acc
       ) do
    {ast_part, %{acc | has_transaction?: true}}
  end

  defp detect_invalid_index_concurrently_inner(
         {:disable_migration_lock, _, [true]} = ast_part,
         acc
       ) do
    {ast_part, %{acc | has_lock?: true}}
  end

  defp detect_invalid_index_concurrently_inner(ast_part, acc) do
    {ast_part, acc}
  end
end
