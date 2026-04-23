# Packet Scheduler

[![Documentation](https://img.shields.io/badge/Project%20Documentation-blue?style=flat&logo=googledocs&logoColor=white&labelColor=4285F4&color=blue)](https://docs.google.com/document/d/1tKyBlKo1QwEhdfcWfyFoxkVA3dFcelzm/edit)


Packet Scheduler is a hardware block designed to **collect, arbitrate, and order data packet requests** coming from **four independent clients** (`Client 0` ... `Client 3`).

It exposes the consolidated packet stream to a host processor/system through a standard **APB interface**.

## High-Level Functionality

The module receives traffic from multiple clients, temporarily buffers it, applies a configurable scheduling policy, and forwards the selected packets through a single output path.

In short, it acts as a configurable traffic arbitration engine.

## Client-Side Interface (REQ/ACK)

Client-to-scheduler data transfer is handled by a **Handler** block using a **Request/Acknowledge (REQ/ACK)** protocol.

- A client issues a request when data is available.
- The scheduler acknowledges accepted requests.
- Rejected/blocked transfers are reflected through status/error signaling (e.g., NACK conditions).

## Buffering Architecture

Each client has a dedicated input queue:

- `Queue 0`
- `Queue 1`
- `Queue 2`
- `Queue 3`

Incoming data is stored immediately in these per-client FIFO buffers. This isolates traffic sources and enables deterministic arbitration.

## Arbitration and Scheduling

An internal arbitration block continuously evaluates the input FIFOs and multiplexes selected packets into a single centralized **Output FIFO**.

Packet selection order is controlled by a configurable scheduling algorithm. The DUT supports three arbitration modes:

1. **Strict Priority (SP)**  
	Fixed priority order among clients.
2. **Round Robin (RR)**  
	Cyclic and fair distribution among active clients.
3. **Weighted Round Robin (WRR)**  
	Weighted distribution based on programmable per-client weights.

## APB Control and Monitoring

The host uses APB to both **consume data** and **configure behavior**:

- Read consolidated packets from the Output FIFO.
- Select the arbitration algorithm (`SP`, `RR`, `WRR`).
- Program WRR weights.
- Enable/disable each client independently.

The DUT also exposes runtime status via registers, including:

- FIFO full/empty indicators
- Transfer-related error conditions (including NACK-related events)
