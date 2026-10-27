defmodule ExcellentMigrations.FilesFinderTest do
  use ExUnit.Case

  alias ExcellentMigrations.FilesFinder

  test "recognizes Windows-style migration paths" do
    path =
      "C:/project/priv/repo/migrations/20261001_add_example.exs"
      |> String.replace("/", "\\")

    assert FilesFinder.relevant_file?(path, "20260930")
  end

  test "excludes Windows-style dependency migration paths" do
    path =
      "C:/project/deps/example/priv/repo/migrations/20261001_add_example.exs"
      |> String.replace("/", "\\")

    refute FilesFinder.relevant_file?(path, "20260930")
  end
end
