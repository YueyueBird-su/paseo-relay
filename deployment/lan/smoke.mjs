import assert from "node:assert/strict";
import { execFileSync, spawn } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";

const repo = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../..");
const archive = path.resolve(process.argv[2]);
const stage = fs.mkdtempSync(path.join(os.tmpdir(), "relay-package-smoke-"));
const isWindows = process.platform === "win32";
if (isWindows) {
	execFileSync("powershell.exe", ["-NoProfile", "-Command",
		"Expand-Archive -LiteralPath $env:PASEO_SMOKE_ARCHIVE -DestinationPath $env:PASEO_SMOKE_STAGE"], {
		env: {...process.env, PASEO_SMOKE_ARCHIVE: archive, PASEO_SMOKE_STAGE: stage},
	});
} else {
	execFileSync("tar", ["-xzf", archive, "-C", stage]);
}
const root = path.join(stage, fs.readdirSync(stage)[0]);
assert(!fs.existsSync(path.join(root, "release/releases/COOKIE")), "archive contains build cookie");
const launcher = path.join(root, isWindows ? "start.cmd" : "start.sh");
assert(fs.existsSync(launcher), `Missing platform launcher: ${launcher}`);
const env = {...process.env, PASEO_RELAY_HOST: "127.0.0.1", PASEO_RELAY_PORT: "4001", ERL_FLAGS: "+S 2:2"};
delete env.RELEASE_COOKIE;
delete env.RELEASE_DISTRIBUTION;
const log = fs.openSync(`${archive}.smoke.log`, "w");
const child = spawn(isWindows ? "cmd.exe" : "sh", isWindows ? ["/d", "/s", "/c", "start.cmd"] : [launcher], {
	cwd: root, env, detached: !isWindows, stdio: ["ignore", log, log], windowsHide: true,
});
try {
	const deadline = Date.now() + 40000;
	while (true) {
		try {
			const health = await fetch("http://127.0.0.1:4001/health", {signal: AbortSignal.timeout(1000)});
			assert.equal((await health.json()).status, "ok");
			break;
		} catch (error) {
			if (child.exitCode !== null || Date.now() > deadline) throw error;
			await new Promise((resolve) => setTimeout(resolve, 200));
		}
	}
	const result = await new Promise((resolve, reject) => {
		const load = spawn(process.execPath, [path.join(repo, "scripts/relay-load.mjs"),
			"--endpoints", "ws://127.0.0.1:4001/ws", "--server-id", "ci-package-smoke",
			"--scenario", "sustained", "--pairs", "2", "--duration", "2", "--rate", "5", "--cleanup-grace", "2"],
			{stdio: ["ignore", "pipe", "inherit"], timeout: 30000});
		let output = "";
		load.stdout.on("data", (chunk) => { output += chunk; });
		load.on("error", reject);
		load.on("close", (code) => {
			try { assert.equal(code, 0); resolve(JSON.parse(output)); } catch (error) { reject(error); }
		});
	});
	assert.equal(result.connection_successes, 5);
	for (const key of ["connection_failures", "frames_lost", "ordering_failures", "abnormal_closes", "cleanup_timeouts", "send_failures"]) assert.equal(result[key], 0, key);
	assert(result.frames_sent > 0);
	assert.equal(result.frames_sent, result.frames_received);
	console.log(`Package smoke passed: 5 connections, ${result.frames_received}/${result.frames_sent} frames`);
} finally {
	if (child.exitCode === null) {
		if (isWindows) {
			try { execFileSync("taskkill", ["/PID", String(child.pid), "/T", "/F"], {stdio: "ignore"}); } catch {}
		} else {
			process.kill(-child.pid, "SIGTERM");
		}
	}
	fs.closeSync(log);
}
