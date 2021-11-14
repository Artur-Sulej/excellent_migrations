defmodule ExcellentMigrations.Parser do
  def parse(ast) do
    {_ast, dangers} =
      Macro.postwalk(ast, [], fn code_part, acc ->
        new_acc = acc ++ find_dangers(code_part)
        {code_part, new_acc}
      end)

    dangers
  end

  defp find_dangers(code_part) do
    find_index_not_concurrently(code_part) ++
      find_raw_sql(code_part) ++
      find_safety_assured(code_part) ++
      find_column_removed(code_part) ++
      find_table_renamed(code_part) ++
      find_column_added_with_default(code_part)
  end

  defp find_index_not_concurrently(
         {:create, location, [{:index, _, [_table, _columns, options]}]}
       ) do
    case Keyword.get(options, :concurrently) do
      true -> []
      _ -> [{:index_not_concurrently, Keyword.get(location, :line)}]
    end
  end

  defp find_index_not_concurrently(_), do: []

  defp find_column_removed({:remove, location, [_, _, _]}) do
    [{:column_removed, Keyword.get(location, :line)}]
  end

  defp find_column_removed(_), do: []

  defp find_raw_sql({:execute, location, _}) do
    [{:raw_sql, Keyword.get(location, :line)}]
  end

  defp find_raw_sql(_), do: []

  defp find_table_renamed({:rename, location, [{:table, _, _}, _]}) do
    [{:table_renamed, Keyword.get(location, :line)}]
  end

  defp find_table_renamed(_), do: []

  def find_column_added_with_default({:alter, _, [{:table, _, _}, _]} = ast) do
    {_ast, dangers} =
      Macro.postwalk(ast, [], fn code_part, acc ->
        new_acc = acc ++ find_column_added_with_default_inner(code_part)
        {code_part, new_acc}
      end)

    dangers
  end

  def find_column_added_with_default(_), do: []

  defp find_column_added_with_default_inner({:add, location, [_, _, options]}) do
    if Keyword.has_key?(options, :default) do
      [{:column_added_with_default, Keyword.get(location, :line)}]
    else
      []
    end
  end

  defp find_column_added_with_default_inner(_), do: []

  defp find_safety_assured({:@, _, [{:safety_assured, _, [value]}]}) do
    [{:safety_assured, value}]
  end

  defp find_safety_assured(_), do: []
end
