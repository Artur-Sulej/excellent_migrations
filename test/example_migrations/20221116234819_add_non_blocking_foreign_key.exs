defmodule DB.Repo.Migrations.AddNonBlockingForeignKey do
  use Ecto.Migration

  def change do
    alter table("posts") do
      add(:group_id, references("groups", validate: false))
    end
  end
end
