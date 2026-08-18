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

  test "skips adding a column with a default when safe for the database version" do
    {ast, source_code} = get_ast_and_source("20191026103007_add_column_with_default_value.exs")

    databases = [
      [engine: :postgres, version: "11.0.0"],
      [engine: :mysql, version: "8.0.12"],
      [engine: :mariadb, version: "10.3.2"]
    ]

    for database <- databases do
      assert [] == DangersDetector.detect_dangers(ast, source_code, database: database)
    end
  end

  test "supports database versions with only major or major and minor components" do
    {ast, source_code} = get_ast_and_source("20191026103007_add_column_with_default_value.exs")

    databases = [
      [engine: :postgres, version: "11"],
      [engine: :mysql, version: "8"],
      [engine: :mariadb, version: "10.3"]
    ]

    for database <- databases do
      assert [] == DangersDetector.detect_dangers(ast, source_code, database: database)
    end
  end

  test "detects adding a column with a default on older database versions" do
    {ast, source_code} = get_ast_and_source("20191026103007_add_column_with_default_value.exs")

    databases = [
      [engine: :postgres, version: "10"],
      [engine: :mysql, version: "7.9"],
      [engine: :mariadb, version: "10.2"],
      [engine: :mysql, version: "8.0.11"],
      [engine: :mariadb, version: "10.3.1"]
    ]

    for database <- databases do
      assert [column_added_with_default: 4, column_added_with_default: 5] ==
               DangersDetector.detect_dangers(ast, source_code, database: database)
    end
  end

  test "still detects a volatile default on a supported database version" do
    source_code = """
    alter table("recipes") do
      add(:identifier, :uuid, default: fragment("uuid_generate_v4()"))
    end
    """

    ast = Code.string_to_quoted!(source_code)

    assert [column_volatile_default: 2] ==
             DangersDetector.detect_dangers(ast, source_code,
               database: [engine: :postgres, version: "11.0.0"]
             )
  end

  defp get_ast_and_source(path) do
    source_code = File.read!("test/example_migrations/#{path}")
    ast = Code.string_to_quoted!(source_code)
    {ast, source_code}
  end
end
