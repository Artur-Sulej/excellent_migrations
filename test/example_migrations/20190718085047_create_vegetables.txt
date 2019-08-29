defmodule CreateVegetables do
  def change do
    create table(:vegetables) do
      add(:color, :integer, null: false, default: 0)
    end
  end
end
