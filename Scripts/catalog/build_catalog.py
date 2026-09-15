#!/usr/bin/env python3
"""Builds a Buckets "Add Rows from JSON" catalog file from researched price rows.

Usage: build_catalog.py rows.json out.json
rows.json is a list of dicts: bucket, name, unit, price (dollars), source, notes, and for equipment
the calculator inputs (price, salvage, life_h, annual_h, fuel_oil_per_h, repair_factor, insurance_per_yr,
cost_of_money_pct). Equipment rates use the same one-division formula as EquipmentCalc (DECISIONS 7).
"""
import json, sys
from decimal import Decimal, ROUND_HALF_UP, getcontext
getcontext().prec = 60

def cents(x): return int((Decimal(x) * 100).quantize(Decimal("1"), rounding=ROUND_HALF_UP))
def D(x): return Decimal(str(x))

def equipment_rate_cents(price, salvage, life_h, annual_h, fuel_oil_per_h, repair_factor, insurance_per_yr, cost_of_money_pct):
    c, s, i, f = D(price), D(salvage), D(insurance_per_yr), D(fuel_oil_per_h)
    l, a, rf, r = D(life_h), D(annual_h), D(repair_factor), D(cost_of_money_pct) / 100
    assert c > 0 and 0 <= s < c and l > 0 and a > 0
    k = 2 * l * c if l <= a else (l - a) * (c + s) + 2 * a * c
    den = 2 * l * a
    num = 2 * a * (c - s) + k * r + 2 * l * i + den * f + 2 * a * c * rf
    return int((num / den * 100).quantize(Decimal("1"), rounding=ROUND_HALF_UP))

# Self-check against BRIEF §2.2: the bucket truck is $23.72/hr.
assert equipment_rate_cents(65000, 15000, 8000, 1500, 7.28, 0.80, 2400, 7) == 2372

def build(rows):
    items, order = [], {}
    for r in rows:
        b = r["bucket"]
        order[b] = order.get(b, -1) + 1
        item = {"bucket": b, "name": r["name"], "unit": r.get("unit") or ("hr" if b in ("labor", "equipment") else "yr" if b == "overhead" else "each"),
                "isActive": True, "source": r.get("source"), "notes": r.get("notes"), "calcInputs": None, "sortOrder": order[b]}
        if b == "equipment" and "price" in r and "life_h" in r:
            ci = {"priceCents": cents(r["price"]), "salvageCents": cents(r.get("salvage", 0)), "lifeHours": r["life_h"],
                  "annualHours": r["annual_h"], "fuelOilPerHourCents": cents(r.get("fuel_oil_per_h", 0)),
                  "repairFactor": r["repair_factor"], "insurancePerYearCents": cents(r.get("insurance_per_yr", 0)),
                  "costOfMoneyPct": r.get("cost_of_money_pct", 0)}
            item["rateCents"] = equipment_rate_cents(r["price"], r.get("salvage", 0), r["life_h"], r["annual_h"], r.get("fuel_oil_per_h", 0),
                                                     r["repair_factor"], r.get("insurance_per_yr", 0), r.get("cost_of_money_pct", 0))
            item["calcInputs"] = ci
        else:
            item["rateCents"] = cents(r["price"])
        items.append(item)
    return {"formatVersion": 1, "exportedAt": "2026-09-15T12:00:00Z",
            "settings": {"billableHoursPerYear": 1500, "laborBurdenPct": 30, "markupPct": 35, "minimumJobCents": 75000, "costOfMoneyPct": 0},
            "items": items, "projects": []}

if __name__ == "__main__":
    rows = json.load(open(sys.argv[1]))
    json.dump(build(rows), open(sys.argv[2], "w"), indent=2, sort_keys=True)
    print(f"wrote {sys.argv[2]}: {len(rows)} rows")
