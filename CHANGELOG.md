# Changelog — medinovai-infrastructure

All notable changes to this project will be documented in this file.

Format: [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
Versioning: [Semantic Versioning](https://semver.org/spec/v2.0.0.html)

---

## [Unreleased]

### Added
- Phase 2 standards alignment artifacts (CONTRIBUTING.md, CHANGELOG.md, etc.)

### Changed
- N/A

### Fixed
- N/A

### Security
- N/A

---

## [1.0.0] — TODO

### Added
- Initial release
- Core functionality
- CI/CD pipeline
- Test scaffold
- Standards alignment (Phase 1): CLAUDE.md, CODEOWNERS, SECURITY.md,
  medinovai.manifest.yaml, atlasos.yaml, .github/workflows/ci.yml

---

## Release Process

1. Update `[Unreleased]` section with all changes
2. Create release branch: `git checkout -b release/vX.Y.Z`
3. Update version in relevant files
4. Rename `[Unreleased]` to `[X.Y.Z] — YYYY-MM-DD`
5. Create PR, get approval, squash-merge to main
6. Tag: `git tag -s vX.Y.Z -m "Release vX.Y.Z"`
7. Push tag: `git push origin vX.Y.Z`
