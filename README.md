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

After independent approval, publish the same SemVer tag from this repository
to the private registries of **Bank-platform** and **Bank-dev-team**. HCP private
registry modules do not automatically cross HCP organization boundaries. In
each consuming workspace, reference the module from its own organization's
registry and pin an exact version. The same packaged release works in both
organizations because its child module is local. The Terraform Cloud GitHub
App should be granted access only to this wrapper repository for publication.
No apply-capable workspace is needed merely to publish a registry version.

Keep the provider lock file in the *consumer root configuration*; this
repository's lock file pins CI only. A wrapper cannot lock the consumer's
provider installation. A public repository and passing CI do not constitute
regulatory approval.

## Verification and release controls

CI verifies the exact upstream Git tree, then runs format, initialization,
validation, mocked plan tests, HIGH/CRITICAL Terraform configuration scanning,
and secret scanning without AWS credentials. Its actions are pinned to commit
SHAs, it has read-only repository permission, and it never applies changes.
Upstream source files are kept byte-for-byte, so formatting checks apply to
the wrapper and example only. The IaC scan excludes upstream example folders;
those examples are not part of the hardened consumer interface.

Before using this as an enterprise release channel, configure enforced branch
and tag rules, independent reviewers, required CI, signed/attested releases,
and immutable approval evidence. A single-owner demo cannot substitute for
two-person approval or separation of duties.

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
