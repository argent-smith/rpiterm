[![argent-smith](https://circleci.com/gh/argent-smith/rpiterm.svg?style=shield)](https://circleci.com/gh/argent-smith/rpiterm)

## What?
Simple temperature Prometheus reporter for Raspberry Pi.

## Why?
Because node_exporter can't. Also, lmsensors can't.

## Usage

### Embedded docs

```bash
rpiterm --help
```

### Deploying a working thermometer

```bash
rpiterm --listen-prometheus=9101
```

### Choosing a thermometer file
You can choose the system's thermometer file via the coresponding cli key as described in self-documenation:

```
-f VAL, --thermometer-file=VAL
(absent=/sys/class/thermal/thermal_zone0/temp or THERMOMETER_FILE env)
    Optional file containing the system thermometer data.
```

### Mirage version note

In MirageOS, the embedded logger logs to STDOUT. It's normal. Just grin and bear it.

### Docker images
[argentoff/rpiterm](https://hub.docker.com/r/argentoff/rpiterm/)

## License
MIT

## Author
Pavel Argentov (argentoff@gmail.com)
