# homebrew-mcc

A [Homebrew](https://brew.sh) tap for [mcc](https://github.com/fecabrera/mcc),
a small, modern-C-style language compiled to native code via LLVM.

## Install

```bash
brew install fecabrera/mcc/mcc
```

Or tap first, then install:

```bash
brew tap fecabrera/mcc
brew install mcc
```

## Updating the formula for a new release

1. Tag and push the release in the `mcc` repo:

   ```bash
   git tag v0.1.0 && git push origin v0.1.0
   ```

2. Compute the source tarball's checksum:

   ```bash
   curl -sL https://github.com/fecabrera/mcc/archive/refs/tags/v0.1.0.tar.gz \
     | shasum -a 256
   ```

3. Update `url` and `sha256` in [Formula/mcc.rb](Formula/mcc.rb).

4. Verify locally:

   ```bash
   brew install --build-from-source ./Formula/mcc.rb
   brew test mcc
   brew audit --strict --new mcc
   ```
