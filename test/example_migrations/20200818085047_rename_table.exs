defmodule RenameTable do
  def change do
    rename(table("dumplings"), to: table("noodles"))
  end
end
