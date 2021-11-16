defmodule ExcellentMigrations.MessageGenerator do
  @moduledoc false

  def build_message(danger_type, path, line) do
    "#{build_message(danger_type)} in #{path}:#{line}"
  end

  def build_message(:raw_sql_executed) do
    "Raw SQL used"
  end

  def build_message(:index_not_concurrently) do
    "Index added not concurrently"
  end

  def build_message(:many_columns_index) do
    "Index added many columns"
  end

  def build_message(:column_added_with_default) do
    "Column with default value added to existing table"
  end

  def build_message(:column_removed) do
    "Column removed"
  end

  def build_message(:table_renamed) do
    "Table renamed"
  end

  def build_message(:column_renamed) do
    "Column renamed"
  end

  def build_message(:not_null_added) do
    "Not null constraint added"
  end

  def build_message(:column_type_changed) do
    "Column type changed"
  end

  def build_message(:operation_insert) do
    "Records inserted"
  end

  def build_message(:operation_update) do
    "Records updated"
  end

  def build_message(:operation_delete) do
    "Records deleted"
  end
end
