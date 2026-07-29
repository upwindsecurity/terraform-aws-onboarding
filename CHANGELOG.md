# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).


## [4.0.1](https://github.com/upwindsecurity/terraform-aws-onboarding/compare/v4.0.0...v4.0.1) (2026-07-29)

### Bug Fixes

* **AG-0:** add subnet and security-group resources for vpc endpoint creation ([d87f31a](https://github.com/upwindsecurity/terraform-aws-onboarding/commit/d87f31a2c14e8d138b74166531606866d7730e42))

## [4.0.0](https://github.com/upwindsecurity/terraform-aws-onboarding/compare/v3.0.1...v4.0.0) (2026-07-24)

### ⚠ BREAKING CHANGES

* **UP-3933:** the module source is now the registry root
(upwindsecurity/onboarding/aws) instead of the
//modules/aws-org-onboarding submodule path. The standalone release
artifact is renamed from terraform-aws-onboarding-aws-org-onboarding-<ver>.tar.gz
to terraform-aws-onboarding-<ver>.tar.gz. 2.x/3.x versions keep their old
paths.

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>

### Features

* **UP-3933:** promote aws-org-onboarding to the repository root module ([4f640b6](https://github.com/upwindsecurity/terraform-aws-onboarding/commit/4f640b605d6d02b14fae5ab5a6c2f35a32044efa))

## [3.0.1](https://github.com/upwindsecurity/terraform-aws-onboarding/compare/v3.0.0...v3.0.1) (2026-07-24)

### Documentation

* **UP-3933:** add terraform usage snippet to example README ([b80f1f1](https://github.com/upwindsecurity/terraform-aws-onboarding/commit/b80f1f1f01f318bca6bc78a031111482a4be2194))

## [3.0.0](https://github.com/upwindsecurity/terraform-aws-onboarding/compare/v2.1.15...v3.0.0) (2026-07-24)

### ⚠ BREAKING CHANGES

* **UP-3933:** the submodule source path changed from
upwindsecurity/onboarding/aws//modules/main/aws-org-onboarding to
upwindsecurity/onboarding/aws//modules/aws-org-onboarding. Consumers must
update their module source when upgrading to 3.x; 2.x versions keep the
old path.

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>

### Features

* **UP-3933:** flatten module layout to modules/aws-org-onboarding ([88bbbb0](https://github.com/upwindsecurity/terraform-aws-onboarding/commit/88bbbb0351df55e5555ea4b39b8a9eb8cb32ca31))

### Bug Fixes

* **UP-3933:** fixing broken tar build in ci ([9c31d55](https://github.com/upwindsecurity/terraform-aws-onboarding/commit/9c31d557c603626ad8bacb7f50a78a1c977c7ed1))
* **UP-3933:** fixing examples, ci and removing dead vars ([3f49bb3](https://github.com/upwindsecurity/terraform-aws-onboarding/commit/3f49bb3ab31ab3adf68eeaee9248f872e170d661))

## [2.1.17](https://github.com/upwindsecurity/terraform-aws-onboarding/compare/v2.1.16...v2.1.17) (2026-07-24)

### Bug Fixes

* **UP-3933:** fixing broken tar build in ci ([9c31d55](https://github.com/upwindsecurity/terraform-aws-onboarding/commit/9c31d557c603626ad8bacb7f50a78a1c977c7ed1))

## [2.1.16](https://github.com/upwindsecurity/terraform-aws-onboarding/compare/v2.1.15...v2.1.16) (2026-07-24)

### Bug Fixes

* **UP-3933:** fixing examples, ci and removing dead vars ([3f49bb3](https://github.com/upwindsecurity/terraform-aws-onboarding/commit/3f49bb3ab31ab3adf68eeaee9248f872e170d661))

## [2.1.13](https://github.com/upwindsecurity/terraform-aws-onboarding/compare/v2.1.12...v2.1.13) (2026-07-15)

### Bug Fixes

* **UP-3091:** adding additional version injection to replace version undefined ([#39](https://github.com/upwindsecurity/terraform-aws-onboarding/issues/39)) ([d990e58](https://github.com/upwindsecurity/terraform-aws-onboarding/commit/d990e58ce59238c8b68b35e9379dc575d157c1d8))

## [2.1.12](https://github.com/upwindsecurity/terraform-aws-onboarding/compare/v2.1.11...v2.1.12) (2026-06-25)

### Bug Fixes

* **AG-2798:** Remove Discovery role registration ([8c873c7](https://github.com/upwindsecurity/terraform-aws-onboarding/commit/8c873c7642a2e6e5d2cae00e486d45e3e682bd54))
* **AG-2798:** Remove Org role registration configurations and related resources ([6dadb23](https://github.com/upwindsecurity/terraform-aws-onboarding/commit/6dadb23acd644f49fc0da3ab980c66a01c9f4cbc))
* **AG-2798:** Remove Org role registration module and related resources ([60c8dd9](https://github.com/upwindsecurity/terraform-aws-onboarding/commit/60c8dd9960eaafb6d4ad016dbee0b2c3857756c0))
* Remove organization role registration configurations and related resources ([801bdc1](https://github.com/upwindsecurity/terraform-aws-onboarding/commit/801bdc160073841e8c473db469a01997c7abac0d))
* Remove unnecessary blank line in variables.tf ([61dd199](https://github.com/upwindsecurity/terraform-aws-onboarding/commit/61dd19929c2cc69bbf849907d1dc0979fc15f0e8))

### Code Refactoring

* Clean up org registration related code and documentation ([de867c3](https://github.com/upwindsecurity/terraform-aws-onboarding/commit/de867c32ca0063a0a53aaad267ada80347c52432))

## [2.1.11](https://github.com/upwindsecurity/terraform-aws-onboarding/compare/v2.1.10...v2.1.11) (2026-06-22)

### Bug Fixes

* **UP-2416:** ap region ([#37](https://github.com/upwindsecurity/terraform-aws-onboarding/issues/37)) ([afe631d](https://github.com/upwindsecurity/terraform-aws-onboarding/commit/afe631d71b7773222819dd3a92c767e3ccc1ea20))

## [2.1.10](https://github.com/upwindsecurity/terraform-aws-onboarding/compare/v2.1.9...v2.1.10) (2026-06-19)

### Bug Fixes

* **AG-5732:** module consolidation ([#36](https://github.com/upwindsecurity/terraform-aws-onboarding/issues/36)) ([7a24799](https://github.com/upwindsecurity/terraform-aws-onboarding/commit/7a247999962844efed96012046c3f5d5dff913c5))

## [2.1.9](https://github.com/upwindsecurity/terraform-aws-onboarding/compare/v2.1.8...v2.1.9) (2026-06-18)

### Bug Fixes

* **UP-463:** fixing asg permission tag issues ([#35](https://github.com/upwindsecurity/terraform-aws-onboarding/issues/35)) ([8f826a7](https://github.com/upwindsecurity/terraform-aws-onboarding/commit/8f826a77b7db9158091f251761157960e5bbf81a))

## [2.1.8](https://github.com/upwindsecurity/terraform-aws-onboarding/compare/v2.1.7...v2.1.8) (2026-06-16)

### Bug Fixes

* **AG-5732:** module consolidation ([#34](https://github.com/upwindsecurity/terraform-aws-onboarding/issues/34)) ([70ebcc8](https://github.com/upwindsecurity/terraform-aws-onboarding/commit/70ebcc852633ea62e5da4c6f642072499c197238))

## [2.1.7](https://github.com/upwindsecurity/terraform-aws-onboarding/compare/v2.1.6...v2.1.7) (2026-06-09)

### Bug Fixes

* **AG-0:** removing unnecessary pr step ([#32](https://github.com/upwindsecurity/terraform-aws-onboarding/issues/32)) ([b3ec09e](https://github.com/upwindsecurity/terraform-aws-onboarding/commit/b3ec09ec278eb44ad2e00e32bd6eb338dada94a8))

## [2.1.6](https://github.com/upwindsecurity/terraform-aws-onboarding/compare/v2.1.5...v2.1.6) (2026-06-09)

### Bug Fixes

* **AG-0:** adding versioning ([#31](https://github.com/upwindsecurity/terraform-aws-onboarding/issues/31)) ([fec41c7](https://github.com/upwindsecurity/terraform-aws-onboarding/commit/fec41c7d4cafe26d9100642923b11b5fdc05ec40))

## [2.1.5](https://github.com/upwindsecurity/terraform-aws-onboarding/compare/v2.1.4...v2.1.5) (2026-06-09)

### Bug Fixes

* **AG-0:** rollback to v2.1.0 ([#29](https://github.com/upwindsecurity/terraform-aws-onboarding/issues/29)) ([4837c3e](https://github.com/upwindsecurity/terraform-aws-onboarding/commit/4837c3e5a77b9e6cca0cdb64e2b31d1dcc62f523)), closes [#26](https://github.com/upwindsecurity/terraform-aws-onboarding/issues/26) [#24](https://github.com/upwindsecurity/terraform-aws-onboarding/issues/24) [#22](https://github.com/upwindsecurity/terraform-aws-onboarding/issues/22) [#20](https://github.com/upwindsecurity/terraform-aws-onboarding/issues/20)

## 1.0.0 (2026-04-13)

### Bug Fixes

* **AG-5732:** Remove superfluous steps ([a8a7f1c](https://github.com/upwindsecurity/terraform-aws-onboarding/commit/a8a7f1c368e314d62a11d6aa98b1b5a42dc6a168))

## [1.4.6](https://github.com/upwindsecurity/terraform-module-template/compare/v1.4.5...v1.4.6) (2025-06-16)

### Bug Fixes

* enable draft releases with draftRelease option ([#24](https://github.com/upwindsecurity/terraform-module-template/issues/24)) ([c28f0ea](https://github.com/upwindsecurity/terraform-module-template/commit/c28f0eac96986aa12ad9b554a82b05ba36455580))

## [1.4.5](https://github.com/upwindsecurity/terraform-module-template/compare/v1.4.4...v1.4.5) (2025-06-16)

### Bug Fixes

* add missing conventional-changelog-conventionalcommits dependency ([#22](https://github.com/upwindsecurity/terraform-module-template/issues/22)) ([acb87e1](https://github.com/upwindsecurity/terraform-module-template/commit/acb87e1cf91465a4335d3cbc4e5aacf823e5efa4))
* configure release workflow to create draft releases ([#21](https://github.com/upwindsecurity/terraform-module-template/issues/21)) ([147c6ed](https://github.com/upwindsecurity/terraform-module-template/commit/147c6ed6d7103ad376474df7eff76b3043a31be5))

## [1.4.4](https://github.com/upwindsecurity/terraform-module-template/compare/v1.4.3...v1.4.4) (2025-06-16)

## [1.4.3](https://github.com/upwindsecurity/terraform-module-template/compare/v1.4.2...v1.4.3) (2025-06-16)

### Bug Fixes

* add issues write permission for PR label management ([#17](https://github.com/upwindsecurity/terraform-module-template/issues/17)) ([cc64007](https://github.com/upwindsecurity/terraform-module-template/commit/cc640073277295446423d74ec3d14a86e78630df))

## [1.3.0](https://github.com/upwindsecurity/terraform-module-template/compare/v1.2.0...v1.3.0) (2025-06-16)

### Features

* update release workflow to use main branch and create release PRs ([#6](https://github.com/upwindsecurity/terraform-module-template/issues/6)) ([b0fa525](https://github.com/upwindsecurity/terraform-module-template/commit/b0fa525f6dc74185acbd0df54fb5d2f069ca8e6a))

## [1.2.0](https://github.com/upwindsecurity/terraform-module-template/compare/v1.1.1...v1.2.0) (2025-06-09)

### Features

* update configuration files for improved tooling and CI/CD ([#5](https://github.com/upwindsecurity/terraform-module-template/issues/5)) ([ef63741](https://github.com/upwindsecurity/terraform-module-template/commit/ef637412d4e21ea6be9b9e56c81e9cf1fb431162))

## [1.1.1](https://github.com/upwindsecurity/terraform-module-template/compare/v1.1.0...v1.1.1) (2025-06-09)

## [1.1.0](https://github.com/upwindsecurity/terraform-module-template/compare/v1.0.2...v1.1.0) (2025-06-09)

### Features

* update Makefile with improved functionality ([#3](https://github.com/upwindsecurity/terraform-module-template/issues/3)) ([dbb9856](https://github.com/upwindsecurity/terraform-module-template/commit/dbb98565069316ff7244734c932390581aaf1213))

## [1.0.2](https://github.com/upwindsecurity/terraform-module-template/compare/v1.0.1...v1.0.2) (2025-06-09)

### Bug Fixes

* correct changelog structure and exclude from linting ([#2](https://github.com/upwindsecurity/terraform-module-template/issues/2)) ([8d35b43](https://github.com/upwindsecurity/terraform-module-template/commit/8d35b43c839de220b3558556cc4fc471130972cb))

## [1.0.1](https://github.com/upwindsecurity/terraform-module-template/compare/v1.0.0...v1.0.1) (2025-06-09)

### Code Refactoring

* remove unused random_id resource from basic example ([#1](https://github.com/upwindsecurity/terraform-module-template/issues/1)) ([52d3861](https://github.com/upwindsecurity/terraform-module-template/commit/52d3861fc08fea39b577b4c9b74aa76575a711ce))

## 1.0.0 (2025-06-09)
