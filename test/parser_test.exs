defmodule ExcellentMigrations.ParserTest do
  use ExUnit.Case
  alias ExcellentMigrations.Parser

  test "detects table renamed" do
    rename_table_ast = string_to_ast("rename table(\"dumplings\"), to: table(\"noodles\")")
    assert [table_renamed: 1] == Parser.parse(rename_table_ast)
  end

  test "detects column renamed" do
    rename_table_ast = string_to_ast("rename table(\"dumplings\"), :filling, to: :stuffing")
    assert [column_renamed: 1] == Parser.parse(rename_table_ast)
  end

  test "detects column type changed" do
    change_column_type_ast = string_to_ast("modify(:size, :integer)")
    assert [column_type_changed: 1] == Parser.parse(change_column_type_ast)
  end

  test "detects danger and safety assured" do
    assert [safety_assured: true, index_not_concurrently: 7] == Parser.parse(safety_assured_ast())
  end

  test "detects raw SQL executed" do
    assert [raw_sql: 2, raw_sql: 6] == Parser.parse(raw_sql_executed_ast())
  end

  test "detects index added not concurrently" do
    index_not_concurrently_ast = string_to_ast("create index(:dumplings, [:dough], unique: true)")
    assert [index_not_concurrently: 1] == Parser.parse(index_not_concurrently_ast)
  end

  test "detects column added with default" do
    assert [column_added_with_default: 2] ==
             Parser.parse(add_column_with_default_in_existing_table_ast())

    assert [] == Parser.parse(add_column_with_default_in_new_table_ast())
  end

  test "detects column removed" do
    assert [column_removed: 1] == Parser.parse(string_to_ast("remove(:size, :string)"))

    assert [column_removed: 1] ==
             Parser.parse(string_to_ast("remove(:size, :string, default: \"big\")"))

    assert [column_removed: 1] ==
             Parser.parse(string_to_ast("remove(:size, :string)"))
  end

  defp add_column_with_default_in_existing_table_ast do
    string_to_ast("""
    alter table("dumplings") do
      add(:taste, :string, default: "sweet")
    end
    """)
  end

  defp add_column_with_default_in_new_table_ast do
    string_to_ast("""
    create table("dumplings") do
      add(:taste, :string, default: "sweet")
    end
    """)
  end

  defp raw_sql_executed_ast do
    string_to_ast("""
    def up do
      execute("CREATE INDEX idx_dumplings_geog ON dumplings using GIST(Geography(geom));")
    end

    def down do
      execute("DROP INDEX idx_dumplings_geog;")
    end
    """)
  end

  defp safety_assured_ast do
    string_to_ast("""
    @safety_assured true
    def change do
      alter(table(:dumplings)) do
        add(:recipe_id, references(:recipes, on_delete: :delete_all), null: false)
      end

      create(index(:dumplings, [:recipe_id, :flour_id], unique: true))
    end
    """)
  end

  defp string_to_ast(string) do
    {:ok, ast} = Code.string_to_quoted(string)
    ast
  end
end
