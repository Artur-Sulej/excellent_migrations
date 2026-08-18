defmodule ExcellentMigrations.DatabaseConfig do
  @moduledoc false

  @safe_since %{
    column_added_with_default: %{
      postgres: "11.0.0",
      mysql: "8.0.12",
      mariadb: "10.3.2"
    }
  }

  def reject_safe_operations(dangers, nil), do: dangers

  def reject_safe_operations(dangers, database),
    do: Enum.reject(dangers, &safe_operation?(&1, database))

  defp safe_operation?({danger_type, _line}, database) do
    db_engine = Keyword.fetch!(database, :engine)
    db_version = Keyword.fetch!(database, :version)

    case @safe_since[danger_type][db_engine] do
      nil -> false
      safe_since -> version_at_least?(db_version, safe_since)
    end
  end

  defp version_at_least?(version, safe_since) do
    version = version_parts(version)
    safe_since = safe_since |> version_parts() |> Enum.take(length(version))
    version >= safe_since
  end

  defp version_parts(version) do
    parts = String.split(version, ".")

    if length(parts) not in 1..3 do
      raise ArgumentError, "expected database version with one to three components"
    end

    Enum.map(parts, &String.to_integer/1)
  end
end
