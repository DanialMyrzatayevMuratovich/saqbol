# Diagrams

| Diagram | Source | Export |
|---|---|---|
| System context (C4 level 1) | [src/01-system-context.puml](src/01-system-context.puml) | [SVG](export/system-context.svg) · [PNG](export/system-context.png) |
| Use cases | [src/02-use-case.puml](src/02-use-case.puml) | [SVG](export/use-case.svg) · [PNG](export/use-case.png) |
| Components (draft) | [src/03-component.puml](src/03-component.puml) | [SVG](export/component.svg) · [PNG](export/component.png) |
| Sequence: SMS check | [src/04-sequence-sms-check.puml](src/04-sequence-sms-check.puml) | [SVG](export/sequence-sms-check.svg) · [PNG](export/sequence-sms-check.png) |
| Sequence: live call analysis | [src/05-sequence-live-call.puml](src/05-sequence-live-call.puml) | [SVG](export/sequence-live-call.svg) · [PNG](export/sequence-live-call.png) |
| Data model | [src/06-data-model.puml](src/06-data-model.puml) | [SVG](export/data-model.svg) · [PNG](export/data-model.png) |

The sources are plain-text [PlantUML](https://plantuml.com). They open in the PlantUML plugin for
VS Code or IntelliJ, or at https://www.plantuml.com/plantuml.

The system-context, component and live-call sequence diagrams describe the implementation at
`main` commit `91862dc`, including the Russian recogniser request (`ru_RU`), unverified speech
processing location and the separate call-session storage. Kazakh STT remains planned. These
are source-based diagrams, not evidence of completed device tests. See
[implementation evidence](../docs/implementation-evidence.md).

## Regenerate the exports

Requires Java 11+. Graphviz is not needed: the sources use the built-in `smetana` layout.

```bash
curl -LO https://repo1.maven.org/maven2/net/sourceforge/plantuml/plantuml/1.2026.7/plantuml-1.2026.7.jar
cd diagrams
java -jar ../plantuml-1.2026.7.jar -tsvg -o ../export src/*.puml
java -jar ../plantuml-1.2026.7.jar -tpng -o ../export src/*.puml
```

Output names come from each source's `@startuml` name, not its numbered filename. For the
three SAQ-86 corrections only, use these commands from `diagrams/` with the jar path adjusted
to your local download; the C4 context include comes from PlantUML's bundled standard library:

```bash
java -jar ../plantuml-1.2026.7.jar -tsvg -o ../export src/01-system-context.puml src/03-component.puml src/05-sequence-live-call.puml
java -jar ../plantuml-1.2026.7.jar -tpng -o ../export src/01-system-context.puml src/03-component.puml src/05-sequence-live-call.puml
```
