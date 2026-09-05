import { once } from "node:events";
import { createServer } from "node:http";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { getBuildJob, InvalidBuildJobResponseError, OpenCiApiError } from "../src/openci-api";
import type { BuildJob, GetBuildJobOptions } from "../src/openci-api";

const options: GetBuildJobOptions = {
  serverUrl: "https://openci.example",
  internalApiKey: "test-internal-key",
};
const job: BuildJob = {
  id: "job-123",
  status: "QUEUED",
  owner: "openci-org",
  repo: "openci",
  workflowName: "Flutter CI",
  workflowFileName: "ci.dart",
  createdAt: "2026-09-05T00:00:00.123456Z",
  updatedAt: "2026-09-05T01:00:00.000Z",
};
const nativeFetch = globalThis.fetch;
const fetchMock = vi.fn<typeof fetch>();

beforeEach(() => {
  fetchMock.mockReset();
  vi.stubGlobal("fetch", fetchMock);
});

afterEach(() => {
  vi.restoreAllMocks();
  vi.unstubAllGlobals();
});

describe("getBuildJob", () => {
  it("sends one authenticated GET and returns the validated job", async () => {
    fetchMock.mockResolvedValue(Response.json(job));
    const timeout = vi.spyOn(AbortSignal, "timeout");

    await expect(getBuildJob(job.id, options)).resolves.toEqual(job);

    expect(fetchMock).toHaveBeenCalledExactlyOnceWith(
      new URL("https://openci.example/builds/job-123"),
      {
        method: "GET",
        headers: {
          Authorization: "Bearer test-internal-key",
          Accept: "application/json",
        },
        signal: expect.any(AbortSignal),
        redirect: "manual",
      },
    );
    expect(timeout).toHaveBeenCalledExactlyOnceWith(10_000);
  });

  it.each(["http://server:8080/api", "http://server:8080/api/"])(
    "preserves the base path and encodes the job ID with %s",
    async (serverUrl) => {
      const jobId = "job/123 ?#%";
      fetchMock.mockResolvedValue(Response.json({ ...job, id: jobId }));

      await getBuildJob(jobId, { ...options, serverUrl, timeoutMs: 2_000 });

      expect(fetchMock).toHaveBeenCalledExactlyOnceWith(
        new URL("http://server:8080/api/builds/job%2F123%20%3F%23%25"),
        expect.objectContaining({ method: "GET" }),
      );
    },
  );

  it("ignores fields outside the worker's required BuildJob fields", async () => {
    fetchMock.mockResolvedValue(
      Response.json({ ...job, teamId: "team-123", commitSha: null, needs: null, hasIpa: false }),
    );

    await expect(getBuildJob(job.id, options)).resolves.toEqual(job);
  });

  it.each([302, 400, 401, 403, 404, 429, 500, 503])(
    "exposes HTTP %i without retrying or including the response body",
    async (statusCode) => {
      const response = new Response("sensitive error body", { status: statusCode });
      fetchMock.mockResolvedValue(response);
      const result = getBuildJob(job.id, options);

      await expect(result).rejects.toBeInstanceOf(OpenCiApiError);
      await expect(result).rejects.toMatchObject({
        name: "OpenCiApiError",
        statusCode,
        message: `Failed to get build job job-123: HTTP ${statusCode}`,
      });
      expect(response.bodyUsed).toBe(true);
      expect(fetchMock).toHaveBeenCalledTimes(1);
    },
  );

  it("propagates network errors without retrying", async () => {
    const error = new TypeError("fetch failed");
    fetchMock.mockRejectedValue(error);

    await expect(getBuildJob(job.id, options)).rejects.toBe(error);
    expect(fetchMock).toHaveBeenCalledTimes(1);
  });

  it("preserves an HTTP error when there is no response body", async () => {
    fetchMock.mockResolvedValue(new Response(null, { status: 404 }));

    await expect(getBuildJob(job.id, options)).rejects.toMatchObject({
      name: "OpenCiApiError",
      statusCode: 404,
    });
  });

  it("preserves an HTTP error even if cancelling its body fails", async () => {
    const response = new Response("unread body", { status: 503 });
    if (response.body === null) {
      throw new Error("Test response has no body");
    }
    vi.spyOn(response.body, "cancel").mockRejectedValue(new Error("already aborted"));
    fetchMock.mockResolvedValue(response);

    await expect(getBuildJob(job.id, options)).rejects.toMatchObject({
      name: "OpenCiApiError",
      statusCode: 503,
    });
  });

  it("rejects a successful response with no job body", async () => {
    fetchMock.mockResolvedValue(new Response(null, { status: 204 }));

    await expect(getBuildJob(job.id, options)).rejects.toEqual(
      new InvalidBuildJobResponseError(job.id, "body is not valid JSON"),
    );
  });

  it("does not mistake a body download failure for malformed JSON", async () => {
    const response = Response.json(job);
    const error = new TypeError("terminated");
    vi.spyOn(response, "json").mockRejectedValue(error);
    fetchMock.mockResolvedValue(response);

    await expect(getBuildJob(job.id, options)).rejects.toBe(error);
  });

  it.each(["not JSON", "", '{"secret": sensitive}'])(
    "rejects invalid JSON without including its contents: %j",
    async (body) => {
      fetchMock.mockResolvedValue(new Response(body));

      await expect(getBuildJob(job.id, options)).rejects.toEqual(
        new InvalidBuildJobResponseError(job.id, "body is not valid JSON"),
      );
    },
  );

  it.each([null, [], "job-123", 123, true, { job }])(
    "rejects an invalid job body: %j",
    async (body) => {
      fetchMock.mockResolvedValue(Response.json(body));

      await expect(getBuildJob(job.id, options)).rejects.toBeInstanceOf(
        InvalidBuildJobResponseError,
      );
    },
  );

  describe.each([
    "id",
    "owner",
    "repo",
    "workflowName",
    "workflowFileName",
    "createdAt",
    "updatedAt",
  ])("required field %s", (field) => {
    it.each([undefined, null, "", " \n", 123, {}])("rejects %j", async (value) => {
      fetchMock.mockResolvedValue(Response.json({ ...job, [field]: value }));

      await expect(getBuildJob(job.id, options)).rejects.toEqual(
        new InvalidBuildJobResponseError(job.id, `${field} must be a non-empty string`),
      );
    });
  });

  it("rejects a response for another job", async () => {
    fetchMock.mockResolvedValue(Response.json({ ...job, id: "another-job" }));

    await expect(getBuildJob(job.id, options)).rejects.toEqual(
      new InvalidBuildJobResponseError(job.id, "id does not match the requested job"),
    );
  });

  it.each([
    "WAITING",
    "QUEUED",
    "IN_PROGRESS",
    "SUCCESS",
    "FAILURE",
    "CANCELLED",
    "SKIPPED",
    "TIMED_OUT",
  ])("accepts the server status %s", async (status) => {
    fetchMock.mockResolvedValue(Response.json({ ...job, status }));

    await expect(getBuildJob(job.id, options)).resolves.toEqual({ ...job, status });
  });

  it.each([undefined, null, "queued", "COMPLETED", "", 1])(
    "rejects an invalid status: %j",
    async (status) => {
      fetchMock.mockResolvedValue(Response.json({ ...job, status }));

      await expect(getBuildJob(job.id, options)).rejects.toEqual(
        new InvalidBuildJobResponseError(job.id, "status is not a recognized BuildJobStatus"),
      );
    },
  );

  describe.each(["createdAt", "updatedAt"])("timestamp %s", (field) => {
    it.each([
      "not a date",
      "2026-09-05",
      "2026-09-05T00:00:00",
      "2026-13-01T00:00:00.000Z",
      "2026-02-30T00:00:00.000Z",
      "2026-09-05T24:00:00.000Z",
    ])("rejects %s", async (value) => {
      fetchMock.mockResolvedValue(Response.json({ ...job, [field]: value }));

      await expect(getBuildJob(job.id, options)).rejects.toEqual(
        new InvalidBuildJobResponseError(job.id, `${field} must be a valid UTC ISO timestamp`),
      );
    });
  });

  it.each(["", " \t", ".", ".."])(
    "rejects an invalid job ID before fetching: %j",
    async (jobId) => {
      await expect(getBuildJob(jobId, options)).rejects.toBeInstanceOf(TypeError);
      expect(fetchMock).not.toHaveBeenCalled();
    },
  );

  it.each(["", " ", "token\nvalue", " token"])(
    "rejects an invalid API key: %j",
    async (internalApiKey) => {
      await expect(getBuildJob(job.id, { ...options, internalApiKey })).rejects.toBeInstanceOf(
        TypeError,
      );
      expect(fetchMock).not.toHaveBeenCalled();
    },
  );

  it.each([0, -1, 1.5, NaN, Infinity, 2_147_483_648])(
    "rejects an invalid timeout: %j",
    async (timeoutMs) => {
      await expect(getBuildJob(job.id, { ...options, timeoutMs })).rejects.toBeInstanceOf(
        RangeError,
      );
      expect(fetchMock).not.toHaveBeenCalled();
    },
  );

  it.each([
    "",
    "/relative",
    "file:///tmp/openci",
    "ftp://openci.example",
    "https://user:password@openci.example",
    "https://openci.example?token=secret",
    "https://openci.example#fragment",
  ])("rejects an invalid server URL before fetching: %s", async (serverUrl) => {
    await expect(getBuildJob(job.id, { ...options, serverUrl })).rejects.toBeInstanceOf(TypeError);
    expect(fetchMock).not.toHaveBeenCalled();
  });

  it.each([false, true])(
    "aborts a real HTTP request (headers already sent: %s)",
    async (sendHeaders) => {
      fetchMock.mockImplementation(nativeFetch);
      let requestReceived = false;
      const server = createServer((_request, response) => {
        requestReceived = true;
        if (sendHeaders) {
          response.writeHead(200, { "Content-Type": "application/json" });
          response.write('{"id":');
        }
        // Deliberately never finish the response; the client must abort it.
      });
      server.listen(0, "127.0.0.1");
      await once(server, "listening");

      try {
        const address = server.address();
        if (address === null || typeof address === "string") {
          throw new Error("Test HTTP server has no TCP address");
        }
        await expect(
          getBuildJob(job.id, {
            ...options,
            serverUrl: `http://127.0.0.1:${address.port}`,
            timeoutMs: 1_000,
          }),
        ).rejects.toMatchObject({ name: "TimeoutError" });
        expect(requestReceived).toBe(true);
        expect(fetchMock).toHaveBeenCalledTimes(1);
      } finally {
        const closed = once(server, "close");
        server.close();
        server.closeAllConnections();
        await closed;
      }
    },
  );
});
