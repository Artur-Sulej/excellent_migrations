defmodule CheckerTest do
  use ExUnit.Case
  alias ExcellentMigrations.Checker

  test "generates warning messages for migration files" do
    file_paths = [
      "test/example_migrations/20180718085047_create_dumplings.txt",
      "test/example_migrations/20180830090807_add_index_to_dumplings.exs"
    ]

    assert [
             "Index added not concurrently in file test/example_migrations/20180718085047_create_dumplings.txt:8",
             "Raw SQL used in file test/example_migrations/20180830090807_add_index_to_dumplings.exs:3",
             "Raw SQL used in file test/example_migrations/20180830090807_add_index_to_dumplings.exs:7"
           ] == Checker.check_migrations(file_paths)
  end
end
