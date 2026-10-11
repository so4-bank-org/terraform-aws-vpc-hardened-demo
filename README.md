# Hardened VPC wrapper (governed demonstration)

This is a **standalone demonstration module** for a private-only AWS VPC. It is
newly authored for this public repository; no source or Git history from the
internal `quarantine-upstream-tf.module` repository is included.

The wrapper uses a complete local snapshot of the public `terraform-aws-vpc`
module at the exact
[`v5.19.0` commit](https://github.com/terraform-aws-modules/terraform-aws-vpc/commit/961c9b51e3ed3959d9419f019e7085c087bf7297).
That commit is also preserved in a private
[organization-owned mirror](https://github.com/so4-bank-org/terraform-aws-vpc-mirror).
The package in `modules/upstream/` has the same Git tree hash as the upstream
commit, and retains the Apache-2.0 license. See [source provenance](UPSTREAM-PROVENANCE.md).
Consumer runs need access to this wrapper release, not credentials for the
private mirror.

## Baseline

- At least two distinct availability zones and one private subnet per zone.
- No public subnets, internet gateway, NAT gateway or automatic public IPs.
- Default security group managed with no ingress or egress rules.
- VPC flow logs for all traffic sent to a module-created CloudWatch Logs group.
- One-year **demo** log retention by default; the log group is preserved on
  Terraform destroy so deletion of a VPC does not erase its log evidence.
- Required environment, owner, cost-center and classification tags.
- Private VPC and non-overlapping subnet CIDR validation.

The wrapper creates an IAM delivery role and restricts its trust policy to VPC
flow logs from the current AWS account and Region. For production, set
`flow_logs_retention_days` to the approved retention period and supply an
approved `flow_logs_kms_key_arn` and `flow_logs_permissions_boundary_arn` when
required by the organization's controls. The null KMS-key default and 365-day
retention are demo settings, not a universal regulated baseline; production
KMS, retention and deletion policy are client-specific. The KMS key policy must
allow the CloudWatch Logs service to use that key. Central log collection,
access controls, immutability and monitoring still require platform controls
outside this module. CloudWatch Logs ingestion and retention incur charges.
An HCP plan-only role can use read-only AWS access. A later apply role needs
permissions to create the log group and IAM role/policy, plus `iam:PassRole`
scoped to the generated delivery role and `iam:PassedToService` set to
`vpc-flow-logs.amazonaws.com`. This wrapper alone does not enforce organization
policy, account boundaries or change approval; those belong in the platform's
HCP Terraform policy and run workflow.

## Example

See [`examples/private/main.tf`](examples/private/main.tf). No S3 bucket is
required. The example does not contain credentials and should be used in a
disposable account for integration tests.

## HCP Terraform distribution

After independent approval, publish the same SemVer tag from this repository
to the private registries of **Bank-platform** and **Bank-dev-team**. HCP private
registry modules do not automatically cross HCP organization boundaries. In
each consuming workspace, reference the module from its own organization's
registry and pin an exact version. The same packaged release works in both
organizations because its child module is local. The Terraform Cloud GitHub
App needs access to this wrapper repository for publication; grant any
consumer repositories separately and keep the private upstream mirror outside
the app installation.
No apply-capable workspace is needed merely to publish a registry version.

Keep the provider lock file in the *consumer root configuration*; this
repository's lock file pins CI only. A wrapper cannot lock the consumer's
provider installation. A public repository and passing CI do not constitute
regulatory approval.

**Breaking interface change for `v0.2.0`:** changing the flow-log destination
from S3 to CloudWatch Logs removes the `flow_logs_bucket_arn` input. After
approval, release tag `v0.2.0`; verify HCP has published version `0.2.0` in
both the Bank-platform and Bank-dev-team private registries; only then update
the consumer's exact version pin and remove its bucket input. Never rewrite the
existing `0.1.0` registry version. The 365-day default is for this demo; set
the approved retention period for each real regulated workload.

## Verification and release controls

CI verifies the exact upstream Git tree, then runs format, initialization,
validation, mocked plan tests, HIGH/CRITICAL Terraform configuration scanning,
and secret scanning without AWS credentials. Its actions are pinned to commit
SHAs, it has read-only repository permission, and it never applies changes.
Upstream source files are kept byte-for-byte, so formatting checks apply to
the wrapper and example only. The IaC scan excludes upstream example folders;
those examples are not part of the hardened consumer interface.

To publish a version, merge the approved change to `main`, then run
**Actions → Release module → Run workflow** on `main` with a new tag such as
`v1.2.3`. The `module-release` environment must require an independent reviewer
and prevent self-review, and allow deployments only from `main`. After approval,
the first job verifies the vendored source and current default-branch commit.
The `v*` tag rule requires a successful `module-release` deployment and the
`validate` check, and blocks tag updates and deletions. The first job is
designed to satisfy that deployment requirement before the tag is pushed;
verify this behavior during the first release before relying on it as a control.
The second job creates an annotated tag only if that tag does not already exist.
Once both HCP registry connections are configured,
verify that the new version appears in **Bank-platform** and **Bank-dev-team**
before pinning it in consuming workspaces. Keep approval evidence with the
release record; signed or attested releases are additional controls.

Run locally:

```sh
bash scripts/verify-upstream-snapshot.sh
terraform fmt -check .
terraform fmt -check examples/private
terraform init -backend=false -lockfile=readonly
terraform validate
terraform test
```

## License

This demonstration wrapper is MIT licensed. The bundled upstream snapshot is
Apache-2.0 licensed under its own preserved [LICENSE](modules/upstream/LICENSE).
