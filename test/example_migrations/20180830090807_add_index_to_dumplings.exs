defmodule AddStuffToDumplings do
  def up do
    execute("CREATE INDEX dumplings_geog ON dumplings using GIST(Geography(geom));")
  end

  def down do
    execute("DROP INDEX dumplings_geog;")
  end
end
