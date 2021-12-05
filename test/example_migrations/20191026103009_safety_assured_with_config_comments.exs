defmodule ExcellentMigrations.AddSomethingToVegetables do
  def up do
    # excellent_migrations:safety-assured-for-this-file raw_sql_executed
    execute("ALTER TABLE vegetables ADD COLUMN something integer;")
  end

  def down do
    execute("ALTER TABLE vegetables DROP COLUMN something;")
  end
end
