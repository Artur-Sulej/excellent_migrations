defmodule ExcellentMigrations.CreateVegetables do
  @moduledoc "Some doc."

  # Some comment
  def change do
    create table(:vegetables) do
      add(:color, :integer, null: false)
    end
  end
end
