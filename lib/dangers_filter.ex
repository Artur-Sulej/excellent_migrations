defmodule ExcellentMigrations.DangersFilter do
  def reject_dangers(dangers, ignored_types) do
    dangers
    |> reject_safety_assured_types()
    |> reject_types(ignored_types)
    |> delete_safety_assured_data()
  end

  defp reject_safety_assured_types(dangers) do
    safety_assured_types =
      dangers
      |> Keyword.get_values(:safety_assured)
      |> Enum.flat_map(fn types -> List.wrap(types) end)
      |> Enum.uniq()

    case safety_assured_types do
      [:all] -> []
      danger_types -> reject_types(dangers, danger_types)
    end
  end

  defp reject_types(dangers, ignored_types) do
    Enum.reduce(ignored_types, dangers, fn skipped_type, dangers_acc ->
      Keyword.delete(dangers_acc, skipped_type)
    end)
  end

  defp delete_safety_assured_data(dangers) do
    Keyword.delete(dangers, :safety_assured)
  end
end
