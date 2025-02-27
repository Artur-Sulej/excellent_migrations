defmodule ExcellentMigrations.AddTasteToDumplingsWithDefault do
  def change do
    alter table("dumplings") do
      add(:taste, :text, default: "sweet")
      add(:size, :text, default: "big")
    end
  end
end
