# Contributing to HL7Swift

Thank you for your interest in HL7Swift. This guide explains how to propose a
change and what a change needs before it is merged. By participating, you
agree to follow the [Code of Conduct](CODE_OF_CONDUCT.md).

## Before you start

- Search the existing issues, and open one before a large change so its scope
  can be agreed first.
- Report vulnerabilities privately, as described in [SECURITY.md](SECURITY.md).
- Never attach or commit messages or documents that contain patient data. Test
  fixtures must be synthetic or come from a public, redistributable source;
  `Scripts/anonymize-test-messages.py` replaces the person data of example
  HL7 v2 messages.
- Never commit HL7 specification artefacts (XSD schemas, tables): HL7Swift
  implements the standard in Swift and redistributes none of them.
  `Scripts/check-no-specifications.sh` enforces this.

## Build and test

```sh
swift build -c release
swift test --parallel
```

Changes that touch networking, resources, or platform code must also pass on
iOS and Linux. CI runs the same jobs on GitHub Actions and GitLab CI.

## What a change needs

| Requirement | Details |
| --- | --- |
| Standard reference | Cite the HL7 v2 chapter, FHIR page, or CDA section that the change implements |
| Tests | Automated tests for every new claim, with synthetic fixtures |
| Platforms | The package builds and the tests pass on macOS, iOS, and Linux |
| Documentation | Update the DocC articles of the product (`Sources/<Product>/<Product>.docc`) in the same change; the site must build without warnings |
| Honest reports | A validator or mapping declares the stages it ran, and leaves the others `notRun` |
| Compatibility | Source or behavior changes come with a migration note in the pull request |

Build the documentation with:

```sh
Scripts/documentation/build.sh .build/documentation
```

## Style

- Follow the style of the surrounding code: naming, comment density, and
  idioms.
- Public API is documented with `///` comments that name every parameter.
- Keep commits focused. Write commit messages in English, following
  [Conventional Commits](https://www.conventionalcommits.org)
  (`feat(v2): …`, `fix(fhir): …`). The changelog is generated from them with
  [git-cliff](https://git-cliff.org).

## Pull requests

Open pull requests against `main`. Describe what changes, why, the standard
reference, and how it was verified. CI must pass before review.

By contributing, you agree that your contributions are licensed under the
[MIT License](LICENSE).
