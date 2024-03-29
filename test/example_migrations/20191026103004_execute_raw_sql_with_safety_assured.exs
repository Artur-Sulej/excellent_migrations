defmodule ExcellentMigrations.AddSomethingToVegetables do
  @safety_assured :all

  def up do
    execute("ALTER TABLE vegetables ADD COLUMN something integer;")
  end

  def down do
    execute("ALTER TABLE vegetables DROP COLUMN something;")
  end
end
