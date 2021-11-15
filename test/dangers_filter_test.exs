defmodule ExcellentMigrations.DangersFilterTest do
  use ExUnit.Case
  alias ExcellentMigrations.DangersFilter

  test "returns empty for empty" do
    assert [] == DangersFilter.reject_dangers([], [])
  end

  test "returns all if no ignoring" do
    assert [raw_sql_executed: 5] == DangersFilter.reject_dangers([raw_sql_executed: 5], [])
  end

  test "rejects given types" do
    assert [column_renamed: 10] ==
             DangersFilter.reject_dangers(
               [raw_sql_executed: 5, column_renamed: 10],
               [:raw_sql_executed]
             )

    assert [column_renamed: 10] ==
             DangersFilter.reject_dangers(
               [raw_sql_executed: 5, raw_sql_executed: 6, column_renamed: 10],
               [:raw_sql_executed]
             )
  end

  test "rejects all if safety assured for all" do
    assert [] ==
             DangersFilter.reject_dangers(
               [table_renamed: 5, safety_assured: :all],
               []
             )

    assert [] ==
             DangersFilter.reject_dangers(
               [table_renamed: 5, column_renamed: 8, safety_assured: :all],
               []
             )
  end

  test "rejects only types that have safety assured" do
    assert [table_renamed: 5] ==
             DangersFilter.reject_dangers(
               [table_renamed: 5, column_renamed: 8, safety_assured: [:column_renamed]],
               []
             )

    assert [] ==
             DangersFilter.reject_dangers(
               [column_renamed: 8, safety_assured: [:column_renamed]],
               []
             )

    assert [] ==
             DangersFilter.reject_dangers(
               [
                 table_renamed: 5,
                 column_renamed: 8,
                 safety_assured: [:table_renamed, :column_renamed]
               ],
               []
             )
  end

  test "rejects types from multiple safety_assured" do
    assert [column_removed: 11] ==
             DangersFilter.reject_dangers(
               [
                 table_renamed: 5,
                 column_renamed: 8,
                 column_renamed: 10,
                 column_removed: 11,
                 safety_assured: [:column_renamed],
                 safety_assured: [:table_renamed]
               ],
               []
             )
  end

  test "safety_assured: :all is ignored if there are specific types listed" do
    assert [table_renamed: 5] ==
             DangersFilter.reject_dangers(
               [table_renamed: 5, column_renamed: 8, safety_assured: [:all, :column_renamed]],
               []
             )

    assert [table_renamed: 5] ==
             DangersFilter.reject_dangers(
               [
                 table_renamed: 5,
                 column_renamed: 8,
                 safety_assured: [:all],
                 safety_assured: [:column_renamed]
               ],
               []
             )
  end
end
