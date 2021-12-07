defmodule ExcellentMigrations.DangersDetectorTest do
  use ExUnit.Case
  alias ExcellentMigrations.DangersDetector

  test "detects dangers in AST" do
    {ast, source_code} = get_ast_and_source("20191026103002_execute_raw_sql.exs")

    assert [{:raw_sql_executed, 3}, {:raw_sql_executed, 7}] ==
             DangersDetector.detect_dangers(ast, source_code)
  end

  test "skips dangers with safety assured" do
    {ast, source_code} =
      get_ast_and_source("20191026103004_execute_raw_sql_with_safety_assured.exs")

    assert [] == DangersDetector.detect_dangers(ast, source_code)
  end

  test "skips dangers with safety assured config comments" do
    {ast, source_code} =
      get_ast_and_source("20191026103009_safety_assured_with_config_comments.exs")

    assert [] == DangersDetector.detect_dangers(ast, source_code)
  end

  defp get_ast_and_source(path) do
    source_code = File.read!("test/example_migrations/#{path}")
    ast = Code.string_to_quoted!(source_code)
    {ast, source_code}
  end
end
