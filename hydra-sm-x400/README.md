# Hydra Samsung SM-X400 Termux:X11 lane

This is an additive display lane for Project Hydra / KAI 9000 on Samsung SM-X400. It does not replace Termux:X11 core behavior.

The default display is `:1`, matching the existing Hydra/VNC display convention. Termux:X11 remains optional: the normal Samsung candidate can run with the WebView/localhost cockpit without X11.

## Commands

```bash
bash hydra-sm-x400/hydra-x11.sh status
bash hydra-sm-x400/hydra-x11.sh start
bash hydra-sm-x400/hydra-x11.sh open
bash hydra-sm-x400/hydra-x11.sh stop
```

Optional compatibility flags:

```bash
HYDRA_X11_LEGACY=1 bash hydra-sm-x400/hydra-x11.sh start
HYDRA_X11_FORCE_BGRA=1 bash hydra-sm-x400/hydra-x11.sh start
```

## Ownership rule

The wrapper records the PID it starts under `$HOME/.local/state/hydra-sm-x400-x11/`. `stop` checks `/proc/<pid>/cmdline` before sending SIGTERM. It does not use broad `pkill` behavior.

## Trust boundary

Termux:X11 is a display transport only. It does not grant Shizuku or root privileges. Stock/Knox development still prefers Shizuku started through ADB/Wireless debugging. Root/Sui remains a separate lab target.
