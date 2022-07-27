defmodule ExcellentMigrations.CreateIndexConcurrently do
  @disable_ddl_transaction true
  @disable_migration_lock true

  def up do
    create(index(:dumplings, [:dough], concurrently: true))
    create_if_not_exists(index(:dumplings, [:dough], concurrently: true))
    create(unique_index(:dumplings, [:dough], concurrently: true))
    create_if_not_exists(unique_index(:dumplings, [:dough], concurrently: true))
  end

  def down do
    drop(index(:dumplings, [:dough], concurrently: true))
    drop_if_exists(index(:dumplings, [:dough], concurrently: true))
    drop(unique_index(:dumplings, [:dough], concurrently: true))
    drop_if_exists(unique_index(:dumplings, [:dough], concurrently: true))
  end
end
