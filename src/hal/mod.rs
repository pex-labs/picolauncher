#[cfg(any(target_os = "linux", target_os = "macos"))]
mod linux;
#[cfg(any(target_os = "linux", target_os = "macos"))]
pub use linux::*;

#[cfg(target_os = "windows")]
mod windows;
#[cfg(target_os = "windows")]
pub use windows::*;
