defmodule ExcellentMigrations.RunnerTest do
  use ExUnit.Case
  alias ExcellentMigrations.Runner

  test "generates warning messages for migration files" do
    file_paths = [
      "test/example_migrations/20191026103001_create_table_and_index.exs",
      "test/example_migrations/20191026103002_execute_raw_sql.exs",
      "test/example_migrations/20191026103003_create_table.exs"
    ]

    assert {
             :error,
             [
               %{
                 message:
                   "Index added not concurrently in test/example_migrations/20191026103001_create_table_and_index.exs:8",
                 path: "test/example_migrations/20191026103001_create_table_and_index.exs",
                 line: 8,
                 type: :index_not_concurrently
               },
               %{
                 message:
                   "Raw SQL used in test/example_migrations/20191026103002_execute_raw_sql.exs:3",
                 path: "test/example_migrations/20191026103002_execute_raw_sql.exs",
                 line: 3,
                 type: :raw_sql_executed
               },
               %{
                 message:
                   "Raw SQL used in test/example_migrations/20191026103002_execute_raw_sql.exs:7",
                 path: "test/example_migrations/20191026103002_execute_raw_sql.exs",
                 line: 7,
                 type: :raw_sql_executed
               }
             ]
           } == Runner.check_migrations(migrations_paths: file_paths)
  end

  test "no dangerous operations" do
    file_paths = [
      "test/example_migrations/20191026103003_create_table.exs",
      "test/example_migrations/20191026103004_execute_raw_sql_with_safety_assured.exs"
    ]

    assert :ok == Runner.check_migrations(migrations_paths: file_paths)
  end
end
