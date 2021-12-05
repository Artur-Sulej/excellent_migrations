defmodule ExcellentMigrations.DangersDetectorTest do
  use ExUnit.Case
  alias ExcellentMigrations.DangersDetector

  test "detects dangers in AST" do
    ast =
      Code.string_to_quoted!(
        File.read!("test/example_migrations/20191026103002_execute_raw_sql.exs")
      )

    assert [{:raw_sql_executed, 3}, {:raw_sql_executed, 7}] == DangersDetector.detect_dangers(ast)
  end

  test "skips dangers with safety assured" do
    ast =
      Code.string_to_quoted!(
        File.read!(
          "test/example_migrations/20191026103004_execute_raw_sql_with_safety_assured.exs"
        )
      )

    assert [] == DangersDetector.detect_dangers(ast)
  end

  test "skips dangers with safety assured config comments" do
    ast =
      Code.string_to_quoted!(
        File.read!(
          "test/example_migrations/20191026103009_safety_assured_with_config_comments.exs"
        )
      )

    assert  [{:raw_sql_executed, 8}] == DangersDetector.detect_dangers(ast)
  end
end
