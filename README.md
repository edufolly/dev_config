# DEV CONFIG

## Command usage

```shell
dev-config [--dry-run] [--debug] [--no-check-update] --path <path>
```

| Parameter           | Required | Default Value | Description               |
| :------------------ | :------: | :------------ | :------------------------ |
| `--path`            |   Yes    | ---           | The base with config.yml. |
| `--dry-run`         |    No    | Disabled      | To do a dry run.          |
| `--debug`           |    No    | Disabled      | Show debug messages.      |
| `--no-check-update` |    No    | Enabled       | No check update.          |

## Important

To scan a folder in `checkPath`, create a empty folder with the same name inside `savePath`.

## Configuration example: `config.yml`

```yaml
# Path to save the files. Relative from  '--path' parameter.
savePath: edufolly

# Path to check. Your projects or user folder. Relative from execution '--path' parameter.
checkPath: ../

# List of regular expressions to ignore a path.
regexAlwaysIgnorePaths:
  - '.*/build/.*'
  - '.*/\.git/.*'
  - '.*\.bkp$'
  - '.*\.log$'

# List of regular expressions to accept a path.
regexAlwaysAcceptPaths:
  - '.*/\.ssh/.*'

# List of regular expressions to accept a file.
regexCheckFiles:
  - '^\.env$'
  - '.*\.jks$'
  - '^.*-service-account\.json$'
  - '^key\.properties$'
  - '^launch\.json$'
```
