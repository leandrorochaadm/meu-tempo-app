#!/usr/bin/env -S uv run
# /// script
# requires-python = ">=3.12"
# dependencies = ["firebase-admin", "httpx"]
# ///
"""Copy the Firestore data of Meu Tempo (users/{uid}/...) into PocketBase.

Read-only on Firestore. Ids are kept; every record is upserted through
POST /api/batch (PUT .../records with the id in the body), so running it
again overwrites everything. Order: validate -> write -> verify.

Usage:
    uv run tool/migration/copy_firestore_to_pocketbase.py \\
        --pb-url https://example.com --user-map <uid>=<email> [--dry-run] [--only tasks]

Environment (also read from ~/.config/meu-tempo/migration.env):
    GOOGLE_APPLICATION_CREDENTIALS, PB_SUPERUSER_EMAIL, PB_SUPERUSER_PASSWORD

Exit codes:
    0 ok; 1 verification diverged; 2 validation refused (nothing written) or
    invalid argument; 3 runtime error (missing credential, server down, batch refused).
"""

from __future__ import annotations

import argparse
import os
import re
import sys
from collections.abc import Mapping, Sequence
from dataclasses import dataclass
from datetime import UTC, datetime
from enum import Enum, IntEnum, StrEnum, auto
from pathlib import Path
from typing import Any, Protocol
from zoneinfo import ZoneInfo

import httpx


class PbCollection(StrEnum):
    TASK_LISTS = "task_lists"
    TASKS = "tasks"
    APPOINTMENTS = "appointments"
    RECURRING_TASKS = "recurring_tasks"
    TIME_ENTRIES = "time_entries"
    DAY_CONFIGS = "day_configs"
    ACTIVE_TIMERS = "active_timers"


class FieldKind(Enum):
    TEXT = auto()
    BOOL = auto()
    NUMBER = auto()
    JSON = auto()
    RELATION = auto()
    INSTANT = auto()
    DAY = auto()

    @property
    def empty(self) -> Any:
        match self:
            case FieldKind.BOOL:
                return False
            case FieldKind.NUMBER:
                return 0
            case FieldKind.JSON:
                return None
            case _:
                return ""


class ExitCode(IntEnum):
    OK = 0
    VERIFY_FAILED = 1
    VALIDATION_FAILED = 2
    RUNTIME_ERROR = 3


class EnvVar(StrEnum):
    CREDENTIALS = "GOOGLE_APPLICATION_CREDENTIALS"
    SUPERUSER_EMAIL = "PB_SUPERUSER_EMAIL"
    SUPERUSER_PASSWORD = "PB_SUPERUSER_PASSWORD"


@dataclass(frozen=True)
class FieldSpec:
    target: str
    kind: FieldKind
    # App default used instead of the empty value when the source lacks the field.
    default: Any | None = None


@dataclass(frozen=True)
class SourceDoc:
    id: str
    data: Mapping[str, Any]


@dataclass(frozen=True)
class Problem:
    collection: PbCollection
    doc_id: str
    message: str
    fatal: bool


def _f(target: str, kind: FieldKind, default: Any | None = None) -> FieldSpec:
    return FieldSpec(target, kind, default)


FIELD_MAP: Mapping[PbCollection, Mapping[str, FieldSpec]] = {
    PbCollection.TASK_LISTS: {
        "name": _f("name", FieldKind.TEXT),
        "isDefault": _f("is_default", FieldKind.BOOL),
    },
    PbCollection.TASKS: {
        "title": _f("title", FieldKind.TEXT),
        "listId": _f("list", FieldKind.RELATION),
        "parentId": _f("parent", FieldKind.RELATION),
        "createdAt": _f("created_at", FieldKind.INSTANT),
        "estimatedMinutes": _f("estimated_minutes", FieldKind.JSON),
        "dueDate": _f("due_date", FieldKind.DAY),
        "importance": _f("importance", FieldKind.TEXT),
        "isDone": _f("is_done", FieldKind.BOOL),
        "hasChildren": _f("has_children", FieldKind.BOOL),
        "spentMinutes": _f("spent_minutes", FieldKind.NUMBER),
        "recurringTaskId": _f("recurring_task_id", FieldKind.TEXT),
    },
    PbCollection.APPOINTMENTS: {
        "title": _f("title", FieldKind.TEXT),
        "listId": _f("list_id", FieldKind.TEXT),
        "date": _f("date", FieldKind.DAY),
        "startMinute": _f("start_minute", FieldKind.NUMBER),
        "durationMinutes": _f("duration_minutes", FieldKind.NUMBER),
        "spentMinutes": _f("spent_minutes", FieldKind.NUMBER),
        "isDone": _f("is_done", FieldKind.BOOL),
    },
    PbCollection.TIME_ENTRIES: {
        "targetId": _f("target_id", FieldKind.TEXT),
        "targetType": _f("target_type", FieldKind.TEXT),
        "listId": _f("list_id", FieldKind.TEXT),
        "origin": _f("origin", FieldKind.TEXT),
        "minutes": _f("minutes", FieldKind.NUMBER),
        "occurredAt": _f("occurred_at", FieldKind.INSTANT),
    },
    PbCollection.RECURRING_TASKS: {
        "title": _f("title", FieldKind.TEXT),
        "listId": _f("list", FieldKind.RELATION),
        "estimatedMinutes": _f("estimated_minutes", FieldKind.NUMBER),
        "importance": _f("importance", FieldKind.TEXT),
        "weekdays": _f("weekdays", FieldKind.JSON),
        "createdAt": _f("created_at", FieldKind.INSTANT),
        "lastGeneratedOn": _f("last_generated_on", FieldKind.DAY),
    },
    PbCollection.DAY_CONFIGS: {
        "availableMinutesPerDay": _f("available_minutes_per_day", FieldKind.NUMBER, 480),
        "onboarded": _f("onboarded", FieldKind.BOOL),
    },
    PbCollection.ACTIVE_TIMERS: {
        "targetId": _f("target_id", FieldKind.TEXT),
        "targetType": _f("target_type", FieldKind.TEXT),
        "listId": _f("list_id", FieldKind.TEXT),
        "status": _f("status", FieldKind.TEXT),
        "startedAt": _f("started_at", FieldKind.INSTANT),
    },
}

SOURCE_PATHS: Mapping[PbCollection, str] = {
    PbCollection.TASK_LISTS: "lists",
    PbCollection.TASKS: "tasks",
    PbCollection.APPOINTMENTS: "appointments",
    PbCollection.TIME_ENTRIES: "timeEntries",
    PbCollection.RECURRING_TASKS: "recurringTasks",
    PbCollection.DAY_CONFIGS: "config/settings",
    PbCollection.ACTIVE_TIMERS: "config/activeTimer",
}

COPY_ORDER: tuple[PbCollection, ...] = (
    PbCollection.TASK_LISTS,
    PbCollection.TASKS,
    PbCollection.APPOINTMENTS,
    PbCollection.RECURRING_TASKS,
    PbCollection.TIME_ENTRIES,
    PbCollection.DAY_CONFIGS,
    PbCollection.ACTIVE_TIMERS,
)

SINGLETON_PREFIX: Mapping[PbCollection, str] = {
    PbCollection.DAY_CONFIGS: "cfg-",
    PbCollection.ACTIVE_TIMERS: "tmr-",
}

BATCH_SIZE = 50
PAGE_SIZE = 500
SOURCE_TIMEZONE = ZoneInfo("America/Sao_Paulo")
EXPECTED_FIREBASE_PROJECT = "meu-tempo-dev"
ENV_FILE = Path.home() / ".config/meu-tempo/migration.env"
ID_PATTERN = re.compile(r"^[A-Za-z0-9_-]{1,64}$")
PB_USER_ID_PLACEHOLDER = "x" * 15
MAX_LISTED_IDS = 10
DAY_EXAMPLES = 3
LOCAL_ONLY_HOSTS = ("127.0.0.1", "localhost")


# ---------------------------------------------------------------- pure functions


def format_instant(value: datetime) -> str:
    if value.tzinfo is None:
        raise ValueError("datetime sem fuso")
    utc = value.astimezone(UTC)
    return f"{utc:%Y-%m-%d %H:%M:%S}.{utc.microsecond // 1000:03d}Z"


def format_day(value: datetime) -> str:
    if value.tzinfo is None:
        raise ValueError("datetime sem fuso")
    local = value.astimezone(SOURCE_TIMEZONE)
    return f"{local.year:04d}-{local.month:02d}-{local.day:02d} 00:00:00.000Z"


def is_valid_id(raw: str) -> bool:
    return ID_PATTERN.fullmatch(raw) is not None


def singleton_id(collection: PbCollection, user_id: str) -> str:
    prefix = SINGLETON_PREFIX.get(collection)
    if prefix is None:
        raise ValueError(f"{collection} não é coleção de documento fixo")
    return f"{prefix}{user_id}"


def unknown_keys(collection: PbCollection, data: Mapping[str, Any]) -> list[str]:
    known = FIELD_MAP[collection]
    return sorted(key for key in data if key != "id" and key not in known)


def _convert(spec: FieldSpec, value: Any) -> Any:
    if value is None:
        return spec.default if spec.default is not None else spec.kind.empty
    match spec.kind:
        case FieldKind.INSTANT:
            return format_instant(value)
        case FieldKind.DAY:
            return format_day(value)
        case _:
            return value


def map_document(
    collection: PbCollection, doc: SourceDoc, user_id: str
) -> tuple[dict[str, Any], list[str]]:
    record_id = singleton_id(collection, user_id) if collection in SINGLETON_PREFIX else doc.id
    body: dict[str, Any] = {"id": record_id, "user": user_id}
    for source_key, spec in FIELD_MAP[collection].items():
        body[spec.target] = _convert(spec, doc.data.get(source_key))
    return body, unknown_keys(collection, doc.data)


def order_parents_first(tasks: list[dict[str, Any]]) -> list[dict[str, Any]]:
    ids = {task["id"] for task in tasks}
    placed: set[str] = set()
    ordered: list[dict[str, Any]] = []
    pending = list(tasks)
    while pending:
        still_pending: list[dict[str, Any]] = []
        for task in pending:
            parent = task.get("parent") or ""
            if parent == "" or parent not in ids or parent in placed:
                ordered.append(task)
                placed.add(task["id"])
            else:
                still_pending.append(task)
        if len(still_pending) == len(pending):
            raise ValueError("Ciclo de tarefas mãe: " + ", ".join(t["id"] for t in still_pending))
        pending = still_pending
    return ordered


def chunked[T](items: Sequence[T], size: int = BATCH_SIZE) -> list[list[T]]:
    if size <= 0:
        raise ValueError("size deve ser positivo")
    return [list(items[i : i + size]) for i in range(0, len(items), size)]


def _is_aware_datetime(value: Any) -> bool:
    return isinstance(value, datetime) and value.tzinfo is not None


def _listed(ids: Sequence[str]) -> str:
    shown = ", ".join(ids[:MAX_LISTED_IDS])
    return shown + (f" (+{len(ids) - MAX_LISTED_IDS})" if len(ids) > MAX_LISTED_IDS else "")


def validate_source(source: Mapping[PbCollection, Sequence[SourceDoc]]) -> list[Problem]:
    """Validates the data of ONE user (references never cross users)."""
    problems: list[Problem] = []

    def add(collection: PbCollection, doc_id: str, message: str, fatal: bool) -> None:
        problems.append(Problem(collection, doc_id, message, fatal))

    list_ids = {d.id for d in source.get(PbCollection.TASK_LISTS, [])}
    tasks = list(source.get(PbCollection.TASKS, []))
    task_ids = {d.id for d in tasks}

    for collection, docs in source.items():
        for doc in docs:
            checked_id = (
                singleton_id(collection, PB_USER_ID_PLACEHOLDER)
                if collection in SINGLETON_PREFIX
                else doc.id
            )
            if not is_valid_id(checked_id):
                add(collection, doc.id, "id fora do padrão aceito pelo PocketBase", True)
        counts: dict[str, int] = {}
        for doc in docs:
            for key in unknown_keys(collection, doc.data):
                counts[key] = counts.get(key, 0) + 1
        for key, count in sorted(counts.items()):
            add(collection, "*", f"chave '{key}' fora do mapa em {count} documento(s); será descartada", False)

        for source_key, spec in FIELD_MAP[collection].items():
            if spec.kind not in (FieldKind.INSTANT, FieldKind.DAY):
                continue
            off_hours: list[str] = []
            for doc in docs:
                value = doc.data.get(source_key)
                if value is None:
                    continue
                if not _is_aware_datetime(value):
                    add(collection, doc.id, f"'{source_key}' não é data com fuso", True)
                elif spec.kind is FieldKind.DAY:
                    local = value.astimezone(SOURCE_TIMEZONE)
                    if (local.hour, local.minute, local.second, local.microsecond) != (0, 0, 0, 0):
                        off_hours.append(doc.id)
            if off_hours:
                add(
                    collection,
                    "*",
                    f"'{source_key}' fora da meia-noite de Brasília em {len(off_hours)} "
                    f"documento(s): {_listed(off_hours)}",
                    False,
                )

    for doc in tasks:
        if not doc.data.get("title"):
            add(PbCollection.TASKS, doc.id, "'title' ausente ou vazio", True)
    for collection in (PbCollection.TASKS, PbCollection.RECURRING_TASKS):
        for doc in source.get(collection, []):
            list_id = doc.data.get("listId")
            if not list_id:
                add(collection, doc.id, "'listId' ausente", True)
            elif list_id not in list_ids:
                add(collection, doc.id, "lista inexistente", True)
    for doc in source.get(PbCollection.APPOINTMENTS, []):
        list_id = doc.data.get("listId")
        if list_id and list_id not in list_ids:
            add(PbCollection.APPOINTMENTS, doc.id, "'listId' aponta para lista inexistente", False)

    parents: set[str] = set()
    for doc in tasks:
        parent = doc.data.get("parentId")
        if parent:
            parents.add(parent)
            if parent not in task_ids:
                add(PbCollection.TASKS, doc.id, "tarefa mãe inexistente", True)
    try:
        order_parents_first([{"id": d.id, "parent": d.data.get("parentId") or ""} for d in tasks])
    except ValueError as error:
        add(PbCollection.TASKS, "*", str(error), True)
    for doc in tasks:
        has_children = bool(doc.data.get("hasChildren"))
        if has_children and doc.id not in parents:
            add(PbCollection.TASKS, doc.id, "'hasChildren' verdadeiro sem tarefa filha", True)
        elif not has_children and doc.id in parents:
            add(PbCollection.TASKS, doc.id, "tem tarefa filha mas 'hasChildren' não é verdadeiro", True)
    return problems


def summarize(collection: PbCollection, records: Sequence[Mapping[str, Any]]) -> dict[str, int]:
    result: dict[str, int] = {"count": len(records)}
    if collection in (PbCollection.TASKS, PbCollection.APPOINTMENTS):
        result["spent_minutes"] = sum(r.get("spent_minutes") or 0 for r in records)
    elif collection is PbCollection.TIME_ENTRIES:
        result["minutes"] = sum(r.get("minutes") or 0 for r in records)
    elif collection is PbCollection.RECURRING_TASKS:
        result["with_last_generated_on"] = sum(1 for r in records if r.get("last_generated_on"))
    return result


def verify(
    expected: Mapping[PbCollection, Sequence[Mapping[str, Any]]],
    actual: Mapping[PbCollection, Sequence[Mapping[str, Any]]],
) -> list[str]:
    issues: list[str] = []
    for collection, wanted in expected.items():
        got = actual.get(collection, [])
        want_summary, got_summary = summarize(collection, wanted), summarize(collection, got)
        if want_summary != got_summary:
            issues.append(f"{collection}: esperado {want_summary}, encontrado {got_summary}")
        want_ids = {r["id"] for r in wanted}
        got_ids = {r["id"] for r in got}
        if want_ids != got_ids:
            issues.append(
                f"{collection}: ids que faltam: {_listed(sorted(want_ids - got_ids)) or '-'}; "
                f"ids que sobram: {_listed(sorted(got_ids - want_ids)) or '-'}"
            )
        if collection is PbCollection.TASKS:
            with_flag = {r["id"] for r in got if r.get("has_children")}
            parent_ids = {r["parent"] for r in got if r.get("parent")}
            if with_flag != parent_ids:
                wrong = sorted(with_flag ^ parent_ids)
                issues.append(f"{collection}: 'has_children' incoerente nos ids: {_listed(wrong)}")
    return issues


# ---------------------------------------------------------------- I/O


class PocketBaseError(Exception):
    def __init__(self, message: str, status: int, code: str | None = None) -> None:
        super().__init__(message)
        self.status = status
        self.code = code


class Source(Protocol):
    project_id: str

    def read_user(self, uid: str) -> dict[PbCollection, list[SourceDoc]]: ...

    def list_user_ids(self) -> list[str]: ...


class FirestoreSource:
    def __init__(self, credentials_path: Path) -> None:
        import firebase_admin
        from firebase_admin import credentials, firestore

        certificate = credentials.Certificate(str(credentials_path))
        self.project_id: str = certificate.project_id
        self._db = firestore.client(firebase_admin.initialize_app(certificate))

    def read_user(self, uid: str) -> dict[PbCollection, list[SourceDoc]]:
        user_ref = self._db.collection("users").document(uid)
        result: dict[PbCollection, list[SourceDoc]] = {}
        for collection in COPY_ORDER:
            path = SOURCE_PATHS[collection]
            if "/" in path:
                parent, name = path.split("/")
                snapshot = user_ref.collection(parent).document(name).get()
                snapshots = [snapshot] if snapshot.exists else []
            else:
                snapshots = list(user_ref.collection(path).stream())
            result[collection] = [SourceDoc(s.id, s.to_dict() or {}) for s in snapshots]
        return result

    def list_user_ids(self) -> list[str]:
        return [ref.id for ref in self._db.collection("users").list_documents()]


class PocketBaseAdmin:
    def __init__(self, base_url: str, client: httpx.Client) -> None:
        self._base = base_url.rstrip("/")
        self._client = client

    def authenticate(self, email: str, password: str) -> None:
        response = self._client.post(
            f"{self._base}/api/collections/_superusers/auth-with-password",
            json={"identity": email, "password": password},
        )
        if response.status_code != 200:
            raise PocketBaseError("Login de superusuário recusado.", response.status_code)
        self._client.headers["Authorization"] = response.json()["token"]

    def find_user_id(self, email: str) -> str | None:
        if any(char in email for char in "'\"\\"):
            raise ValueError("e-mail com caractere não permitido")
        response = self._client.get(
            f"{self._base}/api/collections/users/records",
            params={"filter": f"(email='{email}')", "perPage": 1, "skipTotal": 1},
        )
        if response.status_code != 200:
            raise PocketBaseError("Não foi possível buscar o usuário.", response.status_code)
        items = response.json().get("items", [])
        return items[0]["id"] if items else None

    def upsert(self, collection: PbCollection, bodies: Sequence[Mapping[str, Any]]) -> None:
        for chunk in chunked(bodies):
            payload = {
                "requests": [
                    {"method": "PUT", "url": f"/api/collections/{collection}/records", "body": body}
                    for body in chunk
                ]
            }
            response = self._client.post(f"{self._base}/api/batch", json=payload)
            if response.status_code != 200:
                raise self._batch_error(collection, chunk, response)

    @staticmethod
    def _batch_error(
        collection: PbCollection, chunk: Sequence[Mapping[str, Any]], response: httpx.Response
    ) -> PocketBaseError:
        code: str | None = None
        record_id = "?"
        try:
            body = response.json()
        except ValueError:
            body = {}
        if isinstance(body, dict):
            code = body.get("code")
            requests = (body.get("data") or {}).get("requests") or {}
            for index, entry in requests.items():
                if int(index) < len(chunk):
                    record_id = str(chunk[int(index)].get("id", "?"))
                inner = entry.get("response") or {}
                fields = [v for v in (inner.get("data") or {}).values() if isinstance(v, dict)]
                code = (fields[0].get("code") if fields else None) or inner.get("code") or entry.get("code")
                break
        message = (
            f"PocketBase recusou o lote de {collection} "
            f"(status {response.status_code}, código {code}, registro {record_id})."
        )
        return PocketBaseError(message, response.status_code, code)

    def list_records(self, collection: PbCollection, user_id: str) -> list[dict[str, Any]]:
        if not is_valid_id(user_id):
            raise ValueError("id de usuário inválido")
        records: list[dict[str, Any]] = []
        page = 1
        while True:
            response = self._client.get(
                f"{self._base}/api/collections/{collection}/records",
                params={"filter": f"(user='{user_id}')", "perPage": PAGE_SIZE, "page": page},
            )
            if response.status_code != 200:
                raise PocketBaseError(f"Não foi possível ler {collection}.", response.status_code)
            data = response.json()
            records.extend(data.get("items", []))
            if page >= int(data.get("totalPages", 1)):
                return records
            page += 1


def load_env_file(path: Path) -> None:
    if not path.exists():
        return
    if path.parent.stat().st_mode & 0o777 != 0o700:
        raise RuntimeError(f"A pasta {path.parent} deve ter permissão 700.")
    if path.stat().st_mode & 0o077:
        raise RuntimeError(f"O arquivo {path} deve ter permissão 600.")
    for line in path.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        key, value = key.strip(), value.strip()
        if len(value) >= 2 and value[0] == value[-1] and value[0] in "'\"":
            value = value[1:-1]
        os.environ.setdefault(key, value)


# ---------------------------------------------------------------- command line


def _user_map(raw_items: Sequence[str], parser: argparse.ArgumentParser) -> dict[str, str]:
    mapping: dict[str, str] = {}
    for raw in raw_items:
        uid, sep, email = raw.partition("=")
        if not sep or not uid.strip() or not email.strip():
            parser.error(f"--user-map inválido: use <uid>=<email> (recebido: {uid or '?'}).")
        if uid.strip() in mapping:
            parser.error(f"--user-map repete o uid {uid.strip()}.")
        mapping[uid.strip()] = email.strip()
    return mapping


def parse_args(argv: Sequence[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Copia os dados do Firestore (users/{uid}/...) para o PocketBase.",
        epilog=(
            "Variáveis exigidas: GOOGLE_APPLICATION_CREDENTIALS, PB_SUPERUSER_EMAIL, "
            f"PB_SUPERUSER_PASSWORD (podem vir de {ENV_FILE}, pasta 700 e arquivo 600).\n"
            "Códigos de saída: 0 ok; 1 verificação divergente; 2 validação recusou "
            "(nada gravado) ou argumento inválido; 3 erro de execução."
        ),
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument("--pb-url", required=True, help="endereço do PocketBase")
    parser.add_argument(
        "--user-map", action="append", required=True, metavar="UID=EMAIL",
        help="uid do Firebase = e-mail da conta no PocketBase (repetível)",
    )
    parser.add_argument("--dry-run", action="store_true", help="só valida e mostra; não grava")
    parser.add_argument(
        "--only", action="append", type=PbCollection, choices=list(PbCollection), default=[],
        metavar="COLEÇÃO", help="copia só esta coleção (repetível): " + ", ".join(PbCollection),
    )
    args = parser.parse_args(argv)
    url = args.pb_url
    local = any(url.startswith(f"http://{host}") for host in LOCAL_ONLY_HOSTS)
    if not (url.startswith("https://") or local):
        parser.error("--pb-url deve ser https:// (http:// só para 127.0.0.1 ou localhost).")
    args.user_map = _user_map(args.user_map, parser)
    return args


def _selected(args: argparse.Namespace) -> list[PbCollection]:
    return [c for c in COPY_ORDER if not args.only or c in args.only]


def _print_problems(email: str, problems: Sequence[Problem]) -> None:
    for problem in problems:
        level = "ERRO" if problem.fatal else "aviso"
        print(f"  [{level}] {email} · {problem.collection} · {problem.doc_id}: {problem.message}")


def _print_dry_run(email: str, source: Mapping[PbCollection, Sequence[SourceDoc]], user_id: str) -> None:
    for collection in COPY_ORDER:
        bodies = [map_document(collection, d, user_id)[0] for d in source.get(collection, [])]
        print(f"  {email} · {collection}: {summarize(collection, bodies)}")
        for source_key, spec in FIELD_MAP[collection].items():
            if spec.kind is not FieldKind.DAY:
                continue
            shown = 0
            for doc in source.get(collection, []):
                value = doc.data.get(source_key)
                if shown >= DAY_EXAMPLES or not _is_aware_datetime(value):
                    continue
                local = value.astimezone(SOURCE_TIMEZONE)
                print(
                    f"    {spec.target} {doc.id}: {value.astimezone(UTC).isoformat()} → "
                    f"{format_day(value)} (Brasília {local:%H:%M})"
                )
                shown += 1


def _run(args: argparse.Namespace, source: Source, pb: PocketBaseAdmin) -> ExitCode:
    if source.project_id != EXPECTED_FIREBASE_PROJECT:
        print(f"Credencial de outro projeto Firebase: {source.project_id}.")
        return ExitCode.RUNTIME_ERROR

    pb.authenticate(os.environ[EnvVar.SUPERUSER_EMAIL], os.environ[EnvVar.SUPERUSER_PASSWORD])
    user_ids: dict[str, str] = {}
    missing: list[str] = []
    for uid, email in args.user_map.items():
        found = pb.find_user_id(email)
        if found is None:
            missing.append(email)
        else:
            user_ids[uid] = found
    if missing:
        print("Sem usuário no PocketBase para: " + ", ".join(missing) + ". Nada foi lido nem gravado.")
        return ExitCode.VALIDATION_FAILED

    left_behind = [uid for uid in source.list_user_ids() if uid not in args.user_map]
    if left_behind:
        print(f"Aviso: {len(left_behind)} usuário(s) do Firestore fora do --user-map ficariam para trás: "
              + ", ".join(left_behind))

    data: dict[str, dict[PbCollection, list[SourceDoc]]] = {}
    any_fatal = False
    for uid, email in args.user_map.items():
        data[uid] = source.read_user(uid)
        problems = validate_source(data[uid])
        _print_problems(email, problems)
        any_fatal = any_fatal or any(p.fatal for p in problems)
    if any_fatal:
        print("Validação recusou os dados. Nada foi gravado.")
        return ExitCode.VALIDATION_FAILED

    if args.dry_run:
        for uid, email in args.user_map.items():
            _print_dry_run(email, data[uid], user_ids[uid])
        print("Simulação concluída. Nada foi gravado.")
        return ExitCode.OK

    diverged = False
    for uid, email in args.user_map.items():
        user_id = user_ids[uid]
        expected: dict[PbCollection, list[dict[str, Any]]] = {}
        for collection in _selected(args):
            bodies = [map_document(collection, d, user_id)[0] for d in data[uid].get(collection, [])]
            if collection is PbCollection.TASKS:
                bodies = order_parents_first(bodies)
            try:
                pb.upsert(collection, bodies)
            except PocketBaseError as error:
                print(f"{email} · {collection}: {error}")
                return ExitCode.RUNTIME_ERROR
            expected[collection] = bodies
            print(f"{email} · {collection}: {len(bodies)} gravado(s)")
        actual = {c: pb.list_records(c, user_id) for c in expected}
        issues = verify(expected, actual)
        if issues:
            diverged = True
            for issue in issues:
                print(f"  DIVERGÊNCIA {email} · {issue}")
        else:
            for collection, bodies in expected.items():
                print(f"  conferido {email} · {collection}: {summarize(collection, bodies)}")
    return ExitCode.VERIFY_FAILED if diverged else ExitCode.OK


def run(args: argparse.Namespace, source: Source, pb: PocketBaseAdmin) -> ExitCode:
    try:
        return _run(args, source, pb)
    except httpx.TransportError:
        print(f"Não foi possível falar com o PocketBase em {args.pb_url}.")
        return ExitCode.RUNTIME_ERROR
    except PocketBaseError as error:
        print(f"{error} (status {error.status})")
        return ExitCode.RUNTIME_ERROR
    except ValueError as error:
        print(f"Dado recusado: {error}")
        return ExitCode.VALIDATION_FAILED


def main(argv: Sequence[str] | None = None) -> int:
    args = parse_args(argv)
    try:
        load_env_file(ENV_FILE)
    except RuntimeError as error:
        print(error)
        return ExitCode.RUNTIME_ERROR
    for name in EnvVar:
        if not os.environ.get(name):
            print(f"Variável de ambiente faltando: {name.value}.")
            return ExitCode.RUNTIME_ERROR
    try:
        source = FirestoreSource(Path(os.environ[EnvVar.CREDENTIALS]))
    except (OSError, ValueError) as error:
        print(f"Não foi possível abrir a credencial do Firebase: {type(error).__name__}.")
        return ExitCode.RUNTIME_ERROR
    with httpx.Client(timeout=30) as client:
        return int(run(args, source, PocketBaseAdmin(args.pb_url, client)))


if __name__ == "__main__":
    sys.exit(main())
