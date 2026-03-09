defmodule ExcellentMigrations.FilesFinder do
  @moduledoc """
  Migration files utility module responsible for finding relevant migration files and extracting timestamps from their paths.
  """

  @doc """
  Finds all relevant migration files in the project.

  Searches for files matching `**/migrations/*.exs` and filters them based on:
  - The `:start_after` configuration from application environment
  - Exclusion of `deps/` and `_build/` directories

  """
  @spec get_migrations_paths() :: [String.t()]
  def get_migrations_paths do
    start_after =
      :excellent_migrations
      |> Application.get_env(:start_after)
      |> timestamp_str_to_datetime() || DateTime.from_unix!(0)

    "**/migrations/*.exs"
    |> Path.wildcard()
    |> Enum.filter(&relevant_file?(&1, start_after))
  end

  @doc """
  Determines if a file path is relevant for analysis.

  A file is considered relevant if all of the following are true:
  - The path does not start with `deps/` or `_build/`
  - The path does not contain `/deps/` or `/_build/` anywhere
  - The path contains `migrations/`
  - The migration timestamp is greater than `start_after`

  ## Parameters

    * `path` - The file path to check
    * `start_after` - A DateTime representing the cutoff timestamp

  ## Examples

      iex> start_after = DateTime.from_unix!(1_572_085_800)
      iex> ExcellentMigrations.FilesFinder.relevant_file?(
      ...>   "priv/repo/migrations/20191026103003_create_table.exs",
      ...>   start_after
      ...> )
      true

      iex> start_after = DateTime.from_unix!(1_572_085_800)
      iex> ExcellentMigrations.FilesFinder.relevant_file?(
      ...>   "deps/my_dep/migrations/20191026103003_create_table.exs",
      ...>   start_after
      ...> )
      false

      iex> start_after = DateTime.from_unix!(1_572_085_800)
      iex> ExcellentMigrations.FilesFinder.relevant_file?(
      ...>   "priv/repo/other/20191026103003_create_table.exs",
      ...>   start_after
      ...> )
      false

  """
  @spec relevant_file?(String.t(), DateTime.t()) :: boolean
  def relevant_file?(path, start_after) do
    migration_dt = migration_timestamp(path)

    !String.starts_with?(path, ["deps/", "_build/"]) &&
      !String.contains?(path, ["/deps/", "/_build/"]) &&
      String.contains?(path, "migrations/") &&
      DateTime.compare(migration_dt, start_after) == :gt
  end

  @doc """
  Extracts the timestamp from a migration file path.

  Parses the migration filename to extract the timestamp prefix (expected to be in
  the format `YYYYMMDDHHMMSS`). If the timestamp cannot be parsed, returns
  `DateTime.from_unix!(1)` as a fallback.

  ## Parameters

    * `path` - The migration file path

  ## Examples

      iex> ExcellentMigrations.FilesFinder.migration_timestamp(
      ...>   "priv/repo/migrations/20191026103002_execute_raw_sql.exs"
      ...> )
      ~U[2019-10-26 10:30:02Z]

      iex> ExcellentMigrations.FilesFinder.migration_timestamp(
      ...>   "migrations/invalid_migration.exs"
      ...> )
      ~U[1970-01-01 00:00:01Z]

      iex> ExcellentMigrations.FilesFinder.migration_timestamp("")
      ~U[1970-01-01 00:00:01Z]

  """
  @spec migration_timestamp(String.t()) :: DateTime.t()
  def migration_timestamp(path) do
    path
    |> Path.basename()
    |> String.split("_")
    |> hd()
    |> timestamp_str_to_datetime() || DateTime.from_unix!(1)
  end

  @doc """
  Converts a timestamp string to a DateTime.

  Expects a string in the format `YYYYMMDDHHMMSS` (14 characters representing
  year, month, day, hour, minute, and second). Returns `nil` if the string
  doesn't match the expected format or represents an invalid date.

  ## Parameters

    * `timestamp_str` - A 14-character timestamp string

  ## Examples

      iex> ExcellentMigrations.FilesFinder.timestamp_str_to_datetime("20191026103002")
      ~U[2019-10-26 10:30:02Z]

      iex> ExcellentMigrations.FilesFinder.timestamp_str_to_datetime("invalid")
      nil

      iex> ExcellentMigrations.FilesFinder.timestamp_str_to_datetime("")
      nil

      iex> ExcellentMigrations.FilesFinder.timestamp_str_to_datetime(nil)
      nil

      iex> ExcellentMigrations.FilesFinder.timestamp_str_to_datetime("20190230120000")
      nil

  """
  @spec timestamp_str_to_datetime(String.t() | nil) :: DateTime.t() | nil
  def timestamp_str_to_datetime(timestamp_str) do
    with <<yyyy::binary-size(4), mo::binary-size(2), dd::binary-size(2), hh::binary-size(2),
           mi::binary-size(2), ss::binary-size(2)>> <- timestamp_str,
         {:ok, dt, 0} <- DateTime.from_iso8601("#{yyyy}#{mo}#{dd}T#{hh}#{mi}#{ss}Z", :basic) do
      dt
    else
      _ -> nil
    end
  end
end
