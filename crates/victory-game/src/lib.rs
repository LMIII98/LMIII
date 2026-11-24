//! Everything specific to Grand Theft Auto VI: its container formats, build
//! identities, and the hooks we place in its code (located by per-build
//! offsets or byte-pattern signatures). What may and may not be stored here
//! is defined in docs/asset-policy.md.

pub mod sgd5;

/// A specific build of the Grand Theft Auto VI executable we know how to run.
#[derive(Debug, Clone, Copy)]
pub struct KnownBuild {
    /// Our own label, e.g. "1.0.0 retail".
    pub label: &'static str,
    /// BLAKE3 of the original executable, hex.
    pub blake3: &'static str,
}

/// Builds we support.
pub const KNOWN_BUILDS: &[KnownBuild] = &[
    // The Xbox Series X|S build of 2026-12 (1.0.2.1): one PE32+ image of
    // 120,181,760 bytes importing `d3d12_xs.dll`, `xmem.dll`, `chad.dll`,
    // `xg_xs.dll`, `xapu.dll` and `XboxBvhBuilder.dll` among 68 DLLs.
    KnownBuild {
        label: "1.0.2.1 scarlett master",
        blake3: "b99f876b74d4a77f03af5f878223b27bd647b5c35a79d5decd9f716504239e93",
    },
];

/// Looks up a build by the BLAKE3 hash of its executable.
pub fn identify(blake3_hex: &str) -> Option<&'static KnownBuild> {
    KNOWN_BUILDS
        .iter()
        .find(|b| b.blake3.eq_ignore_ascii_case(blake3_hex))
}
