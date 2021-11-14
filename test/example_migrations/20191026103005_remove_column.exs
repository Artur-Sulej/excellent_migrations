defmodule ExcellentMigrations.RemoveSizeFromDumplings do
  def change do
    alter table("dumplings") do
      remove(:size, :string, default: "")
    end
  end
end
