defmodule DB.Repo.Migrations.AddForeignKeyInvalid do
  use Ecto.Migration

  def change do
    alter table("posts") do
      add(:group_id, references("groups"))
    end
  end
end
