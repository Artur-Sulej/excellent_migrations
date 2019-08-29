defmodule ParserTest do
  use ExUnit.Case
  alias ExcellentMigrations.Parser

  test "generates warnings for migrations" do
    assert [execute: 5, execute: 9] == Parser.parse(migration_ast1())
    assert [] == Parser.parse(migration_ast2())
    assert [] == Parser.parse(migration_ast3())
    assert [safety_assured: :change] == Parser.parse(migration_ast4())
    assert [safety_assured: :change, index_not_concurrently: 10] == Parser.parse(migration_ast5())
  end

  defp migration_ast1 do
    {
      :defmodule,
      [line: 1],
      [
        {:__aliases__, [line: 1],
         [:Migrations, :AddRecipeIndexToDumplings]},
        [
          do: {
            :__block__,
            [],
            [
              {:use, [line: 2], [{:__aliases__, [line: 2], [:Ecto, :Migration]}]},
              {
                :def,
                [line: 4],
                [
                  {:up, [line: 4], nil},
                  [
                    do: {
                      :execute,
                      [line: 5],
                      [
                        "CREATE INDEX idx_dumplings_geog ON dumplings using GIST(Geography(geom));"
                      ]
                    }
                  ]
                ]
              },
              {
                :def,
                [line: 8],
                [
                  {:down, [line: 8], nil},
                  [do: {:execute, [line: 9], ["DROP INDEX idx_dumplings_geog;"]}]
                ]
              }
            ]
          }
        ]
      ]
    }
  end

  defp migration_ast2 do
    {
      :defmodule,
      [line: 1],
      [
        {
          :__aliases__,
          [line: 1],
          [
            :Migrations,
            :AddRecipeIdToDumplings
          ]
        },
        [
          do:
            {:__block__, [],
             [
               {
                 :use,
                 [line: 2],
                 [{:__aliases__, [line: 2], [:Ecto, :Migration]}]
               },
               {
                 :def,
                 [line: 4],
                 [
                   {:change, [line: 4], nil},
                   [
                     do:
                       {:__block__, [],
                        [
                          {
                            :add,
                            [line: 5],
                            [
                              :recipe_id,
                              {
                                :references,
                                [line: 5],
                                [:flours, [on_delete: :delete_all]]
                              },
                              [null: false]
                            ]
                          },
                          {:remove, [line: 6], [:created_at]}
                        ]}
                   ]
                 ]
               }
             ]}
        ]
      ]
    }
  end

  defp migration_ast3 do
    {
      :defmodule,
      [line: 1],
      [
        {
          :__aliases__,
          [line: 1],
          [
            :Migrations,
            :AddRecipeIdToDumplings
          ]
        },
        [
          do:
            {:__block__, [],
             [
               {
                 :use,
                 [line: 2],
                 [{:__aliases__, [line: 2], [:Ecto, :Migration]}]
               },
               {
                 :def,
                 [line: 4],
                 [
                   {:change, [line: 4], nil},
                   [
                     do: {:alter, [line: 4], [{:table, [line: 4], [:dumplings]}]}
                   ]
                 ]
               }
             ]}
        ]
      ]
    }
  end

  defp migration_ast4 do
    {
      :defmodule,
      [line: 1],
      [
        {
          :__aliases__,
          [line: 1],
          [
            :Migrations,
            :AddRecipeIdToDumplings
          ]
        },
        [
          do:
            {:__block__, [],
             [
               {
                 :use,
                 [line: 2],
                 [{:__aliases__, [line: 2], [:Ecto, :Migration]}]
               },
               {:@, [line: 4], [{:safety_assured, [line: 4], [:change]}]},
               {
                 :def,
                 [line: 6],
                 [
                   {:change, [line: 6], nil},
                   [
                     do:
                       {:alter, [line: 7],
                        [
                          {:table, [line: 7], [:dumplings]},
                          [
                            do:
                              {:add, [line: 8],
                               [
                                 :recipe_id,
                                 {
                                   :references,
                                   [line: 8],
                                   [:flours, [on_delete: :delete_all]]
                                 },
                                 [null: false]
                               ]}
                          ]
                        ]}
                   ]
                 ]
               }
             ]}
        ]
      ]
    }
  end

  defp migration_ast5 do
    {
      :defmodule,
      [line: 1],
      [
        {
          :__aliases__,
          [line: 1],
          [
            :Migrations,
            :AddRecipeIdToDumplings
          ]
        },
        [
          do:
            {:__block__, [],
             [
               {
                 :use,
                 [line: 2],
                 [{:__aliases__, [line: 2], [:Ecto, :Migration]}]
               },
               {:@, [line: 4], [{:safety_assured, [line: 4], [:change]}]},
               {
                 :def,
                 [line: 6],
                 [
                   {:change, [line: 6], nil},
                   [
                     do:
                       {:__block__, [],
                        [
                          {
                            :alter,
                            [line: 7],
                            [
                              {:table, [line: 7], [:dumplings]},
                              [
                                do:
                                  {:add, [line: 8],
                                   [
                                     :recipe_id,
                                     {
                                       :references,
                                       [line: 8],
                                       [:flours, [on_delete: :delete_all]]
                                     },
                                     [null: false]
                                   ]}
                              ]
                            ]
                          },
                          {
                            :create,
                            [line: 10],
                            [
                              {
                                :index,
                                [line: 10],
                                [
                                  :pots,
                                  [:recipe_id, :dumplings_id],
                                  [unique: true]
                                ]
                              }
                            ]
                          }
                        ]}
                   ]
                 ]
               }
             ]}
        ]
      ]
    }
  end
end
