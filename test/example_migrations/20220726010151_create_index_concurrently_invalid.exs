defmodule ExcellentMigrations.CreateIndexConcurrentlyInvalid do
  @disable_migration_lock true
  @disable_ddl_transaction true

  def up do
    create(index(:dumplings, [:dough], concurrently: false))
    create_if_not_exists(index(:dumplings, [:dough], concurrently: false))
    create(unique_index(:dumplings, [:dough], concurrently: false))
    create_if_not_exists(unique_index(:dumplings, [:dough], concurrently: false))
  end

  def down do
    drop(index(:dumplings, [:dough], concurrently: false))
    drop_if_exists(index(:dumplings, [:dough], concurrently: false))
    drop(unique_index(:dumplings, [:dough], concurrently: false))
    drop_if_exists(unique_index(:dumplings, [:dough], concurrently: false))
  end
end
