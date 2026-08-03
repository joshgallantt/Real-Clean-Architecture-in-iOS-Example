# Working in this repository

Read the architecture rules before you write a file:

@.claude/architecture.md

That file is **generated from `keystone.json`** and must not be edited by hand. If a rule in it is
wrong, the manifest is wrong — change `keystone.json`, then run:

```bash
keystone --context > .claude/architecture.md
```

Run `keystone` before you hand work off. It reports only what your branch changed, and exits
non-zero if you introduced a violation. Every rule it applies is in the generated file above, with
the correction and the source it rests on.

The architecture, why it is shaped this way, and a walkthrough of one feature are in
[README.md](README.md) and [docs/architecture.md](docs/architecture.md).
