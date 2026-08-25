---
name: fluship-pipeline
description: Runs the Fluship release pipeline with a local picker, cache, logs, optional email and WhatsApp, cleanup, and fix-and-retry. Use when the user says run pipeline, ship, build AAB, APK, IPA, or references AGENTS.md.
---

# Fluship Pipeline

Read and obey [AGENTS.md](../../../AGENTS.md). That file is the protocol. Execute it step by step at full speed. Do not plan, invent steps, or open a second picker tab.

Once the picker returns, stop thinking. Every job is run command, paste board, next job, with no deliberation in between. Reasoning is allowed only when a command fails or a required value is missing, and only about that one problem.

Slow jobs and the picker start in the background and get polled in 5 second checks until the terminal footer shows `exit_code`. Never sit on one long timer and never guess a duration.

After every job, paste the progress board in chat before the next job. The user must see NOW / DONE / WAIT / FAIL / SKIP as chat text. A board left in your reasoning or in tool output does not count as reported.

Never type the WhatsApp chat. `whatsapp_send.py` waits 5 seconds after open so the chat can load, even if WhatsApp was already open.
