# ADR 0006 — One badge renderer, no browser printing

**Status:** accepted

## Context

The predecessor had two: ReportLab server-side, and print CSS in the browser.
Geometry and card content were defined twice.

## Decision

ReportLab only. The browser gets a PDF preview in an iframe and uses its own
print dialog. `layouts.json` is generated from `layout.py` and asserted equal in
CI, so JavaScript can draw the selection grid without owning dimensions.

## Why

The CSS path could not reproduce per-line auto-shrink, so a long name printed
differently depending on which path you used. That is the failure that ruins a
sheet of Avery stock at 6pm the day before, when the shop is shut.

Two definitions of the same geometry drift. They had.

## What is kept

"See it before you print" — which is what staff actually wanted — via the PDF
preview. And the calibration sheet, which matters more than either: print one
blank on plain paper and hold it against a real sheet.
