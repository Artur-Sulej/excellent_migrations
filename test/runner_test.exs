defmodule ExcellentMigrations.RunnerTest do
  use ExUnit.Case
  alias ExcellentMigrations.Runner

  test "generates warning messages for migration files" do
    file_paths = [
      "test/example_migrations/20180718085047_create_dumplings.exs",
      "test/example_migrations/20180830090807_add_index_to_dumplings.exs",
      "test/example_migrations/20190718085047_create_vegetables.exs"
    ]

    assert {
             :error,
             [
               %{
                 message:
                   "Index added not concurrently in test/example_migrations/20180718085047_create_dumplings.exs:8",
                 path: "test/example_migrations/20180718085047_create_dumplings.exs",
                 line: 8,
                 type: :index_not_concurrently
               },
               %{
                 message:
                   "Raw SQL used in test/example_migrations/20180830090807_add_index_to_dumplings.exs:3",
                 path: "test/example_migrations/20180830090807_add_index_to_dumplings.exs",
                 line: 3,
                 type: :execute
               },
               %{
                 message:
                   "Raw SQL used in test/example_migrations/20180830090807_add_index_to_dumplings.exs:7",
                 path: "test/example_migrations/20180830090807_add_index_to_dumplings.exs",
                 line: 7,
                 type: :execute
               }
             ]
           } == Runner.check_migrations(migrations_paths: file_paths)
  end

  test "no dangerous operations" do
    file_paths = [
      "test/example_migrations/20190718085047_create_vegetables.exs",
      "test/example_migrations/20190940090804_add_something_to_vegetables.exs"
    ]

    assert :ok == Runner.check_migrations(migrations_paths: file_paths)
  end
end
