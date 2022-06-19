# DEV CONFIG

## Command parameters

| Parameter   | Required | Default Value | Description               |
| :---------- | :------: | :------------ | :------------------------ |
| `--path`    |   Yes    | ---           | The base path to analyse. |
| `--dry-run` |    No    | Disabled      | To do a dry run.          |
| `--debug`   |    No    | Disabled      | Show debug messages.      |

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
  - '^import.*\.sql$'
```
