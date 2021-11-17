defmodule ExcellentMigrations.CredoCheck.MigrationsSafetyTest do
  use Credo.Test.Case
  alias ExcellentMigrations.CredoCheck.MigrationsSafety

  test "it should NOT report expected code" do
    "test/example_migrations/20191026103003_create_table.exs"
    |> run_check()
    |> refute_issues()
  end

  test "it should report code that includes rejected module attribute names" do
    "test/example_migrations/20191026103002_execute_raw_sql.exs"
    |> run_check()
    |> assert_issues()
  end

  defp run_check(path) do
    path
    |> File.read!()
    |> to_source_file(path)
    |> run_check(MigrationsSafety)
  end
end
