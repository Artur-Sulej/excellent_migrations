defmodule ExcellentMigrations.FilesReader do
  def get_migrations_paths do
    "**/migrations/*.exs"
    |> Path.wildcard()
    |> Enum.reject(fn path ->
      String.starts_with?(path, ["deps/", "_build/"]) ||
        String.contains?(path, ["/deps/", "/_build/"])
    end)
  end
end
