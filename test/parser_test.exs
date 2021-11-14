defmodule ExcellentMigrations.ParserTest do
  use ExUnit.Case
  alias ExcellentMigrations.Parser

  test "detects table renamed" do
    ast = string_to_ast("rename table(\"dumplings\"), to: table(\"noodles\")")
    assert [table_renamed: 1] == Parser.parse(ast)
  end

  test "detects column renamed" do
    ast = string_to_ast("rename table(\"dumplings\"), :filling, to: :stuffing")
    assert [column_renamed: 1] == Parser.parse(ast)
  end

  test "detects column type changed" do
    ast = string_to_ast("modify(:size, :integer, from: :string)")
    assert [column_type_changed: 1] == Parser.parse(ast)
  end

  test "detects not null constraint added to column" do
    ast = string_to_ast("modify :location_id, :integer, null: true")
    assert [column_type_changed: 1, not_null_added: 1] == Parser.parse(ast)
  end

  test "detects check constraint added" do
    ast =
      string_to_ast(
        "create constraint(\"dumplings\", :price_must_be_positive, check: \"price > 0\")"
      )

    assert [check_constraint_added: 1] == Parser.parse(ast)
  end

  test "detects records modified" do
    ast1 =
      string_to_ast("""
      %Dumpling{}
        |> Ecto.Changeset.change(params)
        |> Repo.insert!()
      """)

    ast2 = string_to_ast("Repo.insert_all(Vegetables, vegs)")
    ast3 = string_to_ast("Restaurant.Repo.update_all(query, [])")

    ast4 =
      string_to_ast("""
      Kitchen.Repo.delete_all(
        from(m in Meat,
          where: m.id == ^id
        )
      )
      """)

    ast5 =
      string_to_ast("""
      stuff
        |> change()
        |> some_fun1(data[:some_key])
        |> some_fun2(this: data[:other_key])
        |> Repo.update!()
      """)

    assert [operation_insert: 3] == Parser.parse(ast1)
    assert [operation_insert: 1] == Parser.parse(ast2)
    assert [operation_update: 1] == Parser.parse(ast3)
    assert [operation_delete: 1] == Parser.parse(ast4)
    assert [operation_update: 5] == Parser.parse(ast5)
  end

  test "detects danger and safety assured" do
    assert [safety_assured: true, index_not_concurrently: 7] == Parser.parse(safety_assured_ast())
  end

  test "detects raw SQL executed" do
    assert [raw_sql: 2, raw_sql: 6] == Parser.parse(raw_sql_executed_ast())
  end

  test "detects index added not concurrently" do
    ast = string_to_ast("create index(:dumplings, [:dough], unique: true)")
    assert [index_not_concurrently: 1] == Parser.parse(ast)
  end

  test "detects column added with default" do
    assert [column_added_with_default: 2] ==
             Parser.parse(add_column_with_default_in_existing_table_ast())

    assert [] == Parser.parse(add_column_with_default_in_new_table_ast())
  end

  test "detects column removed" do
    ast1 = string_to_ast("remove(:size, :string)")
    assert [column_removed: 1] == Parser.parse(ast1)
    ast2 = string_to_ast("remove(:size, :string, default: \"big\")")
    assert [column_removed: 1] == Parser.parse(ast2)
    ast3 = string_to_ast("remove(:size, :string)")
    assert [column_removed: 1] == Parser.parse(ast3)
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
