defmodule ExcellentMigrations.RunnerTest do
  use ExUnit.Case
  alias ExcellentMigrations.Runner

  test "generates warning messages for migration files" do
    file_paths = [
      "test/example_migrations/20191026103001_create_table_and_index.exs",
      "test/example_migrations/20191026103002_execute_raw_sql.exs",
      "test/example_migrations/20191026103003_create_table.exs",
      "test/example_migrations/20191026103004_execute_raw_sql_with_safety_assured.exs",
      "test/example_migrations/20191026103005_remove_column.exs",
      "test/example_migrations/20191026103006_rename_table.exs",
      "test/example_migrations/20191026103007_add_column_with_default_value.exs",
      "test/example_migrations/20191026103008_change_column_type.exs",
      "test/example_migrations/20220725111000_create_index.exs",
      "test/example_migrations/20220725111501_create_unique_index.exs"
    ]

    assert {
             :dangerous,
             [
               %{
                 line: 8,
                 path: "test/example_migrations/20191026103001_create_table_and_index.exs",
                 type: :index_not_concurrently
               },
               %{
                 line: 3,
                 path: "test/example_migrations/20191026103002_execute_raw_sql.exs",
                 type: :raw_sql_executed
               },
               %{
                 line: 7,
                 path: "test/example_migrations/20191026103002_execute_raw_sql.exs",
                 type: :raw_sql_executed
               },
               %{
                 line: 4,
                 path: "test/example_migrations/20191026103005_remove_column.exs",
                 type: :column_removed
               },
               %{
                 line: 3,
                 path: "test/example_migrations/20191026103006_rename_table.exs",
                 type: :table_renamed
               },
               %{
                 line: 4,
                 path: "test/example_migrations/20191026103007_add_column_with_default_value.exs",
                 type: :column_added_with_default
               },
               %{
                 line: 5,
                 path: "test/example_migrations/20191026103007_add_column_with_default_value.exs",
                 type: :column_added_with_default
               },
               %{
                 line: 4,
                 path: "test/example_migrations/20191026103008_change_column_type.exs",
                 type: :column_type_changed
               },
               %{
                 line: 3,
                 path: "test/example_migrations/20220725111000_create_index.exs",
                 type: :index_not_concurrently
               },
               %{
                 line: 4,
                 path: "test/example_migrations/20220725111000_create_index.exs",
                 type: :index_not_concurrently
               },
               %{
                 line: 8,
                 path: "test/example_migrations/20220725111000_create_index.exs",
                 type: :index_not_concurrently
               },
               %{
                 line: 9,
                 path: "test/example_migrations/20220725111000_create_index.exs",
                 type: :index_not_concurrently
               },
               %{
                 line: 3,
                 path: "test/example_migrations/20220725111501_create_unique_index.exs",
                 type: :index_not_concurrently
               },
               %{
                 line: 4,
                 path: "test/example_migrations/20220725111501_create_unique_index.exs",
                 type: :index_not_concurrently
               },
               %{
                 line: 8,
                 path: "test/example_migrations/20220725111501_create_unique_index.exs",
                 type: :index_not_concurrently
               },
               %{
                 line: 9,
                 path: "test/example_migrations/20220725111501_create_unique_index.exs",
                 type: :index_not_concurrently
               }
             ]
           } == Runner.check_migrations(migrations_paths: file_paths)
  end

  test "no dangerous operations" do
    file_paths = [
      "test/example_migrations/20191026103003_create_table.exs",
      "test/example_migrations/20191026103004_execute_raw_sql_with_safety_assured.exs"
    ]

    assert :safe == Runner.check_migrations(migrations_paths: file_paths)
  end
end
