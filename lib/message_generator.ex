defmodule ExcellentMigrations.MessageGenerator do
  def get_message(:execute, path, line) do
    "Raw SQL used in file #{path}:#{line}"
  end

  def get_message(:index_not_concurrently, path, line) do
    "Index added not concurrently in file #{path}:#{line}"
  end
end
