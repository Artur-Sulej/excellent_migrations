defmodule ExcellentMigrations.DangersDetector do
  @moduledoc """
  This module finds potentially dangerous or destructive database operations in a given
  migration AST.
  """

  alias ExcellentMigrations.{
    AstParser,
    AstParserFullDetections,
    ConfigCommentsParser,
    DangersFilter
  }

  @type ast :: list | tuple | atom | String.t()

  @type danger_type ::
          :check_constraint_added
          | :column_added_with_default
          | :column_reference_added
          | :column_removed
          | :column_renamed
          | :column_type_changed
          | :column_volatile_default
          | :column_added_generated_stored
          | :index_concurrently_without_disable_ddl_transaction
          | :index_concurrently_without_disable_migration_lock
          | :index_not_concurrently
          | :json_column_added
          | :many_columns_index
          | :not_null_added
          | :operation_delete
          | :operation_insert
          | :operation_update
          | :raw_sql_executed
          | :table_dropped
          | :table_renamed

  @type line :: integer

  @doc """
  Traverses `ast` and finds potentially dangerous database operations. Returns keyword list
  containing danger types and lines where they were detected.
  ## Parameters
    * `ast` is a structure that represents AST of database migration.
      It can be obtained e.g. via `Code.string_to_quoted!/1`.
  ## Examples
          iex> source_code = \"""
          ...>   alter table("dumplings") do
          ...>     remove(:taste, :string)
          ...>     remove(:stuffing, :string)
          ...>   end
          ...> \"""
          iex> ast = Code.string_to_quoted!(source_code)
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

          iex> ExcellentMigrations.DangersDetector.detect_dangers(ast, source_code)
          [column_removed: 2, column_removed: 3]
  """
  @spec detect_dangers(ast, String.t()) :: [{danger_type, line}]
  def detect_dangers(ast, source_code) do
    parsed_dangers =
      [
        AstParser.parse(ast),
        AstParserFullDetections.parse(ast)
      ]
      |> Enum.concat()

    parsed_safety_assured = ConfigCommentsParser.parse(source_code)
    skipped_types = Application.get_env(:excellent_migrations, :skip_checks, [])
    DangersFilter.filter_dangers(parsed_dangers, parsed_safety_assured, skipped_types)
  end
end
