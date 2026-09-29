# am-message-brokers

Domain status: decision only (no playbook files yet)

## Purpose

Message brokers that services actually publish to. Each broker is its own playbook. The playbooks are separate and can be used together.

## Playbook

- `rabbitmq/`
  - One guest
  - RabbitMQ as a systemd service
  - A cluster is a later change inside this playbook
- `kafka/`
  - Three broker guests
  - Kafka as a systemd service, KRaft mode, so there is no ZooKeeper guest

## Alternatives

- NATS.

## Left out

- NATS
- Streams on the cache. The cache stays in `al-data-caching/redis`

## Dependencies

- Upstream: `ac-vm-provisioning` creates the guests, then `ag-os-baseline-and-hardening`
- Downstream: applications that publish or subscribe

## Status

- Playbook files: no
- Guests: one for RabbitMQ, three for Kafka, created by `kvm-vm-provisioning`
