defmodule ExcellentMigrations.DangersFilter do
  @moduledoc false
  require Logger

  def filter_dangers(dangers, safety_assured, skipped_types) do
    dangers
    |> reject_by_safety_assured_attributes()
    |> delete_safety_assured_attributes()
    |> reject_types(skipped_types)
    |> reject_by_safety_assured_comments(safety_assured)
  end

  defp reject_by_safety_assured_attributes(dangers) do
    safety_assured_types =
      dangers
      |> Keyword.get_values(:safety_assured)
      |> Enum.flat_map(fn types -> List.wrap(types) end)
      |> Enum.uniq()

    unless Enum.empty?(safety_assured_types) do
      Logger.warning(
        "Using module attribute @safety_assured is deprecated. Use config comments instead."
      )
    end

    case safety_assured_types do
      [:all] -> []
      danger_types -> reject_types(dangers, danger_types)
    end
  end

  defp reject_by_safety_assured_comments(dangers, safety_assured) do
    safety_assured = advance_config_comments_to_skip_others(safety_assured)

    Enum.reduce(safety_assured, dangers, fn
      {safe_type, :all}, dangers_acc ->
        Keyword.delete(dangers_acc, safe_type)

      {safe_type, comment_line}, dangers_acc ->
        target_line = comment_line + 1

        Enum.reject(dangers_acc, fn
          {^safe_type, ^target_line} -> true
          _ -> false
        end)
    end)
  end

  defp advance_config_comments_to_skip_others(safety_assured_types) do
    safety_assured_types
    |> Enum.sort_by(&elem(&1, 1))
    |> Enum.reduce([], fn
      {_, line} = current, [{_, prev_line} | _] = acc
      when line - 1 == prev_line ->
        new_acc = increment_lines(acc, prev_line)
        [current | new_acc]

      current, acc ->
        [current | acc]
    end)
  end

  defp increment_lines(types, line) do
    Enum.map(types, fn
      {type, ^line} -> {type, line + 1}
      item -> item
    end)
  end

  defp reject_types(dangers, skipped_types) do
    Enum.reduce(skipped_types, dangers, fn skipped_type, dangers_acc ->
      Keyword.delete(dangers_acc, skipped_type)
    end)
  end

  defp delete_safety_assured_attributes(dangers) do
    Keyword.delete(dangers, :safety_assured)
  end
end
