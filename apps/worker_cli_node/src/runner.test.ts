import { describe, expect, it } from "vitest";

import { parseLumeVmJsonList, parseLumeVmTextList } from "./runner.js";

describe("parseLumeVmJsonList", () => {
  it("parses array output", () => {
    expect(
      parseLumeVmJsonList(
        JSON.stringify([
          { name: "openci-vm-worker-12345678", status: "running" },
          { name: "base-vm", state: "stopped" },
        ]),
      ),
    ).toEqual([
      { name: "openci-vm-worker-12345678", status: "running" },
      { name: "base-vm", status: "stopped" },
    ]);
  });

  it("parses wrapped output", () => {
    expect(
      parseLumeVmJsonList(JSON.stringify({ vms: [{ name: "openci-vm-worker-12345678" }] })),
    ).toEqual([{ name: "openci-vm-worker-12345678", status: "" }]);
  });
});

describe("parseLumeVmTextList", () => {
  it("keeps normal table VM names", () => {
    const output = [
      "NAME OS CPU MEMORY DISK DISPLAY STATUS IP",
      "openci-vm-worker-12345678 macOS 4 8GB 50GB 1024x768 stopped 192.168.64.2",
    ].join("\n");

    expect(parseLumeVmTextList(output)).toEqual([
      { name: "openci-vm-worker-12345678", status: "stopped" },
    ]);
  });

  it("strips an OS column that is joined to an overflowing VM name", () => {
    const output = [
      "NAME OS CPU MEMORY DISK DISPLAY STATUS IP",
      "openci-vm-admins-Mini-2-worker1-51ad7c53macOS 4 8GB 50GB 1024x768 stopped 192.168.64.2",
    ].join("\n");

    expect(parseLumeVmTextList(output)).toEqual([
      { name: "openci-vm-admins-Mini-2-worker1-51ad7c53", status: "stopped" },
    ]);
  });
});
