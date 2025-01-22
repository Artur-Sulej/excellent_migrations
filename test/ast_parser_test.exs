defmodule ExcellentMigrations.AstParserTest do
  use ExUnit.Case
  alias ExcellentMigrations.AstParser

  test "detects table renamed" do
    ast =
      string_to_ast(~s"""
      rename table("recipes"), to: table("dish_algorithms")
      """)

    assert [table_renamed: 1] == AstParser.parse(ast)
  end

  test "detects column renamed" do
    ast = string_to_ast("rename table(:recipes), :filling, to: :stuffing")
    assert [column_renamed: 1] == AstParser.parse(ast)
  end

  test "detects column type changed" do
    ast = string_to_ast("modify(:size, :integer, from: :string)")
    assert [column_type_changed: 1] == AstParser.parse(ast)
  end

  test "detects not null constraint added to column" do
    ast = string_to_ast("modify :cookbook_id, :integer, null: false")
    assert [column_type_changed: 1, not_null_added: 1] == AstParser.parse(ast)
  end

  for fun_name <- [:add, :add_if_not_exists] do
    test "detects json column added using #{fun_name}" do
      ast_bad_1 =
        string_to_ast(~s"""
        alter table(:recipes) do
          #{unquote(fun_name)} :details, :json
        end
        """)

      ast_bad_2 =
        string_to_ast(~s"""
        alter table(:recipes) do
          #{unquote(fun_name)} :details, :json, null: false, default: "{}"
        end
        """)

      assert [{:json_column_added, 2}] == AstParser.parse(ast_bad_1)

      assert [{:json_column_added, 2}, {:column_added_with_default, 2}] ==
               AstParser.parse(ast_bad_2)

      ast_good_1 =
        string_to_ast(~s"""
        alter table(:recipes) do
          #{unquote(fun_name)} :details, :jsonb
        end
        """)

      ast_good_2 =
        string_to_ast(~s"""
        alter table(:recipes) do
          #{unquote(fun_name)} :details, :jsonb, null: false, default: "{}"
        end
        """)

      assert [] == AstParser.parse(ast_good_1)
      assert [{:column_added_with_default, 2}] == AstParser.parse(ast_good_2)
    end
  end

  for fun_name <- [:add, :add_if_not_exists] do
    test "detects reference added on add with [validate: false] option using #{fun_name}" do
      ast_bad_1 =
        string_to_ast(~s"""
        alter table(:recipes) do
          #{unquote(fun_name)} :ingredient_id, references(:ingredients)
        end
        """)

      ast_bad_2 =
        string_to_ast(~s"""
        alter table(:recipes) do
          #{unquote(fun_name)} :ingredient_id, references(:ingredients, on_delete: :delete_all)
        end
        """)

      ast_bad_3 =
        string_to_ast(~s"""
        alter table(:recipes) do
          #{unquote(fun_name)} :ingredient_id, references(:ingredients, on_delete: :delete_all), null: true
        end
        """)

      assert [{:column_reference_added, 2}] == AstParser.parse(ast_bad_1)
      assert [{:column_reference_added, 2}] == AstParser.parse(ast_bad_2)
      assert [{:column_reference_added, 2}] == AstParser.parse(ast_bad_3)

      ast_good_1 =
        string_to_ast(~s"""
        alter table(:recipes) do
          #{unquote(fun_name)} :ingredient_id, references(:ingredients, validate: false)
        end
        """)

      ast_good_2 =
        string_to_ast(~s"""
        alter table(:recipes) do
          #{unquote(fun_name)} :ingredient_id, references(:ingredients, validate: false), null: true
        end
        """)

      assert [] == AstParser.parse(ast_good_1)
      assert [] == AstParser.parse(ast_good_2)
    end
  end

  test "detects check constraint added" do
    ast =
      string_to_ast(~s"""
      create constraint("ingredients", :price_must_be_positive, check: "price > 0")
      """)

    assert [check_constraint_added: 1] == AstParser.parse(ast)
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

    assert [operation_insert: 3] == AstParser.parse(ast1)
    assert [operation_insert: 1] == AstParser.parse(ast2)
    assert [operation_update: 1] == AstParser.parse(ast3)
    assert [operation_delete: 1] == AstParser.parse(ast4)
    assert [operation_update: 5] == AstParser.parse(ast5)
  end

  test "detects danger and safety assured" do
    assert [safety_assured: [:index_not_concurrently], index_not_concurrently: 7] ==
             AstParser.parse(safety_assured_ast())
  end

  test "detects raw SQL executed" do
    ast1 =
      string_to_ast("""
      def up do
        execute("CREATE INDEX idx_recipes_geog ON recipes using GIST(Geography(geom));")
      end

      def down do
        execute("DROP INDEX idx_recipes_geog;")
      end
      """)

    ast2 = string_to_ast(~s(execute "SQL up", "SQL down"))
    assert [raw_sql_executed: 2, raw_sql_executed: 6] == AstParser.parse(ast1)
    assert [raw_sql_executed: 1] == AstParser.parse(ast2)
  end

  test "detects index added not concurrently" do
    ast_single = string_to_ast("create index(:recipes, :cuisine)")
    ast_single_with_opts = string_to_ast("create index(:recipes, :cuisine, unique: true)")
    ast_multi = string_to_ast("create index(:recipes, [:cuisine])")
    ast_multi_with_opts = string_to_ast("create index(:recipes, [:cuisine], unique: true)")
    ast_conc_false = string_to_ast("create index(:recipes, [:cuisine], concurrently: false)")
    ast_conc_true = string_to_ast("create index(:recipes, [:cuisine], concurrently: true)")

    assert [index_not_concurrently: 1] == AstParser.parse(ast_single)
    assert [index_not_concurrently: 1] == AstParser.parse(ast_single_with_opts)
    assert [index_not_concurrently: 1] == AstParser.parse(ast_multi)
    assert [index_not_concurrently: 1] == AstParser.parse(ast_multi_with_opts)
    assert [index_not_concurrently: 1] == AstParser.parse(ast_conc_false)
    assert [] == AstParser.parse(ast_conc_true)
  end

  test "detects index added not concurrently using if not exists" do
    ast_single = string_to_ast("create_if_not_exists index(:recipes, :cuisine)")

    ast_single_with_opts =
      string_to_ast("create_if_not_exists index(:recipes, :cuisine, unique: true)")

    ast_multi = string_to_ast("create_if_not_exists index(:recipes, [:cuisine])")

    ast_multi_with_opts =
      string_to_ast("create_if_not_exists index(:recipes, [:cuisine], unique: true)")

    ast_conc_false =
      string_to_ast("create_if_not_exists index(:recipes, [:cuisine], concurrently: false)")

    ast_conc_true =
      string_to_ast("create_if_not_exists index(:recipes, [:cuisine], concurrently: true)")

    assert [index_not_concurrently: 1] == AstParser.parse(ast_single)
    assert [index_not_concurrently: 1] == AstParser.parse(ast_single_with_opts)
    assert [index_not_concurrently: 1] == AstParser.parse(ast_multi)
    assert [index_not_concurrently: 1] == AstParser.parse(ast_multi_with_opts)
    assert [index_not_concurrently: 1] == AstParser.parse(ast_conc_false)
    assert [] == AstParser.parse(ast_conc_true)
  end

  test "detects unique index added not concurrently" do
    ast_single = string_to_ast("create unique_index(:recipes, :cuisine)")
    ast_single_with_opts = string_to_ast("create unique_index(:recipes, :cuisine, unique: true)")
    ast_multi = string_to_ast("create unique_index(:recipes, [:cuisine])")
    ast_multi_with_opts = string_to_ast("create unique_index(:recipes, [:cuisine], unique: true)")

    ast_conc_false =
      string_to_ast("create unique_index(:recipes, [:cuisine], concurrently: false)")

    ast_conc_true = string_to_ast("create unique_index(:recipes, [:cuisine], concurrently: true)")

    assert [index_not_concurrently: 1] == AstParser.parse(ast_single)
    assert [index_not_concurrently: 1] == AstParser.parse(ast_single_with_opts)
    assert [index_not_concurrently: 1] == AstParser.parse(ast_multi)
    assert [index_not_concurrently: 1] == AstParser.parse(ast_multi_with_opts)
    assert [index_not_concurrently: 1] == AstParser.parse(ast_conc_false)
    assert [] == AstParser.parse(ast_conc_true)
  end

  test "detects unique index added not concurrently using if not exists" do
    ast_single = string_to_ast("create_if_not_exists unique_index(:recipes, :cuisine)")

    ast_single_with_opts =
      string_to_ast("create_if_not_exists unique_index(:recipes, :cuisine, unique: true)")

    ast_multi = string_to_ast("create_if_not_exists unique_index(:recipes, [:cuisine])")

    ast_multi_with_opts =
      string_to_ast("create_if_not_exists unique_index(:recipes, [:cuisine], unique: true)")

    ast_conc_false =
      string_to_ast(
        "create_if_not_exists unique_index(:recipes, [:cuisine], concurrently: false)"
      )

    ast_conc_true =
      string_to_ast("create_if_not_exists unique_index(:recipes, [:cuisine], concurrently: true)")

    assert [index_not_concurrently: 1] == AstParser.parse(ast_single)
    assert [index_not_concurrently: 1] == AstParser.parse(ast_single_with_opts)
    assert [index_not_concurrently: 1] == AstParser.parse(ast_multi)
    assert [index_not_concurrently: 1] == AstParser.parse(ast_multi_with_opts)
    assert [index_not_concurrently: 1] == AstParser.parse(ast_conc_false)
    assert [] == AstParser.parse(ast_conc_true)
  end

  test "detects index with too many columns" do
    ast_too_many_not_concurrently =
      string_to_ast("create index(\"ingredients\", [:a, :b, :c, :d])")

    ast_many_columns =
      string_to_ast("create index(:ingredients, [:a, :b, :c, :d], concurrently: true)")

    ast_many_but_unique =
      string_to_ast(
        "create index(\"ingredients\", [:a, :b, :c, :d], concurrently: true, unique: true)"
      )

    ast_ok = string_to_ast("create index(\"ingredients\", [:a, :b, :c], concurrently: true)")

    ast_single_with_opts =
      string_to_ast("create index(\"ingredients\", :one_column, concurrently: true)")

    assert [index_not_concurrently: 1, many_columns_index: 1] ==
             AstParser.parse(ast_too_many_not_concurrently)

    assert [many_columns_index: 1] == AstParser.parse(ast_many_columns)
    assert [] == AstParser.parse(ast_many_but_unique)
    assert [] == AstParser.parse(ast_ok)
    assert [] == AstParser.parse(ast_single_with_opts)
  end

  test "detects column added with default" do
    alter_table =
      string_to_ast("""
      alter table("recipes") do
        add(:taste, :string, default: "sweet")
      end
      """)

    create_table =
      string_to_ast("""
      create table("recipes") do
        add(:taste, :string, default: "sweet")
      end
      """)

    assert [column_added_with_default: 2] == AstParser.parse(alter_table)
    assert [] == AstParser.parse(create_table)
  end

  test "detects column default changed to volatile" do
    ast =
      string_to_ast("""
      alter table("recipes") do
        modify(:boiling_minutes, :integer, default: fragment("random()"))
      end
      """)

    assert [column_volatile_default: 2, column_type_changed: 2] == AstParser.parse(ast)
  end

  test "detects column added with volatile default" do
    ast_add_column1 =
      string_to_ast("""
      alter table("recipes") do
        add_if_not_exists(:identifier, :uuid, default: fragment("uuid_generate_v4()"))
      end
      """)

    ast_add_column2 =
      string_to_ast("""
      alter table("recipes") do
        add(:timestamp, :uuid, default: fragment("now()"))
      end
      """)

    ast_create_empty_table =
      string_to_ast("""
      create table("recipes") do
        add(:timestamp, :uuid, default: fragment("now()"))
      end
      """)

    assert [column_added_with_default: 2, column_volatile_default: 2] ==
             AstParser.parse(ast_add_column1)

    assert [column_added_with_default: 2, column_volatile_default: 2] ==
             AstParser.parse(ast_add_column2)

    assert [] == AstParser.parse(ast_create_empty_table)
  end

  test "detects column added with default using if not exists" do
    ast =
      string_to_ast("""
      alter table("recipes") do
        add_if_not_exists(:taste, :string, default: "sweet")
      end
      """)

    assert [column_added_with_default: 2] == AstParser.parse(ast)
  end

  test "detects column removed" do
    ast1 = string_to_ast("remove(:size, :string)")
    assert [column_removed: 1] == AstParser.parse(ast1)

    ast2 = string_to_ast("remove :size, :string, default: \"big\"")
    assert [column_removed: 1] == AstParser.parse(ast2)

    ast3 = string_to_ast("remove_if_exists :size, :string")
    assert [column_removed: 1] == AstParser.parse(ast3)
  end

  test "detects table dropped" do
    ast1 = string_to_ast("drop_if_exists table(:recipes), mode: :cascade")
    ast2 = string_to_ast("drop_if_exists table(:recipes)")
    ast3 = string_to_ast("drop table(:recipes), mode: :cascade")
    ast4 = string_to_ast("drop table(:recipes)")

    assert [table_dropped: 1] == AstParser.parse(ast1)
    assert [table_dropped: 1] == AstParser.parse(ast2)
    assert [table_dropped: 1] == AstParser.parse(ast3)
    assert [table_dropped: 1] == AstParser.parse(ast4)
  end

  defp safety_assured_ast do
    string_to_ast("""
    @safety_assured [:index_not_concurrently]
    def change do
      alter(table(:recipes)) do
        add(:cookbook_id, references(:cookbooks, on_delete: :delete_all, validate: false), null: false)
      end

      create(index(:recipes, [:cookbook_id, :cuisine], unique: true))
    end
    """)
  end

  defp string_to_ast(string) do
    Code.string_to_quoted!(string)
  end
end
