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
- [Column with volatile default](#column-with-volatile-default)
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

If Ecto is still configured to read a column in any running instances of the application, then queries will fail when loading data into your structs. This can happen in multi-node deployments or if you start the application before running migrations.

**BAD ❌**

```elixir
# Without a code change to the Ecto Schema

def change do
  alter table("recipes") do
    remove :no_longer_needed_column
  end
end
```

**GOOD ✅**

Safety can be assured if the application code is first updated to remove references to the column so it's no longer loaded or queried. Then, the column can safely be removed from the table.

1. Deploy code change to remove references to the field.
1. Deploy migration change to remove the column.

First deployment:

```diff
# First deploy, in the Ecto schema

defmodule Cookbook.Recipe do
  schema "recipes" do
-   column :no_longer_needed_column, :text
  end
end
```

Second deployment:

```elixir
def change do
  alter table("recipes") do
    remove :no_longer_needed_column
  end
end
```

---

### Adding a column with a default value

Adding a column with a default value to an existing table may cause the table to be rewritten. During this time, reads and writes are blocked in Postgres, and writes are blocked in MySQL and MariaDB.

**BAD ❌**

Note: This becomes safe in:

- Postgres 11+
- MySQL 8.0.12+
- MariaDB 10.3.2+

```elixir
def change do
  alter table("recipes") do
    add :favourite, :boolean, default: false
    # This took 10 minutes for 100 million rows with no fkeys,

    # Obtained an AccessExclusiveLock on the table, which blocks reads and
    # writes.
  end
end
```

**GOOD ✅**

Add the column first, then alter it to include the default.

First migration:

```elixir
def change do
  alter table("recipes") do
    add :favourite, :boolean
    # This took 0.27 milliseconds for 100 million rows with no fkeys,
  end
end
```

Second migration:

```elixir
def change do
  alter table("recipes") do
    modify :favourite, :boolean, default: false
    # This took 0.28 milliseconds for 100 million rows with no fkeys,
  end
end
```

Schema change to read the new column:

```diff
schema "recipes" do
+ field :favourite, :boolean, default: false
end
```

---

### Column with volatile default

If the default value is volatile (e.g., `clock_timestamp()`, `uuid_generate_v4()`, `random()`) each row will need to be updated with the value calculated at the time `ALTER TABLE` is executed.

**BAD ❌**

Adding volatile default to column:

```elixir
def change do
  alter table(:recipes) do
    modify(:identifier, :uuid, default: fragment("uuid_generate_v4()"))
  end
end
```

Adding column with volatile default:

```elixir
def change do
  alter table(:recipes) do
    add(:identifier, :uuid, default: fragment("uuid_generate_v4()"))
  end
end
```

**GOOD ✅**

To avoid a potentially lengthy update operation, particularly if you intend to fill the column with mostly nondefault values anyway, it may be preferable to:
1. add the column with no default
1. insert the correct values using `UPDATE` query
1. only then add any desired default

Also creating a new table with column with volatile default is safe, because it does not contain any records. 

---

### Backfilling data

Ecto creates a transaction around each migration, and backfilling in the same transaction that alters a table keeps the table locked for the duration of the backfill.
Also, running a single query to update data can cause issues for large tables.

**BAD ❌**


```elixir
defmodule Cookbook.BackfillRecipes do
  use Ecto.Migration
  import Ecto.Query

  def change do
    alter table("recipes") do
      add :new_data, :text
    end

    flush()

    Cookbook.Recipe
    |> where(new_data: nil)
    |> Cookbook.Repo.update_all(set: [new_data: "some data"])
  end
end

```

**GOOD ✅**

There are several different strategies to perform safe backfilling. [This article](https://fly.io/phoenix-files/backfilling-data) explains them in great details.

---

### Changing the type of a column

Changing the type of a column may cause the table to be rewritten. During this time, reads and writes are blocked in Postgres, and writes are blocked in MySQL and MariaDB.

**BAD ❌**

Safe in Postgres:

- increasing length on varchar or removing the limit
- changing varchar to text
- changing text to varchar with no length limit
- Postgres 9.2+ - increasing precision (NOTE: not scale) of decimal or numeric columns. eg, increasing 8,2 to 10,2 is safe. Increasing 8,2 to 8,4 is not safe.
- Postgres 9.2+ - changing decimal or numeric to be unconstrained
- Postgres 12+ - changing timestamp to timestamptz when session TZ is UTC

Safe in MySQL/MariaDB:

- increasing length of varchar from < 255 up to 255.
- increasing length of varchar from > 255 up to max.

```elixir
def change do
  alter table("recipes") do
    modify :my_column, :boolean, from: :text
  end
end
```

**GOOD ✅**

Take a phased approach:

1. Create a new column
1. In application code, write to both columns
1. Backfill data from old column to new column
1. In application code, move reads from old column to the new column
1. In application code, remove old column from Ecto schemas.
1. Drop the old column.

---

### Renaming a column

Ask yourself: "Do I _really_ need to rename a column?". Probably not, but if you must, read on and be aware it requires time and effort.

If Ecto is configured to read a column in any running instances of the application, then queries will fail when loading data into your structs. This can happen in multi-node deployments or if you start the application before running migrations.

There is a shortcut: Don't rename the database column, and instead rename the schema's field name and configure it to point to the database column.

**BAD ❌**

```elixir
# In your schema
schema "recipes" do
  field :summary, :text
end


# In your migration
def change do
  rename table("recipes"), :title, to: :summary
end
```

The time between your migration running and your application getting the new code may encounter trouble.

**GOOD ✅**

**Strategy 1**

Rename the field in the schema only, and configure it to point to the database column and keep the database column the same. Ensure all calling code relying on the old field name is also updated to reference the new field name.

```elixir
defmodule Cookbook.Recipe do
  use Ecto.Schema

  schema "recipes" do
    field :author, :string
    field :preparation_minutes, :integer, source: :prep_min
  end
end
```

```diff
## Update references in other parts of the codebase:
   recipe = Repo.get(Recipe, "my_id")
-  recipe.prep_min
+  recipe.preparation_minutes
```

**Strategy 2**

Take a phased approach:

1. Create a new column
1. In application code, write to both columns
1. Backfill data from old column to new column
1. In application code, move reads from old column to the new column
1. In application code, remove old column from Ecto schemas.
1. Drop the old column.

---

### Renaming a table

Ask yourself: "Do I _really_ need to rename a table?". Probably not, but if you must, read on and be aware it requires time and effort.

If Ecto is still configured to read a table in any running instances of the application, then queries will fail when loading data into your structs. This can happen in multi-node deployments or if you start the application before running migrations.

There is a shortcut: rename the schema only, and do not change the underlying database table name.

**BAD ❌**

```elixir
def change do
  rename table("recipes"), to: table("dish_algorithms")
end
```

**GOOD ✅**

**Strategy 1**

Rename the schema only and all calling code, and don’t rename the table:

```diff
- defmodule Cookbook.Recipe do
+ defmodule Cookbook.DishAlgorithm do
  use Ecto.Schema

  schema "dish_algorithms" do
    field :author, :string
    field :preparation_minutes, :integer
  end
end

# and in calling code:
- recipe = Cookbook.Repo.get(Cookbook.Recipe, "my_id")
+ dish_algorithm = Cookbook.Repo.get(Cookbook.DishAlgorithm, "my_id")
```

**Strategy 2**

Take a phased approach:

1. Create the new table. This should include creating new constraints (checks and foreign keys) that mimic behavior of the old table.
1. In application code, write to both tables, continuing to read from the old table.
1. Backfill data from old table to new table
1. In application code, move reads from old table to the new table
1. In application code, remove the old table from Ecto schemas.
1. Drop the old table.

---

### Adding a check constraint

Adding a check constraint blocks reads and writes to the table in Postgres, and blocks writes in MySQL/MariaDB while every row is checked.

**BAD ❌**

```elixir
def change do
  create constraint("ingredients", :price_must_be_positive, check: "price > 0")
  # Creating the constraint with validate: true (the default when unspecified)
  # will perform a full table scan and acquires a lock preventing updates
end
```

**GOOD ✅**

There are two operations occurring:

1. Creating a new constraint for new or updating records
1. Validating the new constraint for existing records

If these commands are happening at the same time, it obtains a lock on the table as it validates the entire table and fully scans the table. To avoid this full table scan, we can separate the operations.

In one migration:

```elixir
def change do
  create constraint("ingredients", :price_must_be_positive, check: "price > 0", validate: false)
  # Setting validate: false will prevent a full table scan, and therefore
  # commits immediately.
end
```

In the next migration:

```elixir
def change do
  execute "ALTER TABLE ingredients VALIDATE CONSTRAINT price_must_be_positive", ""
  # Acquires SHARE UPDATE EXCLUSIVE lock, which allows updates to continue
end
```

These can be in the same deployment, but ensure there are 2 separate migrations.

---

### Setting NOT NULL on an existing column

Setting NOT NULL on an existing column blocks reads and writes while every row is checked.  Just like the Adding a check constraint scenario, there are two operations occurring:

1. Creating a new constraint for new or updating records
1. Validating the new constraint for existing records

To avoid the full table scan, we can separate these two operations.

**BAD ❌**

```elixir
def change do
  alter table("recipes") do
    modify :favourite, :boolean, null: false
  end
end
```

**GOOD ✅**

Add a check constraint without validating it, backfill data to satiate the constraint and then validate it. This will be functionally equivalent.

In the first migration:

```elixir
# Deployment 1
def change do
  create constraint("recipes", :favourite_not_null, check: "favourite IS NOT NULL", validate: false)
end
```

This will enforce the constraint in all new rows, but not care about existing rows until that row is updated.

You'll likely need a data migration at this point to ensure that the constraint is satisfied.

Then, in the next deployment's migration, we'll enforce the constraint on all rows:

```elixir
# Deployment 2
def change do
  execute "ALTER TABLE recipes VALIDATE CONSTRAINT favourite_not_null", ""
end
```

If you're using Postgres 12+, you can add the NOT NULL to the column after validating the constraint. From the Postgres 12 docs:

> SET NOT NULL may only be applied to a column provided
> none of the records in the table contain a NULL value
> for the column. Ordinarily this is checked during the
> ALTER TABLE by scanning the entire table; however, if
> a valid CHECK constraint is found which proves no NULL
> can exist, then the table scan is skipped.

```elixir
# **Postgres 12+ only**

def change do
  execute "ALTER TABLE recipes VALIDATE CONSTRAINT favourite_not_null", ""

  alter table("recipes") do
    modify :favourite, :boolean, null: false
  end

  drop constraint("recipes", :favourite_not_null)
end
```

If your constraint fails, then you should consider backfilling data first to cover the gaps in your desired data integrity, then revisit validating the constraint.

---

### Executing SQL directly

Excellent Migrations can’t ensure safety for raw SQL statements. Make really sure that what you’re doing is safe, then use:

```elixir
defmodule Cookbook.ExecuteRawSql do
  # excellent_migrations:safety-assured-for-this-file raw_sql_executed

  def change do
    execute("...")
  end
end
```

---

### Adding an index non-concurrently

Creating an index will block both reads and writes.

**BAD ❌**

```elixir
def change do
  create index("recipes", [:slug])

  # This obtains a ShareLock on "recipes" which will block writes to the table
end
```

**GOOD ✅**

With Postgres, instead create the index concurrently which does not block reads. You will need to disable the database transactions to use `CONCURRENTLY`, and since Ecto obtains migration locks through database transactions this also implies that competing nodes may attempt to try to run the same migration (eg, in a multi-node Kubernetes environment that runs migrations before startup). Therefore, some nodes will fail startup for a variety of reasons. 

```elixir
@disable_ddl_transaction true
@disable_migration_lock true

def change do
  create index("recipes", [:slug], concurrently: true)
end
```

The migration may still take a while to run, but reads and updates to rows will continue to work. For example, for 100,000,000 rows it took 165 seconds to add run the migration, but SELECTS and UPDATES could occur while it was running.

**Do not have other changes in the same migration**; only create the index concurrently and separate other changes to later migrations.

---

### Adding an index concurrently without disabling lock or transaction

Concurrently indexes need to set both `@disable_ddl_transaction` and `@disable_migration_lock` to true. [See more](https://hexdocs.pm/ecto_sql/Ecto.Migration.html#index/3-adding-dropping-indexes-concurrently):

**BAD ❌**

```elixir
defmodule Cookbook.AddIndex do
  def change do
    create index(:recipes, [:cookbook_id, :cuisine], concurrently: true)
  end
end
```

**GOOD ✅**

```elixir
defmodule Cookbook.AddIndex do
  @disable_ddl_transaction true
  @disable_migration_lock true

  def change do
    create index(:recipes, [:cookbook_id, :cuisine], concurrently: true)
  end
end
```

---

### Adding a reference

Adding a foreign key blocks writes on both tables.

**BAD ❌**

```elixir
def change do
  alter table("recipes") do
    add :cookbook_id, references("cookbooks")
  end
end
```

**GOOD ✅**

In the first migration

```elixir
def change do
  alter table("recipes") do
    add :cookbook_id, references("cookbooks", validate: false)
  end
end
```

In the second migration

```elixir
def change do
  execute "ALTER TABLE recipes VALIDATE CONSTRAINT cookbook_id_fkey", ""
end
```

 These migrations can be in the same deployment, but make sure they are separate migrations.

---

### Adding a `json` column

In Postgres, there is no equality operator for the json column type, which can cause errors for existing SELECT DISTINCT queries in your application.

**BAD ❌**

```elixir
def change do
  alter table("recipes") do
    add :extra_data, :json
  end
end
```

**GOOD ✅**

Use jsonb instead. Some say it’s like "json" but "**b**etter."

```elixir
def change do
  alter table("recipes") do
    add :extra_data, :jsonb
  end
end
```

---

### Keeping non-unique indexes to three columns or less

**BAD ❌**

Adding a non-unique index with more than three columns rarely improves performance.

```elixir
defmodule Cookbook.AddIndexOnIngredients do
  def change do
    create index(:recipes, [:a, :b, :c, :d], concurrently: true)
  end
end
```

**GOOD ✅**

Instead, start an index with columns that narrow down the results the most.

```elixir
defmodule Cookbook.AddIndexOnIngredients do
  def change do
    create index(:recipes, [:b, :d], concurrently: true)
  end
end
```

For Postgres, be sure to add them concurrently.

---

## Assuring safety

To mark an operation in a migration as safe use config comment. It will be ignored during analysis.

There are two config comments available:

* `excellent_migrations:safety-assured-for-next-line <operation_type>`
* `excellent_migrations:safety-assured-for-this-file <operation_type>`

Ignoring checks for given line:

```elixir
defmodule Cookbook.AddTypeToRecipesWithDefault do
  def change do
    alter table(:recipes) do
      # excellent_migrations:safety-assured-for-next-line column_added_with_default
      add(:type, :string, default: "dessert")
    end
  end
end
```

Ignoring checks for the whole file:

```elixir
defmodule Cookbook.AddTypeToRecipesWithDefault do
  # excellent_migrations:safety-assured-for-this-file column_added_with_default

  def change do
    alter table(:recipes) do
      add(:type, :string, default: "dessert")
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
* `column_volatile_default`
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

## Existing migrations

You can specify paths where your migrations are stored, set `migrations_paths` in config:

```elixir
config :excellent_migrations, migrations_paths: ["migrations/", "migrations_storage/"]
```

The default value for `migrations_paths` is `"migrations/"`

## Similar tools & resources

* https://github.com/ankane/strong_migrations (Ruby)
* https://github.com/rrrene/credo (Elixir)
* https://github.com/fly-apps/safe-ecto-migrations – Special thanks for unsafe actions explanation and recipes.
* https://www.postgresql.org/docs/current/sql-altertable.html#Notes

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
