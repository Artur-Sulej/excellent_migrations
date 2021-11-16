defmodule ExcellentMigrations.DangersDetector do
  @moduledoc """
  This module finds potentially dangerous or destructive database operations in a given
  migration AST.
  """

  alias ExcellentMigrations.{
    DangersFilter,
    Parser
  }

  @type ast :: list | tuple | atom | String.t()

  @type danger_type ::
          :raw_sql_executed
          | :index_not_concurrently
          | :many_columns_index
          | :column_added_with_default
          | :column_removed
          | :table_renamed
          | :column_renamed
          | :not_null_added
          | :column_type_changed
          | :operation_insert
          | :operation_update
          | :operation_delete

  @type line :: integer

  @doc """
  Traverses `ast` and finds potentially dangerous database operations. Returns keyword list
  containing danger types and lines where they were detected.
  ## Parameters
    * ast: structure that represents AST of database migration.
      It can be obtained e.g. via `Code.string_to_quoted/1`.
  ## Examples
      iex> {:ok, ast} = Code.string_to_quoted(\"""
      ...> alter table("dumplings") do
      ...>   remove(:taste, :string)
      ...>   remove(:stuffing, :string)
      ...> end
      ...> \""")
      {:ok,
      {:alter, [line: 1],
      [
        {:table, [line: 1], ["dumplings"]},
        [
          do: {:__block__, [],
           [
             {:remove, [line: 2], [:taste, :string]},
             {:remove, [line: 3], [:stuffing, :string]}
           ]}
        ]
      ]}}
      iex> ExcellentMigrations.DangersDetector.detect_dangers(ast)
      [column_removed: 2, column_removed: 3]
  """
  @spec detect_dangers(ast) :: [{danger_type, line}]
  def detect_dangers(ast) do
    ast
    |> Parser.parse()
    |> DangersFilter.reject_dangers(skipped_types())
  end

  defp skipped_types do
    Application.get_env(:excellent_migrations, :skip_checks, [])
  end
end
