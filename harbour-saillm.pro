# NOTICE:
#
# Application name defined in TARGET has a corresponding QML filename.
# If name defined in TARGET is changed, the following needs to be done
# to match new name:
#   - corresponding QML filename must be changed
#   - desktop icon filename must be changed
#   - desktop filename must be changed
#   - icon definition filename in desktop file must be changed
#   - translation filenames have to be changed

# The name of your application
TARGET = harbour-saillm

CONFIG += sailfishapp

SOURCES += src/harbour-saillm.cpp

DISTFILES += qml/harbour-saillm.qml \
    qml/components/ToolSwitch.qml \
    qml/cover/CoverPage.qml \
    qml/tools/BuiltInToolsManager.qml \
    qml/tools/Tool.qml \
    qml/tools/ToolRegistry.js \
    qml/pages/FirstPage.qml \
    qml/pages/SettingsPage.qml \
    rpm/harbour-saillm.changes.in \
    rpm/harbour-saillm.changes.run.in \
    rpm/harbour-saillm.spec \
    translations/*.ts \
    harbour-saillm.desktop

SAILFISHAPP_ICONS = 86x86 108x108 128x128 172x172

# to disable building translations every time, comment out the
# following CONFIG line
CONFIG += sailfishapp_i18n

TRANSLATIONS += translations/harbour-saillm-ru.ts

images.files = images
images.path = /usr/share/$${TARGET}

python.files = python
python.path = /usr/share/$${TARGET}

INSTALLS += images python

DEFINES += APP_VERSION=\\\"$$VERSION\\\"
DEFINES += APP_RELEASE=\\\"$$RELEASE\\\"
include(libs/opal-cached-defines.pri)
