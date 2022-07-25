defmodule ExcellentMigrations.CreateIndex do
  def up do
    create(index(:dumplings, [:dough]))
    create_if_not_exists(index(:dumplings, [:dough]))
  end

  def down do
    drop(index(:dumplings, [:dough]))
    drop_if_exists(index(:dumplings, [:dough]))
  end
end
