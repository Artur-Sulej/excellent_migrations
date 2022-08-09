# Excellent Migrations

[![CI Tests](https://github.com/artur-sulej/excellent_migrations/workflows/Tests/badge.svg)](https://github.com/artur-sulej/excellent_migrations/actions?query=branch%3Amaster)
[![Module Version](https://img.shields.io/hexpm/v/excellent_migrations.svg)](https://hex.pm/packages/excellent_migrations)
[![Hex Docs](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/excellent_migrations/)
[![Total Download](https://img.shields.io/hexpm/dt/excellent_migrations.svg)](https://hex.pm/packages/excellent_migrations)
[![License](https://img.shields.io/hexpm/l/excellent_migrations.svg)](https://github.com/artur-sulej/excellent_migrations/blob/master/LICENSE.md)
[![Last Updated](https://img.shields.io/github/last-commit/artur-sulej/excellent_migrations.svg)](https://github.com/artur-sulej/excellent_migrations/commits/master)

Detect potentially dangerous or destructive operations in your database migrations.

## Installation

The package can be installed by adding `:excellent_migrations` to your list of dependencies
in `mix.exs`:

```elixir
def deps do
  [
    {:excellent_migrations, "~> 0.1", only: [:dev, :test], runtime: false}
  ]
end
```

## Documentation

Documentation is available on [Hexdocs](https://hexdocs.pm/excellent_migrations/).

## How It Works

This tool analyzes code (AST) of migration files. You don't have to edit or include any additional
code in your migration files, except for occasionally adding a config comment
for [assuring safety](#assuring-safety).

## How to use it

There are multiple ways to integrate with Excellent Migrations.

### Credo check

Excellent Migrations provide custom, ready-to-use check for [Credo](https://github.com/rrrene/credo).

Add `ExcellentMigrations.CredoCheck.MigrationsSafety` to your `.credo` file:

```elixir
%{
  configs: [
    %{
      # …
      checks: [
        # …
        {ExcellentMigrations.CredoCheck.MigrationsSafety, []}
      ]
    }
  ]
}

```

Example credo warnings:

```
  Warnings - please take a look
┃
┃ [W] ↗ Raw SQL used
┃       apps/cookbook/priv/repo/migrations/20211024133700_create_recipes.exs:13 #(Cookbook.Repo.Migrations.CreateRecipes.up)
┃ [W] ↗ Index added not concurrently
┃       apps/cookbook/priv/repo/migrations/20211024133705_create_index_on_veggies.exs:37 #(Cookbook.Repo.Migrations.CreateIndexOnVeggies.up)
```

### mix task

`mix excellent_migrations.check_safety`

This mix task analyzes migrations and logs a warning for each danger detected.

### migration task

`mix excellent_migrations.migrate`

Running this task will first analyze migrations. If no dangers are detected it will proceed and
run `mix ecto.migrate`. If there are any, it will log errors and stop.

### Code

You can also use it in code. To do so, you need to get source code and AST of your migration file,
e.g. via `File.read!/1`
and [`Code.string_to_quoted/2`](https://hexdocs.pm/elixir/1.12/Code.html#string_to_quoted/2). Then
pass them to `ExcellentMigrations.DangersDetector.detect_dangers(ast)`. It will return a keyword
list containing danger types and lines where they were detected.

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
- [Adding an index concurrently without disabling lock or transaction](#adding-an-index-concurrently-without-disabling-lock-or-transaction)

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
      modify :shape, :integer, null: false
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

### Adding an index concurrently without disabling lock or transaction

Concurrently indexes need to set both `@disable_ddl_transaction` and `@disable_migration_lock` to true. [See more](https://hexdocs.pm/ecto_sql/Ecto.Migration.html#index/3-adding-dropping-indexes-concurrently):

#### Bad example

```elixir
defmodule Cookbook.AddIndex do
  def change do
    create index(:dumplings, [:recipe_id, :flour_id], concurrently: true)
  end
end
```

#### Good example

```elixir
defmodule Cookbook.AddIndex do
  @disable_ddl_transaction true
  @disable_migration_lock true

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

To mark an operation in a migration as safe use config comment. It will be ignored during analysis.

There are two config comments available:

* `excellent_migrations:safety-assured-for-next-line <operation_type>`
* `excellent_migrations:safety-assured-for-this-file <operation_type>`

```elixir
defmodule Cookbook.AddTasteToDumplingsWithDefault do
  def change do
    alter table(:dumplings) do
      # excellent_migrations:safety-assured-for-next-line column_added_with_default
      add(:taste, :string, default: "sweet")
    end
  end
end
```

```elixir
defmodule Cookbook.AddTasteToDumplingsWithDefault do
  # excellent_migrations:safety-assured-for-this-file column_added_with_default

  def change do
    alter table(:dumplings) do
      add(:taste, :string, default: "sweet")
    end
  end
end
```

Possible operation types are:

* `check_constraint_added`
* `column_added_with_default`
* `column_reference_added`
* `column_removed`
* `column_renamed`
* `column_type_changed`
* `index_concurrently_without_disable_ddl_transaction`
* `index_concurrently_without_disable_migration_lock`
* `index_not_concurrently`
* `json_column_added`
* `many_columns_index`
* `not_null_added`
* `operation_delete`
* `operation_insert`
* `operation_update`
* `raw_sql_executed`
* `table_dropped`
* `table_renamed`
* `index_concurrently_without_disable_ddl_transaction`
* `index_concurrently_without_disable_migration_lock`

## Disable checks

Ignore specific dangers for all migration checks with:

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

Everyone is encouraged and welcome to help improve this project. Here are a few ways you can help:

- Give feedback – your opinion matters
- Visit [TODO list](https://github.com/Artur-Sulej/excellent_migrations/projects/1)
- [Submit pull request](https://github.com/Artur-Sulej/excellent_migrations/pulls)
- [Suggest feature](https://github.com/Artur-Sulej/excellent_migrations/issues)
- [Report bug](https://github.com/Artur-Sulej/excellent_migrations/issues)
- Improve documentation

## Copyright and License

Copyright (c) 2021 Artur Sulej

This work is free. You can redistribute it and/or modify it under the terms of the MIT License. See
the [LICENSE.md](./LICENSE.md) file for more details.
