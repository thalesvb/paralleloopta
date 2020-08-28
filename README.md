# Paralleloopta

A simple object-oriented wrapper (with just a little bit of syntax sugar) for SPTA Framework (SAP Standard Parallel processing framework).

As many developers know, SPTA internally works with classes, but for unkown reasons SAP never released an OO API for it. You always have to rely on Function Module that enforces you to create a FORM (already obsolete). This wrapper still have one, but you will never need to create it again to use SPTA.

It was mainly developed for some mass ETL activities, but you can use for any other purpose.
Its current state is more like a PoC than a full fledged and robust wrapper, but still does it job nicely.

## Steps to use

Requires 7.40+ ABAP Stack because, but can be downported to older versions (PRs welcome).

1. Clone into system.
1. Create a class that implements interface ``zif_proota_parallel_code`` (it can be either a global or local class).
1. Feed it to a runner instance ``zcl_proota_parallel_runner``. You decide when it should start, or simply ignore and abort mission.
1. Profit.

You can alco check [``zproota_demo_01`` report][demo_report] for a working example.

## Other implementaions are also available

There are other implementations available (mentioned below), and the modern way to parallel things is by [bgRFC queues][bgrfc_queues], so this wrapper acts as a backup / cheap shot to save your day.

* https://blogs.sap.com/2013/07/16/parallel-abap-objects/
* https://blogs.sap.com/2019/03/19/parallel-processing-made-easy/

[bgrfc_queues]: help.sap.com/viewer/753088fc00704d0a80e7fbd6803c8adb/latest/en-US/489f05f8f7ec6bb9e10000000a42189d.html
[demo_report]: //github.com/thalesvb/paralleloopta/blob/master/src/zproota_demo_01.prog.abap
