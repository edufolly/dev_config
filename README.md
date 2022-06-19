# DEV CONFIG


### `config.yml` example

```yaml
savePath: edufolly

checkPath: ../

regexAlwaysIgnorePaths:
  - '.*/build/.*'
  - '.*/\.git/.*'

regexAlwaysAcceptPaths:
  - '.*/\.ssh/.*'

regexCheckFiles:
  - '^\.env$'
  - '.*\.jks$'
  - '^.*-service-account\.json$'
  - '^key\.properties$'
  - '^launch\.json$'
  - '^import.*\.sql$'
```
