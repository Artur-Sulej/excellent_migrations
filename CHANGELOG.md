# Changelog

## [Unreleased]

## [0.1.8] - 2024-02-09
### Fixed
- Using `Logger.warning` instead of deprecated `Logger.warn`

## [0.1.7] - 2024-01-18
### Fixed
- Correct exit code
- Choosing the right type when detected lack of disable_ddl_transaction or disable_migration_lock

## [0.1.6] - 2022-11-20
### Added
- Detecting volatile default when adding a column or adding a default

### Fixed
- Detecting index with too many columns

## [0.1.5] - 2022-08-05
### Added
- Handling unique index
- Detecting concurrently added indexes without disable_ddl_transaction nor disable_migration_lock

## [0.1.4] - 2022-07-24
### Fixed
- Handling "if (not) exists" variants of operations

## [0.1.3] - 2021-12-07
### Added
- Safety assured handled with config comments

### Deprecated
- Using module attribute `@safety_assured`

## [0.1.2] - 2021-11-25
### Fixed
- Fixed generating warning messages

## [0.1.1] - 2021-11-19
### Fixed
- Fixed handling index with one column as an atom

## [0.1.0] - 2021-11-18
### Added
- First release!

[Unreleased]: https://github.com/artur-sulej/excellent_migrations/compare/v0.1.8...HEAD
[0.1.8]: https://github.com/artur-sulej/excellent_migrations/compare/v0.1.7...v0.1.8
[0.1.7]: https://github.com/artur-sulej/excellent_migrations/compare/v0.1.6...v0.1.7
[0.1.6]: https://github.com/artur-sulej/excellent_migrations/compare/v0.1.5...v0.1.6
[0.1.5]: https://github.com/artur-sulej/excellent_migrations/compare/v0.1.4...v0.1.5
[0.1.4]: https://github.com/artur-sulej/excellent_migrations/compare/v0.1.3...v0.1.4
[0.1.3]: https://github.com/artur-sulej/excellent_migrations/compare/v0.1.2...v0.1.3
[0.1.2]: https://github.com/artur-sulej/excellent_migrations/compare/v0.1.1...v0.1.2
[0.1.1]: https://github.com/artur-sulej/excellent_migrations/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/artur-sulej/excellent_migrations/releases/tag/v0.1.0
