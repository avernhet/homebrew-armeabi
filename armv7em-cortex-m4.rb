class Armv7emCortexM4 < Formula
  desc "Newlib & compiler runtime for baremetal Cortex-M4 targets"
  homepage "https://sourceware.org/newlib/"
  # and homepage "http://compiler-rt.llvm.org/"

  stable do
    # This is kinda stupid to use this URL as the recipe base URL, but
    # Homebrew insists to be asymetric with resources.
    url "https://gist.githubusercontent.com/eblot/d0d2db95e1d0aa4a36deb1e46d61382c/raw/00bb3af1f74ee0f27afb0e5e9ce7ee4fedcefe28/CMakeLists.txt"
    sha256 "578874c9cedecca03a96a134389534a5922ba4362c0a883cdfb2de554a415901"
    # Follow LLVM/compiler RT versionning (Homebrew wants a version here)
    version "5.0.0"

    resource "newlib" do
      url "https://github.com/eblot/newlib-cygwin.git", :branch => "clang-armeabi-20170818"
    end

    resource "compiler-rt" do
      url "https://releases.llvm.org/5.0.0/compiler-rt-5.0.0.src.tar.xz"
      sha256 "d5ad5266462134a482b381f1f8115b6cad3473741b3bb7d1acc7f69fd0f0c0b3"
    end
  end

  depends_on "arm-none-eabi-llvm" => :build
  depends_on "cmake" => :build
  depends_on "ninja" => :build

  def install
    llvm = Formulary.factory 'arm-none-eabi-llvm'

    (buildpath/"newlib").install resource("newlib")
    (buildpath/"compiler-rt").install resource("compiler-rt")

    ENV.append_path "PATH", "#{llvm.opt_prefix}/bin"

    ENV['CC_FOR_TARGET']="#{llvm.opt_prefix}/bin/clang"
    ENV['AR_FOR_TARGET']="#{llvm.opt_prefix}/bin/llvm-ar"
    ENV['NM_FOR_TARGET']="#{llvm.opt_prefix}/bin/llvm-nm"
    ENV['RANLIB_FOR_TARGET']="#{llvm.opt_prefix}/bin/llvm-ranlib"
    ENV['READELF_FOR_TARGET']="#{llvm.opt_prefix}/bin/llvm-readelf"
    ENV['CFLAGS_FOR_TARGET']="-target armv7em-none-eabi -mcpu=cortex-m4 -mfloat-abi=soft -mthumb -mabi=aapcs -g -O3 -ffunction-sections -fdata-sections -Wno-unused-command-line-argument"
    ENV['AS_FOR_TARGET']="#{llvm.opt_prefix}/bin/clang"

    host=`cc -dumpmachine`.strip

    mktemp do
      system buildpath/"newlib/configure",
                "--host=#{host}",
                "--build=#{host}",
                "--target=armv7em-none-eabi",
                "--prefix=#{prefix}/armv7em-none-eabi/cortex-m4",
                "--disable-newlib-supplied-syscalls",
                "--enable-newlib-reent-small",
                "--disable-newlib-fvwrite-in-streamio",
                "--disable-newlib-fseek-optimization",
                "--disable-newlib-wide-orient",
                "--enable-newlib-nano-malloc",
                "--disable-newlib-unbuf-stream-opt",
                "--enable-lite-exit",
                "--enable-newlib-global-atexit",
                "--enable-newlib-nano-formatted-io",
                "--disable-nls"
      system "make"
      system "make -j1 install; true"
      system "mv #{prefix}/armv7em-none-eabi/cortex-m4/armv7em-none-eabi/* #{prefix}/armv7em-none-eabi/cortex-m4/"
      system "rm -rf #{prefix}/armv7em-none-eabi/cortex-m4/armv7em-none-eabi"
    end

    mktemp do
      # custom CMakeLists.txt not installed as a resource, so duplicate it for
      # the sake of simplicity. Did I write I hate ruby as a language?
      mkdir_p "#{buildpath}/compiler-rt/cortex-m"
      cp "#{buildpath}/CMakeLists.txt", "#{buildpath}/compiler-rt/cortex-m/CMakeLists.txt"
      system "cmake",
                "-G", "Ninja",
                "-DXTARGET=armv7em-none-eabi",
                "-DXCPU=cortex-m4",
                "-DXCPUDIR=cortex-m4",
                "-DXCFLAGS=-mfloat-abi=soft",
                "-DXNEWLIB=#{prefix}/armv7em-none-eabi/cortex-m4",
                 buildpath/"compiler-rt/cortex-m"
      system "ninja"
      system "cp libcompiler_rt.a #{prefix}/armv7em-none-eabi/cortex-m4/lib/"
    end
  end

end