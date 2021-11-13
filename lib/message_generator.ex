defmodule ExcellentMigrations.MessageGenerator do
  def build_message(:execute, path, line) do
    "Raw SQL used in #{path}:#{line}"
  end

  def build_message(:index_not_concurrently, path, line) do
    "Index added not concurrently in #{path}:#{line}"
  end
end
