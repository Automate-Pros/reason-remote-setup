// Tests for install.sh, the macOS installer. Run: node --test
//
// The installer is driven on any OS through its overrides: REASON_REMOTE_BUNDLE (a local zip
// instead of the download), REASON_REMOTE_ROOTS (instead of the two Remote folders) and
// REASON_REMOTE_OS (instead of uname). Real Reason and real IAC buses are the PR's manual test.
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { randomBytes } from "node:crypto";
import { existsSync, mkdirSync, mkdtempSync, readFileSync, readdirSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
import { after, describe, it } from "node:test";
import { fileURLToPath } from "node:url";

const repo = join(dirname(fileURLToPath(import.meta.url)), "..");
const script = join(repo, "install.sh");

const temps = [];
function tempDir() {
  const dir = mkdtempSync(join(tmpdir(), "rr-setup-sh-"));
  temps.push(dir);
  return dir;
}
after(() => {
  for (const dir of temps) rmSync(dir, { recursive: true, force: true });
});

const CODEC = ["StreamDeckPlusMaster.lua", "StreamDeckPlusMaster.luacodec", "StreamDeckPlusMaster.png", "StreamDeckPlusRemote.lua", "StreamDeckPlusRemote.luacodec", "StreamDeckPlusRemote.png"];
const MAPS = ["Automate Pros Stream Deck+ Master.remotemap", "Automate Pros Stream Deck+ Remote.remotemap", "batch-scopes.remotemap.fragment"];

/** A zip laid out like the published reason-remote-setup.zip. Random padding keeps it past the 10 KB floor once compressed. */
function makeBundle({ omitRemoteMap = false } = {}) {
  const stage = tempDir();
  const codec = join(stage, "Codecs", "Lua Codecs", "Automate Pros");
  const maps = join(stage, "Maps", "Automate Pros");
  mkdirSync(codec, { recursive: true });
  mkdirSync(maps, { recursive: true });
  for (const f of CODEC) writeFileSync(join(codec, f), f.endsWith(".lua") ? `-- ${f}\r\n-- ${randomBytes(6000).toString("hex")}\r\n` : f);
  for (const f of MAPS) if (!(omitRemoteMap && f.includes("Remote.remotemap"))) writeFileSync(join(maps, f), f);
  writeFileSync(join(stage, "install-remote.ps1"), "# pwsh installer");
  writeFileSync(join(stage, "README.md"), "# guide");
  const zip = join(tempDir(), "reason-remote-setup.zip");
  const res = spawnSync("zip", ["-qr", "-X", zip, "."], { cwd: stage });
  assert.equal(res.status, 0, "zip must be installed to run these tests");
  return zip;
}

function run(env, args = []) {
  const res = spawnSync("bash", [script, ...args], {
    encoding: "utf8",
    env: { PATH: process.env.PATH ?? "", HOME: tempDir(), REASON_REMOTE_OS: "Darwin", ...env },
  });
  return { status: res.status, out: `${res.stdout}${res.stderr}` };
}

describe("install.sh", () => {
  it("parses as bash and avoids what macOS's bash 3.2 lacks", () => {
    assert.equal(spawnSync("bash", ["-n", script]).status, 0);
    const code = readFileSync(script, "utf8").split("\n").filter((l) => !/^\s*#/.test(l)).join("\n");
    for (const banned of [/declare -A/, /\bmapfile\b/, /\breadarray\b/, /\$\{[a-zA-Z_]+,,\}/]) assert.doesNotMatch(code, banned);
  });

  it("says it is beta and untested on hardware", () => {
    const res = run({ REASON_REMOTE_BUNDLE: makeBundle(), REASON_REMOTE_ROOTS: tempDir() });
    assert.match(res.out, /beta, untested on Mac hardware/i);
  });

  it("installs codec and maps into both folders", () => {
    const a = join(tempDir(), "system");
    const b = join(tempDir(), "user");
    const res = run({ REASON_REMOTE_BUNDLE: makeBundle(), REASON_REMOTE_ROOTS: `${a}:${b}` });
    assert.equal(res.status, 0, res.out);
    for (const root of [a, b]) {
      assert.deepEqual(readdirSync(join(root, "Codecs", "Lua Codecs", "Automate Pros")).sort(), CODEC);
      assert.deepEqual(readdirSync(join(root, "Maps", "Automate Pros")).sort(), MAPS);
    }
    // Only Reason's files are installed, not the bundle's installer or guide.
    assert.ok(!existsSync(join(b, "install-remote.ps1")));
    assert.match(res.out, /Installed to .*user/);
  });

  it("removes the pre-1.1 Community surfaces", () => {
    const root = tempDir();
    mkdirSync(join(root, "Codecs", "Lua Codecs", "Community"), { recursive: true });
    mkdirSync(join(root, "Maps", "Community"), { recursive: true });
    const res = run({ REASON_REMOTE_BUNDLE: makeBundle(), REASON_REMOTE_ROOTS: root });
    assert.equal(res.status, 0, res.out);
    assert.ok(!existsSync(join(root, "Codecs", "Lua Codecs", "Community")));
    assert.ok(!existsSync(join(root, "Maps", "Community")));
  });

  it("skips the system folder without write access and still succeeds", () => {
    const user = tempDir();
    const res = run({ REASON_REMOTE_BUNDLE: makeBundle(), REASON_REMOTE_ROOTS: `/dev/null/system:${user}` });
    assert.equal(res.status, 0, res.out);
    assert.match(res.out, /Skipped \/dev\/null\/system/);
    assert.match(res.out, /sudo bash/);
    assert.ok(existsSync(join(user, "Maps", "Automate Pros", "Automate Pros Stream Deck+ Remote.remotemap")));
  });

  it("fails when nothing can be written", () => {
    const res = run({ REASON_REMOTE_BUNDLE: makeBundle(), REASON_REMOTE_ROOTS: "/dev/null/a:/dev/null/b" });
    assert.equal(res.status, 1);
    assert.match(res.out, /Could not install to any Reason Remote location/);
  });

  it("refuses a bundle without the Remote map rather than half-installing", () => {
    const root = tempDir();
    const res = run({ REASON_REMOTE_BUNDLE: makeBundle({ omitRemoteMap: true }), REASON_REMOTE_ROOTS: root });
    assert.equal(res.status, 1);
    assert.match(res.out, /not the setup bundle|missing/i);
    assert.ok(!existsSync(join(root, "Codecs")));
  });

  it("refuses a download too small to be the bundle (an error page)", () => {
    const tiny = join(tempDir(), "tiny.zip");
    writeFileSync(tiny, "<html>Not Found</html>");
    const res = run({ REASON_REMOTE_BUNDLE: tiny, REASON_REMOTE_ROOTS: tempDir() });
    assert.equal(res.status, 1);
    assert.match(res.out, /only \d+ bytes/);
  });

  it("prints the IAC Driver bus and Reason surface steps with the port names", () => {
    const res = run({ REASON_REMOTE_BUNDLE: makeBundle(), REASON_REMOTE_ROOTS: tempDir() });
    assert.match(res.out, /Show MIDI Studio/);
    assert.match(res.out, /Input Port:\s+IAC Driver Bus 1/);
    assert.match(res.out, /Output Port:\s+IAC Driver Bus 4/);
    assert.match(res.out, /Surface Locking/);
  });

  it("points Windows users at install.ps1", () => {
    const res = run({ REASON_REMOTE_OS: "MINGW64_NT-10.0", REASON_REMOTE_BUNDLE: makeBundle() });
    assert.equal(res.status, 1);
    assert.match(res.out, /install\.ps1/);
  });

  it("under sudo, gives the per-user copy back to the user who ran sudo", { skip: process.getuid?.() !== 0 && "needs root" }, () => {
    const user = tempDir();
    const res = run({ REASON_REMOTE_BUNDLE: makeBundle(), REASON_REMOTE_ROOTS: user, SUDO_USER: "nobody" });
    assert.equal(res.status, 0, res.out);
    const owner = spawnSync("stat", ["-c", "%U", join(user, "Maps", "Automate Pros")], { encoding: "utf8" }).stdout.trim();
    assert.equal(owner, "nobody");
  });

  it("cleans up its temporary folder", () => {
    const work = tempDir();
    const res = run({ REASON_REMOTE_BUNDLE: makeBundle(), REASON_REMOTE_ROOTS: tempDir(), TMPDIR: work });
    assert.equal(res.status, 0, res.out);
    assert.deepEqual(readdirSync(work), []);
  });
});
