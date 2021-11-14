defmodule ExcellentMigrations.AddTasteToDumplingsWithDefault do
  def change do
    alter table("dumplings") do
      add(:taste, :string, default: "sweet")
      add(:size, :string, default: "big")
    end
  end
end
