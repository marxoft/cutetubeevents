TARGET = cutetubeevents
QT += dbus network

LIBS += -L/opt/lib -lqyoutube -lqdailymotion -lqvimeo
CONFIG += link_prl
PKGCONFIG += \
    libqyoutube \
    libqdailymotion \
    libvimeo

HEADERS += \
    src/events.h

SOURCES += \
    src/events.cpp \
    src/main.cpp

desktop.files = desktop/cutetubeevents.desktop
desktop.path = /opt/hildonevents/settings

icon.files = desktop/cutetubeevents.png
icon.path = /usr/share/icons/hicolor/64x64/apps

settings.files = \
    src/settings/DailymotionUserDialog.qml \
    src/settings/NewFeedDialog.qml \
    src/settings/SettingsDialog.qml \
    src/settings/VimeoUserDialog.qml \
    src/settings/YouTubeUserDialog.qml
    
settings.path = /opt/cutetubeevents/settings

target.path = /opt/cutetubeevents/bin

INSTALLS += \
    target \
    desktop \
    icon \
    settings
