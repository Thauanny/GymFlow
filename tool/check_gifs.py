#!/usr/bin/env python3
"""Confere se os GIFs usados pelo app (assets/gif) ainda existem no servidor.

Uso: python3 tool/check_gifs.py
Lista os ids que respondem diferente de 200, para remover dos JSONs.
"""
import glob
import json
import subprocess
from concurrent.futures import ThreadPoolExecutor

BASE = "https://static.exercisedb.dev/media/"
ids = set()
for group in json.load(open("assets/gif/items.json")).values():
    ids |= set(group.values())
ids |= set(json.load(open("assets/gif/exercises.json")).values())
for f in glob.glob("assets/gif/alts/*.json"):
    ids |= {a[1] for a in json.load(open(f))}


def status(i):
    r = subprocess.run(
        ["curl", "-s", "-o", "/dev/null", "-w", "%{http_code}", "--max-time", "25", "-I", f"{BASE}{i}.gif"],
        capture_output=True, text=True)
    return i, r.stdout.strip()


with ThreadPoolExecutor(24) as ex:
    bad = [(i, c) for i, c in ex.map(status, sorted(ids)) if c != "200"]
print(f"{len(ids)} GIFs verificados; {len(bad)} com problema")
for i, c in bad:
    print(i, c)
