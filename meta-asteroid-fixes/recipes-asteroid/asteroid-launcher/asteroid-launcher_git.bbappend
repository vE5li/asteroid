FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += "file://fix-cmake-module-path.patch"

DEPENDS += "mlite"
