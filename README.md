# Hardened VPC wrapper (public demonstration)

This is a **standalone demonstration module** for a private-only AWS VPC. It is
newly authored for this public repository; no source or Git history from the
internal `quarantine-upstream-tf.module` repository is included.

The wrapper calls the public `terraform-aws-vpc` module at the immutable
[`v5.19.0` commit](https://github.com/terraform-aws-modules/terraform-aws-vpc/commit/961c9b51e3ed3959d9419f019e7085c087bf7297).
It does not vendor that upstream project's source. The upstream project has its
own license and maintenance lifecycle.

## Baseline

- At least two distinct availability zones and one private subnet per zone.
- No public subnets, internet gateway, NAT gateway or automatic public IPs.
- Default security group managed with no ingress or egress rules.
- VPC flow logs for all traffic sent to an existing central S3 bucket.
- Required environment, owner, cost-center and classification tags.
- Private VPC and non-overlapping subnet CIDR validation.

The caller must provide a bucket with approved delivery permissions, encryption,
retention, immutability and monitoring. An ARN cannot prove those controls.
Likewise, this wrapper alone does not enforce IAM, organization policy, account
boundaries or change approval. Those belong in the platform's HCP Terraform
policy and run workflow.

## Example

See [`examples/private/main.tf`](examples/private/main.tf). Set the bucket ARN to
a real platform-owned bucket before planning. The example does not contain
credentials and should be used in a disposable account for integration tests.

## HCP Terraform distribution

Publish a reviewed SemVer tag from this repository to the **Bank-platform**
private registry. To consume it from the separate **Bank-dev-team** HCP
organization, register the same approved VCS tag in that organization's private
registry and pin an exact version in the consuming workspace. Keep the provider
lock file in the *consumer root configuration*; this repository's lock file pins
CI only, and a wrapper cannot lock the consumer's provider installation. Do not connect this module repository to an
apply-capable workspace just to publish registry versions.

This public demo currently references the pinned public upstream source. A
regulated production release should use a client-owned, approved mirror at an
exact reviewed commit, with license/provenance evidence and scoped HCP read
credentials. Changing that source requires a reviewed release, contract tests,
security scans, and a saved HCP plan. A public repository and passing CI are
not themselves regulatory approval.

## Verification and release controls

CI runs format, initialization, validation and mocked plan tests without AWS
credentials. It has read-only repository permission and never applies changes.
Before using this as an enterprise release channel, configure enforced branch
and tag rules, independent reviewers, required CI, signed/attested releases,
secret scanning, and immutable approval evidence. A single-owner demo cannot
substitute for two-person approval or separation of duties.

Run locally:

```sh
terraform fmt -check -recursive
terraform init -backend=false -lockfile=readonly
terraform validate
terraform test
```

## License

This demonstration wrapper is MIT licensed. Its referenced upstream dependency
remains separately licensed by its maintainers.
