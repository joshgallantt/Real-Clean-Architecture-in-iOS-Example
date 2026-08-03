# Working in this repository

The architecture rules live in `keystone.json` and nowhere else. There is no generated copy of
them in this repository, on purpose: a copy is a thing that can fall behind the manifest the
checker actually reads, while still reading as authoritative.

Install the hook once, per clone:

```bash
keystone --add-to-claude
```

From then on every session opens with the rules already in context, generated from the manifest,
and every Write and Edit is checked against them before it lands. A write that breaks a rule is
refused, and the refusal carries the correction and the source it rests on.

If a rule is wrong, the manifest is wrong — change `keystone.json`. Nothing else needs
regenerating.

Run `keystone` before you hand work off. It reports only what your branch changed, and exits
non-zero if you introduced a violation.

The architecture, why it is shaped this way, and a walkthrough of one feature are in
[README.md](README.md) and [docs/architecture.md](docs/architecture.md).
