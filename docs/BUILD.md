# Build instructions

## Test
```sh
dart test
```

## Check Dart formatting

```sh
dart format .
```

## Check Preflight for Publish
```sh
dart pub get
dart pub publish --dry-run
```

## Commit / Release
```sh
git tag v0.3.0
git push origin v0.3.0
```

## Publish

```sh
dart pub publish
```
