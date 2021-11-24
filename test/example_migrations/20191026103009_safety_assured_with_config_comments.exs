defmodule ExcellentMigrations.AddSomethingToVegetables do
  def up do
    # safety_assured:raw_sql_executed
    execute("ALTER TABLE vegetables ADD COLUMN something integer;")
  end

  def down do
    execute("ALTER TABLE vegetables DROP COLUMN something;")
  end
end
