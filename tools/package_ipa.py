"""Package a signed iOS bundle directly into IPA without a second .app directory."""
import argparse
from pathlib import Path
import stat
import plistlib
import subprocess
import zipfile


def package(app, output):
    app = app.resolve()
    if not (app / 'Info.plist').is_file() or (app / 'Contents').exists():
        raise ValueError('Expected a device iOS application bundle')
    metadata = plistlib.loads((app / 'Info.plist').read_bytes())
    if 'iPhoneOS' not in metadata.get('CFBundleSupportedPlatforms', []):
        raise ValueError('IPA packaging requires a device build, not a simulator build')
    subprocess.run(['codesign', '--verify', '--deep', '--strict', str(app)], check=True)
    output.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(output, 'w', zipfile.ZIP_DEFLATED) as archive:
        for path in sorted(app.rglob('*')):
            name = 'Payload/' + app.name + '/' + str(path.relative_to(app))
            if path.is_symlink():
                info = zipfile.ZipInfo(name)
                info.create_system = 3
                info.external_attr = (stat.S_IFLNK | 0o777) << 16
                archive.writestr(info, str(path.readlink()))
            elif path.is_file():
                archive.write(path, name)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('app', type=Path)
    parser.add_argument('output', type=Path)
    args = parser.parse_args()
    package(args.app, args.output)
