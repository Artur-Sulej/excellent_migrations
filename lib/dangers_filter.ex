defmodule ExcellentMigrations.DangersFilter do
  def reject_dangers(dangers, skipped_types) do
    dangers
    |> reject_safety_assured()
    |> skip_ignored_checks(skipped_types)
  end

  defp reject_safety_assured(dangers) do
    if Keyword.get(dangers, :safety_assured) do
      []
    else
      Keyword.delete(dangers, :safety_assured)
    end
  end

  defp skip_ignored_checks(dangers, skipped_types) do
    Enum.reduce(skipped_types, dangers, fn skipped_type, dangers_acc ->
      Keyword.delete(dangers_acc, skipped_type)
    end)
  end
end
