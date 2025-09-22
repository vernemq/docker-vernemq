# 🐋 VerneMQ (Open Source Build)

This repository is a fork of [vernemq/docker-vernemq](https://github.com/vernemq/docker-vernemq) with one key change:

The Dockerfile has been modified to **build VerneMQ from source** instead of downloading prebuilt binary tarballs that require a paid subscription.

As of right now, this is the version **v2.0.1**. After some other stable version is released, this repository will also be updated accordingly.

That means you can run VerneMQ entirely under its **Apache 2.0 license**, without hitting the subscription model.

---

## ✨ What’s different?

- **Original `docker-vernemq`:**  
  Downloads a precompiled VerneMQ binary tarball under EULA → requires a paid subscription.

- **This fork:**  
  Clones [vernemq/vernemq](https://github.com/vernemq/vernemq), runs `make rel` inside a build stage, and packages the result into a slim Debian runtime image.

No EULA, no subscription — just pure OSS VerneMQ.

If you are confused about the license usage, you can check out this [issue](https://github.com/vernemq/vernemq/issues/1487) for more information.

---

## ⚡ Is the performance really the same as the official version?

To compare the official version with this one, we used the following benchmarking tool and tested **locally**: [mqtt-benchmark](https://github.com/krylovsk/mqtt-benchmark).

### Benchmark configuration
```
clients = 100
messages_per_client = 10000
message_interval = 0 ms
publish_qos = 1
payload_size = 100 Byte
qos1_timeout = 60000 ms
```

### Results  
The numbers are **almost identical**:

| Metric                        | Our Version | Official Version |
|-------------------------------|-------------|------------------|
| Total Runtime (sec)           | 178.548     | 176.821          |
| Average Runtime (sec)         | 174.476     | 173.456          |
| Msg time mean (ms)            | 17.375      | 17.281           |
| Msg time std (ms)             | 0.373       | 0.275            |
| Average Bandwidth (msg/sec)   | **57.343**  | **57.667**       |
| Total Bandwidth (msg/sec)     | 5734.345    | 5766.739        |

Both versions achieve a **1.0 success ratio** and near-identical latency and throughput.  
The small differences fall within expected variance.

## ⬇️ Pull the image

```bash
docker pull ghcr.io/alpamayo-solutions/vernemq:latest
```

---

## ▶️ Run VerneMQ

Start a single-node broker with anonymous access enabled:

```bash
docker run -d --name vernemq \
  -p 1883:1883 \
  -p 8888:8888 \
  -e DOCKER_VERNEMQ_ALLOW_ANONYMOUS=on \
  ghcr.io/alpamayo-solutions/vernemq:latest
```

Check logs:

```bash
docker logs -f vernemq
```

---

⚠️ Notes

This fork is meant for OSS usage. If you prefer official, supported binaries, use the subscription-based images
.

---

📜 License

VerneMQ itself: Apache License 2.0

This Docker setup: same as upstream docker-vernemq
