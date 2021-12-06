defmodule ExcellentMigrations.DangersFilterTest do
  use ExUnit.Case
  alias ExcellentMigrations.DangersFilter

  describe "no safety assured" do
    test "returns empty for empty" do
      assert [] == DangersFilter.filter_dangers([], [], [])
    end

    test "returns all if no ignoring" do
      assert [raw_sql_executed: 5] == DangersFilter.filter_dangers([raw_sql_executed: 5], [], [])
    end

    test "skips given types" do
      assert [column_renamed: 10] ==
               DangersFilter.filter_dangers(
                 [raw_sql_executed: 5, column_renamed: 10],
                 [],
                 [:raw_sql_executed]
               )

      assert [column_renamed: 10] ==
               DangersFilter.filter_dangers(
                 [raw_sql_executed: 5, raw_sql_executed: 6, column_renamed: 10],
                 [],
                 [:raw_sql_executed]
               )
    end
  end

  describe "safety assured via config comment" do
    test "skips danger with safety assured for whole file" do
      assert [] == DangersFilter.filter_dangers([column_renamed: 8], [column_renamed: :all], [])
    end

    test "skips danger with safety assured for next line" do
      assert [] == DangersFilter.filter_dangers([column_renamed: 8], [column_renamed: 7], [])
    end

    test "safety assured for next line omits line with comment" do
      assert [] ==
               DangersFilter.filter_dangers(
                 [column_type_changed: 8, not_null_added: 8],
                 [column_type_changed: 7, not_null_added: 6],
                 []
               )
    end

    test "leaves danger with safety assured for wrong line" do
      assert [column_renamed: 8] ==
               DangersFilter.filter_dangers([column_renamed: 8], [column_renamed: 6], [])
    end

    test "leaves danger with safety assured not matching danger type" do
      assert [column_renamed: 8] ==
               DangersFilter.filter_dangers([column_renamed: 8], [table_renamed: 7], [])
    end
  end

  describe "safety assured via module attribute" do
    test "rejects all if safety assured module attribute for all" do
      assert [] ==
               DangersFilter.filter_dangers(
                 [table_renamed: 5, safety_assured: :all],
                 [],
                 []
               )

      assert [] ==
               DangersFilter.filter_dangers(
                 [table_renamed: 5, column_renamed: 8, safety_assured: :all],
                 [],
                 []
               )
    end

    test "rejects only types that have safety assured module attribute" do
      assert [table_renamed: 5] ==
               DangersFilter.filter_dangers(
                 [table_renamed: 5, column_renamed: 8, safety_assured: [:column_renamed]],
                 [],
                 []
               )

      assert [] ==
               DangersFilter.filter_dangers(
                 [column_renamed: 8, safety_assured: [:column_renamed]],
                 [],
                 []
               )

      assert [] ==
               DangersFilter.filter_dangers(
                 [
                   table_renamed: 5,
                   column_renamed: 8,
                   safety_assured: [:table_renamed, :column_renamed]
                 ],
                 [],
                 []
               )
    end

    test "rejects types from multiple safety_assured module attribute" do
      assert [column_removed: 11] ==
               DangersFilter.filter_dangers(
                 [
                   table_renamed: 5,
                   column_renamed: 8,
                   column_renamed: 10,
                   column_removed: 11,
                   safety_assured: [:column_renamed],
                   safety_assured: [:table_renamed]
                 ],
                 [],
                 []
               )
    end

    test "module attribute safety_assured: :all is ignored if there are specific types listed" do
      assert [table_renamed: 5] ==
               DangersFilter.filter_dangers(
                 [table_renamed: 5, column_renamed: 8, safety_assured: [:all, :column_renamed]],
                 [],
                 []
               )

      assert [table_renamed: 5] ==
               DangersFilter.filter_dangers(
                 [
                   table_renamed: 5,
                   column_renamed: 8,
                   safety_assured: [:all],
                   safety_assured: [:column_renamed]
                 ],
                 [],
                 []
               )
    end
  end
end
