Application.ensure_all_started(:credo)

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

  test "it should report code that is defined in user specified directory" do
    Application.put_env(:excellent_migrations, :migrations_paths, [
      "migrations/",
      "migrations_storage/"
    ])

    "test/migrations_storage/20230425200039_execute_raw_sql.exs"
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
