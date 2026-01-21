defmodule AstMacro do
  defmacro ast(_line_arg \\ 1, do: ast) do
    double_quoted = Code.string_to_quoted!(inspect(ast))

    {result, _lines} =
      Macro.prewalk(double_quoted, 0, fn
        {:{}, _, [:_, _, nil]}, acc ->
          new_code_part = {:_, [], nil}
          {new_code_part, acc}

        [line: _line], acc ->
          new_code_part = [{:line, {:"line#{acc}", [], nil}}]
          {new_code_part, acc + 1}

        code_part, acc ->
          {code_part, acc}
      end)

    IO.puts("--- result #{inspect(result)} ---")
    IO.puts("--- result-to_string #{inspect(Macro.to_string(result))} ---")

    result
  end
end
