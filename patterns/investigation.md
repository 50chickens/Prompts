# Investigation rules

Applies to establishing a fact about a vendor format, a device, or a platform.

A vendor figure that shows an instruction format tells you which bits carry which field. It does not tell you the discriminator. Constant bits in such a figure are frequently a sample encoding, and the same row of digits can appear for several different types in the same chapter, so a figure that repeats a pattern across three types is evidence that the pattern is a sample, not that the three share an opcode. Take a discriminator from a type-opcode table, or from a second figure that differs.

When two vendor documents disagree, establish first whether they document the same part family. A program reference for one family can look authoritative while encoding a different instruction set, and using it to correct the manual for the part in hand imports another chip's numbering without a symptom.

Two documents that disagree are not a tie to be broken by preference, and one is not thereby wrong. Record both readings with their coordinates and say what evidence would decide between them. A model row is not evidence: a constant that decodes plausibly and executes is the worst case rather than the best, because a wrong discriminator that falls through to a neighbouring form produces no refusal and no message.

Prefer the documented interface. A feature that needs reverse-engineered structures, unpublished payloads or unobtainable symbols costs more to deliver and more to support than it returns, and it makes the tool depend on an interior that can change without notice. Prefer a package over a private implementation.

Do not hardcode a machine identifier where it can be resolved. A COM port, device path, control index or bus address belongs to the machine at the time of the run, so it is discovered by matching the device through its own identity and never written into configuration, source or documentation as if it were stable.

Observing a device and owning it are different permissions. Where an interface is held exclusively by another application, reading it is not an option and the attempt fails in a way that looks like a permissions problem. Capture the transport underneath it, or ask the application to produce the traffic, and say which of the two the tool does.
