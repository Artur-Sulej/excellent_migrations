defmodule ExcellentMigrations.AddKindToFruitsWithStringType do
  def change do
    alter table("fruits") do
      add(:kind, :string)
      add(:size, :string, null: true)
    end
  end
end
