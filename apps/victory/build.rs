//! Deploy the DirectX 12 Agility SDK with our binary.
//!
//! Windows uses an app-local `D3D12\D3D12Core.dll` only when the executable
//! exports `D3D12SDKVersion` and `D3D12SDKPath`, and that runtime is what
//! brings the D3D12 debug layer (`d3d12SDKLayers.dll`) this machine's Windows
//! install lacks. The two are data, so their names go in a module definition
//! file — the one export form both linkers accept (`--export-all-symbols`
//! breaks the image, and the GNU linker has no per-symbol data export).

fn main() {
    println!("cargo:rerun-if-changed=victory.def");
    if std::env::var("CARGO_CFG_TARGET_OS").as_deref() != Ok("windows") {
        return;
    }
    let def = std::path::Path::new(&std::env::var("CARGO_MANIFEST_DIR").unwrap())
        .join("victory.def");
    if !def.is_file() {
        return;
    }
    match std::env::var("CARGO_CFG_TARGET_ENV").as_deref() {
        Ok("msvc") => println!("cargo:rustc-link-arg-bins=/DEF:{}", def.display()),
        // Under the GNU driver a definition file is handed to the linker as an
        // input; it produces an image Windows will not start, so it is only
        // used where it works.
        _ => {}
    }
}
