---
name: fluship-pipeline
description: Runs the Fluship release pipeline with a local picker, cache, logs, optional email and WhatsApp, cleanup, and fix-and-retry. Use when the user says run pipeline, ship, build AAB, APK, IPA, or references AGENTS.md.
---

# Fluship Pipeline

Read and obey [AGENTS.md](../../../AGENTS.md). That file is the protocol. Execute it step by step at full speed. Do not plan or invent steps.

Once the picker returns, stop thinking. Every job is run command, paste board, next job. Reasoning is only for a command that failed or a value that is missing.

Slow jobs and the picker run in the background and get polled in 5 second checks until the footer shows `exit_code`. Never guess a duration.

Paste the board into your own reply after every job, in a fenced code block. Running `pipeline_progress.dart` is not printing it: tool output sits in a collapsed block the user has to click open, and reasoning is never shown. The user must read NOW / DONE / WAIT / FAIL / SKIP as chat text every time.

Never touch the picker tab and never type into the WhatsApp chat.
