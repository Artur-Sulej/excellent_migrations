defmodule CheckerTest do
  use ExUnit.Case
  alias ExcellentMigrations.Checker

  test "generates warning messages for migration files" do
    file_paths = [
      "test/example_migrations/20180718085047_create_dumplings.txt",
      "test/example_migrations/20180830090807_add_index_to_dumplings.exs",
      "test/example_migrations/20190718085047_create_vegetables.txt"
    ]

    assert {:error,
            [
              "Index added not concurrently in file test/example_migrations/20180718085047_create_dumplings.txt:8",
              "Raw SQL used in file test/example_migrations/20180830090807_add_index_to_dumplings.exs:3",
              "Raw SQL used in file test/example_migrations/20180830090807_add_index_to_dumplings.exs:7"
            ]} == Checker.check_migrations(file_paths)
  end

  test "no dangerous operations" do
    file_paths = [
      "test/example_migrations/20190718085047_create_vegetables.txt"
    ]

    assert :ok == Checker.check_migrations(file_paths)
  end
end
