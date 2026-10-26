#!/usr/bin/env -S uv run
# /// script
# requires-python = ">=3.12"
# dependencies = ["firebase-admin", "httpx"]
# ///
"""Tests for copy_firestore_to_pocketbase (no Firebase, no real server)."""

from __future__ import annotations

import json
import os
import sys
import tempfile
import unittest
from datetime import UTC, datetime
from pathlib import Path
from unittest import mock
from urllib.parse import parse_qs, urlparse
from zoneinfo import ZoneInfo

import httpx

sys.path.insert(0, str(Path(__file__).resolve().parent))

import copy_firestore_to_pocketbase as cp  # noqa: E402
from copy_firestore_to_pocketbase import ExitCode, PbCollection, SourceDoc  # noqa: E402

SP = ZoneInfo("America/Sao_Paulo")
PB_URL = "http://127.0.0.1:8095"
PB_USER = "pbuser0000001"


def utc(*args: int) -> datetime:
    return datetime(*args, tzinfo=UTC)


def doc(doc_id: str, **data: object) -> SourceDoc:
    return SourceDoc(doc_id, data)


def coherent_source() -> dict[PbCollection, list[SourceDoc]]:
    return {
        PbCollection.TASK_LISTS: [doc("L1", name="Casa", isDefault=True)],
        PbCollection.TASKS: [
            doc("T2", title="Filha", listId="L1", parentId="T1", hasChildren=False),
            doc("T1", title="Mãe", listId="L1", hasChildren=True, spentMinutes=5,
                dueDate=utc(2026, 10, 24, 3)),
        ],
        PbCollection.APPOINTMENTS: [doc("A1", title="Dentista", listId="L1", spentMinutes=7)],
        PbCollection.RECURRING_TASKS: [doc("R1", title="Ler", listId="L1",
                                           lastGeneratedOn=utc(2026, 10, 24, 3))],
        PbCollection.TIME_ENTRIES: [doc("E1", targetId="T1", minutes=12,
                                        occurredAt=utc(2026, 10, 24, 15))],
        PbCollection.DAY_CONFIGS: [doc("settings", onboarded=True)],
        PbCollection.ACTIVE_TIMERS: [],
    }


def fatal(problems: list[cp.Problem]) -> list[cp.Problem]:
    return [p for p in problems if p.fatal]


class FormatTest(unittest.TestCase):
    def test_instant_truncates_milliseconds(self) -> None:
        self.assertEqual(cp.format_instant(utc(2026, 10, 24, 15, 4, 5, 678901)), "2026-10-24 15:04:05.678Z")

    def test_instant_converts_to_utc(self) -> None:
        local = utc(2026, 10, 24, 15, 4, 5).astimezone(SP)
        self.assertEqual(cp.format_instant(local), "2026-10-24 15:04:05.000Z")

    def test_naive_datetime_rejected(self) -> None:
        with self.assertRaises(ValueError):
            cp.format_instant(datetime(2026, 1, 1))
        with self.assertRaises(ValueError):
            cp.format_day(datetime(2026, 1, 1))

    def test_day_midnight_in_brasilia(self) -> None:
        self.assertEqual(cp.format_day(utc(2026, 10, 24, 3)), "2026-10-24 00:00:00.000Z")

    def test_day_before_midnight_in_brasilia(self) -> None:
        self.assertEqual(cp.format_day(utc(2026, 10, 24, 2, 59)), "2026-10-23 00:00:00.000Z")

    def test_day_year_boundary(self) -> None:
        self.assertEqual(cp.format_day(utc(2027, 1, 1, 3)), "2027-01-01 00:00:00.000Z")
        self.assertEqual(cp.format_day(utc(2026, 12, 31, 3)), "2026-12-31 00:00:00.000Z")


class IdTest(unittest.TestCase):
    def test_valid_ids(self) -> None:
        for raw in ("aB3dE5fG7hI9jK1lM2nO", "abc-2026-10-24", "a_b", "a" * 64):
            self.assertTrue(cp.is_valid_id(raw), raw)

    def test_invalid_ids(self) -> None:
        for raw in ("", "a" * 65, "a/b", "a.b", "a b"):
            self.assertFalse(cp.is_valid_id(raw), raw)

    def test_singleton_id(self) -> None:
        self.assertEqual(cp.singleton_id(PbCollection.DAY_CONFIGS, "u1"), "cfg-u1")
        self.assertEqual(cp.singleton_id(PbCollection.ACTIVE_TIMERS, "u1"), "tmr-u1")
        with self.assertRaises(ValueError):
            cp.singleton_id(PbCollection.TASKS, "u1")


class MapDocumentTest(unittest.TestCase):
    def test_full_task(self) -> None:
        body, unknown = cp.map_document(
            PbCollection.TASKS,
            doc("T1", title="Relatório", listId="L1", parentId="T0",
                createdAt=utc(2026, 10, 20, 12, 0, 0, 999000), estimatedMinutes=30,
                dueDate=utc(2026, 10, 24, 3), importance="high", isDone=True,
                hasChildren=False, spentMinutes=4, recurringTaskId="R1"),
            PB_USER,
        )
        self.assertEqual(body, {
            "id": "T1", "user": PB_USER, "title": "Relatório", "list": "L1", "parent": "T0",
            "created_at": "2026-10-20 12:00:00.999Z", "estimated_minutes": 30,
            "due_date": "2026-10-24 00:00:00.000Z", "importance": "high", "is_done": True,
            "has_children": False, "spent_minutes": 4, "recurring_task_id": "R1",
        })
        self.assertEqual(unknown, [])

    def test_minimal_task_gets_empty_values(self) -> None:
        body, _ = cp.map_document(PbCollection.TASKS, doc("T1", title="x", listId="L1"), PB_USER)
        self.assertEqual(body["parent"], "")
        self.assertEqual(body["created_at"], "")
        self.assertEqual(body["due_date"], "")
        self.assertIs(body["is_done"], False)
        self.assertEqual(body["spent_minutes"], 0)
        self.assertIsNone(body["estimated_minutes"])
        self.assertEqual(body["importance"], "")

    def test_appointment_list_id_stays_text_field(self) -> None:
        body, _ = cp.map_document(PbCollection.APPOINTMENTS, doc("A1", listId="L1"), PB_USER)
        self.assertEqual(body["list_id"], "L1")
        self.assertNotIn("list", body)

    def test_settings_uses_singleton_id(self) -> None:
        body, _ = cp.map_document(PbCollection.DAY_CONFIGS, doc("settings", availableMinutesPerDay=300), PB_USER)
        self.assertEqual(body["id"], f"cfg-{PB_USER}")
        self.assertEqual(body["available_minutes_per_day"], 300)

    def test_settings_default_minutes(self) -> None:
        body, _ = cp.map_document(PbCollection.DAY_CONFIGS, doc("settings", onboarded=True), PB_USER)
        self.assertEqual(body["available_minutes_per_day"], 480)
        self.assertIs(body["onboarded"], True)

    def test_unknown_keys(self) -> None:
        _, unknown = cp.map_document(PbCollection.TASK_LISTS, doc("L1", name="x", foo=1, id="L1"), PB_USER)
        self.assertEqual(unknown, ["foo"])


class OrderingTest(unittest.TestCase):
    def test_parents_first(self) -> None:
        tasks = [
            {"id": "C", "parent": "B"}, {"id": "B", "parent": "A"}, {"id": "A", "parent": ""},
            {"id": "O", "parent": "missing"}, {"id": "B2", "parent": "A"},
        ]
        ordered = [t["id"] for t in cp.order_parents_first(tasks)]
        for child, parent in (("C", "B"), ("B", "A"), ("B2", "A")):
            self.assertLess(ordered.index(parent), ordered.index(child))
        self.assertLess(ordered.index("O"), ordered.index("C"))
        self.assertEqual(len(ordered), 5)

    def test_cycle(self) -> None:
        with self.assertRaises(ValueError):
            cp.order_parents_first([{"id": "A", "parent": "B"}, {"id": "B", "parent": "A"}])

    def test_chunked(self) -> None:
        self.assertEqual(cp.chunked([]), [])
        self.assertEqual([len(c) for c in cp.chunked(list(range(50)))], [50])
        self.assertEqual([len(c) for c in cp.chunked(list(range(101)))], [50, 50, 1])
        with self.assertRaises(ValueError):
            cp.chunked([1], size=0)


class ValidateSourceTest(unittest.TestCase):
    def _with(self, collection: PbCollection, *docs: SourceDoc) -> dict[PbCollection, list[SourceDoc]]:
        source = coherent_source()
        source[collection] = list(docs)
        return source

    def test_coherent_data_has_no_fatal(self) -> None:
        self.assertEqual(fatal(cp.validate_source(coherent_source())), [])

    def test_invalid_id(self) -> None:
        source = self._with(PbCollection.TASK_LISTS, doc("a/b", name="x"))
        self.assertTrue(fatal(cp.validate_source(source)))

    def test_task_with_missing_list(self) -> None:
        source = self._with(PbCollection.TASKS, doc("T1", title="x", listId="nope"))
        self.assertTrue(fatal(cp.validate_source(source)))

    def test_template_without_list_id(self) -> None:
        source = self._with(PbCollection.RECURRING_TASKS, doc("R1", title="x"))
        self.assertTrue(fatal(cp.validate_source(source)))

    def test_missing_parent(self) -> None:
        source = self._with(PbCollection.TASKS, doc("T1", title="x", listId="L1", parentId="nope"))
        self.assertTrue(fatal(cp.validate_source(source)))

    def test_parent_cycle(self) -> None:
        source = self._with(
            PbCollection.TASKS,
            doc("A", title="a", listId="L1", parentId="B", hasChildren=True),
            doc("B", title="b", listId="L1", parentId="A", hasChildren=True),
        )
        self.assertTrue(fatal(cp.validate_source(source)))

    def test_has_children_without_child(self) -> None:
        source = self._with(PbCollection.TASKS, doc("T1", title="x", listId="L1", hasChildren=True))
        self.assertTrue(fatal(cp.validate_source(source)))

    def test_child_without_has_children(self) -> None:
        source = self._with(
            PbCollection.TASKS,
            doc("T1", title="x", listId="L1"),
            doc("T2", title="y", listId="L1", parentId="T1"),
        )
        self.assertTrue(fatal(cp.validate_source(source)))

    def test_text_date(self) -> None:
        source = self._with(PbCollection.TASKS, doc("T1", title="x", listId="L1", dueDate="2026-10-24"))
        self.assertTrue(fatal(cp.validate_source(source)))

    def test_empty_title(self) -> None:
        source = self._with(PbCollection.TASKS, doc("T1", title="", listId="L1"))
        self.assertTrue(fatal(cp.validate_source(source)))

    def test_only_warnings(self) -> None:
        source = self._with(
            PbCollection.APPOINTMENTS,
            doc("A1", title="x", listId="nope", foo=1),
            doc("A2", title="y", date=utc(2026, 10, 24, 6)),
        )
        problems = cp.validate_source(source)
        self.assertEqual(fatal(problems), [])
        messages = " ".join(p.message for p in problems)
        self.assertIn("lista inexistente", messages)
        self.assertIn("'foo'", messages)
        self.assertIn("A2", messages)


class SummarizeVerifyTest(unittest.TestCase):
    def _expected(self) -> dict[PbCollection, list[dict[str, object]]]:
        return {
            PbCollection.TASKS: [
                {"id": "T1", "parent": "", "has_children": True, "spent_minutes": 5},
                {"id": "T2", "parent": "T1", "has_children": False, "spent_minutes": 0},
            ],
            PbCollection.TIME_ENTRIES: [{"id": "E1", "minutes": 12}],
        }

    def test_equal(self) -> None:
        self.assertEqual(cp.verify(self._expected(), self._expected()), [])

    def test_extra_record(self) -> None:
        actual = self._expected()
        actual[PbCollection.TIME_ENTRIES].append({"id": "E2", "minutes": 0})
        self.assertEqual(len([i for i in cp.verify(self._expected(), actual) if "time_entries" in i]), 2)

    def test_spent_minutes_differs(self) -> None:
        actual = self._expected()
        actual[PbCollection.TASKS][0]["spent_minutes"] = 6
        self.assertEqual(len(cp.verify(self._expected(), actual)), 1)

    def test_has_children_without_child(self) -> None:
        actual = self._expected()
        actual[PbCollection.TASKS][1]["has_children"] = True
        self.assertEqual(len(cp.verify(self._expected(), actual)), 1)

    def test_summarize_recurring(self) -> None:
        records = [{"last_generated_on": "2026-10-24 00:00:00.000Z"}, {"last_generated_on": ""}]
        self.assertEqual(cp.summarize(PbCollection.RECURRING_TASKS, records),
                         {"count": 2, "with_last_generated_on": 1})


class LoadEnvFileTest(unittest.TestCase):
    def _make(self, directory: Path, file_mode: int, dir_mode: int = 0o700) -> Path:
        directory.chmod(dir_mode)
        path = directory / "migration.env"
        path.write_text('# comment\n\nTEST_COPY_A="one"\nTEST_COPY_B=two\n')
        path.chmod(file_mode)
        return path

    def test_reads_values(self) -> None:
        with tempfile.TemporaryDirectory() as tmp, mock.patch.dict(os.environ, clear=False):
            os.environ.pop("TEST_COPY_A", None)
            os.environ.pop("TEST_COPY_B", None)
            cp.load_env_file(self._make(Path(tmp), 0o600))
            self.assertEqual(os.environ["TEST_COPY_A"], "one")
            self.assertEqual(os.environ["TEST_COPY_B"], "two")

    def test_rejects_open_permissions(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            with self.assertRaises(RuntimeError):
                cp.load_env_file(self._make(Path(tmp), 0o644))

    def test_rejects_open_directory(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            with self.assertRaises(RuntimeError):
                cp.load_env_file(self._make(Path(tmp), 0o600, dir_mode=0o755))

    def test_keeps_existing_variable(self) -> None:
        with tempfile.TemporaryDirectory() as tmp, mock.patch.dict(os.environ, {"TEST_COPY_A": "kept"}):
            cp.load_env_file(self._make(Path(tmp), 0o600))
            self.assertEqual(os.environ["TEST_COPY_A"], "kept")

    def test_missing_file_is_ignored(self) -> None:
        cp.load_env_file(Path("/nonexistent-dir/migration.env"))


class FakeServer:
    """In-memory PocketBase: records every request and serves back what it received."""

    def __init__(self, users: dict[str, str] | None = None, drop_last: bool = False) -> None:
        self.users = users if users is not None else {"a@x.com": PB_USER}
        self.drop_last = drop_last
        self.batches: list[dict[str, object]] = []
        self.stored: dict[str, list[dict[str, object]]] = {}
        self.list_queries: list[dict[str, list[str]]] = []

    def handler(self, request: httpx.Request) -> httpx.Response:
        url = urlparse(str(request.url))
        query = parse_qs(url.query)
        if url.path.endswith("/auth-with-password"):
            return httpx.Response(200, json={"token": "t"})
        if url.path == "/api/collections/users/records":
            email = query["filter"][0].split("'")[1]
            found = self.users.get(email)
            return httpx.Response(200, json={"items": [{"id": found}] if found else []})
        if url.path == "/api/batch":
            payload = json.loads(request.content)
            self.batches.append(payload)
            for item in payload["requests"]:
                name = item["url"].split("/")[3]
                self.stored.setdefault(name, []).append(item["body"])
            return httpx.Response(200, json=[{"status": 200} for _ in payload["requests"]])
        name = url.path.split("/")[3]
        self.list_queries.append(query)
        items = list(self.stored.get(name, []))
        if self.drop_last and items:
            items = items[:-1]
        return httpx.Response(200, json={"items": items, "page": 1, "totalPages": 1})

    def batch_collections(self) -> list[str]:
        return [r["url"].split("/")[3] for b in self.batches for r in b["requests"]]  # type: ignore[index]


class MemorySource:
    project_id = "meu-tempo-dev"

    def __init__(self, data: dict[PbCollection, list[SourceDoc]]) -> None:
        self._data = data

    def read_user(self, uid: str) -> dict[PbCollection, list[SourceDoc]]:
        return self._data

    def list_user_ids(self) -> list[str]:
        return ["u1"]


class AdminTest(unittest.TestCase):
    def _admin(self, handler: object) -> cp.PocketBaseAdmin:
        return cp.PocketBaseAdmin(PB_URL, httpx.Client(transport=httpx.MockTransport(handler)))  # type: ignore[arg-type]

    def test_upsert_batches_of_50(self) -> None:
        server = FakeServer()
        bodies = [{"id": f"id{i}", "user": PB_USER} for i in range(101)]
        self._admin(server.handler).upsert(PbCollection.TASK_LISTS, bodies)
        self.assertEqual([len(b["requests"]) for b in server.batches], [50, 50, 1])  # type: ignore[arg-type]
        for batch in server.batches:
            for item in batch["requests"]:  # type: ignore[attr-defined]
                self.assertEqual(item["method"], "PUT")
                self.assertEqual(item["url"], "/api/collections/task_lists/records")
                self.assertIn("id", item["body"])

    def test_upsert_empty_sends_nothing(self) -> None:
        server = FakeServer()
        self._admin(server.handler).upsert(PbCollection.TASKS, [])
        self.assertEqual(server.batches, [])

    def test_upsert_error_hides_body(self) -> None:
        def handler(request: httpx.Request) -> httpx.Response:
            return httpx.Response(400, json={"status": 400, "data": {"requests": {"0": {"code": "batch_request_failed",
                "response": {"data": {"title": {"code": "validation_required"}}}}}}})

        with self.assertRaises(cp.PocketBaseError) as ctx:
            self._admin(handler).upsert(PbCollection.TASKS, [{"id": "T1", "title": "segredo"}])
        self.assertEqual(ctx.exception.code, "validation_required")
        self.assertEqual(ctx.exception.status, 400)
        self.assertNotIn("segredo", str(ctx.exception))
        self.assertIn("T1", str(ctx.exception))

    def test_list_records_two_pages(self) -> None:
        queries: list[dict[str, list[str]]] = []

        def handler(request: httpx.Request) -> httpx.Response:
            query = parse_qs(urlparse(str(request.url)).query)
            queries.append(query)
            page = int(query["page"][0])
            return httpx.Response(200, json={"items": [{"id": f"r{page}"}], "totalPages": 2})

        records = self._admin(handler).list_records(PbCollection.TASKS, PB_USER)
        self.assertEqual([r["id"] for r in records], ["r1", "r2"])
        self.assertTrue(all(q["perPage"] == ["500"] for q in queries))

    def test_find_user_id(self) -> None:
        admin = self._admin(FakeServer(users={}).handler)
        self.assertIsNone(admin.find_user_id("nobody@x.com"))
        with self.assertRaises(ValueError):
            admin.find_user_id("a'b@x.com")


class RunTest(unittest.TestCase):
    def setUp(self) -> None:
        patcher = mock.patch.dict(os.environ, {
            "PB_SUPERUSER_EMAIL": "root@x.com", "PB_SUPERUSER_PASSWORD": "pw",
        })
        patcher.start()
        self.addCleanup(patcher.stop)

    def _run(self, server: FakeServer, data: dict[PbCollection, list[SourceDoc]], *extra: str) -> ExitCode:
        args = cp.parse_args(["--pb-url", PB_URL, "--user-map", "u1=a@x.com", *extra])
        pb = cp.PocketBaseAdmin(PB_URL, httpx.Client(transport=httpx.MockTransport(server.handler)))
        return cp.run(args, MemorySource(data), pb)

    def test_unknown_email(self) -> None:
        server = FakeServer(users={})
        self.assertEqual(self._run(server, coherent_source()), ExitCode.VALIDATION_FAILED)
        self.assertEqual(server.batches, [])

    def test_fatal_validation(self) -> None:
        data = coherent_source()
        data[PbCollection.TASKS] = [doc("T1", title="x", listId="nope")]
        server = FakeServer()
        self.assertEqual(self._run(server, data), ExitCode.VALIDATION_FAILED)
        self.assertEqual(server.batches, [])

    def test_dry_run(self) -> None:
        server = FakeServer()
        self.assertEqual(self._run(server, coherent_source(), "--dry-run"), ExitCode.OK)
        self.assertEqual(server.batches, [])

    def test_copy_writes_parents_first_and_verifies(self) -> None:
        server = FakeServer()
        self.assertEqual(self._run(server, coherent_source()), ExitCode.OK)
        order = server.batch_collections()
        self.assertLess(order.index("task_lists"), order.index("tasks"))
        tasks = [b["id"] for b in server.stored["tasks"]]
        self.assertLess(tasks.index("T1"), tasks.index("T2"))
        self.assertEqual(server.stored["day_configs"][0]["id"], f"cfg-{PB_USER}")

    def test_verify_failure(self) -> None:
        self.assertEqual(self._run(FakeServer(drop_last=True), coherent_source()), ExitCode.VERIFY_FAILED)

    def test_only_tasks(self) -> None:
        server = FakeServer()
        self.assertEqual(self._run(server, coherent_source(), "--only", "tasks"), ExitCode.OK)
        self.assertEqual(set(server.batch_collections()), {"tasks"})

    def test_other_firebase_project(self) -> None:
        source = MemorySource(coherent_source())
        source.project_id = "outro"
        args = cp.parse_args(["--pb-url", PB_URL, "--user-map", "u1=a@x.com"])
        pb = cp.PocketBaseAdmin(PB_URL, httpx.Client(transport=httpx.MockTransport(FakeServer().handler)))
        self.assertEqual(cp.run(args, source, pb), ExitCode.RUNTIME_ERROR)


class ParseArgsTest(unittest.TestCase):
    def _exit_code(self, *argv: str) -> object:
        with mock.patch("sys.stderr"), self.assertRaises(SystemExit) as ctx:
            cp.parse_args(list(argv))
        return ctx.exception.code

    def test_http_remote_host(self) -> None:
        self.assertEqual(self._exit_code("--pb-url", "http://exemplo.com", "--user-map", "u1=a@x.com"), 2)

    def test_malformed_user_map(self) -> None:
        self.assertEqual(self._exit_code("--pb-url", PB_URL, "--user-map", "u1"), 2)

    def test_repeated_uid(self) -> None:
        self.assertEqual(
            self._exit_code("--pb-url", PB_URL, "--user-map", "u1=a@x.com", "--user-map", "u1=b@x.com"), 2)

    def test_valid(self) -> None:
        args = cp.parse_args(["--pb-url", "https://pb.example.com", "--user-map", "u1=a@x.com",
                              "--only", "tasks", "--dry-run"])
        self.assertEqual(args.user_map, {"u1": "a@x.com"})
        self.assertEqual(args.only, [PbCollection.TASKS])
        self.assertTrue(args.dry_run)


if __name__ == "__main__":
    unittest.main()
