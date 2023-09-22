defmodule ExcellentMigrations.CreateIndexUnconventionalStructure do
  def change do
    dumplings_index = index(:dumplings, [:dough])
    create(dumplings_index)

    :dumplings |> index([:dough]) |> create()
  end
end
