import {
	type IncusAsyncResponse,
	IncusAsyncResponseSchema,
	type IncusEnv,
	type IncusInstancesResponse,
	IncusInstancesResponseSchema,
	IncusOperationStatusSchema,
	type IncusProperty,
	IncusStatusSchema,
} from "../types/incus.types";

export type { IncusAsyncResponse, IncusInstancesResponse, IncusProperty };

export async function _fetchIncusInstances(
	envData: IncusEnv,
): Promise<IncusInstancesResponse> {
	const baseUrl = envData.server_url;
	const instanceUrl = `${baseUrl}/1.0/instances`;
	const cloudflareAccessHeaders = {
		"CF-Access-Client-Id": envData.cloudflare_access_client_id,
		"CF-Access-Client-Secret": envData.cloudflare_access_client_secret,
	};

	const recursionRes = await fetch(`${instanceUrl}?recursion=1`, {
		headers: cloudflareAccessHeaders,
	});

	if (!recursionRes.ok) {
		throw new Error(
			`Failed to fetch Incus instances: ${recursionRes.status} ${recursionRes.statusText}`,
		);
	}

	return IncusInstancesResponseSchema.parse(await recursionRes.json());
}

export async function fetchAvailableIncusInstances(
	envData: IncusEnv,
): Promise<IncusProperty[]> {
	const res = await _fetchIncusInstances(envData);
	return res.metadata.filter(
		(e) => e.status === IncusStatusSchema.enum.Stopped,
	);
}

export async function requestCreateInstance(
	envData: IncusEnv,
	instanceName: string,
	imageName: string,
): Promise<string | undefined> {
	const baseUrl = envData.server_url;
	const instanceUrl = `${baseUrl}/1.0/instances`;
	const cloudflareAccessHeaders = {
		"CF-Access-Client-Id": envData.cloudflare_access_client_id,
		"CF-Access-Client-Secret": envData.cloudflare_access_client_secret,
		"Content-Type": "application/json",
	};

	const requestBody = {
		config: {
			"limits.cpu": "8",
			"limits.memory": "16GB",
		},
		devices: {
			root: {
				path: "/",
				pool: "default",
				size: "100GB",
				type: "disk",
			},
		},
		name: instanceName,
		source: {
			alias: imageName,
			type: "image",
		},
		start: true,
		type: "virtual-machine",
	};

	const response = await fetch(instanceUrl, {
		body: JSON.stringify(requestBody),
		headers: cloudflareAccessHeaders,
		method: "POST",
	});

	if (!response.ok) {
		throw new Error(
			`Failed to create Incus instance: ${response.status} ${response.statusText}`,
		);
	}

	const result = IncusAsyncResponseSchema.parse(await response.json());

	if (result.type === "async") {
		const parts = result.operation.split("/");
		const operationId = parts[parts.length - 1];
		if (!operationId) {
			throw new Error(`Invalid operation path format: ${result.operation}`);
		}
		return operationId;
	}

	return undefined;
}

export async function createInstance(
	envData: IncusEnv,
	instanceName: string,
	imageName: string,
): Promise<void> {
	console.log("Incus instance creation initiated");

	const operationId = await requestCreateInstance(
		envData,
		instanceName,
		imageName,
	);

	if (operationId) {
		console.log(`Waiting for operation ${operationId} to complete...`);
		await waitForOperation(envData, operationId);
		console.log(`Operation ${operationId} completed successfully`);
	}
}

export async function stopInstance(
	envData: IncusEnv,
	instanceName: string,
): Promise<void> {
	console.log(`Stopping Incus instance: ${instanceName}`);

	const baseUrl = envData.server_url;
	const stateUrl = `${baseUrl}/1.0/instances/${instanceName}/state`;
	const cloudflareAccessHeaders = {
		"CF-Access-Client-Id": envData.cloudflare_access_client_id,
		"CF-Access-Client-Secret": envData.cloudflare_access_client_secret,
		"Content-Type": "application/json",
	};

	const requestBody = {
		action: "stop",
		force: true,
	};

	const response = await fetch(stateUrl, {
		body: JSON.stringify(requestBody),
		headers: cloudflareAccessHeaders,
		method: "PUT",
	});

	if (!response.ok) {
		throw new Error(
			`Failed to stop Incus instance: ${response.status} ${response.statusText}`,
		);
	}

	const result = IncusAsyncResponseSchema.parse(await response.json());

	if (result.type === "async") {
		const parts = result.operation.split("/");
		const operationId = parts[parts.length - 1];
		if (!operationId) {
			throw new Error(`Invalid operation path format: ${result.operation}`);
		}
		console.log(`Waiting for stop operation ${operationId} to complete...`);
		await waitForOperation(envData, operationId);
		console.log(`Instance ${instanceName} stopped successfully`);
	}
}

export async function deleteInstance(
	envData: IncusEnv,
	instanceName: string,
): Promise<void> {
	// Stop the instance first (required before deletion)
	await stopInstance(envData, instanceName);

	console.log(`Deleting Incus instance: ${instanceName}`);

	const baseUrl = envData.server_url;
	const instanceUrl = `${baseUrl}/1.0/instances/${instanceName}`;
	const cloudflareAccessHeaders = {
		"CF-Access-Client-Id": envData.cloudflare_access_client_id,
		"CF-Access-Client-Secret": envData.cloudflare_access_client_secret,
	};

	const response = await fetch(instanceUrl, {
		headers: cloudflareAccessHeaders,
		method: "DELETE",
	});

	if (!response.ok) {
		throw new Error(
			`Failed to delete Incus instance: ${response.status} ${response.statusText}`,
		);
	}

	const result = IncusAsyncResponseSchema.parse(await response.json());

	if (result.type === "async") {
		const parts = result.operation.split("/");
		const operationId = parts[parts.length - 1];
		if (!operationId) {
			throw new Error(`Invalid operation path format: ${result.operation}`);
		}
		console.log(`Waiting for delete operation ${operationId} to complete...`);
		await waitForOperation(envData, operationId);
		console.log(`Instance ${instanceName} deleted successfully`);
	}
}

export async function fetchStatusOfOperation(
	envData: IncusEnv,
	operationId: string,
): Promise<IncusAsyncResponse> {
	const baseUrl = envData.server_url;
	const operationUrl = `${baseUrl}/1.0/operations/${operationId}`;
	const cloudflareAccessHeaders = {
		"CF-Access-Client-Id": envData.cloudflare_access_client_id,
		"CF-Access-Client-Secret": envData.cloudflare_access_client_secret,
	};

	const response = await fetch(operationUrl, {
		headers: cloudflareAccessHeaders,
	});

	if (!response.ok) {
		throw new Error(
			`Failed to check operation status: ${response.status} ${response.statusText}`,
		);
	}

	return IncusAsyncResponseSchema.parse(await response.json());
}

export async function waitForOperation(
	envData: IncusEnv,
	operationId: string,
	maxWaitMs = 5 * 60 * 1000,
	intervalMs = 2000,
): Promise<void> {
	const startTime = Date.now();

	while (Date.now() - startTime < maxWaitMs) {
		const result = await fetchStatusOfOperation(envData, operationId);
		const status = result.metadata?.status;
		const statusCode = result.metadata?.status_code;

		console.log(`Operation status: ${status} (code: ${statusCode})`);

		if (
			status === IncusOperationStatusSchema.enum.Success ||
			statusCode === 200
		) {
			return;
		}

		if (
			status === IncusOperationStatusSchema.enum.Failure ||
			status === IncusOperationStatusSchema.enum.Cancelled ||
			(statusCode && statusCode >= 400)
		) {
			throw new Error(`Operation failed: ${result.metadata?.err}`);
		}

		await new Promise((resolve) => setTimeout(resolve, intervalMs));
	}

	throw new Error(`Operation timed out after ${maxWaitMs / 1000} seconds`);
}

export async function waitForVMAgent(
	envData: IncusEnv,
	instanceName: string,
	maxWaitMs = 2 * 60 * 1000,
): Promise<void> {
	console.log(
		`Waiting for VM agent to be ready in instance ${instanceName}...`,
	);

	const baseUrl = envData.server_url;
	const stateUrl = `${baseUrl}/1.0/instances/${instanceName}/state`;
	const cloudflareAccessHeaders = {
		"CF-Access-Client-Id": envData.cloudflare_access_client_id,
		"CF-Access-Client-Secret": envData.cloudflare_access_client_secret,
	};

	const startTime = Date.now();
	let checkCount = 0;

	// Cloudflare Workersのアイドルタイムアウト対策：setTimeoutの代わりにfetchでポーリング
	while (Date.now() - startTime < maxWaitMs) {
		const response = await fetch(stateUrl, {
			headers: cloudflareAccessHeaders,
		});

		if (response.ok) {
			const result = (await response.json()) as {
				metadata?: { processes?: number };
			};
			const processes = result.metadata?.processes;
			if (processes !== undefined && processes !== -1) {
				console.log(`VM agent is ready in instance ${instanceName}`);
				return;
			}
		}

		checkCount++;
		if (checkCount % 10 === 0) {
			console.log(
				`Still waiting for VM agent... (${Math.round((Date.now() - startTime) / 1000)}s elapsed)`,
			);
		}

		// 短い間隔でポーリング（I/Oアクティビティを維持）
		await new Promise((resolve) => setTimeout(resolve, 1000));
	}

	throw new Error(
		`VM agent did not become ready within ${maxWaitMs / 1000} seconds`,
	);
}

export async function execCommand(
	envData: IncusEnv,
	instanceName: string,
	command: string[],
	options?: { cwd?: string; environment?: Record<string, string> },
): Promise<void> {
	console.log(
		`Executing command in instance ${instanceName}: ${command.join(" ")}`,
	);

	const baseUrl = envData.server_url;
	const execUrl = `${baseUrl}/1.0/instances/${instanceName}/exec`;
	const cloudflareAccessHeaders = {
		"CF-Access-Client-Id": envData.cloudflare_access_client_id,
		"CF-Access-Client-Secret": envData.cloudflare_access_client_secret,
		"Content-Type": "application/json",
	};

	const requestBody = {
		command,
		cwd: options?.cwd,
		environment: options?.environment ?? {},
		interactive: false,
		"record-output": true,
		"wait-for-websocket": false,
	};

	const response = await fetch(execUrl, {
		body: JSON.stringify(requestBody),
		headers: cloudflareAccessHeaders,
		method: "POST",
	});

	if (!response.ok) {
		throw new Error(
			`Failed to execute command in Incus instance: ${response.status} ${response.statusText}`,
		);
	}

	const result = IncusAsyncResponseSchema.parse(await response.json());

	if (result.type === "async") {
		const parts = result.operation.split("/");
		const operationId = parts[parts.length - 1];
		if (!operationId) {
			throw new Error(`Invalid operation path format: ${result.operation}`);
		}
		console.log(`Waiting for exec operation ${operationId} to complete...`);
		await waitForOperation(envData, operationId);
		console.log(`Command executed successfully in instance ${instanceName}`);
	}
}
