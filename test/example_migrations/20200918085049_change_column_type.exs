defmodule ChangeColumnSizeTypeToInteger do
  def change do
    alter table(:dumplings) do
      modify(:size, :integer)
    end
  end
end
