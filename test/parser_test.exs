defmodule ExcellentMigrations.ParserTest do
  use ExUnit.Case
  alias ExcellentMigrations.Parser

  test "generates warnings for migrations" do
    assert [raw_sql: 5, raw_sql: 9] == Parser.parse(migration_ast1())
    assert [] == Parser.parse(migration_ast2())
    assert [] == Parser.parse(migration_ast3())
    assert [safety_assured: true] == Parser.parse(migration_ast4())
    assert [safety_assured: true, index_not_concurrently: 10] == Parser.parse(migration_ast5())
    assert [column_removed: 4] == Parser.parse(remove_column_ast())
  end

  defp get_ast_from_file(path) do
    {:ok, ast} = Code.string_to_quoted(File.read!(path))
    ast
  end

  defp remove_column_ast do
    get_ast_from_file("test/example_migrations/20200718085047_remove_column.exs")
  end

  defp migration_ast1 do
    string_to_ast("""
    defmodule Migrations.AddRecipeIndexToDumplings do
      use Ecto.Migration

      def up do
        execute("CREATE INDEX idx_dumplings_geog ON dumplings using GIST(Geography(geom));")
      end

      def down do
        execute("DROP INDEX idx_dumplings_geog;")
      end
    end
    """)
  end

  defp migration_ast2 do
    string_to_ast("""
    defmodule Migrations.AddRecipeIdToDumplings do
      use Ecto.Migration

      def change do
        add(:recipe_id, references(:recipes, on_delete: :delete_all), null: false)
        remove(:created_at)
      end
    end
    """)
  end

  defp migration_ast3 do
    string_to_ast("""
    defmodule Migrations.AddRecipeIdToDumplings do
      use Ecto.Migration

      def change do
        add(:recipe_id, references(:recipes, on_delete: :delete_all), null: false)
        remove(:created_at)
      end
    end
    """)
  end

  defp migration_ast4 do
    string_to_ast("""
    defmodule Migrations.AddRecipeIdToDumplings do
      use Ecto.Migration

      @safety_assured true
      def change do
        alter(table(:dumplings)) do
          add(:recipe_id, references(:recipes, on_delete: :delete_all), null: false)
        end
      end
    end
    """)
  end

  defp migration_ast5 do
    string_to_ast("""
    defmodule Migrations.AddRecipeIdToDumplings do
      use Ecto.Migration

      @safety_assured true
      def(change) do
        alter(table(:dumplings)) do
          add(:recipe_id, references(:recipes, on_delete: :delete_all), null: false)
        end

        create(index(:dumplings, [:recipe_id, :flour_id], unique: true))
      end
    end
    """)
  end

  defp string_to_ast(string) do
    {:ok, ast} = Code.string_to_quoted(string)
    ast
  end
end
