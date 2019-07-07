defmodule Parser do
  def parse(ast) do
    _parse(ast, [])
  end

  defp _parse(
         {
           :def,
           _,
           [{name, _, _}, [do: {:__block__, _, body}]]
         },
         acc
       ) do
    parse_body(body, acc)
  end

  defp _parse(
         {
           :def,
           _,
           [{name, _, _}, [do: body]]
         },
         acc
       ) do
    parse_body(body, acc)
  end

  defp _parse({:@, _, [{:safety_assured, _, [name]}]}, acc) do
    [{:safety_assured, name} | acc]
  end

  defp _parse({_name, _meta, args}, acc) do
    _parse(args, acc)
  end

  defp _parse({:do, tuple}, acc) do
    _parse(tuple, acc)
  end

  defp _parse([head | tail], acc) do
    new_acc = _parse(head, acc)
    _parse(tail, new_acc)
  end

  defp _parse([], acc), do: acc

  defp _parse(other, acc) when is_atom(other), do: acc

  defp parse_body(body, acc) do
    IO.puts("---- body #{inspect(body)} ---")
    dangers =
      check_for_execute(body)
      ++ check_for_index_concurrently(body)

    dangers = Enum.reject(dangers, &is_nil/1)
    acc ++ dangers
  end

  defp check_for_execute({:execute, [line: line], _}) do
    [{:execute, line}]
  end

  defp check_for_execute([head | tail]) do
    check_for_execute(head) ++ check_for_execute(tail)
  end

  defp check_for_execute(_), do: []

  defp check_for_index_concurrently({:create, [line: line], [{:index, _, [_table, _columns, options]}]}) do
    case Keyword.get(options, :concurrently) do
      true -> []
      _ -> [{:index_not_concurrently, line}]
    end
  end

  defp check_for_index_concurrently([head | tail]) do
    check_for_index_concurrently(head) ++ check_for_index_concurrently(tail)
  end

  defp check_for_index_concurrently(_), do: []
end
