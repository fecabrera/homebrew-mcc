class Mcc < Formula
  include Language::Python::Virtualenv

  desc "Small, modern-C-style language compiled to native code via LLVM"
  homepage "https://github.com/fecabrera/mcc"
  url "https://github.com/fecabrera/mcc/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "REPLACE_WITH_TARBALL_SHA256"
  license "BSD-3-Clause"

  depends_on "python@3.14"

  def install
    venv = virtualenv_create(libexec, "python3.14")

    # llvmlite ships prebuilt wheels that bundle a matching LLVM. Building it
    # from source needs a specific, pinned LLVM that won't match Homebrew's
    # `llvm`, so install the wheel instead of letting pip build the sdist.
    system venv.root/"bin/pip", "install", "--only-binary=:all:", "llvmlite"

    # Install mcc itself (and link the `mcc` script into bin); its llvmlite
    # dependency is already satisfied by the line above.
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
