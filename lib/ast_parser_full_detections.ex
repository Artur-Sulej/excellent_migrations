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
      ddl_transaction_disabled?: false,
      lock_disabled?: false
    }

    ast
    |> Macro.postwalk(default, &detect_invalid_index_concurrently_inner/2)
    |> case do
      {_, %{is_index_concurrently?: false}} ->
        []

      {_, %{lock_disabled?: true, ddl_transaction_disabled?: true}} ->
        []

      {_, %{lock_disabled?: true, ddl_transaction_disabled?: false, line: line}} ->
        [{:index_concurrently_without_disable_migration_lock, line}]

      {_, %{lock_disabled?: false, ddl_transaction_disabled?: true, line: line}} ->
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
    {ast_part, %{acc | ddl_transaction_disabled?: true}}
  end

  defp detect_invalid_index_concurrently_inner(
         {:disable_migration_lock, _, [true]} = ast_part,
         acc
       ) do
    {ast_part, %{acc | lock_disabled?: true}}
  end

  defp detect_invalid_index_concurrently_inner(ast_part, acc) do
    {ast_part, acc}
  end
end
