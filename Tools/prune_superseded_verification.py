#!/usr/bin/env python3
"""One-time CI queue maintenance; never deletes commits, logs or artifacts.

Preserve requested Run50/51. Only supersede older diagnostics 47-49 and queued
52-57 and superseded diagnostic attempts 59-60, whose repairs are all retained in the newer source checkpoint. Inventory
is uploaded before cancellation. Completed runs and all later runs are untouched.
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
            and run["run_number"] in OBSOLETE_NUMBERS
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
