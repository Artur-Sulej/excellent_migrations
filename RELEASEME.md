# How to release a new version

* Ensure working dir is clean
* Make sure tests pass with `mix test`
* Update version in `mix.exs`
* Update `CHANGELOG.md`
* Create a commit:

```sh
  git commit -a -m "Bump version to 0.X.Y"
  git tag v0.X.Y
  mix hex.publish
  git push --tags
```