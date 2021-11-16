# Excellent Migrations

Detect potentially dangerous or destructive operations in your database migrations.

## Installation

The package can be installed by adding `excellent_migrations` to your list of dependencies
in `mix.exs`:

```elixir
def deps do
  [
    {:excellent_migrations, "~> 0.1.0"}
  ]
end
```

## How It Works

This tool analyzes code (AST) of migration files. You don't have to edit or include anything in your
migration files, except for ocassionally adding module attribute `@safety_assured`.

## How to use it

There are multiple ways to integrate with Excellent Migrations.

### mix task

`mix excellent_migrations.check_safety`

This mix task analyzes migrations and logs a warning for each danger detected.

### migration task

`mix excellent_migrations.migrate`

Running this task will first analyze migrations. If no dangers are detected it will proceed and
run `mix ecto.migrate`. If there are any, it will log errors and stop.

### Credo check

Excellent Migrations provide custom check for [Credo](https://github.com/rrrene/credo).
Add `ExcellentMigrations.CredoCheck.CheckSafety` to your `.credo` file. Example warnings:

```
  Warnings - please take a look                                                                                                                                             
┃ 
┃ [W] ↗ Raw SQL used
┃       apps/cookbook/priv/repo/migrations/20211024133700_create_recipes.exs:13 #(Cookbook.Repo.Migrations.CreateRecipes.up)
┃ [W] ↗ Index added not concurrently
┃       apps/cookbook/priv/repo/migrations/20211024133705_create_index_on_veggies.exs:37 #(Cookbook.Repo.Migrations.CreateIndexOnVeggies.up)
```

### Code

You can also use it in code. To do so, you need to get AST of your migration, e.g.
via [`Code.string_to_quoted/2`](https://hexdocs.pm/elixir/1.12/Code.html#string_to_quoted/2) and
pass it to `ExcellentMigrations.DangersDetector.detect_dangers(ast)`. It will return keyword list
containing danger types and lines where they were detected.

## Checks

Potentially dangerous operations:

- [Adding a check constraint](#adding-a-check-constraint)
- [Adding a column with a default value](#adding-a-column-with-a-default-value)
- [Backfilling data](#backfilling-data)
- [Changing the type of a column](#changing-the-type-of-a-column)
- [Executing SQL directly](#executing-SQL-directly)
- [Removing a column](#removing-a-column)
- [Renaming a column](#renaming-a-column)
- [Renaming a table](#renaming-a-table)
- [Setting NOT NULL on an existing column](#setting-not-null-on-an-existing-column)

Postgres-specific checks:

- [Adding a json column](#adding-a-json-column)
- [Adding a reference](#adding-a-reference)
- [Adding an index non-concurrently](#adding-an-index-non-concurrently)

Best practices:

- [Keeping non-unique indexes to three columns or less](#keeping-non-unique-indexes-to-three-columns-or-less)

You can also [disable specific checks](#disable-checks).

### Removing a column

#### Example

```elixir
defmodule Cookbook.RemoveSizeFromDumplings do
  def change do
    alter table(:dumplings) do
      remove :size, :string
    end
  end
end
```

### Adding a column with a default value

#### Example

```elixir
defmodule Cookbook.AddTasteToDumplingsWithDefault do
  def change do
    alter table(:dumplings) do
      add(:taste, :string, default: "sweet")
    end
  end
end
```

### Backfilling data

#### Example

```elixir
defmodule Cookbook.BackfillRecords do
  def change do
    Repo.insert!(%Dumpling{taste: "umami"})
  end
end
```

### Changing the type of a column

#### Example

```elixir
defmodule Cookbook.ChangeColumnSizeTypeToInteger do
  def change do
    alter table(:dumplings) do
      modify(:size, :integer)
    end
  end
end
```

### Renaming a column

#### Example

```elixir
defmodule Cookbook.RenameFillingToStuffing do
  def change do
    rename table(:dumplings), :filling, to: :stuffing
  end
end
```

### Renaming a table

#### Example

```elixir
defmodule Cookbook.RenameDumplingsToNoodles do
  def change do
    rename(table(:dumplings), to: table("noodles"))
  end
end
```

### Adding a check constraint

#### Example

```elixir
defmodule Cookbook.CreatePriceConstraint do
  def change do
    create constraint("dumplings", :price_must_be_positive, check: "price > 0")
  end
end
```

### Setting NOT NULL on an existing column

#### Example

```elixir
defmodule Cookbook.AddNotNullOnShape do
  def change do
    alter table(:dumplings) do
      modify :shape, :integer, null: true
    end
  end
end
```

### Executing SQL directly

#### Example

```elixir
defmodule Cookbook.CreateIndexOnDumplings do
  def up do
    execute("CREATE INDEX dumplings_geog ON dumplings using GIST(Geography(geom));")
  end

  def down do
    execute("DROP INDEX dumplings_geog;")
  end
end
```

### Adding an index non-concurrently

#### Example

```elixir
defmodule Cookbook.AddIndex do
  def change do
    create index(:dumplings, [:recipe_id, :flour_id])
  end
end
```

### Adding a reference

#### Example

```elixir
defmodule Cookbook.AddReferenceToIngredient do
  def change do
    alter table(:recipes) do
      modify :ingredient_id, references(:ingredients)
    end
  end
end
```

### Adding a `json` column

```elixir
defmodule Cookbook.AddDetailsJson do
  def change do
    add :details, :json, default: "{}"
  end
end
```

### Keeping non-unique indexes to three columns or less

```elixir
defmodule Cookbook.AddIndexOnIngredients do
  def change do
    alter table(:dumplings) do
      create index(:ingredients, [:a, :b, :c, :d], concurrently: true)
    end
  end
end
```

## Assuring safety

To mark an operation in a migration as safe list it in `@safety_assured` attribute. It will be
ignored during analysis.

```elixir
defmodule Cookbook.AddTasteToDumplingsWithDefault do
  @safety_assured [:column_added_with_default]

  def change do
    alter table(:dumplings) do
      add(:taste, :string, default: "sweet")
    end

    create index(:dumplings, [:recipe_id, :flour_id])
  end
end
```

You can also mark all operations as safe in a given migration by adding `@safety_assured :all`

```elixir
defmodule Cookbook.BackfillRecords do
  @safety_assured :all

  def change do
    Repo.insert!(%Dumpling{taste: "umami"})
  end
end
```

Possible operation types are:

* `:column_added_with_default`
* `:column_removed`
* `:column_renamed`
* `:column_type_changed`
* `:index_not_concurrently`
* `:many_columns_index`
* `:not_null_added`
* `:operation_delete`
* `:operation_insert`
* `:operation_update`
* `:raw_sql_executed`
* `:table_renamed`

## Disable checks

Ignore specific dangers for all migraion checks with:

```elixir
config :excellent_migrations, skip_checks: [:raw_sql_executed, :not_null_added]
```

## Existing migrations

To skip analyzing migrations that were created before adding this package, set timestamp from the
last migration in `start_after` in config:

```elixir
config :excellent_migrations, start_after: "20191026080101"
```

## Similar tools

* https://github.com/ankane/strong_migrations (Ruby)
* https://github.com/rrrene/credo (Elixir)

## Contributing

Everyone is encouraged to help improve this project. Here are a few ways you can help:

- Give feedback – your opinion matters
- Suggest or add new
  features, [submit pull requests](https://github.com/Artur-Sulej/excellent_migrations/pulls)
- [Report bugs](https://github.com/Artur-Sulej/excellent_migrations/issues)
- Improve documentation
