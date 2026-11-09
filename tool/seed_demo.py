# /// script
# requires-python = ">=3.12"
# dependencies = ["httpx"]
# ///
"""Create (or recreate) a demo account (demo@meutempo.com / demo1234) on the production Meu Tempo PocketBase and seed it.

Runs locally: opens an SSH tunnel to the VPS, creates a temporary superuser only to
create the demo user, then writes every record as the demo user (so the owner rules apply),
and finally removes the temporary superuser.

Usage: uv run tool/seed_demo.py  (needs `ssh hostinger` access)
"""

from __future__ import annotations

import random
import secrets
import subprocess
import time
from datetime import date, datetime, timedelta, timezone

import httpx

SSH_HOST = "hostinger"
REMOTE_PORT = 8094
LOCAL_PORT = 18094
PB_BIN = "/opt/pocketbase/versions/0.40.5/pocketbase"
PB_DIR = "/opt/pocketbase/mytime/pb_data"
BASE = f"http://127.0.0.1:{LOCAL_PORT}"

DEMO_EMAIL = "demo@meutempo.com"
DEMO_NAME = "Conta de demonstração"
# Easy to type on a phone: this account only holds fictional data for screenshots.
DEMO_PASSWORD = "demo1234"

BRT = timezone(timedelta(hours=-3))
TODAY = datetime.now(BRT).date()

random.seed(20261109)


def day(offset: int) -> str:
    d = TODAY + timedelta(days=offset)
    return f"{d.isoformat()} 00:00:00.000Z"


def instant(offset_days: int, hour: int, minute: int = 0) -> str:
    d = TODAY + timedelta(days=offset_days)
    local = datetime(d.year, d.month, d.day, hour, minute, tzinfo=BRT)
    return local.astimezone(timezone.utc).strftime("%Y-%m-%d %H:%M:%S.000Z")


def ssh(cmd: str) -> None:
    subprocess.run(["ssh", SSH_HOST, cmd], check=True, capture_output=True)


# ---------------------------------------------------------------- seed data
LISTS = ["Casa", "Mercado e cozinha", "Finanças", "Família", "Saúde e bem-estar", "Jardim e pets"]

# (title, list, est_min, due_offset, importance, done, spent, children)
# Leaves have est/due/importance; parents only have children.
TASKS = [
    # Entrada (quick capture)
    ("Ligar para o encanador sobre o vazamento da pia", "Entrada", 10, 0, "max", False, 0, None),
    ("Devolver a furadeira do vizinho", "Entrada", 10, 2, "low", False, 0, None),
    ("Ver horário da feira de domingo", "Entrada", 5, None, "min", False, 0, None),
    # Casa
    ("Faxina geral do apartamento", "Casa", None, None, None, False, 0, [
        ("Cozinha", None, None, None, False, 0, [
            ("Limpar a geladeira por dentro", 30, 1, "high", True, 35, None),
            ("Desengordurar o fogão e o exaustor", 40, 1, "high", False, 15, None),
            ("Lavar o chão da cozinha", 20, 1, "low", False, 0, None),
        ]),
        ("Banheiros", None, None, None, False, 0, [
            ("Esfregar o box e os azulejos", 35, 2, "high", False, 0, None),
            ("Trocar as toalhas e os tapetes", 10, 2, "low", True, 10, None),
        ]),
        ("Quartos", None, None, None, False, 0, [
            ("Trocar a roupa de cama", 20, 3, "low", False, 0, None),
            ("Aspirar embaixo das camas", 25, 3, "min", False, 0, None),
        ]),
    ]),
    ("Organizar o guarda-roupa para o verão", "Casa", None, None, None, False, 0, [
        ("Separar roupas para doação", 45, 5, "low", False, 20, None),
        ("Guardar os casacos em sacos a vácuo", 30, 6, "min", False, 0, None),
    ]),
    ("Trocar a lâmpada queimada da área de serviço", "Casa", 10, 0, "high", False, 0, None),
    ("Lavar as cortinas da sala", "Casa", 60, 8, "min", False, 0, None),
    ("Consertar a porta do armário que range", "Casa", 15, -1, "low", False, 0, None),
    # Mercado e cozinha
    ("Fazer a lista de compras da semana", "Mercado e cozinha", 15, 0, "high", True, 12, None),
    ("Compras do mês no atacado", "Mercado e cozinha", 120, 3, "high", False, 0, None),
    ("Marmitas da semana", "Mercado e cozinha", None, None, None, False, 0, [
        ("Cozinhar arroz e feijão", 60, 0, "high", False, 25, None),
        ("Assar frango com legumes", 50, 0, "high", False, 0, None),
        ("Porcionar e congelar", 20, 0, "low", False, 0, None),
    ]),
    ("Descongelar o freezer", "Mercado e cozinha", 40, 9, "min", False, 0, None),
    # Finanças
    ("Pagar a conta de luz", "Finanças", 5, 1, "max", False, 0, None),
    ("Pagar o condomínio", "Finanças", 5, 4, "max", False, 0, None),
    ("Revisar o orçamento de novembro", "Finanças", None, None, None, False, 0, [
        ("Lançar os gastos do cartão na planilha", 30, 2, "high", False, 18, None),
        ("Cancelar assinaturas que não uso", 20, 2, "high", True, 22, None),
        ("Definir quanto guardar para as férias", 15, 5, "low", False, 0, None),
    ]),
    ("Separar documentos do imposto de renda", "Finanças", 60, 20, "low", False, 0, None),
    # Família
    ("Aniversário da Júlia", "Família", None, None, None, False, 0, [
        ("Encomendar o bolo", 15, 4, "max", False, 0, None),
        ("Comprar decoração e lembrancinhas", 45, 6, "high", False, 0, None),
        ("Enviar convites para a turma", 20, 3, "high", True, 15, None),
    ]),
    ("Ajudar o Pedro com a lição de matemática", "Família", 40, 0, "high", False, 0, None),
    ("Separar o uniforme para a semana", "Família", 15, 0, "low", True, 15, None),
    ("Marcar o almoço de domingo com os avós", "Família", 10, 5, "low", False, 0, None),
    # Saúde e bem-estar
    ("Agendar consulta no dentista", "Saúde e bem-estar", 10, 1, "high", False, 0, None),
    ("Renovar a receita do remédio de pressão", "Saúde e bem-estar", 15, 3, "max", False, 0, None),
    ("Caminhada no parque", "Saúde e bem-estar", 40, 0, "low", False, 0, None),
    ("Organizar a caixa de remédios", "Saúde e bem-estar", 20, 7, "min", False, 0, None),
    # Jardim e pets
    ("Dar banho no Thor", "Jardim e pets", 45, 2, "high", False, 0, None),
    ("Comprar ração e areia", "Jardim e pets", 20, 1, "high", False, 0, None),
    ("Replantar a costela-de-adão", "Jardim e pets", 30, 10, "min", False, 0, None),
    ("Vacina anual da Mel", "Jardim e pets", 60, 12, "high", False, 0, None),
]

# (title, list, est, importance, weekdays)
RECURRING = [
    ("Lavar roupa", "Casa", 30, "high", ["monday", "thursday"]),
    ("Regar as plantas", "Jardim e pets", 10, "low", ["monday", "wednesday", "friday", "sunday"]),
    ("Tirar o lixo reciclável", "Casa", 5, "low", ["tuesday", "friday"]),
    ("Passear com o Thor", "Jardim e pets", 30, "high",
     ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"]),
]

# (title, list, day_offset, start "HH:MM", duration, done, spent)
APPOINTMENTS = [
    ("Reunião de pais na escola", "Família", -3, "19:00", 60, True, 70),
    ("Consulta da Mel no veterinário", "Jardim e pets", -2, "10:30", 45, True, 50),
    ("Pilates", "Saúde e bem-estar", -1, "07:00", 50, True, 50),
    ("Levar o carro na revisão", "Casa", 0, "08:30", 60, False, 0),
    ("Buscar as crianças na natação", "Família", 0, "17:30", 30, False, 0),
    ("Pilates", "Saúde e bem-estar", 1, "07:00", 50, False, 0),
    ("Técnico da internet", "Casa", 1, "14:00", 120, False, 0),
    ("Dentista do Pedro", "Saúde e bem-estar", 2, "16:00", 40, False, 0),
    ("Feira de domingo", "Mercado e cozinha", 6, "08:00", 60, False, 0),
    ("Almoço com os avós", "Família", 6, "12:30", 150, False, 0),
]

# Past time on tasks that are already gone from the list (history for the reports).
HISTORY = [
    # (list, days_ago, hour, minutes)
    ("Casa", 1, 9, 45), ("Casa", 2, 10, 30), ("Casa", 4, 8, 60), ("Casa", 6, 15, 25),
    ("Mercado e cozinha", 1, 18, 40), ("Mercado e cozinha", 3, 11, 90), ("Mercado e cozinha", 7, 17, 35),
    ("Finanças", 2, 21, 30), ("Finanças", 5, 20, 20),
    ("Família", 1, 19, 50), ("Família", 3, 16, 30), ("Família", 5, 14, 60), ("Família", 8, 10, 45),
    ("Saúde e bem-estar", 2, 7, 40), ("Saúde e bem-estar", 4, 7, 40), ("Saúde e bem-estar", 6, 7, 40),
    ("Jardim e pets", 1, 7, 30), ("Jardim e pets", 2, 7, 30), ("Jardim e pets", 3, 18, 45),
    ("Jardim e pets", 5, 7, 30), ("Casa", 9, 9, 120), ("Família", 11, 15, 40),
]


# ---------------------------------------------------------------- API helpers
class Api:
    def __init__(self, token: str) -> None:
        self.c = httpx.Client(base_url=BASE, headers={"Authorization": token}, timeout=30)

    def create(self, collection: str, body: dict) -> dict:
        r = self.c.post(f"/api/collections/{collection}/records", json=body)
        if r.status_code >= 400:
            raise RuntimeError(f"{collection}: {r.status_code} {r.text} body={body}")
        return r.json()


def auth(collection: str, email: str, password: str) -> str:
    r = httpx.post(f"{BASE}/api/collections/{collection}/auth-with-password",
                   json={"identity": email, "password": password}, timeout=30)
    r.raise_for_status()
    return r.json()["token"]


def main() -> None:
    su_email = "seed-tmp@localhost.local"
    su_pass = secrets.token_urlsafe(24)
    tunnel = subprocess.Popen(
        ["ssh", "-N", "-o", "ExitOnForwardFailure=yes", "-L", f"{LOCAL_PORT}:127.0.0.1:{REMOTE_PORT}", SSH_HOST]
    )
    try:
        time.sleep(3)
        ssh(f"sudo runuser -u pocketbase -- {PB_BIN} superuser upsert {su_email} '{su_pass}' --dir={PB_DIR}")
        admin = httpx.Client(base_url=BASE, headers={"Authorization": auth("_superusers", su_email, su_pass)})

        # Recreate the demo user (cascade removes its old records).
        found = admin.get("/api/collections/users/records", params={"filter": f'email="{DEMO_EMAIL}"'}).json()
        for item in found["items"]:
            admin.delete(f"/api/collections/users/records/{item['id']}").raise_for_status()

        password = DEMO_PASSWORD
        r = admin.post("/api/collections/users/records", json={
            "email": DEMO_EMAIL, "password": password, "passwordConfirm": password,
            "name": DEMO_NAME, "verified": True, "emailVisibility": False,
        })
        r.raise_for_status()
        user_id = r.json()["id"]

        api = Api(auth("users", DEMO_EMAIL, password))
        seed(api, user_id)
    finally:
        try:
            ssh(f"sudo runuser -u pocketbase -- {PB_BIN} superuser delete {su_email} --dir={PB_DIR}")
        finally:
            tunnel.terminate()


def seed(api: Api, uid: str) -> None:
    api.create("day_configs", {"user": uid, "available_minutes_per_day": 240, "onboarded": True})

    lists = {"Entrada": api.create("task_lists", {"user": uid, "name": "Entrada", "is_default": True})["id"]}
    for name in LISTS:
        lists[name] = api.create("task_lists", {"user": uid, "name": name, "is_default": False})["id"]

    counts = {"tasks": 0, "time_entries": 0}

    def entries_for(target: str, target_type: str, list_id: str, spent: int, base_offset: int) -> None:
        # Split the spent time into 1-2 timer sessions in the last days.
        parts = [spent] if spent < 25 else [spent // 2, spent - spent // 2]
        for i, minutes in enumerate(parts):
            api.create("time_entries", {
                "user": uid, "target_id": target, "target_type": target_type, "list_id": list_id,
                "origin": "manual" if i == 1 else "timer", "minutes": minutes,
                "occurred_at": instant(base_offset - i, random.choice([8, 10, 14, 19]), random.choice([0, 15, 30])),
            })
            counts["time_entries"] += 1

    def make_task(spec: tuple, list_name: str, parent: str | None, created_offset: int) -> None:
        title, est, due, imp, done, spent, children = spec
        has_children = bool(children)
        body = {
            "user": uid, "title": title, "list": lists[list_name], "parent": parent or "",
            "created_at": instant(created_offset, 9, random.randint(0, 59)),
            "estimated_minutes": None if has_children else est,
            "due_date": None if (has_children or due is None) else day(due),
            "importance": "" if has_children else imp,
            "is_done": done, "has_children": has_children,
            "spent_minutes": 0 if has_children else spent,
            "recurring_task_id": "",
        }
        rec = api.create("tasks", body)
        counts["tasks"] += 1
        if spent and not has_children:
            entries_for(rec["id"], "task", lists[list_name], spent, -1 if done else 0)
        for child in children or []:
            make_task(child, list_name, rec["id"], created_offset)

    for i, (title, list_name, *rest) in enumerate(TASKS):
        make_task((title, *rest), list_name, None, -random.randint(1, 12))

    for title, list_name, est, imp, weekdays in RECURRING:
        api.create("recurring_tasks", {
            "user": uid, "title": title, "list": lists[list_name], "estimated_minutes": est,
            "importance": imp, "weekdays": weekdays, "created_at": instant(-20, 8),
            "last_generated_on": day(-1),  # the app generates today's copies on open
        })

    for title, list_name, offset, start, dur, done, spent in APPOINTMENTS:
        h, m = map(int, start.split(":"))
        rec = api.create("appointments", {
            "user": uid, "title": title, "list_id": lists[list_name], "date": day(offset),
            "start_minute": h * 60 + m, "duration_minutes": dur, "spent_minutes": spent, "is_done": done,
        })
        if spent:
            api.create("time_entries", {
                "user": uid, "target_id": rec["id"], "target_type": "appointment", "list_id": lists[list_name],
                "origin": "timer", "minutes": spent, "occurred_at": instant(offset, h, m),
            })
            counts["time_entries"] += 1

    # History: done tasks from past days, with their time.
    for n, (list_name, ago, hour, minutes) in enumerate(HISTORY):
        title = HISTORY_TITLES[list_name][n % len(HISTORY_TITLES[list_name])]
        rec = api.create("tasks", {
            "user": uid, "title": title, "list": lists[list_name], "parent": "",
            "created_at": instant(-ago - 2, 9), "estimated_minutes": minutes, "due_date": day(-ago),
            "importance": random.choice(["high", "low"]), "is_done": True, "has_children": False,
            "spent_minutes": minutes, "recurring_task_id": "",
        })
        counts["tasks"] += 1
        api.create("time_entries", {
            "user": uid, "target_id": rec["id"], "target_type": "task", "list_id": lists[list_name],
            "origin": "timer", "minutes": minutes, "occurred_at": instant(-ago, hour, random.choice([0, 20, 40])),
        })
        counts["time_entries"] += 1

    print(f"lists={len(lists)} tasks={counts['tasks']} recurring={len(RECURRING)} "
          f"appointments={len(APPOINTMENTS)} time_entries={counts['time_entries']}")


HISTORY_TITLES = {
    "Casa": ["Arrumar a despensa", "Passar roupa", "Limpar os vidros da varanda", "Organizar a gaveta de talheres",
             "Lavar o tapete da sala"],
    "Mercado e cozinha": ["Fazer pão caseiro", "Compras na quitanda", "Preparar o molho de tomate"],
    "Finanças": ["Conferir o extrato do banco", "Pagar a internet"],
    "Família": ["Levar as crianças ao parque", "Montar o trabalho de ciências", "Visitar a tia Rosa",
                "Organizar o álbum de fotos"],
    "Saúde e bem-estar": ["Yoga em casa"],
    "Jardim e pets": ["Passear com o Thor", "Adubar os vasos"],
}


if __name__ == "__main__":
    main()
