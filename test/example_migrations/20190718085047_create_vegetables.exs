defmodule CreateVegetables do
  @moduledoc "Some doc."

  # Some comment
  def change do
    create table(:vegetables) do
      add(:color, :integer, null: false, default: 0)
    end
  end
end
