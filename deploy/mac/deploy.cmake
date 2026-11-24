# SPDX-FileCopyrightText: (C) 2024 Chris Rizzitello <sithlord48@gmail.com>
# SPDX-License-Identifier: MIT

set(OS_STRING "macos-${BUILD_ARCHITECTURE}")

if(BUILD_OSX_BUNDLE)
  set(APPLE_CODESIGN_IDENTITY "" CACHE STRING "Developer ID Application identity for the distribution bundle")
  if(APPLE_CODESIGN_IDENTITY)
    set(sign_option "-sign-for-notarization=${APPLE_CODESIGN_IDENTITY}")
  else()
    set(sign_option "-codesign=-")
  endif()

  install(CODE "
    set(bundle \"\$ENV{DESTDIR}\${CMAKE_INSTALL_PREFIX}/${CMAKE_PROJECT_DISPLAY_NAME}.app\")
    execute_process(COMMAND \"${DEPLOYQT}\" \"\${bundle}\"
      \"-executable=\${bundle}/Contents/MacOS/${CMAKE_PROJECT_NAME}-core\"
      -always-overwrite \"${sign_option}\"
      COMMAND_ERROR_IS_FATAL ANY)
    execute_process(COMMAND /usr/bin/codesign --verify --deep --strict \"\${bundle}\"
      COMMAND_ERROR_IS_FATAL ANY)
  ")

  set(CPACK_STRIP_FILES FALSE) # macdeployqt strips all binaries before signing.
  set(CPACK_PACKAGE_ICON "${MACOS_BUNDLE_ICON}")
  set(CPACK_DMG_VOLUME_NAME "${CMAKE_PROJECT_DISPLAY_NAME}")
  set(CPACK_DMG_SLA_USE_RESOURCE_FILE_LICENSE ON)
  set(CPACK_GENERATOR "DragNDrop")
endif()
