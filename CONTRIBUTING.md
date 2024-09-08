
<!--pex philosophy: _"everything is a cart"_-->

this page is a WIP

## Compiling

**PicoLauncher** needs to be built for a variety of targets, notably:
- linux x86_64
- linux arm
- windows (64-bit)

To compile for these platforms, we need to add the rust toolchains as well as install the respective cross compilers.
```sh
rustup target add x86_64-unknown-linux-gnu
rustup target add armv7-unknown-linux-gnueabihf
rustup target add x86_64-pc-windows-gnu
```

Another option is to use [cross-rs](https://github.com/cross-rs/cross), which you can install with
```sh
cargo install cross --git https://github.com/cross-rs/cross
```

### Troubleshooting

If you get any build errors during the cross compiling process, running
```sh
cargo clean
```
may resolve issues


