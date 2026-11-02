#!/usr/bin/env python3
"""One-time CI queue maintenance; never deletes commits, logs or artifacts.

Preserve requested Run50/51. Only supersede older diagnostics 47-49 and queued
52-57 and superseded diagnostic attempts 59-60, whose repairs are all retained in the newer source checkpoint. Inventory
is uploaded before cancellation. Run62 and Run66 unit/build artifacts have been downloaded, SHA/CRC verified and retained; its same Button-label repair is included in Run64 and later source. Run67-69 unit artifacts and failures are also downloaded and retained; their duplicate broad traversals and queued pre-diagnostic export attempt are superseded by source74. Run64 functional evidence and current corrected source remain active. Run64/65 focused and native-audit artifacts and Run70 shared-control failures are retained locally with checksums; only their remaining superseded traversal is cancelled. The duplicate Run73 and queued intermediate source76-78 are superseded by source79, which remains protected, as does source74 unique export/modal diagnostic. Completed runs and all other later runs are untouched.
"""
import json
import os
from pathlib import Path
import sys
import urllib.error
import urllib.request

REPOSITORY = "paigielake-dev/Fruitfolio_AUDIT_WORKING_COPY_NEW"
BRANCH = "fruitfolio/prompt-1b-alignment"
WORKFLOW = 403220650
PRESERVE = {41357420177, 41358742740}
OBSOLETE_NUMBERS = {47, 48, 49, 52, 53, 54, 55, 56, 57, 59, 60}
OBSOLETE_COMMITS = {"8d9d067f392cac84ec1edc47ca8bcc08b1d444a4",
                    "5a4e0ec21e6c8737700516302afe3682cf023a6a",
                    "d3d4a81f265620eb4b6952b3ddcf9148e158c026",
                    "44eee9e70631e83892380ecd2747e94a59f27f3a",
                    "3eb4b84a83acea614deee0320d8b037e408045ef",
                    "c0e6020eba31f62e56a8f1a14df2722d6afe395d",
                    "e132ba82bcb61919c291c2031cbbf4a331a38bbf",
                    "db650d9d44d9285a199c454540ef1094913637a6",
                    "a2ae944aa07d23670357e56d4abbcbbcca52e74b",
                    "3f67f201abde93e9b8d41c86a747e9ac79bb9484",
                    "ee9fcf87eaf86e9f33738ae40798a2ec0ce5a85f",
                    "044c8c040c8ed06f06abe2f5e63831ccfcc5075d",
                    "94da0de68e69de0b2befe226a31625dddcea5769",
                    "b1aa214ed2494af5192751558eb21116a1af30c3",
                    "34b8051048b1a5e8352f5566bd361f373fbd9f38"}
OUT = Path("verification-queue-state.json")


def api(path, method="GET"):
    request = urllib.request.Request("https://api.github.com/repos/" + REPOSITORY + path,
        data=b"" if method == "POST" else None, method=method,
        headers={"Authorization": "Bearer " + os.environ["GH_TOKEN"],
                 "Accept": "application/vnd.github+json", "X-GitHub-Api-Version": "2022-11-28"})
    with urllib.request.urlopen(request, timeout=30) as response:
        content = response.read()
        return json.loads(content) if content else None


def safe(run):
    return (run["id"] not in PRESERVE and str(run["id"]) != os.environ["GITHUB_RUN_ID"]
            and run["head_branch"] == BRANCH and run["workflow_id"] == WORKFLOW
            and (run["run_number"] in OBSOLETE_NUMBERS or run["head_sha"] in OBSOLETE_COMMITS)
            and run["head_sha"] != os.environ["FRUITFOLIO_HEAD_SHA"])


if __name__ == "__main__":
    assert os.environ.get("GITHUB_ACTIONS") == "true"
    assert os.environ.get("GITHUB_REPOSITORY") == REPOSITORY
    if sys.argv[1:] == ["inventory"]:
        runs = api("/actions/workflows/" + str(WORKFLOW) + "/runs?branch=" + BRANCH + "&event=pull_request&per_page=100")["workflow_runs"]
        candidates = []
        for run in runs:
            if safe(run) and run["status"] != "completed":
                candidates.append({"run": run, "jobs": api("/actions/runs/" + str(run["id"]) + "/jobs?per_page=100"),
                                   "artifacts": api("/actions/runs/" + str(run["id"]) + "/artifacts?per_page=100")})
        OUT.write_text(json.dumps({"reason": "Preserve old diagnostics and free macOS capacity for repaired source; no acceptance implied by cancellation", "preservedRequestedRuns": sorted(PRESERVE), "candidates": candidates}, indent=2) + "\n")
        print("Inventoried", len(candidates), "superseded runs; commits and artifacts remain intact.")
    elif sys.argv[1:] == ["cancel"]:
        for item in json.loads(OUT.read_text())["candidates"]:
            run = api("/actions/runs/" + str(item["run"]["id"]))
            assert safe(run)
            if run["status"] == "completed":
                continue
            try:
                api("/actions/runs/" + str(run["id"]) + "/cancel", "POST")
                print("Requested cancellation of superseded run", run["run_number"], run["id"], "; evidence retained, no PASS assigned.")
            except urllib.error.HTTPError as error:
                if error.code == 409:
                    print("Run finished before cancellation", run["id"])
                else:
                    raise
    else:
        raise SystemExit("Expected inventory or cancel")
