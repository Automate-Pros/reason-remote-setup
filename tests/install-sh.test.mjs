// Tests for install.sh, the macOS installer. Run: node --test
//
// The installer is driven on any OS through its overrides: REASON_REMOTE_BUNDLE (a local zip
// instead of the download), REASON_REMOTE_ROOTS (instead of the two Remote folders) and
// REASON_REMOTE_OS (instead of uname). Real Reason and real IAC buses are the PR's manual test.
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { createHash, randomBytes } from "node:crypto";
import { existsSync, mkdirSync, mkdtempSync, readFileSync, readdirSync, rmSync, statSync, writeFileSync } from "node:fs";
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

const sha256 = (file) => createHash("sha256").update(readFileSync(file)).digest("hex");

/**
 * Runs install.sh. A local test bundle is accepted only with its checksum, the same way the
 * real download is accepted only when it matches the SHA-256 pinned in the script.
 */
function run(env, args = []) {
  const withSum = env.REASON_REMOTE_BUNDLE && !("REASON_REMOTE_BUNDLE_SHA256" in env) && existsSync(env.REASON_REMOTE_BUNDLE)
    ? { REASON_REMOTE_BUNDLE_SHA256: sha256(env.REASON_REMOTE_BUNDLE) }
    : {};
  const res = spawnSync("bash", [script, ...args], {
    encoding: "utf8",
    env: { PATH: process.env.PATH ?? "", HOME: tempDir(), REASON_REMOTE_OS: "Darwin", REASON_REMOTE_APPS_DIRS: fakeApps(), ...withSum, ...env },
  });
  return { status: res.status, out: `${res.stdout}${res.stderr}` };
}

/** An Applications folder holding (empty stand-ins for) the apps the installer looks for. */
function fakeApps(apps = ["Reason 13.app", "Elgato Stream Deck.app"]) {
  const dir = tempDir();
  for (const app of apps) mkdirSync(join(dir, app, "Contents"), { recursive: true });
  return dir;
}

const pinned = () => {
  const text = readFileSync(script, "utf8");
  return { tag: /^BUNDLE_TAG="([^"]+)"$/m.exec(text)?.[1], sum: /^BUNDLE_SHA256="([0-9a-f]{64})"$/m.exec(text)?.[1], text };
};

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
    const codec = join(root, "Codecs", "Lua Codecs", "Community");
    const maps = join(root, "Maps", "Community");
    mkdirSync(join(codec, "src"), { recursive: true });
    mkdirSync(maps, { recursive: true });
    for (const f of CODEC) writeFileSync(join(codec, f), "old");
    for (const f of ["Community Stream Deck+ Remote.remotemap", "Community Stream Deck+ Master.remotemap", "batch-scopes.remotemap.fragment"]) writeFileSync(join(maps, f), "old");
    const res = run({ REASON_REMOTE_BUNDLE: makeBundle(), REASON_REMOTE_ROOTS: root });
    assert.equal(res.status, 0, res.out);
    assert.ok(!existsSync(codec));
    assert.ok(!existsSync(maps));
  });

  it("removes only the old Automate Pros files from Community, never another maker's codec", () => {
    const root = tempDir();
    const codec = join(root, "Codecs", "Lua Codecs", "Community");
    const maps = join(root, "Maps", "Community");
    mkdirSync(codec, { recursive: true });
    mkdirSync(maps, { recursive: true });
    writeFileSync(join(codec, "StreamDeckPlusRemote.luacodec"), "old");
    writeFileSync(join(codec, "SomeoneElse.luacodec"), "keep");
    writeFileSync(join(maps, "Community Stream Deck+ Remote.remotemap"), "old");
    writeFileSync(join(maps, "Community Other Controller.remotemap"), "keep");
    const res = run({ REASON_REMOTE_BUNDLE: makeBundle(), REASON_REMOTE_ROOTS: root });
    assert.equal(res.status, 0, res.out);
    assert.ok(!existsSync(join(codec, "StreamDeckPlusRemote.luacodec")));
    assert.ok(!existsSync(join(maps, "Community Stream Deck+ Remote.remotemap")));
    assert.equal(readFileSync(join(codec, "SomeoneElse.luacodec"), "utf8"), "keep");
    assert.equal(readFileSync(join(maps, "Community Other Controller.remotemap"), "utf8"), "keep");
  });

  it("downloads a pinned release and pins its SHA-256", () => {
    const { tag, sum, text } = pinned();
    assert.match(tag ?? "", /^v\d+\.\d+\.\d+$/);
    assert.ok(sum, "BUNDLE_SHA256 must be a 64-hex SHA-256");
    assert.ok(text.includes('releases/download/$BUNDLE_TAG/reason-remote-setup.zip'), "must not download releases/latest");
    assert.ok(!/releases\/latest\/download/.test(text));
  });

  it("refuses a bundle whose SHA-256 does not match, and installs nothing", () => {
    const root = tempDir();
    const res = run({ REASON_REMOTE_BUNDLE: makeBundle(), REASON_REMOTE_BUNDLE_SHA256: "0".repeat(64), REASON_REMOTE_ROOTS: root });
    assert.equal(res.status, 1, res.out);
    assert.match(res.out, /SHA-256/);
    assert.ok(!existsSync(join(root, "Codecs")));
  });

  it("checks a local bundle against the pinned SHA-256 when no other checksum is given", () => {
    const root = tempDir();
    const res = run({ REASON_REMOTE_BUNDLE: makeBundle(), REASON_REMOTE_BUNDLE_SHA256: "", REASON_REMOTE_ROOTS: root });
    assert.equal(res.status, 1, res.out);
    assert.match(res.out, /SHA-256/);
    assert.ok(!existsSync(join(root, "Codecs")));
  });

  it("is safe to run twice: same files, still succeeds", () => {
    const root = tempDir();
    const bundle = makeBundle();
    assert.equal(run({ REASON_REMOTE_BUNDLE: bundle, REASON_REMOTE_ROOTS: root }).status, 0);
    const second = run({ REASON_REMOTE_BUNDLE: bundle, REASON_REMOTE_ROOTS: root });
    assert.equal(second.status, 0, second.out);
    assert.deepEqual(readdirSync(join(root, "Codecs", "Lua Codecs", "Automate Pros")).sort(), CODEC);
    assert.deepEqual(readdirSync(join(root, "Maps", "Automate Pros")).sort(), MAPS);
  });

  it("says clearly when Reason or the Stream Deck app is not installed, and still copies the files", () => {
    const root = tempDir();
    const res = run({ REASON_REMOTE_BUNDLE: makeBundle(), REASON_REMOTE_ROOTS: root, REASON_REMOTE_APPS_DIRS: fakeApps([]) });
    assert.equal(res.status, 0, res.out);
    assert.match(res.out, /Reason was not found/);
    assert.match(res.out, /Stream Deck app was not found/);
    assert.ok(existsSync(join(root, "Maps", "Automate Pros", "Automate Pros Stream Deck+ Remote.remotemap")));
  });

  it("finds Reason in its own folder (Reason 14 layout) and the Stream Deck app", () => {
    const res = run({ REASON_REMOTE_BUNDLE: makeBundle(), REASON_REMOTE_ROOTS: tempDir(), REASON_REMOTE_APPS_DIRS: fakeApps(["Reason 14/Reason 14.app", "Elgato Stream Deck.app"]) });
    assert.equal(res.status, 0, res.out);
    assert.doesNotMatch(res.out, /was not found/);
  });

  it("runs nothing until the whole script has arrived (a cut-off download does no harm)", () => {
    const lines = readFileSync(script, "utf8").trimEnd().split("\n");
    assert.equal(lines.at(-1), 'main "$@"');
    // Everything above the last line only defines things: no command runs at top level
    // except set, variable assignments and function definitions.
    const top = [];
    let depth = 0;
    for (const line of lines.slice(0, -1)) {
      if (/^\s*(#|$)/.test(line)) continue;
      if (depth === 0 && !/^(set -eu|[A-Z_][A-Z0-9_]*=|[a-z_][a-z0-9_]*\(\) \{)/.test(line)) top.push(line);
      if (/^[a-z_][a-z0-9_]*\(\) \{/.test(line)) depth++;
      if (/^\}$/.test(line)) depth--;
    }
    assert.deepEqual(top, []);
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
    // statSync, not `stat -c`: BSD stat on macOS has no -c.
    const nobody = Number(spawnSync("id", ["-u", "nobody"], { encoding: "utf8" }).stdout.trim());
    assert.equal(statSync(join(user, "Maps", "Automate Pros")).uid, nobody);
  });

  it("under sudo, also gives back the parent folders it had to create", { skip: process.getuid?.() !== 0 && "needs root" }, () => {
    // ~/Library/Application Support exists; Propellerhead Software/Remote/... may not yet.
    const support = tempDir();
    const root = join(support, "Propellerhead Software", "Remote");
    const res = run({ REASON_REMOTE_BUNDLE: makeBundle(), REASON_REMOTE_ROOTS: root, SUDO_USER: "nobody" });
    assert.equal(res.status, 0, res.out);
    const nobody = Number(spawnSync("id", ["-u", "nobody"], { encoding: "utf8" }).stdout.trim());
    for (const dir of [join(support, "Propellerhead Software"), root, join(root, "Codecs"), join(root, "Codecs", "Lua Codecs"), join(root, "Maps")]) {
      assert.equal(statSync(dir).uid, nobody, `${dir} should belong to the sudo user`);
    }
    for (const f of CODEC) assert.equal(statSync(join(root, "Codecs", "Lua Codecs", "Automate Pros", f)).uid, nobody, f);
    // The folder that already existed is left as it was.
    assert.equal(statSync(support).uid, 0);
  });

  it("cleans up its temporary folder", () => {
    const work = tempDir();
    const res = run({ REASON_REMOTE_BUNDLE: makeBundle(), REASON_REMOTE_ROOTS: tempDir(), TMPDIR: work });
    assert.equal(res.status, 0, res.out);
    assert.deepEqual(readdirSync(work), []);
  });
});
