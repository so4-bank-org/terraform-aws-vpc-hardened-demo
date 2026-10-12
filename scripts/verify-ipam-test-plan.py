#!/usr/bin/env python3
"""Run mocked Terraform contracts and verify the AWS VPC IPAM plan boundary."""

import json
import subprocess
import sys


RUN = "allocate_explicit_cidr_from_ipam"
VPC = "module.vpc.aws_vpc.this[0]"
EXPECTED = {
    "cidr_block": "10.42.0.0/16",
    "ipv4_ipam_pool_id": "ipam-pool-0123456789abcdef0",
    "ipv4_netmask_length": None,
}


def main() -> int:
    process = subprocess.Popen(
        ["terraform", "test", "-json", "-verbose"],
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
    )
    assert process.stdout is not None
    planned_vpc = None
    plan_error = None
    summary = None
    for line in process.stdout:
        try:
            event = json.loads(line)
        except json.JSONDecodeError:
            print(line.rstrip(), file=sys.stderr)
            continue
        if event.get("type") == "test_plan" and event.get("@testrun") == RUN:
            matches = [
                change
                for change in event["test_plan"]["resource_changes"]
                if change["address"] == VPC
            ]
            if len(matches) != 1:
                plan_error = f"Expected one planned {VPC}; found {len(matches)}"
            else:
                planned_vpc = matches[0]["change"]["after"]
        elif event.get("type") == "test_summary":
            summary = event["test_summary"]

    result = process.wait()
    if result != 0 or summary is None or summary.get("status") != "pass":
        print(f"Terraform contract tests failed: {summary}, exit={result}", file=sys.stderr)
        return 1
    if plan_error is not None:
        print(plan_error, file=sys.stderr)
        return 1
    if planned_vpc is None:
        print(f"Missing JSON plan for {RUN}", file=sys.stderr)
        return 1
    actual = {key: planned_vpc.get(key) for key in EXPECTED}
    if actual != EXPECTED:
        print(f"IPAM VPC plan mismatch: expected {EXPECTED}; got {actual}", file=sys.stderr)
        return 1
    print(
        f"{summary['passed']} mocked contracts passed; VPC plan uses the reviewed "
        "CIDR and IPAM pool without a dynamic netmask."
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
