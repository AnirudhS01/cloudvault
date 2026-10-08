// Run: node test.mjs  (crypto round-trip + wrong-passphrase + tamper detection)
import assert from "node:assert";
import { newSalt, deriveKey, encrypt, decrypt } from "./web/crypto.js";
const salt = newSalt(), k = await deriveKey("correct horse battery", salt);
const entry = { site: "example.com", user: "me", pass: "p@ss" };
const e = await encrypt(k, entry);
assert.deepEqual(await decrypt(k, e), entry);
assert.ok(!JSON.stringify(e).includes("p@ss"), "plaintext leaked into ciphertext");
await assert.rejects(decrypt(await deriveKey("wrong", salt), e), "wrong passphrase must fail");
await assert.rejects(decrypt(k, { ...e, ct: (e.ct[0] === "A" ? "B" : "A") + e.ct.slice(1) }), "tamper must fail");
assert.notEqual((await encrypt(k, entry)).iv, e.iv, "IV must be fresh");
console.log("crypto ok");
