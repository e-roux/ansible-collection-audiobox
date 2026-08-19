# Contributing

Thanks for considering contributing!

## Code contribution

- please **fork** the repository.
- make sure all of your commits are
[atomic](https://en.wikipedia.org/wiki/Atomic_commit) (one feature per commit).
- make a pull request to the **devel** branch
- commits must follow the [conventional
commits](https://www.conventionalcommits.org/en/v1.0.0/) recommandation, see
[hereunder](#Semantic-Commit-Messages) for an extract.
- write a clear log message for your commits. One-line messages are fine for
small changes, but bigger changes should look like this:

```bash
$ git commit -m "feat(scope): a brief summary of the commit
>
> A paragraph describing what changed and its impact."
```

**Pipeline**

This projects aims at using gitlab [CI/CD
pipeline](https://docs.gitlab.com/ee/ci/pipelines/). You can skip triggering
pipelines by [sending the `ci.skip`
option](https://docs.gitlab.com/ee/ci/yaml/#skip-pipeline) to the server.

```bash
git push -o ci.skip
```

### Semantic Commit Messages

```
feat(scope): add foobar
^--^ ^---^   ^--------^
|    |       |
|    |       +-> Summary in present tense.
|    |
|    +-> Optional scope
|
+-------> Type: build, chore, docs, feat, fix, refactor, style, or test.
```

#### Types

Semantic version relevant changes are handled by `feat` and `fix` types.
`BREAKING CHANGES` entries in the footer are meant for major version tags.

| type     | type long name          | description                                                                     |
|----------|-------------------------|---------------------------------------------------------------------------------|
| build    | Builds                  | Changes that affect the build system or external dependencies (e.g. gulps, npm) |
| chore    | Chores                  | Changes that don't modify src or test                                           |
| ci       | Continuous Integration  | Changes to our CI configuration files and scripts (e.g. Travis, Circle, ...)    |
| docs     | Documentation           | Documentation only changes                                                      |
| feat     | Features                | A new feature                                                                   |
| fix      | Bug Fixes               | A bug fix                                                                       |
| perf     | Performance Improvement | A code change that improves performance                                         |
| refactor | Code Refactoring        | A code change that neither fixes a bug nor adds a feature                       |
| revert   | Reverts                 | Reverts a previous commit                                                       |
| style    | Styles                  | Changes that do not affect the meaning of the code                              |
| test     | Tests                   | Test related addition or modification                                           |

References:

- [AngularJS Git Commit Message Conventions](https://docs.google.com/document/d/1QrDFcIiPjSLDn3EL15IJygNPiHORgU1_OOAqWjiDU5Y)
- [Conventinal Commits](https://www.conventionalcommits.org/)
- [Seesparkbox.com](https://seesparkbox.com/foundry/semantic_commit_messages)
- [Karma runner](http://karma-runner.github.io/1.0/dev/git-commit-msg.html)

### Scope

The scope indentifies the part of the code beeing modified, e.g. module,
documentation, ...

## Code style

Common code formatters:

- python: [ruff](https://astral.sh/ruff)
- golang: [gofmt](https://pkg.go.dev/cmd/gofmt)
- typescrit: [deno fmt](https://docs.deno.com/runtime/reference/cli/formatter/)

## Test

**Please include tests to cover your changes!**
