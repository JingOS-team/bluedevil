add_library(kcm_bluetooth MODULE 
    bluetooth.cpp
    bluetoothagent.cpp
    resource.qrc
    )

find_package(Qt5 COMPONENTS Bluetooth)

kconfig_add_kcfg_files(kcm_bluetooth GENERATE_MOC
                    ../settings/filereceiversettings.kcfgc)

target_link_libraries(kcm_bluetooth
    Qt5::Gui
    Qt5::Qml
    Qt5::DBus
    KF5::CoreAddons
    KF5::ConfigGui
    KF5::QuickAddons
    KF5::I18n
    KF5::BluezQt 
    KF5::Notifications
    )
kcoreaddons_desktop_to_json(kcm_bluetooth "package/metadata.desktop")

install(FILES package/metadata.desktop RENAME bluetooth.desktop DESTINATION ${KDE_INSTALL_KSERVICES5DIR})
install(TARGETS kcm_bluetooth DESTINATION ${KDE_INSTALL_PLUGINDIR}/kcms)
kpackage_install_package(package kcm_bluetooth kcms)
