defmodule ExcellentMigrations.Parser do
  @moduledoc false
  @max_columns_for_index 3

  def parse(ast) do
    traverse_ast(ast, &detect_dangers/1)
  end

  defp traverse_ast(ast, detect_fun) do
    {_ast, dangers} =
      Macro.postwalk(ast, [], fn code_part, acc ->
        new_acc = acc ++ detect_fun.(code_part)
        {code_part, new_acc}
      end)

    dangers
  end

  defp detect_dangers(code_part) do
    detect_index_not_concurrently(code_part) ++
      detect_many_columns_index(code_part) ++
      detect_raw_sql(code_part) ++
      detect_safety_assured(code_part) ++
      detect_column_removed(code_part) ++
      detect_table_dropped(code_part) ++
      detect_table_renamed(code_part) ++
      detect_column_renamed(code_part) ++
      detect_column_added_with_default(code_part) ++
      detect_column_modified(code_part) ++
      detect_not_null_added(code_part) ++
      detect_check_constraint(code_part) ++
      detect_records_modified(code_part) ++
      detect_json_column_added(code_part)
  end

  defp detect_index_not_concurrently({:create, location, [{:index, _, [_, _]}]}) do
    [{:index_not_concurrently, Keyword.get(location, :line)}]
  end

  defp detect_index_not_concurrently({:create, location, [{:index, _, [_, _, options]}]}) do
    case Keyword.get(options, :concurrently) do
      true -> []
      _ -> [{:index_not_concurrently, Keyword.get(location, :line)}]
    end
  end

  defp detect_index_not_concurrently(_), do: []

  defp detect_many_columns_index({:create, location, [{:index, _, [_, columns, options]}]}) do
    cond do
      Keyword.get(options, :unique) ->
        []

      Enum.count(columns) > @max_columns_for_index ->
        [{:many_columns_index, Keyword.get(location, :line)}]

      true ->
        []
    end
  end

  defp detect_many_columns_index({:create, location, [{:index, _, [_, columns]}]}) do
    if Enum.count(columns) > @max_columns_for_index do
      [{:many_columns_index, Keyword.get(location, :line)}]
    else
      []
    end
  end

  defp detect_many_columns_index(_), do: []

  defp detect_column_removed({:remove, location, _}) do
    [{:column_removed, Keyword.get(location, :line)}]
  end

  defp detect_column_removed({:remove_if_exists, location, _}) do
    [{:column_removed, Keyword.get(location, :line)}]
  end

  defp detect_column_removed(_), do: []

  defp detect_table_dropped({:drop, location, [{:table, _, _}]}) do
    [{:table_dropped, Keyword.get(location, :line)}]
  end

  defp detect_table_dropped({:drop, location, [{:table, _, _}, _]}) do
    [{:table_dropped, Keyword.get(location, :line)}]
  end

  defp detect_table_dropped({:drop_if_exists, location, [{:table, _, _}]}) do
    [{:table_dropped, Keyword.get(location, :line)}]
  end

  defp detect_table_dropped({:drop_if_exists, location, [{:table, _, _}, _]}) do
    [{:table_dropped, Keyword.get(location, :line)}]
  end

  defp detect_table_dropped(_), do: []

  defp detect_raw_sql({:execute, location, _}) do
    [{:raw_sql_executed, Keyword.get(location, :line)}]
  end

  defp detect_raw_sql(_), do: []

  defp detect_table_renamed({:rename, location, [{:table, _, _}, [to: {:table, _, _}]]}) do
    [{:table_renamed, Keyword.get(location, :line)}]
  end

  defp detect_table_renamed(_), do: []

  defp detect_column_renamed({:rename, location, [{:table, _, _}, _, [to: _]]}) do
    [{:column_renamed, Keyword.get(location, :line)}]
  end

  defp detect_column_renamed(_), do: []

  def detect_column_added_with_default({:alter, _, [{:table, _, _}, _]} = ast) do
    traverse_ast(ast, &detect_column_added_with_default_inner/1)
  end

  def detect_column_added_with_default(_), do: []

  def detect_column_modified(
        {:modify, location, [_, {:references, _, _}, [from: {:references, _, _}]]}
      ) do
    [{:column_reference_added, Keyword.get(location, :line)}]
  end

  def detect_column_modified({:modify, location, [_, {:references, _, _}]}) do
    [{:column_reference_added, Keyword.get(location, :line)}]
  end

  def detect_column_modified({:modify, location, _}) do
    [{:column_type_changed, Keyword.get(location, :line)}]
  end

  def detect_column_modified(_), do: []

  def detect_not_null_added({:modify, location, [_, _, options]}) do
    if Keyword.get(options, :null) do
      [{:not_null_added, Keyword.get(location, :line)}]
    else
      []
    end
  end

  def detect_not_null_added(_), do: []

  def detect_json_column_added({:add, location, [_, :json, _]}) do
    [{:json_column_added, Keyword.get(location, :line)}]
  end

  def detect_json_column_added(_), do: []

  def detect_check_constraint({:create, location, [{:constraint, _, _}]}) do
    [{:check_constraint_added, Keyword.get(location, :line)}]
  end

  def detect_check_constraint(_), do: []

  def detect_records_modified({:., location, [{:__aliases__, _, modules}, operation]}) do
    if Enum.member?(modules, :Repo) do
      danger =
        operation
        |> Atom.to_string()
        |> String.replace_suffix("!", "")
        |> String.replace_suffix("_all", "")
        |> (&"operation_#{&1}").()
        |> String.to_atom()

      [{danger, Keyword.get(location, :line)}]
    else
      []
    end
  end

  def detect_records_modified(_), do: []

  defp detect_column_added_with_default_inner({:add, location, [_, _, options]}) do
    if Keyword.has_key?(options, :default) do
      [{:column_added_with_default, Keyword.get(location, :line)}]
    else
      []
    end
  end

  defp detect_column_added_with_default_inner(_), do: []

  defp detect_safety_assured({:@, _, [{:safety_assured, _, [value]}]}) do
    [{:safety_assured, value}]
  end

  defp detect_safety_assured(_), do: []
end
