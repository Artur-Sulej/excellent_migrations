defmodule ExcellentMigrations.FilesReader do
  def get_paths do
    [
      "test/example_migrations/20180718085047_create_dumplings.txt",
      "test/example_migrations/20180830090807_add_index_to_dumplings.exs"
    ]
  end
end
