import Testing

/// Top-level serialized suite.
///
/// All child suites that share mutable state (Keychain keys, MockURLProtocol.requestHandler)
/// are nested under this type via extensions in their own files.
/// Swift Testing serializes all direct children of a `.serialized` suite, so nesting
/// here prevents cross-suite races without changing each suite's internal parallelism.
@Suite(.serialized)
struct FMSYSTests {}
