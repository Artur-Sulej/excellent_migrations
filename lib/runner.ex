defmodule ExcellentMigrations.Runner do
  @moduledoc """
  This module finds migration files in a project and detects potentially dangerous database
  operations in them.
  """

  alias ExcellentMigrations.{
    DangersDetector,
    FilesFinder
  }

  @type danger_type ::
          :check_constraint_added
          | :column_added_with_default
          | :column_reference_added
          | :column_removed
          | :column_renamed
          | :column_type_changed
          | :column_volatile_default
          | :index_concurrently_without_disable_ddl_transaction
          | :index_concurrently_without_disable_migration_lock
          | :index_dropped
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

  @type danger :: %{
          type: danger_type,
          path: String.t(),
          line: integer
        }

  @doc """
  Detects potentially dangerous database operations in database migration files.
  ## Options
    * `:migrations_paths` - optional list of file paths to be checked.
  ## Scope of analysis
    * If `migrations_paths` are specified, the analysis will be narrowed down to these files only.
    * If not and application env `:excellent_migrations, :start_after` is set, only migrations with
      timestamp older than the provided one will be chosen.
    * If none of the above, all migration files in a project will be analyzed.

  """
  @spec check_migrations(migrations_paths: [String.t()]) :: :safe | {:dangerous, [danger]}
  def check_migrations(opts \\ []) do
    opts
    |> get_migrations_paths()
    |> Task.async_stream(fn path ->
      source_code = File.read!(path)
      ast = Code.string_to_quoted!(source_code)
      dangers = DangersDetector.detect_dangers(ast, source_code)
      build_result(dangers, path)
    end)
    |> Stream.flat_map(fn {:ok, items} -> items end)
    |> Enum.to_list()
    |> close()
  end

  defp get_migrations_paths(opts) do
    opts
    |> Keyword.get_lazy(:migrations_paths, &FilesFinder.get_migrations_paths/0)
    |> Enum.sort()
  end

  defp build_result(dangers, path) do
    Enum.map(dangers, fn {type, line} ->
      %{
        type: type,
        path: path,
        line: line
      }
    end)
  end

  defp close([]), do: :safe
  defp close(dangers), do: {:dangerous, dangers}
end
