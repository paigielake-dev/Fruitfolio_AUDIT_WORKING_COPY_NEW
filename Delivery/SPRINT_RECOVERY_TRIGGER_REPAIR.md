# Evidence recovery trigger repair

The first recovery job was SKIPPED: this workflow runs on pull_request, whose payload has no head_commit.message. Recovery now uses the same actual checked-out head-commit message that already correctly plans Apple verification. Both original Run 2 and Run 9 oversized archives are selected once; neither recovery had executed before this repair. There is no test rerun or inferred test PASS in this tooling operation. Original artifacts remain immutable and retained.
