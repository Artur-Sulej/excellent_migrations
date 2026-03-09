defmodule ExcellentMigrations.CreateIndexOnPineapples do
  def up do
    execute("CREATE INDEX pineapples_geog ON pineapples using GIST(Geography(geom));")
  end

  def down do
    execute("DROP INDEX pineapples_geog;")
  end
end
