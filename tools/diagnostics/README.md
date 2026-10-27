# Diagnóstico

Ferramentas pequenas usadas para medir o que estava (ou não) lento. Compile no Mac e rode no alvo
(x86_64).

## vtcheck — decode por hardware

```bash
clang -arch x86_64 -mmacosx-version-min=11.0 \
  -framework VideoToolbox -framework CoreMedia -o vtcheck vtcheck.c
./vtcheck
# H.264  hardware decode: SIM
# HEVC   hardware decode: SIM
# VP9    hardware decode: NAO
# AV1    hardware decode: NAO
```

## randread — IOPS 4K aleatório

```bash
clang -arch x86_64 -O2 -mmacosx-version-min=11.0 -o randread randread.c
dd if=/dev/zero of=/tmp/randtest.bin bs=1m count=2048
sudo purge
./randread /tmp/randtest.bin
rm -f /tmp/randtest.bin
```

> Use `dd`, não `mkfile -n`: `mkfile -n` cria arquivo **esparso** e a leitura vem da RAM (resultado
> falso de ~300k IOPS).

## displayinfo — modos e refresh

```bash
clang -arch x86_64 -mmacosx-version-min=11.0 \
  -framework CoreGraphics -framework CoreFoundation -o displayinfo displayinfo.c
./displayinfo
```

Neste driver o refresh pode aparecer `0.00 Hz`; o painel roda a 60 Hz.

## gpu_load — carga de compute Metal

```bash
clang -arch x86_64 -mmacosx-version-min=11.0 -fobjc-arc \
  -framework Metal -framework Foundation -o gpu_load gpu_load.m
./gpu_load
```

Use junto com `sudo powermetrics --samplers gpu_power`. No WEX a telemetria de P-state do GPU pode
reportar 0% mesmo sob carga; o throughput (`iters/s`) é o que importa.

## btscan — scan Bluetooth

```bash
clang -arch x86_64 -mmacosx-version-min=11.0 -fobjc-arc \
  -framework Foundation -framework IOBluetooth -o btscan btscan.m
./btscan
```

Se retornar `start=0xe00002e2` (`kIOReturnNotPermitted`), é **TCC de Bluetooth** (processo CLI/SSH
sem permissão). Pareie pelo Ajustes do Sistema; não é falha do controlador.
