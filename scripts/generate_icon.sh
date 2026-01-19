#!/usr/bin/env bash
#!/usr/bin/env bash
# Copyright (C) 2026 ProcessLeash contributors
# Licensed under the GNU General Public License v3.0
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BASE_PNG="${ROOT_DIR}/Packaging/icon_base.png"
ICONSET_DIR="${ROOT_DIR}/Packaging/AppIcon.iconset"
ICNS_OUT="${ROOT_DIR}/Packaging/AppIcon.icns"
PNG_OUT="${ROOT_DIR}/Packaging/AppIcon.png"

echo "Generating base icon ${BASE_PNG}"
python3 - <<'PY'
import struct, zlib, pathlib
size = 1024
top = (54, 139, 255, 255)    # soft blue
bottom = (29, 78, 216, 255)  # deeper blue
data = bytearray()
for y in range(size):
    t = y / (size - 1)
    r = int(top[0] * (1 - t) + bottom[0] * t)
    g = int(top[1] * (1 - t) + bottom[1] * t)
    b = int(top[2] * (1 - t) + bottom[2] * t)
    a = int(top[3] * (1 - t) + bottom[3] * t)
    data.append(0)
    data.extend(bytes((r, g, b, a)) * size)
raw = zlib.compress(bytes(data), 9)
def chunk(tag, payload):
    return struct.pack(">I", len(payload)) + tag + payload + struct.pack(">I", zlib.crc32(tag + payload) & 0xFFFFFFFF)
ihdr = chunk(b'IHDR', struct.pack(">IIBBBBB", size, size, 8, 6, 0, 0, 0))
idat = chunk(b'IDAT', raw)
iend = chunk(b'IEND', b'')
png = b'\x89PNG\r\n\x1a\n' + ihdr + idat + iend
path = pathlib.Path(r'Packaging/icon_base.png')
path.write_bytes(png)
print("Base icon written:", path)
PY

echo "Building iconset"
rm -rf "${ICONSET_DIR}"
mkdir -p "${ICONSET_DIR}"

for sz in 16 32 128 256 512; do
  sips -z $sz $sz "${BASE_PNG}" --out "${ICONSET_DIR}/icon_${sz}x${sz}.png" >/dev/null
  dbl=$((sz*2))
  sips -z $dbl $dbl "${BASE_PNG}" --out "${ICONSET_DIR}/icon_${sz}x${sz}@2x.png" >/dev/null
done

echo "Converting to icns ${ICNS_OUT}"
iconutil -c icns -o "${ICNS_OUT}" "${ICONSET_DIR}"
echo "Icon generated at ${ICNS_OUT}"

echo "Exporting PNG ${PNG_OUT}"
sips -z 512 512 "${BASE_PNG}" --out "${PNG_OUT}" >/dev/null
