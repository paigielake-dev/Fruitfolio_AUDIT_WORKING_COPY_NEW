#!/usr/bin/env python3
"""Typecheck the real Swift MADLAD implementation against actual llama C headers.

A temporary Clang module exposes the checked-in headers on Linux. No C symbols
are stubbed or linked. Apple ABI, Metal and real inference still require Xcode.
"""
import argparse
import platform
from pathlib import Path
import subprocess
import tempfile


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--swiftc', default='swiftc')
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    with tempfile.TemporaryDirectory(prefix='fruitfolio-llama-api-') as temporary:
        work = Path(temporary)
        header = root / 'Fruitfolio/Frameworks/llama.framework/Headers/llama.h'
        (work / 'module.modulemap').write_text(f'module llama [system] {{\n header "{header}"\n export *\n}}\n')
        files = [root / 'Fruitfolio/Core/Translation' / name for name in [
            'FruitfolioMADLADModels.swift', 'FruitfolioModelChecksum.swift', 'FruitfolioLlamaBackend.swift', 'FruitfolioMADLADRuntime.swift']]
        includes = ['-I', str(work)]
        if platform.system() == 'Linux':
            if not Path('/usr/include/openssl/evp.h').is_file():
                parser.error('Linux checksum API verification requires system OpenSSL development headers')
            crypto = work / 'FruitfolioOpenSSL'
            crypto.mkdir()
            (crypto / 'shim.h').write_text('#include <openssl/evp.h>\n')
            (crypto / 'module.modulemap').write_text('module FruitfolioOpenSSL [system] { header "shim.h" export * }\n')
            includes += ['-I', str(crypto)]
        result = subprocess.run([args.swiftc, '-typecheck', '-swift-version', '5', '-module-name', 'FruitfolioTranslationAPI',
                                 *includes, '-module-cache-path', str(work / 'cache'), *map(str, files)])
        if result.returncode == 0:
            print('MADLAD Swift/C API typecheck passed. No Apple link or inference was performed.')
        return result.returncode

if __name__ == '__main__':
    raise SystemExit(main())
