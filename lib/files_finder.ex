defmodule ExcellentMigrations.FilesFinder do
  def get_migrations_paths do
    start_after = Application.get_env(:excellent_migrations, :start_after)

    "**/migrations/*.exs"
    |> Path.wildcard()
    |> Enum.reject(fn path ->
      String.starts_with?(path, ["deps/", "_build/"]) ||
        String.contains?(path, ["/deps/", "/_build/"]) ||
        Path.basename(path) <= start_after
    end)
  end
end
