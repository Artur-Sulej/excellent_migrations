defmodule ExcellentMigrations.CreateUniqueIndex do
  def up do
    create(unique_index(:dumplings, [:dough]))
    create_if_not_exists(unique_index(:dumplings, [:dough]))
  end

  def down do
    drop(unique_index(:dumplings, [:dough]))
    drop_if_exists(unique_index(:dumplings, [:dough]))
  end
end
