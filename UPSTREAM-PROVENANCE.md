# Upstream VPC source provenance

The wrapper packages an exact, unmodified source snapshot from
[`terraform-aws-modules/terraform-aws-vpc` v5.19.0](https://github.com/terraform-aws-modules/terraform-aws-vpc/tree/v5.19.0).

| Item | Recorded value |
| --- | --- |
| Canonical upstream commit | `961c9b51e3ed3959d9419f019e7085c087bf7297` |
| Canonical upstream Git tree | `54066e3843bf9844727fdccf800e435018fa2b61` |
| Organization mirror | [`so4-bank-org/terraform-aws-vpc-mirror`](https://github.com/so4-bank-org/terraform-aws-vpc-mirror) (private) |
| Mirror refs verified | `main` and `v5.19.0` both equal the canonical commit |
| Packaged location | `modules/upstream/` |
| Upstream license | Apache-2.0; preserved in `modules/upstream/LICENSE` |

`modules/upstream/` was extracted from the canonical commit with `git archive`.
Its Git tree hash equals the recorded upstream tree, so the package includes
the full upstream source snapshot rather than a modified selection of files.
CI runs `scripts/verify-upstream-snapshot.sh` to reject a changed snapshot.
The hardened behavior is in the wrapper at the repository root. This record
establishes source identity; it does **not** establish independent approval of
the mirror or release.

For the next upstream intake, record the new upstream commit and license,
rebuild the package from that exact commit, update the expected tree hash,
run the contract tests and security scans, and obtain an independent review
before publishing a new immutable SemVer release. Do not update a released
tag in place.
