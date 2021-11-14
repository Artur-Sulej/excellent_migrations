defmodule ExcellentMigrations.CredoCheck.CheckSafetyTest do
  use Credo.Test.Case
  alias ExcellentMigrations.CredoCheck.CheckSafety

  test "it should NOT report expected code" do
    "test/example_migrations/20190718085047_create_vegetables.exs"
    |> run_check()
    |> refute_issues()
  end

  test "it should report code that includes rejected module attribute names" do
    "test/example_migrations/20180830090807_add_index_to_dumplings.exs"
    |> run_check()
    |> assert_issues()
  end

  defp run_check(path) do
    path
    |> File.read!()
    |> to_source_file(path)
    |> run_check(CheckSafety)
  end
end
