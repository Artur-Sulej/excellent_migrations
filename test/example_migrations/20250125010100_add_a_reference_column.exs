defmodule ExcellentMigrations.AddAReferenceColumn do
  def change do
    alter table(:dumplings) do
      add(:vegetable_id, references(:vegetables, on_delete: :delete_all), null: true)
    end
  end
end
