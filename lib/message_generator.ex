defmodule ExcellentMigrations.MessageGenerator do
  def build_message(danger_type, path, line) do
    "#{build_message(danger_type)} in #{path}:#{line}"
  end

  def build_message(:raw_sql) do
    "Raw SQL used"
  end

  def build_message(:index_not_concurrently) do
    "Index added not concurrently"
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
end
