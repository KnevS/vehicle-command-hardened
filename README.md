# vehicle-command-hardened

Gehärteter Build von Teslas `tesla-http-proxy` aus
[teslamotors/vehicle-command](https://github.com/teslamotors/vehicle-command).
Der Proxy signiert Fahrzeugbefehle für die Tesla Fleet API.

## Warum

Das offizielle Image `tesla/vehicle-command` (Stand 0.4.1) wird mit `golang:1.23.0` auf
`distroless/base-debian12` gebaut. Ein Trivy-Scan meldete darin 8 kritische und 180 hohe,
behebbare Lücken (Go-Standardbibliothek, libssl).

Dieser Build verwendet **denselben Quellcode** (fester Upstream-Commit), aber:

- aktuelles Go,
- statisch gelinkt (`CGO_ENABLED=0`) auf `distroless/static-debian12:nonroot` – ohne libc und libssl,
- nur das Proxy-Binary,
- Basis-Images und GitHub Actions per Digest bzw. Commit-SHA gepinnt.

## Image

```
ghcr.io/knevs/vehicle-command-hardened:stable
ghcr.io/knevs/vehicle-command-hardened:<upstream>-go<version>   # z. B. 0.4.1-go1.27.3
```

Direkter Ersatz für `tesla/vehicle-command` – gleicher Entrypoint `tesla-http-proxy`, gleiche Optionen.

## Ablauf

- CI baut bei jedem Push, jedem PR und wöchentlich neu.
- Ein Funktionstest prüft, dass das Binary startet und die erwarteten Optionen kennt.
- **Trivy-Gate:** Enthält das Image behebbare HIGH- oder CRITICAL-Lücken, wird nichts veröffentlicht.
- Dependabot hält Basis-Images und Actions aktuell.

Upstream-Version wechseln: `UPSTREAM_TAG` und `UPSTREAM_COMMIT` im `Dockerfile` gemeinsam anpassen.
Der Build bricht ab, wenn der Tag nicht (mehr) auf den erwarteten Commit zeigt.

## Lizenz

Der gebaute Code stammt von Tesla, Inc. und steht unter der Apache License 2.0
(siehe Upstream-Repository). Dieses Repository enthält nur die Build-Beschreibung.
