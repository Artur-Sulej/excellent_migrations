defmodule ExcellentMigrations.CreateDumplings do
  def change do
    create table(:dumplings) do
      add(:dough, references(:dough_id, on_delete: :delete_all, validate: false), null: false)
      add(:size, :integer, null: false, default: 0)
    end

    create(index(:dumplings, [:dough], unique: true))
  end
end
