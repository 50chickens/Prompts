Audio Performance Optimization
Zero-Copy: Direct device-to-device routing using shared memory buffers and reference passing.
Buffer Management: Ring buffers for smooth streaming, pre-allocated buffer pools, lock-free circular queues.
Thread Synchronization: One audio thread per device, lock-free message passing for coordination, SPSC queues for inter-thread communication.
Sample Rate Conversion: High-quality resampling with configurable quality vs latency trade-off, automatic rate detection and conversion.
