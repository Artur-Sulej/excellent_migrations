defmodule AddTasteToDumplingsWithDefault do
  def change do
    alter table("dumplings") do
      add(:taste, :string, default: "sweet")
    end
  end
end
