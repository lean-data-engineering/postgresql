# 🌀 Understanding Streaming

**streaming** means processing data continuously and in real time, rather than waiting for an entire file or dataset to download or load completely.

Think of it like water:

- **Batch Processing (The Opposite):** This is like filling a bucket of water from a tap, carrying it across the room, and dumping it into a tub all at once. You must wait for the bucket to be full before you can use any of it.
- **Streaming:** This is like using a hose. Water flows continuously, and you use it the exact millisecond it arrives.

## Key Types of Streaming

- **Media Streaming (Netflix/Spotify):** The server sends a video file in tiny, sequential chunks. Your device plays the chunks immediately while downloading the next ones. You do not have to wait for the whole 2 GB movie to download before watching.
- **Data/Stream Processing (Kafka/Flink):** Applications analyze data as it is generated. Examples include tracking live financial stock tickers, monitoring credit card fraud instantly, or capturing real-time GPS locations of delivery drivers.
