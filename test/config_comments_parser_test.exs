defmodule ExcellentMigrations.ConfigCommentsParserTest do
  use ExUnit.Case
  alias ExcellentMigrations.ConfigCommentsParser

  test "finds lines with config comment disable-for-file" do
    source_code =
      File.read!("test/example_migrations/20191026103009_safety_assured_with_config_comments.exs")

    assert [raw_sql_executed: :all] == ConfigCommentsParser.parse(source_code)
  end

  test "finds lines with config comment disable-for-next-line" do
    source_code =
      "    # excellent_migrations:safety-assured-for-next-line raw_sql_executed column_renamed"

    assert [raw_sql_executed: 1, column_renamed: 1] == ConfigCommentsParser.parse(source_code)
  end

  test "works for kebab case" do
    source_code =
      "    # excellent_migrations:safety-assured-for-next-line raw-sql-executed column_renamed"

    assert [raw_sql_executed: 1, column_renamed: 1] == ConfigCommentsParser.parse(source_code)
  end
end
