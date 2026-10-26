#!/usr/bin/env -S uv run
# /// script
# requires-python = ">=3.12"
# dependencies = ["httpx"]
# ///
"""Ownership permission test and technical proofs P1-P8 against a throwaway PocketBase.

Exit codes: 0 all passed; 1 a permission line failed; 2 environment problem;
10-17 = proof P1-P8 failed (stops at the first failing proof).
"""

import argparse
import asyncio
import itertools
import json as jsonlib
import os
import secrets
import shutil
import socket
import subprocess
import sys
import tempfile
import time
from dataclasses import dataclass, field
from pathlib import Path

import httpx

ROOT = Path(__file__).resolve().parent.parent
REFUSED = {400, 403, 404}
RATE_LIMIT_WAIT = 3.2
SU_EMAIL = "su@pb-test.local"
TS = "2026-10-24 00:00:00.000Z"

BASE = ""
CLIENT: httpx.Client | None = None
_ids = itertools.count(1)


@dataclass(frozen=True)
class Actor:
    name: str  # "anon" | "A" | "B" | "superuser"
    token: str | None
    user_id: str | None


class ProofFailed(Exception):
    def __init__(self, exit_code: int, message: str) -> None:
        super().__init__(message)
        self.exit_code = exit_code
        self.message = message


class EnvError(Exception):
    pass


ANON = Actor("anon", None, None)


def request(
    actor: Actor,
    method: str,
    path: str,
    *,
    json: dict | None = None,
    params: dict | None = None,
    retry_429: bool = True,
) -> httpx.Response:
    assert CLIENT is not None
    headers = {"Authorization": actor.token} if actor.token else {}
    for attempt in range(4):
        r = CLIENT.request(method, BASE + path, headers=headers, json=json, params=params)
        if r.status_code != 429 or not retry_429 or attempt == 3:
            return r
        time.sleep(RATE_LIMIT_WAIT)
    raise AssertionError("unreachable")


def new_id(prefix: str) -> str:
    return f"{prefix}{next(_ids):06d}{secrets.token_hex(3)}"


def rec(coll: str, rid: str | None = None) -> str:
    base = f"/api/collections/{coll}/records"
    return f"{base}/{rid}" if rid else base


def su_get(su: Actor, coll: str, rid: str) -> httpx.Response:
    return request(su, "GET", rec(coll, rid))


def su_count(su: Actor, coll: str, flt: str) -> int:
    r = request(su, "GET", rec(coll), params={"filter": flt, "perPage": 1})
    return r.json()["totalItems"]


def must(r: httpx.Response, what: str, codes: tuple[int, ...] = (200,)) -> dict:
    if r.status_code not in codes:
        raise EnvError(f"{what} failed: {r.status_code} {r.text[:300]}")
    return r.json() if r.content else {}


# ---------------------------------------------------------------- server

def port_in_use(port: int) -> bool:
    with socket.socket() as s:
        s.settimeout(1)
        return s.connect_ex(("127.0.0.1", port)) == 0


def start_server(port: int, data_dir: Path) -> subprocess.Popen:
    log_path = data_dir.parent / "server.log"
    log = open(log_path, "wb")
    proc = subprocess.Popen(
        ["tool/pb.sh", "serve"],
        cwd=ROOT,
        env={**os.environ, "PB_PORT": str(port), "PB_DATA_DIR": str(data_dir)},
        stdout=log,
        stderr=subprocess.STDOUT,
    )
    deadline = time.monotonic() + 120
    while time.monotonic() < deadline:
        if proc.poll() is not None:
            break
        try:
            if httpx.get(f"http://127.0.0.1:{port}/api/health", timeout=2).status_code == 200:
                return proc
        except httpx.HTTPError:
            pass
        time.sleep(0.5)
    tail = log_path.read_text(errors="replace").splitlines()[-30:]
    print("\n".join(tail), file=sys.stderr)
    stop_server(proc)
    raise EnvError("server did not start within 120 s")


def stop_server(proc: subprocess.Popen) -> None:
    if proc.poll() is None:
        proc.terminate()
        try:
            proc.wait(10)
        except subprocess.TimeoutExpired:
            proc.kill()
            proc.wait()


def login(collection: str, identity: str, password: str, name: str) -> Actor:
    r = request(
        ANON, "POST", f"/api/collections/{collection}/auth-with-password",
        json={"identity": identity, "password": password},
    )
    data = must(r, f"login {name}")
    return Actor(name, data["token"], data["record"]["id"])


def create_user(su: Actor, email: str, password: str) -> str:
    r = request(su, "POST", rec("users"), json={
        "email": email, "password": password, "passwordConfirm": password,
    })
    return must(r, f"create user {email}")["id"]


# ---------------------------------------------------------------- data

COLLECTIONS = [
    "task_lists", "tasks", "recurring_tasks", "recurring_task_claims",
    "appointments", "time_entries", "day_configs", "active_timers",
]
UNIQUE = {"day_configs", "active_timers"}


@dataclass
class Owner:
    actor: Actor
    seeds: dict[str, str] = field(default_factory=dict)

    @property
    def ctx(self) -> dict[str, str]:
        return {
            "list": self.seeds["task_lists"],
            "task": self.seeds["tasks"],
            "rt": self.seeds["recurring_tasks"],
        }


def payload(coll: str, uid: str, ctx: dict[str, str], rid: str | None = None) -> dict:
    body: dict = {"user": uid}
    match coll:
        case "task_lists":
            body |= {"name": "List", "is_default": False}
        case "tasks":
            body |= {
                "title": "Task", "list": ctx["list"], "created_at": TS,
                "estimated_minutes": 30, "is_done": False, "has_children": False,
                "spent_minutes": 0,
            }
        case "recurring_tasks":
            body |= {
                "title": "Recurring", "list": ctx["list"], "estimated_minutes": 10,
                "weekdays": ["monday"], "created_at": TS,
            }
        case "recurring_task_claims":
            body |= {"recurring_task": ctx["rt"]}
            rid = rid or new_id("clm-")
        case "appointments":
            body |= {
                "title": "Appointment", "list_id": ctx["list"], "date": TS,
                "start_minute": 60, "duration_minutes": 30, "spent_minutes": 0,
                "is_done": False,
            }
        case "time_entries":
            body |= {
                "target_id": ctx["task"], "target_type": "task", "list_id": ctx["list"],
                "origin": "timer", "minutes": 5, "occurred_at": TS,
            }
        case "day_configs":
            body |= {"available_minutes_per_day": 480, "onboarded": True}
        case "active_timers":
            body |= {
                "target_id": ctx["task"], "target_type": "task", "list_id": ctx["list"],
                "status": "running", "started_at": TS,
            }
    if rid:
        body["id"] = rid
    return body


def change_body(coll: str, ctx: dict[str, str]) -> dict:
    return {
        "task_lists": {"name": "changed"},
        "tasks": {"title": "changed"},
        "recurring_tasks": {"title": "changed"},
        "recurring_task_claims": {"recurring_task": ctx["rt"]},
        "appointments": {"title": "changed"},
        "time_entries": {"minutes": 99},
        "day_configs": {"available_minutes_per_day": 99},
        "active_timers": {"status": "paused"},
    }[coll]


def seed_owner(actor: Actor) -> Owner:
    owner = Owner(actor)
    uid = actor.user_id
    assert uid
    ctx: dict[str, str] = {}

    def make(coll: str) -> str:
        r = request(actor, "POST", rec(coll), json=payload(coll, uid, ctx))
        rid = must(r, f"seed {coll} for {actor.name}")["id"]
        owner.seeds[coll] = rid
        return rid

    ctx["list"] = make("task_lists")
    ctx["task"] = make("tasks")
    ctx["rt"] = make("recurring_tasks")
    for coll in ("recurring_task_claims", "appointments", "time_entries", "day_configs", "active_timers"):
        make(coll)
    # A child task, so parent relations have something to move.
    r = request(actor, "POST", rec("tasks"),
                json=payload("tasks", uid, ctx) | {"parent": ctx["task"], "title": "Child"})
    owner.seeds["child"] = must(r, "seed child task")["id"]
    return owner


# ---------------------------------------------------------------- permissions

class Results:
    def __init__(self) -> None:
        self.failed: list[str] = []

    def check(self, line: str, ok: bool, detail: str = "") -> None:
        if ok:
            print(f"PASS {line}")
        else:
            print(f"FAIL {line} {detail}".rstrip())
            self.failed.append(line)


def refused(r: httpx.Response) -> bool:
    return r.status_code in REFUSED


def check_permissions(su: Actor, a: Owner, b: Owner) -> list[str]:
    res = Results()
    A, B = a.actor, b.actor

    # Positive control: A works on its own records.
    for coll in COLLECTIONS:
        sid = a.seeds[coll]
        r = request(A, "GET", rec(coll))
        res.check(f"{coll}:list:owner", r.status_code == 200 and any(i["id"] == sid for i in r.json()["items"]),
                  str(r.status_code))
        r = request(A, "GET", rec(coll, sid))
        res.check(f"{coll}:view:owner", r.status_code == 200, str(r.status_code))
        r = request(A, "PATCH", rec(coll, sid), json=change_body(coll, a.ctx))
        if coll == "recurring_task_claims":
            res.check(f"{coll}:update:owner-blocked", refused(r), str(r.status_code))
        else:
            res.check(f"{coll}:update:owner", r.status_code == 200, f"{r.status_code} {r.text[:200]}")
        if coll in UNIQUE:
            r = request(A, "DELETE", rec(coll, sid))
            res.check(f"{coll}:delete:owner", r.status_code == 204, str(r.status_code))
            r = request(A, "POST", rec(coll), json=payload(coll, A.user_id, a.ctx))
            res.check(f"{coll}:create:owner", r.status_code == 200, f"{r.status_code} {r.text[:200]}")
            if r.status_code == 200:
                a.seeds[coll] = r.json()["id"]
        else:
            nid = new_id("pos-")
            r = request(A, "POST", rec(coll), json=payload(coll, A.user_id, a.ctx, nid))
            res.check(f"{coll}:create:owner", r.status_code == 200, f"{r.status_code} {r.text[:200]}")
            r = request(A, "DELETE", rec(coll, nid))
            res.check(f"{coll}:delete:owner", r.status_code == 204, str(r.status_code))

    for coll in COLLECTIONS:
        sid = a.seeds[coll]
        original = su_get(su, coll, sid).json()
        body = change_body(coll, a.ctx)

        def intact() -> bool:
            r = su_get(su, coll, sid)
            return r.status_code == 200 and all(r.json().get(k) == original.get(k) for k in body)

        # Anonymous.
        r = request(ANON, "GET", rec(coll))
        res.check(f"{coll}:list:anon", r.status_code == 200 and r.json()["items"] == [], str(r.status_code))
        r = request(ANON, "GET", rec(coll, sid))
        res.check(f"{coll}:view:anon", refused(r) and intact(), str(r.status_code))
        r = request(ANON, "PATCH", rec(coll, sid), json=body | ({"title": "x"} if "title" in original else {}))
        res.check(f"{coll}:update:anon", refused(r) and intact(), str(r.status_code))
        r = request(ANON, "DELETE", rec(coll, sid))
        res.check(f"{coll}:delete:anon", refused(r) and su_get(su, coll, sid).status_code == 200, str(r.status_code))
        rid = new_id("anon-")
        r = request(ANON, "POST", rec(coll), json=payload(coll, A.user_id, a.ctx, rid))
        res.check(f"{coll}:create:anon", refused(r) and su_get(su, coll, rid).status_code == 404, str(r.status_code))

        # B x A.
        r = request(B, "GET", rec(coll))
        mine = {i["id"] for i in r.json()["items"]} if r.status_code == 200 else {sid}
        res.check(f"{coll}:list:other-user", r.status_code == 200 and sid not in mine, str(r.status_code))
        r = request(B, "GET", rec(coll, sid))
        res.check(f"{coll}:view:other-user", refused(r), str(r.status_code))
        r = request(B, "PATCH", rec(coll, sid), json=body)
        res.check(f"{coll}:update:other-user", refused(r) and intact(), str(r.status_code))
        r = request(B, "DELETE", rec(coll, sid))
        res.check(f"{coll}:delete:other-user", refused(r) and su_get(su, coll, sid).status_code == 200, str(r.status_code))

        # B creates on behalf of A (relations are B's own, so only `user` is wrong).
        rid = new_id("neg-")
        r = request(B, "POST", rec(coll), json=payload(coll, A.user_id, b.ctx, rid))
        res.check(f"{coll}:create:on-behalf", refused(r) and su_get(su, coll, rid).status_code == 404, str(r.status_code))

        # Owner cannot hand the record over, nor send `user` at all.
        for label, target in (("to-other", B.user_id), ("same-owner", A.user_id)):
            r = request(A, "PATCH", rec(coll, sid), json={"user": target})
            after = su_get(su, coll, sid).json()
            res.check(f"{coll}:update:user-{label}", refused(r) and after["user"] == A.user_id, str(r.status_code))

    # Relation to another owner's record: create and update.
    relations = [
        ("tasks", "list", "task_lists"),
        ("tasks", "parent", "tasks"),
        ("recurring_tasks", "list", "task_lists"),
        ("recurring_task_claims", "recurring_task", "recurring_tasks"),
    ]
    for coll, fld, target_coll in relations:
        foreign = a.seeds[target_coll]
        rid = new_id("rel-")
        r = request(B, "POST", rec(coll), json=payload(coll, B.user_id, b.ctx, rid) | {fld: foreign})
        res.check(f"{coll}:create:foreign-{fld}", refused(r) and su_get(su, coll, rid).status_code == 404,
                  str(r.status_code))
        if coll == "recurring_task_claims":
            continue  # update is locked (null)
        sid = b.seeds[coll]
        before = su_get(su, coll, sid).json()[fld]
        r = request(B, "PATCH", rec(coll, sid), json={fld: foreign})
        res.check(f"{coll}:update:foreign-{fld}", refused(r) and su_get(su, coll, sid).json()[fld] == before,
                  str(r.status_code))

    check_users(res, su, a, b)
    return res.failed


def check_users(res: Results, su: Actor, a: Owner, b: Owner) -> None:
    A, B = a.actor, b.actor
    r = request(A, "GET", rec("users", A.user_id))
    res.check("users:view:owner", r.status_code == 200, str(r.status_code))
    r = request(A, "PATCH", rec("users", A.user_id), json={"name": "Owner A"})
    res.check("users:update:owner", r.status_code == 200, f"{r.status_code} {r.text[:200]}")
    pwd = secrets.token_urlsafe(24)
    tmp_email = f"tmp{secrets.token_hex(4)}@pb-test.local"
    tmp_id = create_user(su, tmp_email, pwd)
    tmp = login("users", tmp_email, pwd, "tmp")
    r = request(tmp, "DELETE", rec("users", tmp_id))
    res.check("users:delete:owner", r.status_code == 204, str(r.status_code))

    r = request(ANON, "GET", rec("users"))
    res.check("users:list:anon", r.status_code == 200 and r.json()["items"] == [], str(r.status_code))
    r = request(B, "GET", rec("users"))
    res.check("users:list:other-user",
              r.status_code == 200 and [i["id"] for i in r.json()["items"]] == [B.user_id], str(r.status_code))
    r = request(B, "GET", rec("users", A.user_id))
    res.check("users:view:other-user", refused(r), str(r.status_code))
    r = request(B, "PATCH", rec("users", A.user_id), json={"name": "hacked"})
    res.check("users:update:other-user",
              refused(r) and su_get(su, "users", A.user_id).json()["name"] == "Owner A", str(r.status_code))
    r = request(B, "DELETE", rec("users", A.user_id))
    res.check("users:delete:other-user", refused(r) and su_get(su, "users", A.user_id).status_code == 200,
              str(r.status_code))

    before = su_count(su, "users", "")
    p = secrets.token_urlsafe(24)
    r = request(ANON, "POST", rec("users"), json={
        "email": f"anon{secrets.token_hex(4)}@pb-test.local", "password": p, "passwordConfirm": p,
    })
    res.check("users:create:anon", r.status_code == 403 and su_count(su, "users", "") == before,
              str(r.status_code))
    r = request(su, "POST", rec("users"), json={
        "email": f"short{secrets.token_hex(4)}@pb-test.local", "password": "1234567", "passwordConfirm": "1234567",
    })
    res.check("users:create:short-password", r.status_code == 400, str(r.status_code))


# ---------------------------------------------------------------- proofs

def batch(actor: Actor, requests: list[dict], retry_429: bool = True) -> httpx.Response:
    return request(actor, "POST", "/api/batch", json={"requests": requests}, retry_429=retry_429)


def post_req(coll: str, body: dict) -> dict:
    return {"method": "POST", "url": rec(coll), "body": body}


def patch_req(coll: str, rid: str, body: dict) -> dict:
    return {"method": "PATCH", "url": rec(coll, rid), "body": body}


def delete_req(coll: str, rid: str) -> dict:
    return {"method": "DELETE", "url": rec(coll, rid)}


def total(actor: Actor, coll: str, flt: str = "") -> int:
    r = request(actor, "GET", rec(coll), params={"filter": flt, "perPage": 1})
    return r.json()["totalItems"]


def proof_p1(a: Owner) -> None:
    A = a.actor
    fail = ProofFailed(10, "P1 failed: batch blocked for a regular user")
    before = total(A, "time_entries")
    entries = [post_req("time_entries", payload("time_entries", A.user_id, a.ctx)) for _ in range(500)]
    r = batch(A, entries, retry_429=False)
    if r.status_code != 200 or total(A, "time_entries") - before != 500:
        raise fail
    start = time.monotonic()
    for _ in range(5):
        pair = [post_req("time_entries", payload("time_entries", A.user_id, a.ctx)) for _ in range(2)]
        if batch(A, pair, retry_429=False).status_code != 200:
            raise fail
    if time.monotonic() - start >= 1.0:
        raise fail


def spent(actor: Actor, coll: str, rid: str) -> int:
    return request(actor, "GET", rec(coll, rid)).json()["spent_minutes"]


async def concurrently(fns: list) -> list:
    return await asyncio.gather(*(asyncio.to_thread(fn) for fn in fns))


def proof_p2(a: Owner, b: Owner) -> None:
    A, B = a.actor, b.actor
    fail = ProofFailed(11, "P2 failed: spent_minutes+ did not add up")
    for coll in ("appointments", "tasks"):
        rid = a.seeds[coll]
        start = spent(A, coll, rid)
        if request(A, "PATCH", rec(coll, rid), json={"spent_minutes+": 5}).status_code != 200:
            raise fail
        if request(A, "PATCH", rec(coll, rid), json={"spent_minutes+": -3}).status_code != 200:
            raise fail
        if spent(A, coll, rid) != start + 2:
            raise fail
    rid = a.seeds["tasks"]
    start = spent(A, "tasks", rid)
    increment = [patch_req("tasks", rid, {"spent_minutes+": 1})]
    results = asyncio.run(concurrently([lambda: batch(A, increment) for _ in range(20)]))
    if any(r.status_code != 200 for r in results) or spent(A, "tasks", rid) != start + 20:
        raise fail
    before = spent(A, "tasks", rid)
    r = request(B, "PATCH", rec("tasks", rid), json={"spent_minutes+": 5})
    if not refused(r) or spent(A, "tasks", rid) != before:
        raise fail


def proof_p3(su: Actor, a: Owner) -> None:
    A = a.actor
    fail = ProofFailed(12, "P3 failed: concurrent delete did not have a single winner")
    for _ in range(5):
        for item in request(A, "GET", rec("active_timers")).json()["items"]:
            request(A, "DELETE", rec("active_timers", item["id"]))
        r = request(A, "POST", rec("active_timers"), json=payload("active_timers", A.user_id, a.ctx))
        rid = must(r, "p3 create")["id"]
        removal = [delete_req("active_timers", rid)]
        results = asyncio.run(concurrently([lambda: batch(A, removal) for _ in range(2)]))
        statuses = sorted(x.status_code for x in results)
        if statuses[0] != 200 or statuses[1] < 400:
            raise fail
        if su_get(su, "active_timers", rid).status_code != 404:
            raise fail


def proof_p4(su: Actor, a: Owner) -> None:
    A = a.actor
    fail = ProofFailed(13, "P4 failed: generation claim batch was not all-or-nothing")
    r = request(A, "POST", rec("recurring_tasks"), json=payload("recurring_tasks", A.user_id, a.ctx))
    rt = must(r, "p4 create model")["id"]

    def claim_batch(day: str, claim_id: str) -> list[dict]:
        return [
            patch_req("recurring_tasks", rt, {"last_generated_on": f"{day} 00:00:00.000Z"}),
            post_req("recurring_task_claims", {"id": claim_id, "user": A.user_id, "recurring_task": rt}),
        ]

    def last_generated() -> str:
        return su_get(su, "recurring_tasks", rt).json()["last_generated_on"]

    if batch(A, claim_batch("2026-10-24", f"{rt}-2026-10-24")).status_code != 200:
        raise fail
    r = batch(A, claim_batch("2026-10-25", f"{rt}-2026-10-24"))
    print(f"P4 INFO: batch error={r.text}")
    if r.status_code < 400 or not last_generated().startswith("2026-10-24"):
        raise fail
    claim_id = f"{rt}-2026-10-26"
    results = asyncio.run(concurrently([
        lambda: batch(A, claim_batch("2026-10-26", claim_id)) for _ in range(2)
    ]))
    codes = sorted(x.status_code for x in results)
    if codes[0] != 200 or codes[1] < 400:
        raise fail
    if su_count(su, "recurring_task_claims", f"id = '{claim_id}'") != 1:
        raise fail


def proof_p5(su: Actor, a: Owner, b: Owner) -> None:
    A, B = a.actor, b.actor
    fail = ProofFailed(14, "P5 failed: parent clear or id restore not accepted")
    child = a.seeds["child"]
    for value in (None, ""):
        request(A, "PATCH", rec("tasks", child), json={"parent": a.seeds["tasks"]})
        r = request(A, "PATCH", rec("tasks", child), json={"parent": value})
        if r.status_code != 200 or r.json()["parent"] != "":
            raise fail
    r = request(B, "PATCH", rec("tasks", b.seeds["tasks"]), json={"parent": a.seeds["tasks"]})
    if not refused(r) or su_get(su, "tasks", b.seeds["tasks"]).json()["parent"] != "":
        raise fail
    for rid in ("Ab3dE5gH7jK9mN1pQ3sT", "abc-2026-10-24"):
        r = request(A, "POST", rec("tasks"), json=payload("tasks", A.user_id, a.ctx, rid))
        if r.status_code != 200 or r.json()["id"] != rid:
            raise fail
        if request(A, "GET", rec("tasks", rid)).json()["id"] != rid:
            raise fail
    r = request(A, "POST", rec("tasks"), json=payload("tasks", A.user_id, a.ctx, "abc-2026-10-24"))
    code = r.json().get("data", {}).get("id", {}).get("code", "") if r.status_code == 400 else ""
    print(f"P5 INFO: duplicate id code={code}")
    print(f"P5 INFO: duplicate id body={r.text}")
    if r.status_code != 400 or not code:
        raise fail
    r = request(A, "POST", rec("tasks"), json=payload("tasks", A.user_id, a.ctx, "has.dot"))
    if r.status_code != 400:
        raise fail


def proof_p6(a: Owner) -> None:
    A = a.actor
    fail = ProofFailed(15, "P6 failed: empty values, dates or range filter differ")
    r = request(A, "POST", rec("appointments"), json={"user": A.user_id, "title": "p6-empty"})
    got = must(r, "p6 empty appointment")
    if (got["list_id"], got["start_minute"], got["is_done"], got["date"]) != ("", 0, False, ""):
        raise fail
    for value in (None, 30):
        body = payload("tasks", A.user_id, a.ctx) | {"estimated_minutes": value}
        r = request(A, "POST", rec("tasks"), json=body)
        if r.status_code != 200 or r.json()["estimated_minutes"] != value:
            raise fail
    body = payload("tasks", A.user_id, a.ctx) | {
        "due_date": "2026-10-24 00:00:00.000Z", "created_at": "2026-10-24 13:45:07.123Z",
    }
    got = must(request(A, "POST", rec("tasks"), json=body), "p6 dates")
    if got["due_date"] != "2026-10-24 00:00:00.000Z" or got["created_at"] != "2026-10-24 13:45:07.123Z":
        raise fail

    stamps = [
        "2026-10-24 02:59:59.999Z", "2026-10-24 03:00:00.000Z",
        "2026-10-25 02:59:59.999Z", "2026-10-25 03:00:00.000Z",
    ]
    for stamp in stamps:
        body = payload("time_entries", A.user_id, a.ctx) | {"target_id": "p6", "occurred_at": stamp}
        must(request(A, "POST", rec("time_entries"), json=body), "p6 entry")
    flt = ("occurred_at >= '2026-10-24 03:00:00.000Z' && occurred_at < '2026-10-25 03:00:00.000Z'"
           " && target_id = 'p6'")
    r = request(A, "GET", rec("time_entries"), params={"filter": flt, "sort": "occurred_at"})
    if r.status_code != 200 or [i["occurred_at"] for i in r.json()["items"]] != stamps[1:3]:
        raise fail

    days = ["2026-10-23", "2026-10-24", "2026-10-25"]
    for day in days:
        body = payload("appointments", A.user_id, a.ctx) | {"title": f"p6-{day}", "date": f"{day} 00:00:00.000Z"}
        must(request(A, "POST", rec("appointments"), json=body), "p6 appointment")
    flt = "date = '2026-10-24 00:00:00.000Z' && title ~ 'p6-'"
    r = request(A, "GET", rec("appointments"), params={"filter": flt})
    if r.status_code != 200 or [i["title"] for i in r.json()["items"]] != ["p6-2026-10-24"]:
        raise fail


def proof_p7(su: Actor, a: Owner, b: Owner) -> None:
    A, B = a.actor, b.actor
    fail = ProofFailed(16, "P7 failed: UNIQUE (user) did not reject a second record")
    for coll in ("active_timers", "day_configs"):
        mine = request(A, "GET", rec(coll)).json()["items"]
        if not mine:
            must(request(A, "POST", rec(coll), json=payload(coll, A.user_id, a.ctx)), f"p7 seed {coll}")
        r = request(A, "POST", rec(coll), json=payload(coll, A.user_id, a.ctx))
        code = r.json().get("data", {}).get("user", {}).get("code") if r.status_code == 400 else None
        if code != "validation_not_unique":
            raise fail
        for item in request(B, "GET", rec(coll)).json()["items"]:
            request(B, "DELETE", rec(coll, item["id"]))
        if request(B, "POST", rec(coll), json=payload(coll, B.user_id, b.ctx)).status_code != 200:
            raise fail

    old = request(A, "GET", rec("active_timers")).json()["items"][0]["id"]
    swap = [delete_req("active_timers", old), post_req("active_timers", payload("active_timers", A.user_id, a.ctx))]
    r = batch(A, swap)
    items = request(A, "GET", rec("active_timers")).json()["items"]
    if r.status_code != 200 or len(items) != 1 or items[0]["id"] == old:
        raise fail
    current = items[0]["id"]
    r = batch(A, [delete_req("active_timers", old), swap[1]])
    items = request(A, "GET", rec("active_timers")).json()["items"]
    if r.status_code < 400 or [i["id"] for i in items] != [current]:
        raise fail


@dataclass
class Subscriber:
    actor: Actor
    topics: list[str]
    events: list[tuple[str, dict]] = field(default_factory=list)
    connected: asyncio.Event = field(default_factory=asyncio.Event)
    client_id: str = ""

    async def read(self, client: httpx.AsyncClient) -> None:
        async with client.stream("GET", BASE + "/api/realtime", timeout=None) as resp:
            name = ""
            async for line in resp.aiter_lines():
                if line.startswith("event:"):
                    name = line[6:].strip()
                elif line.startswith("data:"):
                    data = jsonlib.loads(line[5:].strip() or "{}")
                    if name == "PB_CONNECT":
                        self.client_id = data["clientId"]
                        self.connected.set()
                    else:
                        self.events.append((name, data))

    async def subscribe(self, client: httpx.AsyncClient) -> int:
        headers = {"Authorization": self.actor.token} if self.actor.token else {}
        r = await client.post(
            BASE + "/api/realtime", headers=headers,
            json={"clientId": self.client_id, "subscriptions": self.topics},
        )
        return r.status_code

    def saw(self, rid: str, action: str) -> bool:
        return any(d.get("action") == action and d.get("record", {}).get("id") == rid for _, d in self.events)

    def saw_any(self, rid: str) -> bool:
        return any(d.get("record", {}).get("id") == rid for _, d in self.events)


async def realtime(a: Owner, b: Owner) -> bool:
    A, B = a.actor, b.actor
    fail = ProofFailed(17, "P8 failed: realtime leaked or missed an event")
    foreign = a.seeds["tasks"]
    subs = [
        Subscriber(A, ["tasks"]),
        Subscriber(B, ["tasks", f"tasks/{foreign}"]),
        Subscriber(ANON, ["tasks", f"tasks/{foreign}"]),
    ]
    async with httpx.AsyncClient(timeout=30) as client:
        readers = [asyncio.create_task(s.read(client)) for s in subs]
        try:
            for s in subs:
                await asyncio.wait_for(s.connected.wait(), 10)
                if await s.subscribe(client) != 204:
                    raise fail
            r = await asyncio.to_thread(
                request, A, "POST", rec("tasks"), json=payload("tasks", A.user_id, a.ctx))
            tid = must(r, "p8 create")["id"]
            await asyncio.to_thread(request, A, "PATCH", rec("tasks", tid), json={"title": "renamed"})
            await asyncio.to_thread(request, A, "PATCH", rec("tasks", foreign), json={"title": "renamed"})
            deadline = time.monotonic() + 5
            while time.monotonic() < deadline and not (
                subs[0].saw(tid, "create") and subs[0].saw(tid, "update") and subs[0].saw(foreign, "update")
            ):
                await asyncio.sleep(0.1)
            if not (subs[0].saw(tid, "create") and subs[0].saw(tid, "update")):
                raise fail
            await asyncio.sleep(2)
            if any(s.saw_any(tid) or s.saw_any(foreign) for s in subs[1:]):
                raise fail
        finally:
            for t in readers:
                t.cancel()
            await asyncio.gather(*readers, return_exceptions=True)
    return True


def proof_p8(a: Owner, b: Owner) -> None:
    asyncio.run(realtime(a, b))


# ---------------------------------------------------------------- main

def run(port: int) -> int:
    global BASE, CLIENT
    if port_in_use(port):
        print(f"port {port} is already in use", file=sys.stderr)
        return 2
    tmp = Path(tempfile.mkdtemp(prefix="pb-perm-"))
    data_dir = tmp / "pb_data"
    proc: subprocess.Popen | None = None
    BASE = f"http://127.0.0.1:{port}"
    CLIENT = httpx.Client(timeout=60)
    try:
        try:
            proc = start_server(port, data_dir)
            su_password = secrets.token_urlsafe(24)
            done = subprocess.run(
                ["tool/pb.sh", "superuser", SU_EMAIL], cwd=ROOT, input=su_password + "\n",
                text=True, capture_output=True,
                env={**os.environ, "PB_PORT": str(port), "PB_DATA_DIR": str(data_dir)},
            )
            if done.returncode != 0:
                raise EnvError(f"superuser not created: {done.stderr[-300:]}")
            su = login("_superusers", SU_EMAIL, su_password, "superuser")
            pwd_a, pwd_b = secrets.token_urlsafe(24), secrets.token_urlsafe(24)
            create_user(su, "a@pb-test.local", pwd_a)
            create_user(su, "b@pb-test.local", pwd_b)
            A = login("users", "a@pb-test.local", pwd_a, "A")
            B = login("users", "b@pb-test.local", pwd_b, "B")
            a, b = seed_owner(A), seed_owner(B)
        except EnvError as exc:
            print(f"environment error: {exc}", file=sys.stderr)
            return 2

        failed = check_permissions(su, a, b)
        if failed:
            print(f"{len(failed)} permission line(s) failed", file=sys.stderr)
            return 1

        proofs = [
            ("P1", lambda: proof_p1(a)),
            ("P2", lambda: proof_p2(a, b)),
            ("P3", lambda: proof_p3(su, a)),
            ("P4", lambda: proof_p4(su, a)),
            ("P5", lambda: proof_p5(su, a, b)),
            ("P6", lambda: proof_p6(a)),
            ("P7", lambda: proof_p7(su, a, b)),
            ("P8", lambda: proof_p8(a, b)),
        ]
        for name, fn in proofs:
            try:
                fn()
            except ProofFailed as exc:
                print(exc.message, file=sys.stderr)
                return exc.exit_code
            print(f"PASS {name}")
        print("OK: permissions and P1-P8 passed")
        return 0
    finally:
        if proc is not None:
            stop_server(proc)
        CLIENT.close()
        shutil.rmtree(tmp, ignore_errors=True)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--port", type=int, default=8096)
    return run(parser.parse_args().port)


if __name__ == "__main__":
    sys.exit(main())
