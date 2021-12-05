defmodule ExcellentMigrations.DangersFilter do
  @moduledoc false

  def reject_dangers(dangers, safety_assured, ignored_types) do
    dangers
    |> reject_by_safety_assured_attributes()
    |> delete_safety_assured_attributes()
    |> reject_types(ignored_types)
    |> reject_by_safety_assured_comments(safety_assured)
  end

  defp reject_by_safety_assured_attributes(dangers) do
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

  defp reject_by_safety_assured_comments(dangers, safe_types) do
    Enum.reduce(safe_types, dangers, fn
      {safe_type, :all}, dangers_acc -> Keyword.delete(dangers_acc, safe_type)
      {safe_type, line}, dangers_acc -> Keyword.delete(dangers_acc, safe_type, line + 1)
    end)
  end

  defp reject_types(dangers, ignored_types) do
    Enum.reduce(ignored_types, dangers, fn skipped_type, dangers_acc ->
      Keyword.delete(dangers_acc, skipped_type)
    end)
  end

  defp delete_safety_assured_attributes(dangers) do
    Keyword.delete(dangers, :safety_assured)
  end
end
