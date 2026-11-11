import assert from "node:assert/strict";
import { describe, it } from "node:test";
import {
  configGroup,
  describeLimits,
  describeValue,
  parseConfigInput,
  parseFlagInput,
  sameValue,
  toInputText,
  type ConfigDefinition,
} from "./app_config_format.ts";

const integer: ConfigDefinition = { type: "integer", default: 4, min: 1, max: 4, description: "" };
const list: ConfigDefinition = { type: "integer_list", default: [80, 100], min: 1, max: 100, minItems: 1, maxItems: 4, description: "" };
const money: ConfigDefinition = { type: "money_minor_list", default: ["10000000"], currencyCode: "VND", minItems: 0, maxItems: 6, description: "" };
const window: ConfigDefinition = { type: "enum", default: "6m", values: ["3m", "6m"], description: "" };
const kinds: ConfigDefinition = { type: "enum_list", default: ["home"], values: ["home", "car"], minItems: 1, maxItems: 2, description: "" };
const time: ConfigDefinition = { type: "time", default: "21:00", description: "" };

describe("WA-P5-001 config input", () => {
  it("parses what staff type", () => {
    assert.deepEqual(parseConfigInput(integer, " 3 "), { ok: true, value: 3 });
    assert.deepEqual(parseConfigInput(list, "70, 80;90\n100"), { ok: true, value: [70, 80, 90, 100] });
    assert.deepEqual(parseConfigInput(money, "10.000.000, 15 000 000"), { ok: true, value: ["10000000", "15000000"] });
    assert.deepEqual(parseConfigInput(money, ""), { ok: true, value: [] });
    assert.deepEqual(parseConfigInput(window, "3m"), { ok: true, value: "3m" });
    assert.deepEqual(parseConfigInput(kinds, "car, home"), { ok: true, value: ["car", "home"] });
    assert.deepEqual(parseConfigInput(time, "07:30"), { ok: true, value: "07:30" });
  });

  it("explains bad input in Vietnamese", () => {
    for (const [definition, text] of [
      [integer, "5"], [integer, "0"], [integer, "2.5"], [integer, "abc"],
      [list, "100, 80"], [list, "80, 80"], [list, ""], [list, "10,20,30,40,50"], [list, "0"],
      [money, "0"], [money, "-5"], [money, "20, 10"],
      [window, "1y"], [kinds, "car, car"], [kinds, "bike"], [kinds, ""],
      [time, "24:00"], [time, "9:00"],
    ] as const) {
      const result = parseConfigInput(definition, text);
      assert.equal(result.ok, false, `${definition.type} "${text}" should fail`);
      if (!result.ok) assert.ok(result.message.length > 0);
    }
  });

  it("shows values back in the input and the comparison", () => {
    assert.equal(toInputText(list, [80, 100]), "80, 100");
    assert.equal(toInputText(money, ["10000000", "15000000"]), "10.000.000, 15.000.000");
    assert.equal(describeValue(money, ["10000000"]), "10.000.000 VND");
    assert.equal(describeValue(money, []), "(trống)");
    assert.equal(describeValue(kinds, []), "(trống)");
    assert.equal(describeLimits(list), "1–100 · 1–4 giá trị · tăng dần, cách nhau dấu phẩy");
    assert.equal(describeLimits(time), "HH:mm");
  });
});

describe("WA-P5-001 flag input", () => {
  const id = "5F0C1A52-8A1E-4F4C-9B7E-3C8F2E6D1A90";

  it("accepts a percentage and one UUID per line", () => {
    assert.deepEqual(parseFlagInput(true, "25", `${id}\n${id.toLowerCase()}\n`), {
      ok: true,
      value: { enabled: true, percentage: 25, userIds: [id.toLowerCase()] },
    });
  });

  it("points at the field that is wrong", () => {
    assert.deepEqual(parseFlagInput(true, "101", ""), { ok: false, field: "percentage", message: "Nhập số nguyên từ 0 đến 100." });
    const bad = parseFlagInput(true, "0", "not-a-uuid");
    assert.equal(bad.ok, false);
    if (!bad.ok) assert.equal(bad.field, "userIds");
  });
});

describe("WA-P5-001 helpers", () => {
  it("groups keys and compares values", () => {
    assert.equal(configGroup("budget.alertThresholdOptions"), "budget");
    assert.equal(configGroup("insights"), "");
    assert.equal(sameValue([80, 100], [80, 100]), true);
    assert.equal(sameValue([80, 100], [100, 80]), false);
  });
});
