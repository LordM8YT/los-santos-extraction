# EasyAdmin Setup

EasyAdmin is installed as a third-party admin tool, not as part of the gameplay resources.

## Install Location

Clone EasyAdmin into:

```text
resources/[admin]/EasyAdmin
```

Pinned version:

```text
7.53
```

Pinned commit:

```text
d732e54626dc362dbd1e42121c0b243eacbf24e4
```

## Server Config

EasyAdmin is standalone and does not require MySQL.

```cfg
ensure EasyAdmin

setr ea_LanguageName "en"
setr ea_defaultKey "F7"
setr ea_enableSplash false
setr ea_enableReportScreenshots false

add_ace group.admin easyadmin allow
add_ace resource.EasyAdmin command allow
```

The menu opens with `/easyadmin` or F7.

`ea_enableReportScreenshots` is disabled because this project does not currently install `screenshot-basic`.

Project admin helpers are provided by `extraction_admin`:

- `/copycoords` or `/coords` copies the current position as `vec3(x, y, z)`.
- `/coords vec4` copies `vec4(x, y, z, heading)`.
- `/coords table` copies `{ x = ..., y = ..., z = ..., heading = ... }`.

These commands require the same `easyadmin` ACE permission.
