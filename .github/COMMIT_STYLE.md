# Commit Style Guide

This project follows a specific commit message convention based on its history. Please adhere to these rules to maintain a clean and searchable history.

## Structure

```text
type(scope): description

[optional body]

[optional footer]
```

## Rules

- **Type**: Must be one of the following (in lowercase):
  - `feat`: A new feature
  - `fix`: A bug fix
  - `refactor`: A code change that neither fixes a bug nor adds a feature
  - `docs`: Documentation only changes
  - `style`: Changes that do not affect the meaning of the code (white-space, formatting, missing semi-colons, etc)
  - `perf`: A code change that improves performance
  - `test`: Adding missing tests or correcting existing tests
  - `build`: Changes that affect the build system or external dependencies (example scopes: gulp, broccoli, npm)
  - `ci`: Changes to our CI configuration files and scripts (example scopes: GitHub Actions)
  - `chore`: Other changes that don't modify src or test files
- **Scope**: (Optional) Indicates the part of the project affected (e.g., `backend`, `client`, `frontend`, `api`). Multiple scopes can be separated by commas: `feat(backend, client): ...`.
- **Subject**:
  - Use the imperative, present tense: "change" not "changed" nor "changes".
  - Don't capitalize the first letter.
  - No dot (`.`) at the end.
- **Body**: (Optional) Use for complex changes.
  - Separate from the subject with a blank line.
  - Use bullet points (`*` or `-`) for lists.
  - Explain *what* and *why* rather than *how*.

## Examples

### Simple Feature
```text
feat: backend and frontend structure
```

### Scoped Refactor
```text
refactor(frontend): directory change
```

### Complex Feature with Body
```text
feat(backend, client): implement gRPC API, authentication, and gameplay session tracking

* API & Protobuf:
  * Migrated protocol definitions to the xyz.fire_step.v1 namespace.
  * Introduced new gRPC services: LoginService, SessionsService, and SeancesService.
...
```
