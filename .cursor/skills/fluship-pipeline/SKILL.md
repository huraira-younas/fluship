---
name: fluship-pipeline
description: Runs the Fluship release pipeline with a local picker, cache, logs, optional email and WhatsApp, cleanup, and fix-and-retry. Use when the user says run pipeline, ship, build AAB, APK, IPA, or references AGENTS.md.
---

# Fluship Pipeline

Read and obey [AGENTS.md](../../../AGENTS.md). That file is the protocol. Execute it step by step. Do not plan, invent steps, or open a second picker tab. Think only when a command fails, and only about that failure.

After every job, paste the progress board in chat before the next job. The user must see NOW / DONE / WAIT / FAIL / SKIP. Never keep the board only in tool output.

Never type the WhatsApp chat. `whatsapp_send.py` waits 5 seconds after open so the chat can load, even if WhatsApp was already open.
