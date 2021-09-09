# 9. Transactions

Date: 2021-09-09

## Status

Proposed

## Context

XTDB is a deterministic, dynamic document database. It doesn't (for
the foreseeable future) support interactive transactions. A
transaction is instead proposed asynchronously onto a central, totally
ordered log. The transaction might get rejected during processing. All
nodes process all transactions in parallel and must reach the same
result.

### Format

A transaction is composed of a series of operations executed in order.

Options:

1. EDN (classic): put/delete/evict and integrity checks via match + find.
2. SQL DML: insert/update/delete/evict and integrity checks via select.

Operations also need to be able to do bitemporal corrections.

## Decision

We will support EDN-style transactions to start.

As per the [data model](0002-data-model.md), the transactions are
converted to Arrow client side before submitted.

Integrity checks are done via queries and transaction functions should
not be supported by default. Transactions are proposed and can be
rejected.

## Consequences

Transactions must be fully deterministic as all nodes needs to reach
the same conclusion and also share the same object store.

If a transaction has committed could potentially be figured out via
querying the transaction id column.

SQL:2011 always assumes start/end time for corrections, while classic
supports calculating the end time if not given. The core needs to
support both.