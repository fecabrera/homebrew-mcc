class Mcc < Formula
  include Language::Python::Virtualenv

  desc "Small, modern-C-style language compiled to native code via LLVM"
  homepage "https://github.com/fecabrera/mcc"
  url "https://github.com/fecabrera/mcc/archive/refs/tags/v0.1.2.tar.gz"
  sha256 "6fe85131bb7aa1c2e429af3430b7bec6bfec04967cf813a25b9d11a16a58e1e8"
  license "BSD-3-Clause"

  depends_on "python@3.14"

  # llvmlite ships only as a prebuilt wheel that bundles a matching LLVM;
  # building it from source needs a specific, pinned LLVM that won't match
  # Homebrew's `llvm`. Declare the per-platform wheel as a resource so Homebrew
  # fetches it before the (network-less) build sandbox, then install it below.
  # No cp314 macOS x86_64 wheel is published, so Intel macs are unsupported.
  on_macos do
    on_arm do
      resource "llvmlite" do
        url "https://files.pythonhosted.org/packages/1c/d4/33c8af00f0bf6f552d74f3a054f648af2c5bc6bece97972f3bfadce4f5ec/llvmlite-0.47.0-cp314-cp314-macosx_12_0_arm64.whl"
        sha256 "de966c626c35c9dff5ae7bf12db25637738d0df83fc370cf793bc94d43d92d14"
      end
    end
  end

  on_linux do
    on_intel do
      resource "llvmlite" do
        url "https://files.pythonhosted.org/packages/64/1d/a760e993e0c0ba6db38d46b9f48f6c7dceb8ac838824997fb9e25f97bc04/llvmlite-0.47.0-cp314-cp314-manylinux2014_x86_64.manylinux_2_17_x86_64.whl"
        sha256 "ddbccff2aeaff8670368340a158abefc032fe9b3ccf7d9c496639263d00151aa"
      end
    end
    on_arm do
      resource "llvmlite" do
        url "https://files.pythonhosted.org/packages/84/3b/e679bc3b29127182a7f4aa2d2e9e5bea42adb93fb840484147d59c236299/llvmlite-0.47.0-cp314-cp314-manylinux_2_27_aarch64.manylinux_2_28_aarch64.whl"
        sha256 "d4a7b778a2e144fc64468fb9bf509ac1226c9813a00b4d7afea5d988c4e22fca"
      end
    end
  end

  def install
    venv = virtualenv_create(libexec, "python3.14")

    # Install the pre-fetched llvmlite wheel with the venv's own python. We
    # can't route it through venv.pip_install: that passes --no-binary=:all:
    # (which rejects a prebuilt wheel) and would extract this platform wheel
    # rather than install it. The venv is --system-site-packages, so its
    # python can import pip; the wheel is a local file, so no network is used.
    # Copy to the canonical wheel filename first — Homebrew's cache prefixes a
    # checksum (<sha>--…) that breaks pip's strict wheel-name parsing.
    wheel = buildpath/File.basename(resource("llvmlite").url)
    cp resource("llvmlite").cached_download, wheel
    system libexec/"bin/python", "-m", "pip", "install", "--no-deps",
           "--no-index", wheel

    # Install mcc itself and link the `mcc` script into bin. Homebrew passes
    # --no-deps here, so the already-present llvmlite satisfies the dependency
    # without touching the (unavailable) network.
    venv.pip_install_and_link buildpath
  end

  test do
    (testpath/"hi.mc").write <<~MC
      import "libc/stdio";
      fn main() -> int32 { printf("hi\\n"); return 0; }
    MC

    # JIT path exercises codegen + the bundled standard library.
    assert_equal "hi", shell_output("#{bin}/mcc #{testpath}/hi.mc --run").strip

    # Native path exercises object emission and linking with cc.
    system bin/"mcc", testpath/"hi.mc", "-o", testpath/"hi"
    assert_equal "hi", shell_output(testpath/"hi").strip
  end
end
